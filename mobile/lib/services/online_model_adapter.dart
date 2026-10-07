import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as image;

import '../domain/assistant_provider_settings.dart';
import '../domain/local_assistant_message.dart';
import 'diary_companion_prompt.dart';

/// A safe message for the UI. Provider bodies and credentials are never exposed.
class OnlineModelException implements Exception {
  const OnlineModelException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class OnlineModelAdapter {
  Stream<String> generate({
    required OnlineModelConfiguration configuration,
    required String apiKey,
    required String diary,
    required LocalAssistantTone tone,
    required String persona,
    List<String> imagePaths = const [],
  });

  Future<void> cancel();
  Future<void> dispose();
}

/// Each call owns its connection so cancellation also interrupts a slow server.
/// There are no retries, redirects, or logging of requests and provider bodies.
class OpenAiCompatibleAdapter implements OnlineModelAdapter {
  OpenAiCompatibleAdapter({
    HttpClient Function()? clientFactory,
    this.connectionTimeout = const Duration(seconds: 20),
    this.idleTimeout = const Duration(seconds: 20),
    this.totalTimeout = const Duration(seconds: 90),
    this.allowInsecureLoopback = false,
    this.maxResponseBytes = 256 * 1024,
  }) : _clientFactory = clientFactory ?? HttpClient.new;

  static const _maxOutputCharacters = 4096;
  static const _maxFrameCharacters = 64 * 1024;
  final HttpClient Function() _clientFactory;
  final Duration connectionTimeout;
  final Duration idleTimeout;
  final Duration totalTimeout;
  final bool allowInsecureLoopback;
  final int maxResponseBytes;
  _OnlineOperation? _active;
  bool _disposed = false;

  /// Provider-specific options belong only to their explicit adapter.
  Map<String, Object?> providerOptions(
    OnlineModelConfiguration configuration,
  ) => const {};

  void validateProviderResponse(Map<dynamic, dynamic> response) {}

  bool get hideThinkingTags => false;

  @override
  Stream<String> generate({
    required OnlineModelConfiguration configuration,
    required String apiKey,
    required String diary,
    required LocalAssistantTone tone,
    required String persona,
    List<String> imagePaths = const [],
  }) {
    late final StreamController<String> controller;
    _OnlineOperation? operation;
    controller = StreamController<String>(
      onListen: () {
        if (_disposed) {
          controller.addError(const OnlineModelException('线上助手已经关闭。'));
          unawaited(controller.close());
          return;
        }
        if (_active != null) {
          controller.addError(const OnlineModelException('请等待当前回复结束。'));
          unawaited(controller.close());
          return;
        }
        final current = _OnlineOperation();
        operation = current;
        _active = current;
        unawaited(
          _run(
            current,
            controller,
            configuration: configuration,
            apiKey: apiKey,
            diary: diary,
            tone: tone,
            persona: persona,
            imagePaths: List<String>.of(imagePaths),
          ),
        );
      },
      onCancel: () async {
        final current = operation;
        if (current == null) return;
        await current.cancel();
        await current.done.future;
      },
    );
    return controller.stream;
  }

  Future<void> _run(
    _OnlineOperation operation,
    StreamController<String> controller, {
    required OnlineModelConfiguration configuration,
    required String apiKey,
    required String diary,
    required LocalAssistantTone tone,
    required String persona,
    required List<String> imagePaths,
  }) async {
    try {
      _validate(configuration, apiKey);
      final text = _lastRunes(diary.trim(), 1200);
      final paths = configuration.sendImages ? imagePaths : const <String>[];
      if (text.isEmpty && paths.isEmpty) {
        throw const OnlineModelException('这条日记没有可以回复的文字或图片。');
      }
      final pictures = paths.isEmpty
          ? const <String>[]
          : await _wait(operation, _prepareImagesInWorker(paths), totalTimeout);
      if (operation.cancelled) return;
      final payload = <String, Object?>{
        'model': configuration.model.trim(),
        'messages': [
          {
            'role': 'system',
            'content': buildDiaryCompanionInstruction(
              tone: tone,
              persona: persona,
            ),
          },
          {
            'role': 'user',
            'content': pictures.isEmpty
                ? text
                : <Map<String, Object>>[
                    {
                      'type': 'text',
                      'text': text.isEmpty ? '请简短回应这条图片日记。' : text,
                    },
                    for (final picture in pictures)
                      {
                        'type': 'image_url',
                        'image_url': {'url': picture},
                      },
                  ],
          },
        ],
        'stream': true,
        'max_tokens': 256,
        'temperature': 0.7,
        ...providerOptions(configuration),
      }..removeWhere((key, value) => value == null);
      final client = _clientFactory();
      operation.client = client;
      client.connectionTimeout = connectionTimeout;
      final request = await _wait(
        operation,
        client.postUrl(configuration.completionUri),
        connectionTimeout,
      );
      request.followRedirects = false;
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${apiKey.trim()}',
      );
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await _wait(
        operation,
        request.close(),
        connectionTimeout,
      );
      if (response.statusCode != HttpStatus.ok) {
        throw _statusError(response.statusCode);
      }
      final stream = response
          .map((chunk) {
            operation.receivedBytes += chunk.length;
            if (operation.receivedBytes > maxResponseBytes) {
              throw const OnlineModelException('模型返回的内容过大，已停止接收。');
            }
            return chunk;
          })
          .transform(utf8.decoder);
      final iterator = StreamIterator<String>(stream);
      operation.iterator = iterator;
      if (response.headers.contentType?.mimeType == 'application/json') {
        final body = StringBuffer();
        while (await _wait(operation, iterator.moveNext(), idleTimeout)) {
          body.write(iterator.current);
        }
        final decoded = jsonDecode(body.toString());
        if (decoded is Map) validateProviderResponse(decoded);
        var reply = _jsonReply(decoded);
        if (hideThinkingTags) {
          final filter = _ThinkingTextFilter();
          reply = '${filter.add(reply)}${filter.finish()}';
        }
        if (reply.trim().isEmpty) {
          throw const OnlineModelException('模型没有返回回复正文，请检查所选模型。');
        }
        if (reply.length > _maxOutputCharacters) {
          throw const OnlineModelException('模型回复过长，已停止接收。');
        }
        if (!operation.cancelled) controller.add(reply);
        return;
      }
      final parser = _SseParser(maxFrameCharacters: _maxFrameCharacters);
      final output = StringBuffer();
      final thinkingFilter = hideThinkingTags ? _ThinkingTextFilter() : null;
      var lastEmittedLength = 0;
      var lastEmittedAt = -80;
      var completed = false;
      var finishedChoice = false;
      void accept(_SseEvent event) {
        if (event.data.trim() == '[DONE]') {
          completed = true;
          return;
        }
        if (event.event == 'error') {
          throw const OnlineModelException('模型服务未能完成回复，请稍后再试。');
        }
        final chunk = jsonDecode(event.data);
        if (chunk is! Map || chunk['error'] != null) {
          throw const OnlineModelException('模型服务返回了无效的回复。');
        }
        validateProviderResponse(chunk);
        final choices = chunk['choices'];
        if (choices is! List) {
          throw const OnlineModelException('模型服务返回了无效的回复。');
        }
        for (final choice in choices) {
          if (choice is! Map) continue;
          if (choice['index'] != null && choice['index'] != 0) continue;
          final rawFinish = choice['finish_reason'];
          // Some compatible services send an empty string on intermediate
          // chunks. It is not a completed choice or an error reason.
          final finish = rawFinish is String && rawFinish.trim().isEmpty
              ? null
              : rawFinish;
          if (finish != null) {
            if (finish == 'length') {
              throw const OnlineModelException('模型输出达到上限，回复未完成，请更换模型后重试。');
            }
            if (finish != 'stop') {
              throw const OnlineModelException('模型服务未能完成回复，请检查模型设置。');
            }
            finishedChoice = true;
          }
          final delta = choice['delta'];
          if (delta is Map && delta['content'] is String) {
            final content = delta['content'] as String;
            output.write(thinkingFilter?.add(content) ?? content);
          }
        }
        if (output.length > _maxOutputCharacters) {
          throw const OnlineModelException('模型回复过长，已停止接收。');
        }
        if (output.length > lastEmittedLength &&
            operation.clock.elapsedMilliseconds - lastEmittedAt >= 80 &&
            !operation.cancelled) {
          controller.add(output.toString());
          lastEmittedLength = output.length;
          lastEmittedAt = operation.clock.elapsedMilliseconds;
        }
      }

      while (!completed &&
          await _wait(operation, iterator.moveNext(), idleTimeout)) {
        for (final event in parser.add(iterator.current)) {
          accept(event);
          if (completed) break;
        }
      }
      if (!completed) {
        for (final event in parser.finish()) {
          accept(event);
        }
      }
      if (operation.cancelled) return;
      if (!completed && !finishedChoice) {
        throw const OnlineModelException('模型连接提前中断，回复未完成，请重试。');
      }
      if (thinkingFilter != null) output.write(thinkingFilter.finish());
      if (output.toString().trim().isEmpty) {
        throw const OnlineModelException('模型没有返回回复正文，请检查所选模型。');
      }
      if (output.length > lastEmittedLength) {
        controller.add(output.toString());
      }
    } on _OnlineCancelled {
      // Intentional cancellation produces neither a partial saved reply nor error.
    } catch (error) {
      if (!operation.cancelled && !controller.isClosed) {
        controller.addError(_safeError(error));
      }
    } finally {
      await operation.cancel();
      if (identical(_active, operation)) _active = null;
      if (!operation.done.isCompleted) operation.done.complete();
      if (!controller.isClosed) await controller.close();
    }
  }

  void _validate(OnlineModelConfiguration configuration, String apiKey) {
    try {
      configuration.validate(allowInsecureLoopback: allowInsecureLoopback);
    } catch (_) {
      throw const OnlineModelException('请检查 API 地址和模型名称。');
    }
    if (apiKey.trim().isEmpty || apiKey.contains(RegExp(r'[\r\n]'))) {
      throw const OnlineModelException('请先填写有效的 API Key。');
    }
    if (connectionTimeout <= Duration.zero ||
        idleTimeout <= Duration.zero ||
        totalTimeout <= Duration.zero ||
        maxResponseBytes <= 0) {
      throw const OnlineModelException('线上模型连接参数无效。');
    }
  }

  Future<T> _wait<T>(
    _OnlineOperation operation,
    Future<T> future,
    Duration idleLimit,
  ) {
    final remaining = totalTimeout - operation.clock.elapsed;
    if (remaining <= Duration.zero) {
      throw const OnlineModelException('模型回复超时，请稍后重试。');
    }
    if (operation.cancelled) throw const _OnlineCancelled();
    final limit = remaining < idleLimit ? remaining : idleLimit;
    return Future.any<T>([
      future,
      operation.cancelledSignal.future.then<T>((_) {
        throw const _OnlineCancelled();
      }),
    ]).timeout(limit);
  }

  @override
  Future<void> cancel() async {
    final current = _active;
    if (current == null) return;
    await current.cancel();
    await current.done.future;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await cancel();
  }
}

class DeepSeekAdapter extends OpenAiCompatibleAdapter {
  DeepSeekAdapter({
    super.clientFactory,
    super.connectionTimeout,
    super.idleTimeout,
    super.totalTimeout,
    super.allowInsecureLoopback,
    super.maxResponseBytes,
  });

  @override
  Map<String, Object?> providerOptions(
    OnlineModelConfiguration configuration,
  ) => const {
    'thinking': {'type': 'disabled'},
  };
}

class MiniMaxAdapter extends OpenAiCompatibleAdapter {
  MiniMaxAdapter({
    super.clientFactory,
    super.connectionTimeout,
    super.idleTimeout,
    super.totalTimeout,
    super.allowInsecureLoopback,
    super.maxResponseBytes,
  });

  @override
  Map<String, Object?> providerOptions(
    OnlineModelConfiguration configuration,
  ) => {
    'reasoning_split': true,
    'max_tokens': null,
    'max_completion_tokens': 1024,
    if (configuration.model == 'MiniMax-M3')
      'thinking': const {'type': 'disabled'}
    else
      'reasoning_effort': 'low',
  };

  @override
  bool get hideThinkingTags => true;

  @override
  void validateProviderResponse(Map<dynamic, dynamic> response) {
    final base = response['base_resp'];
    if (base is! Map || base['status_code'] == null) return;
    final code = base['status_code'];
    if (code == 0) return;
    throw switch (code) {
      1004 || 2049 => const OnlineModelException('API Key 无效或已过期，请重新填写。'),
      1008 => const OnlineModelException('模型服务余额不足，请检查账户余额。'),
      1002 ||
      1039 ||
      2056 => const OnlineModelException('模型服务请求受限，请检查额度或稍后重试。'),
      1001 => const OnlineModelException('模型服务响应超时，请稍后重试。'),
      2013 => const OnlineModelException('模型不接受当前参数，请检查所选模型。'),
      _ => const OnlineModelException('模型服务未能完成回复，请检查服务配置或稍后重试。'),
    };
  }
}

class _OnlineOperation {
  final clock = Stopwatch()..start();
  final cancelledSignal = Completer<void>();
  final done = Completer<void>();
  HttpClient? client;
  StreamIterator<String>? iterator;
  int receivedBytes = 0;
  bool cancelled = false;

  Future<void> cancel() async {
    if (cancelled) return;
    cancelled = true;
    cancelledSignal.complete();
    client?.close(force: true);
    final current = iterator;
    iterator = null;
    if (current != null) {
      try {
        await current.cancel();
      } catch (_) {
        // The forced connection close can surface through the iterator.
      }
    }
  }
}

class _OnlineCancelled implements Exception {
  const _OnlineCancelled();
}

/// A defensive fallback for services that ignore reasoning_split. The parser
/// retains incomplete tag prefixes across chunks, so thought fragments never
/// flash briefly in the diary UI before a closing tag arrives.
class _ThinkingTextFilter {
  String _pending = '';
  bool _thinking = false;

  String add(String text) {
    _pending += text;
    final visible = StringBuffer();
    while (_pending.isNotEmpty) {
      final angle = _pending.indexOf('<');
      if (angle == -1) {
        if (!_thinking) visible.write(_pending);
        _pending = '';
        break;
      }
      if (angle > 0) {
        if (!_thinking) visible.write(_pending.substring(0, angle));
        _pending = _pending.substring(angle);
      }
      final lower = _pending.toLowerCase();
      if (lower.startsWith('<think>')) {
        _thinking = true;
        _pending = _pending.substring(7);
      } else if (lower.startsWith('</think>')) {
        _thinking = false;
        _pending = _pending.substring(8);
      } else if ('<think>'.startsWith(lower) || '</think>'.startsWith(lower)) {
        break;
      } else {
        if (!_thinking) visible.write(_pending[0]);
        _pending = _pending.substring(1);
      }
    }
    return visible.toString();
  }

  String finish() {
    final visible = _thinking ? '' : _pending;
    _pending = '';
    return visible;
  }
}

OnlineModelException _safeError(Object error) {
  if (error is OnlineModelException) return error;
  if (error is TimeoutException) {
    return const OnlineModelException('模型回复超时，请检查网络或稍后重试。');
  }
  if (error is HandshakeException) {
    return const OnlineModelException('无法建立安全连接，请检查 API 地址和网络。');
  }
  if (error is SocketException || error is HttpException) {
    return const OnlineModelException('无法连接模型服务，请检查网络和 API 地址。');
  }
  return const OnlineModelException('模型服务返回了无法读取的回复，请检查服务配置。');
}

OnlineModelException _statusError(int status) => switch (status) {
  >= 300 && < 400 => const OnlineModelException(
    'API 地址发生重定向，请填写服务的最终 HTTPS 地址。',
  ),
  400 || 422 => const OnlineModelException('模型服务不接受当前请求，请检查模型名称和图片支持。'),
  401 => const OnlineModelException('API Key 无效或已过期，请重新填写。'),
  402 => const OnlineModelException('模型服务余额不足，请检查账户余额。'),
  403 => const OnlineModelException('当前 API Key 没有访问权限，请检查账户和模型权限。'),
  404 => const OnlineModelException('未找到模型接口，请检查 API 地址和模型名称。'),
  408 || 504 => const OnlineModelException('模型服务响应超时，请稍后重试。'),
  413 => const OnlineModelException('模型服务不接受当前图片大小，请减少图片数量。'),
  429 => const OnlineModelException('模型服务请求受限，请检查额度或稍后重试。'),
  >= 500 => const OnlineModelException('模型服务暂时不可用，请稍后重试。'),
  _ => const OnlineModelException('模型服务拒绝了请求，请检查服务配置。'),
};

String _jsonReply(dynamic value) {
  if (value is! Map || value['error'] != null) {
    throw const OnlineModelException('模型服务返回了无效的回复。');
  }
  final choices = value['choices'];
  if (choices is! List || choices.isEmpty) return '';
  final choice = choices.first;
  if (choice is! Map) return '';
  final message = choice['message'];
  if (message is! Map || message['content'] is! String) return '';
  return message['content'] as String;
}

String _lastRunes(String text, int limit) {
  final runes = text.runes.toList(growable: false);
  return String.fromCharCodes(runes.skip(math.max(0, runes.length - limit)));
}

class _SseEvent {
  const _SseEvent(this.data, this.event);
  final String data;
  final String? event;
}

class _SseParser {
  _SseParser({required this.maxFrameCharacters});
  final int maxFrameCharacters;
  String _pending = '';
  final List<String> _data = [];
  String? _event;
  int _frameCharacters = 0;

  List<_SseEvent> add(String text) {
    _pending += text;
    final events = <_SseEvent>[];
    while (true) {
      final newline = _pending.indexOf(RegExp(r'[\r\n]'));
      if (newline == -1) break;
      if (_pending[newline] == '\r' && newline == _pending.length - 1) break;
      final consumed =
          _pending[newline] == '\r' &&
              newline + 1 < _pending.length &&
              _pending[newline + 1] == '\n'
          ? 2
          : 1;
      _line(_pending.substring(0, newline), events);
      _pending = _pending.substring(newline + consumed);
    }
    if (_pending.length + _frameCharacters > maxFrameCharacters) {
      throw const OnlineModelException('模型返回的数据片段过大，已停止接收。');
    }
    return events;
  }

  List<_SseEvent> finish() {
    final events = <_SseEvent>[];
    if (_pending.isNotEmpty) {
      _line(_pending.replaceFirst(RegExp(r'\r$'), ''), events);
      _pending = '';
    }
    _line('', events);
    return events;
  }

  void _line(String line, List<_SseEvent> events) {
    if (line.isEmpty) {
      if (_data.isNotEmpty) events.add(_SseEvent(_data.join('\n'), _event));
      _data.clear();
      _event = null;
      _frameCharacters = 0;
      return;
    }
    _frameCharacters += line.length;
    if (_frameCharacters > maxFrameCharacters) {
      throw const OnlineModelException('模型返回的数据片段过大，已停止接收。');
    }
    if (line.startsWith(':')) return;
    final colon = line.indexOf(':');
    final field = colon == -1 ? line : line.substring(0, colon);
    var value = colon == -1 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    if (field == 'data') _data.add(value);
    if (field == 'event') _event = value;
  }
}

// Isolating the closure here prevents capturing a request's unsendable client
// or stream controller from the surrounding HTTP method.
Future<List<String>> _prepareImagesInWorker(List<String> paths) =>
    Isolate.run(() => _prepareImages(paths));

List<String> _prepareImages(List<String> paths) {
  const maxImages = 4;
  const maxSourceBytes = 20 * 1024 * 1024;
  const maxEncodedBytes = 1024 * 1024;
  const maxTotalBytes = 4 * 1024 * 1024;
  if (paths.length > maxImages) {
    throw const OnlineModelException('每条日记最多发送 4 张图片，请减少图片数量。');
  }
  final pictures = <String>[];
  var total = 0;
  try {
    for (final path in paths) {
      final file = File(path);
      final length = file.lengthSync();
      if (length <= 0 || length > maxSourceBytes) {
        throw const OnlineModelException('图片无法读取或过大，请选择小于 20 MB 的图片。');
      }
      final handle = file.openSync();
      late final Uint8List bytes;
      try {
        bytes = handle.readSync(length + 1);
      } finally {
        handle.closeSync();
      }
      if (bytes.length != length) {
        throw const OnlineModelException('图片无法读取或内容已变化，请重新选择图片。');
      }
      final decoder = image.findDecoderForData(bytes);
      if (decoder == null ||
          !const {
            image.ImageFormat.jpg,
            image.ImageFormat.png,
            image.ImageFormat.webp,
            image.ImageFormat.gif,
          }.contains(decoder.format)) {
        throw const OnlineModelException('图片无法读取，仅支持 JPEG、PNG、WebP 和 GIF。');
      }
      final info = decoder.startDecode(bytes);
      if (info == null ||
          info.width <= 0 ||
          info.height <= 0 ||
          info.width > 16384 ||
          info.height > 16384 ||
          info.width * info.height > 16000000) {
        throw const OnlineModelException('图片无法读取或尺寸过大，请先缩小图片。');
      }
      final decoded = decoder.decodeFrame(0);
      if (decoded == null) {
        throw const OnlineModelException('图片无法读取，请重新选择图片。');
      }
      final upright = image.bakeOrientation(decoded);
      final scale = math.min(
        1.0,
        1024 / math.max(upright.width, upright.height),
      );
      final resized = scale < 1
          ? image.copyResize(
              upright,
              width: math.max(1, (upright.width * scale).round()),
              height: math.max(1, (upright.height * scale).round()),
              interpolation: image.Interpolation.average,
            )
          : upright;
      // Re-encode only pixels; location, camera and other metadata stay local.
      resized.exif = image.ExifData();
      resized.iccProfile = null;
      final encoded = image.encodeJpg(resized, quality: 80);
      total += encoded.length;
      if (encoded.length > maxEncodedBytes || total > maxTotalBytes) {
        throw const OnlineModelException('处理后的图片仍然过大，请减少图片或缩小尺寸。');
      }
      pictures.add('data:image/jpeg;base64,${base64Encode(encoded)}');
    }
    return pictures;
  } on OnlineModelException {
    rethrow;
  } catch (_) {
    throw const OnlineModelException('图片无法读取，请重新选择图片。');
  }
}
