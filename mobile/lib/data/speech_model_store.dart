import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'speech_model_license.dart';

class SpeechModelFiles {
  const SpeechModelFiles({required this.modelPath, required this.tokensPath});

  final String modelPath;
  final String tokensPath;
}

class SpeechModelException implements Exception {
  const SpeechModelException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SpeechModelCancelled implements Exception {
  const SpeechModelCancelled();
}

/// URLs and checksums are pinned to the official sherpa-onnx conversion.
class SpeechModelPackage {
  const SpeechModelPackage({
    required this.modelUrl,
    required this.tokensUrl,
    required this.modelBytes,
    required this.tokensBytes,
    required this.modelSha256,
    required this.tokensSha256,
  });

  static const senseVoice = SpeechModelPackage(
    modelUrl:
        'https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/2365baeacb507f821a0c8120fcee3d484dba7a07/model.int8.onnx',
    tokensUrl:
        'https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17/resolve/2365baeacb507f821a0c8120fcee3d484dba7a07/tokens.txt',
    modelBytes: 239233841,
    tokensBytes: 315894,
    modelSha256:
        'c71f0ce00bec95b07744e116345e33d8cbbe08cef896382cf907bf4b51a2cd51',
    tokensSha256:
        'f449eb28dc567533d7fa59be34e2abca8784f771850c78a47fb731a31429a1dc',
  );

  final String modelUrl;
  final String tokensUrl;
  final int modelBytes;
  final int tokensBytes;
  final String modelSha256;
  final String tokensSha256;
  int get totalBytes => modelBytes + tokensBytes;
}

/// Speech resources and preferences live outside diary export/sync data.
/// Constructing or reading this store never makes a network request.
class SpeechModelStore {
  SpeechModelStore({
    Future<Directory> Function()? directoryProvider,
    HttpClient Function()? clientFactory,
    this.package = SpeechModelPackage.senseVoice,
    this.transferTimeout = const Duration(minutes: 20),
    this.idleTimeout = const Duration(seconds: 30),
  }) : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory,
       _clientFactory = clientFactory ?? HttpClient.new;

  static const modelName = 'SenseVoice Small int8';
  static const modelLicenseUrl =
      'https://github.com/modelscope/FunASR/blob/main/MODEL_LICENSE';
  static const modelSourceUrl =
      'https://huggingface.co/csukuangfj/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17';
  final Future<Directory> Function() _directoryProvider;
  final HttpClient Function() _clientFactory;
  final SpeechModelPackage package;
  final Duration transferTimeout;
  final Duration idleTimeout;
  _SpeechDownload? _download;
  bool _disposed = false;
  Future<void> _settingsWrites = Future<void>.value();

  Future<Directory> _root() async =>
      Directory(p.join((await _directoryProvider()).path, 'speech-models'));

  Future<SpeechModelFiles?> installed() async {
    final root = await _root();
    final directory = Directory(p.join(root.path, 'sensevoice-int8-2024'));
    final model = File(p.join(directory.path, 'model.int8.onnx'));
    final tokens = File(p.join(directory.path, 'tokens.txt'));
    final marker = File(p.join(directory.path, 'verified.json'));
    try {
      if (!await model.exists() ||
          !await tokens.exists() ||
          !await marker.exists() ||
          await model.length() != package.modelBytes ||
          await tokens.length() != package.tokensBytes ||
          await marker.length() > 4096) {
        return null;
      }
      final metadata = jsonDecode(await marker.readAsString());
      if (metadata is! Map ||
          metadata['modelSha256'] != package.modelSha256 ||
          metadata['tokensSha256'] != package.tokensSha256) {
        return null;
      }
      return SpeechModelFiles(modelPath: model.path, tokensPath: tokens.path);
    } catch (_) {
      return null;
    }
  }

  Future<bool> readAutoTranscribe() async {
    await _settingsWrites;
    final root = await _root();
    final file = File(p.join(root.path, 'settings.json'));
    try {
      if (!await file.exists() || await file.length() > 4096) return false;
      final value = jsonDecode(await file.readAsString());
      return value is Map && value['autoTranscribe'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> writeAutoTranscribe(bool enabled) {
    final next = _settingsWrites.then((_) async {
      final root = await _root();
      await root.create(recursive: true);
      final file = File(p.join(root.path, 'settings.json'));
      final staging = File('${file.path}.part');
      try {
        await staging.writeAsString(
          jsonEncode({'version': 1, 'autoTranscribe': enabled}),
          flush: true,
        );
        await staging.rename(file.path);
      } finally {
        if (await staging.exists()) await staging.delete();
      }
    });
    _settingsWrites = next.catchError((Object _) {});
    return next;
  }

  Future<SpeechModelFiles> download({void Function(double)? onProgress}) async {
    if (_disposed) throw const SpeechModelException('语音模型管理已经关闭。');
    if (_download != null) throw const SpeechModelException('语音模型正在下载，请稍候。');
    final operation = _SpeechDownload();
    _download = operation;
    Directory? staging;
    final deadline = Timer(transferTimeout, () {
      operation.timedOut = true;
      operation.cancel();
    });
    try {
      final existing = await installed();
      operation.check();
      if (existing != null) {
        onProgress?.call(1);
        return existing;
      }
      if (package.modelBytes <= 0 ||
          package.modelBytes > 300 * 1024 * 1024 ||
          package.tokensBytes <= 0 ||
          package.tokensBytes > 2 * 1024 * 1024) {
        throw const SpeechModelException('语音模型下载配置无效。');
      }
      final root = await _root();
      await root.create(recursive: true);
      staging = await root.createTemp('sensevoice-install-');
      final client = _clientFactory()..connectionTimeout = idleTimeout;
      operation.client = client;
      onProgress?.call(0);
      var transferred = 0;
      final progressClock = Stopwatch()..start();
      var lastProgressAt = -80;
      for (final item in [
        (
          name: 'model.int8.onnx',
          url: package.modelUrl,
          bytes: package.modelBytes,
        ),
        (
          name: 'tokens.txt',
          url: package.tokensUrl,
          bytes: package.tokensBytes,
        ),
      ]) {
        operation.check();
        final request = await _wait(
          operation,
          client.getUrl(Uri.parse(item.url)),
        );
        final response = await _wait(operation, request.close());
        if (response.statusCode != HttpStatus.ok) {
          throw const SpeechModelException('语音模型下载失败，请检查网络后重试。');
        }
        if (response.contentLength >= 0 &&
            response.contentLength != item.bytes) {
          throw const SpeechModelException('语音模型文件大小不匹配，请重新下载。');
        }
        final file = File(p.join(staging.path, item.name));
        final sink = file.openWrite();
        final iterator = StreamIterator<List<int>>(response);
        operation.iterator = iterator;
        var received = 0;
        try {
          while (await _wait(operation, iterator.moveNext())) {
            received += iterator.current.length;
            if (received > item.bytes) {
              throw const SpeechModelException('语音模型文件大小不匹配，已停止下载。');
            }
            sink.add(iterator.current);
            await sink.flush();
            operation.check();
            if (progressClock.elapsedMilliseconds - lastProgressAt >= 80 ||
                received == item.bytes) {
              lastProgressAt = progressClock.elapsedMilliseconds;
              onProgress?.call(
                ((transferred + received) / package.totalBytes) * 0.95,
              );
            }
          }
        } finally {
          await iterator.cancel();
          operation.iterator = null;
          await sink.close();
        }
        operation.check();
        if (received != item.bytes) {
          throw const SpeechModelException('语音模型下载不完整，请重新下载。');
        }
        transferred += received;
      }
      final stagingPath = staging.path;
      final specification = package;
      // Release verification file handles before cancellation removes staging.
      await _verifyPackageInWorker(
        stagingPath,
        specification,
      ).timeout(idleTimeout);
      operation.check();
      await File(p.join(staging.path, 'MODEL_LICENSE.txt')).writeAsString(
        'SenseVoice Small by Alibaba / FunAudioLLM.\n'
        'ONNX int8 conversion by sherpa-onnx / csukuangfj.\n'
        'License source: $modelLicenseUrl\n'
        'Model source: $modelSourceUrl\n\n'
        '$senseVoiceModelLicense\n',
        flush: true,
      );
      await File(p.join(staging.path, 'verified.json')).writeAsString(
        jsonEncode({
          'version': 1,
          'modelSha256': package.modelSha256,
          'tokensSha256': package.tokensSha256,
        }),
        flush: true,
      );
      operation.check();
      final destination = Directory(p.join(root.path, 'sensevoice-int8-2024'));
      // An invalid old install is moved aside until the complete new pair lands.
      Directory? previous;
      if (await destination.exists()) {
        previous = await destination.rename('${staging.path}.previous');
      }
      try {
        await staging.rename(destination.path);
        staging = null;
      } catch (_) {
        if (previous != null) await previous.rename(destination.path);
        rethrow;
      }
      if (previous != null) await _deleteInstall(root, previous);
      onProgress?.call(1);
      return SpeechModelFiles(
        modelPath: p.join(destination.path, 'model.int8.onnx'),
        tokensPath: p.join(destination.path, 'tokens.txt'),
      );
    } on SpeechModelCancelled {
      rethrow;
    } on SpeechModelException {
      rethrow;
    } catch (_) {
      operation.check();
      throw const SpeechModelException('语音模型下载失败，请检查网络或稍后重试。');
    } finally {
      deadline.cancel();
      try {
        await operation.cancel();
        if (staging != null) await _deleteInstall(await _root(), staging);
      } finally {
        if (identical(_download, operation)) _download = null;
        operation.done.complete();
      }
    }
  }

  Future<T> _wait<T>(_SpeechDownload operation, Future<T> future) {
    operation.check();
    return Future.any<T>([
      future,
      operation.signal.future.then<T>((_) {
        operation.check();
        throw const SpeechModelCancelled();
      }),
    ]).timeout(idleTimeout);
  }

  Future<void> cancelDownload() async {
    final current = _download;
    if (current == null) return;
    await current.cancel();
    await current.done.future;
  }

  Future<void> remove() async {
    await cancelDownload();
    final root = await _root();
    final directory = Directory(p.join(root.path, 'sensevoice-int8-2024'));
    await _deleteInstall(root, directory);
    await writeAutoTranscribe(false);
  }

  Future<void> dispose() async {
    _disposed = true;
    await cancelDownload();
    await _settingsWrites;
  }
}

class _SpeechDownload {
  final signal = Completer<void>();
  final done = Completer<void>();
  HttpClient? client;
  StreamIterator<List<int>>? iterator;
  bool cancelled = false;
  bool timedOut = false;

  Future<void> cancel() async {
    if (cancelled) return;
    cancelled = true;
    signal.complete();
    client?.close(force: true);
    try {
      await iterator?.cancel();
    } catch (_) {
      // Closing a paused connection may surface as an iterator error.
    }
  }

  void check() {
    if (timedOut) throw const SpeechModelException('语音模型下载超时，请稍后重试。');
    if (cancelled) throw const SpeechModelCancelled();
  }
}

// Keep the isolate closure outside the store's HTTP/download object scope.
Future<void> _verifyPackageInWorker(
  String directory,
  SpeechModelPackage specification,
) => Isolate.run(() => _verifyPackage(directory, specification));

Future<void> _verifyPackage(
  String directory,
  SpeechModelPackage specification,
) async {
  for (final item in [
    (
      name: 'model.int8.onnx',
      bytes: specification.modelBytes,
      digest: specification.modelSha256,
    ),
    (
      name: 'tokens.txt',
      bytes: specification.tokensBytes,
      digest: specification.tokensSha256,
    ),
  ]) {
    final file = File(p.join(directory, item.name));
    if (await file.length() != item.bytes ||
        (await sha256.bind(file.openRead()).first).toString() != item.digest) {
      throw const SpeechModelException('语音模型校验失败，请重新下载。');
    }
  }
}

Future<void> _deleteInstall(Directory root, Directory directory) async {
  final target = p.normalize(directory.absolute.path);
  if (!p.equals(p.dirname(target), p.normalize(root.absolute.path)) ||
      !(p.basename(target) == 'sensevoice-int8-2024' ||
          p.basename(target).startsWith('sensevoice-install-'))) {
    throw const SpeechModelException('无法清理语音模型临时文件。');
  }
  if (await directory.exists()) await directory.delete(recursive: true);
}
