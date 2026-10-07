import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:llamadart/llamadart.dart';

import '../domain/local_assistant_message.dart';
import 'diary_companion_prompt.dart';

/// Text never leaves the device through this interface.
abstract interface class LocalLlmEngine {
  Future<void> load(String path);
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  });
  Future<void> cancel();
  Future<void> unload();
  Future<void> dispose();
}

/// Checks model headers before handing a file to the native runtime.
///
/// This deliberately supports only small Qwen2/Qwen3 text models in the first
/// release. Reading the bounded metadata and tensor table happens off the UI
/// isolate; neither validation nor inference downloads model files.
Future<void> validateLocalLlmModel(String path) =>
    Isolate.run(() => _validateGguf(path));

class LlamadartLocalLlmEngine implements LocalLlmEngine {
  LlamadartLocalLlmEngine({int? seed}) : _seed = seed;

  static const _capabilities = MethodChannel('com.ling.diary/local_assistant');
  static const _contextSize = 2048;
  static const _replyTokens = 128;
  static const _promptBudget = _contextSize - _replyTokens - 64;
  final int? _seed;

  LlamaEngine? _engine;
  String? _loadedPath;
  Future<void> _lifecycle = Future<void>.value();
  Completer<void>? _generationDone;
  int _generationEpoch = 0;
  bool _disposed = false;

  bool get isLoaded => _engine?.isReady ?? false;
  bool get isGenerating => _generationDone != null;

  @override
  Future<void> load(String path) => _serialize(() async {
    if (_disposed) throw StateError('本地助手已经关闭。');
    if (_loadedPath == path && isLoaded) return;
    if (Platform.isAndroid) {
      final capabilities = await _capabilities.invokeMapMethod<String, dynamic>(
        'capabilities',
      );
      if (capabilities?['supported'] != true) {
        throw UnsupportedError('本地助手需要 Android 10 或更新版本和 64 位设备。');
      }
    }
    await validateLocalLlmModel(path);
    await _releaseEngine();

    final engine = LlamaEngine(LlamaBackend());
    _engine = engine;
    final threads = math.max(1, math.min(3, Platform.numberOfProcessors - 1));
    try {
      // Native logging can include prompts; disable it for a private diary.
      await engine.setLogLevel(LlamaLogLevel.none);
      await engine.loadModel(
        path,
        modelParams: ModelParams(
          contextSize: _contextSize,
          preferredBackend: GpuBackend.cpu,
          gpuLayers: 0,
          numberOfThreads: threads,
          numberOfThreadsBatch: threads,
          batchSize: 128,
          microBatchSize: 64,
          useMmap: true,
          useMlock: false,
        ),
      );
      _loadedPath = path;
    } catch (_) {
      await _releaseEngine();
      rethrow;
    }
  });

  @override
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  }) async* {
    final engine = _engine;
    if (_disposed || engine == null || !engine.isReady) {
      throw StateError('请先下载或导入模型，再启用本地助手。');
    }
    if (_generationDone != null) {
      throw StateError('请等待当前回复结束。');
    }
    final done = Completer<void>();
    _generationDone = done;
    final epoch = ++_generationEpoch;
    final output = StringBuffer();
    final clock = Stopwatch()..start();
    var lastEmittedAt = -80;
    var lastEmittedLength = 0;
    try {
      final prompt = await _fitPrompt(engine, messages, tone, persona);
      if (epoch != _generationEpoch) return;

      // llamadart loads, prefills, and decodes on its native worker isolate.
      // The UI receives cumulative snapshots at most once every 80 ms.
      await for (final chunk in engine.create(
        prompt,
        enableThinking: false,
        params: GenerationParams(
          maxTokens: _replyTokens,
          temp: 0.5,
          topP: 0.8,
          topK: 20,
          minP: 0,
          penalty: 1.0,
          seed: _seed,
          thinkingBudget: const ThinkingBudget(maxTokens: 0),
        ),
      )) {
        if (epoch != _generationEpoch) break;
        for (final choice in chunk.choices) {
          final text = choice.delta.content;
          if (text != null) output.write(text);
        }
        if (output.length > lastEmittedLength &&
            clock.elapsedMilliseconds - lastEmittedAt >= 80) {
          lastEmittedAt = clock.elapsedMilliseconds;
          lastEmittedLength = output.length;
          yield output.toString();
        }
      }
      if (epoch == _generationEpoch && output.length > lastEmittedLength) {
        yield output.toString();
      }
    } finally {
      // This also runs when the listener cancels its stream subscription.
      engine.cancelGeneration();
      clock.stop();
      _generationDone = null;
      if (!done.isCompleted) done.complete();
    }
  }

  Future<List<LlamaChatMessage>> _fitPrompt(
    LlamaEngine engine,
    List<LocalAssistantMessage> messages,
    LocalAssistantTone tone,
    String persona,
  ) async {
    if (messages.isEmpty ||
        messages.last.role != LocalAssistantRole.user ||
        messages.last.text.trim().isEmpty) {
      throw ArgumentError('需要一条有文字的日记。');
    }
    // Only this diary is visible to the model. Older messages in a caller's
    // list are deliberately ignored, and the original diary is never edited.
    var diary = _lastRunes(messages.last.text, 800);
    var character = String.fromCharCodes(persona.trim().runes.take(600));
    if (character.isEmpty) character = defaultLocalAssistantPersona;
    while (true) {
      final prompt = [
        LlamaChatMessage.fromText(
          role: LlamaChatRole.system,
          text: buildDiaryCompanionInstruction(
            tone: tone,
            persona: character,
            compact: true,
          ),
        ),
        // Fixed examples show how to respond, rather than rewrite a diary.
        // They are unrelated to the user's private entries or reply history.
        LlamaChatMessage.fromText(
          role: LlamaChatRole.user,
          text: '还没吃晚饭，好饿，打算点个外卖。',
        ),
        LlamaChatMessage.fromText(
          role: LlamaChatRole.assistant,
          text: '晚饭还没吃上，饿着肚子的感觉真不好受。',
        ),
        LlamaChatMessage.fromText(
          role: LlamaChatRole.user,
          text: '今天自己修好了椅子，嘿嘿。',
        ),
        LlamaChatMessage.fromText(
          role: LlamaChatRole.assistant,
          text: '自己修好的成就感可真不错，椅子又能接着用了！',
        ),
        LlamaChatMessage.fromText(role: LlamaChatRole.user, text: diary),
      ];
      final template = await engine.chatTemplate(prompt, enableThinking: false);
      final count =
          template.tokenCount ??
          (await engine.tokenize(template.prompt)).length;
      if (count <= _promptBudget) return prompt;
      final diaryRunes = diary.runes.toList(growable: false);
      final characterRunes = character.runes.toList(growable: false);
      if (diaryRunes.length > 160) {
        diary = String.fromCharCodes(diaryRunes.skip(diaryRunes.length ~/ 4));
      } else if (characterRunes.length > 64) {
        character = String.fromCharCodes(
          characterRunes.take(characterRunes.length * 3 ~/ 4),
        );
      } else if (diaryRunes.length > 32) {
        diary = String.fromCharCodes(diaryRunes.skip(diaryRunes.length ~/ 4));
      } else {
        throw StateError('模型的对话模板过长，请换用推荐模型。');
      }
    }
  }

  @override
  Future<void> cancel() async {
    ++_generationEpoch;
    _engine?.cancelGeneration();
    final done = _generationDone;
    if (done != null) await done.future;
  }

  @override
  Future<void> unload() => _serialize(_releaseEngine);

  @override
  Future<void> dispose() {
    _disposed = true;
    return _serialize(_releaseEngine);
  }

  Future<void> _releaseEngine() async {
    await cancel();
    final engine = _engine;
    _engine = null;
    _loadedPath = null;
    if (engine != null) await engine.dispose();
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _lifecycle.then((_) => operation());
    _lifecycle = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }
}

String _lastRunes(String text, int count) {
  // Examine only a bounded suffix instead of allocating runes for a long diary
  // on the UI isolate. Avoid beginning halfway through a UTF-16 surrogate pair.
  var start = math.max(0, text.length - count * 2 - 2);
  if (start < text.length &&
      text.codeUnitAt(start) >= 0xDC00 &&
      text.codeUnitAt(start) <= 0xDFFF) {
    start++;
  }
  final runes = text.substring(start).runes.toList(growable: false);
  return String.fromCharCodes(runes.skip(math.max(0, runes.length - count)));
}

void _validateGguf(String path) {
  const maximumBytes = 3 * 1024 * 1024 * 1024;
  final file = File(path);
  final length = file.lengthSync();
  if (length < 24 || length > maximumBytes) {
    throw const FormatException('请使用不超过 3 GB 的 Qwen GGUF 模型。');
  }
  final handle = file.openSync();
  late final Uint8List bytes;
  try {
    bytes = handle.readSync(math.min(length, 32 * 1024 * 1024));
  } finally {
    handle.closeSync();
  }
  final reader = _GgufReader(bytes);
  if (reader.uint32() != 0x46554747) {
    throw const FormatException('文件不是有效的 GGUF 模型。');
  }
  final version = reader.uint32();
  if (version != 2 && version != 3) {
    throw const FormatException('不支持这个 GGUF 文件版本。');
  }
  final tensorCount = reader.uint64();
  final metadataCount = reader.uint64();
  if (tensorCount < 1 ||
      tensorCount > 1024 ||
      metadataCount < 1 ||
      metadataCount > 128) {
    throw const FormatException('模型的元数据或张量数量不合理。');
  }
  final values = <String, Object>{};
  final keys = <String>{};
  for (var i = 0; i < metadataCount; i++) {
    final key = reader.string(maximumLength: 256);
    if (!keys.add(key)) {
      throw const FormatException('模型含有重复的元数据字段。');
    }
    final type = reader.uint32();
    if (key == 'general.architecture') {
      if (type != 8) throw const FormatException('模型架构信息无效。');
      values[key] = reader.string(maximumLength: 64);
    } else if (key == 'general.alignment' ||
        key.endsWith('.block_count') ||
        key.endsWith('.embedding_length') ||
        key.endsWith('.feed_forward_length') ||
        key.endsWith('.attention.head_count') ||
        key.endsWith('.attention.head_count_kv') ||
        key.endsWith('.attention.key_length') ||
        key.endsWith('.attention.value_length') ||
        key.endsWith('.rope.dimension_count')) {
      values[key] = reader.integer(type);
    } else {
      reader.skipValue(type);
    }
  }
  final architecture = values['general.architecture'];
  if (architecture != 'qwen2' && architecture != 'qwen3') {
    throw const FormatException('目前支持 Qwen2 和 Qwen3 的小型文字对话模型。');
  }
  final blocks = values['$architecture.block_count'];
  final embedding = values['$architecture.embedding_length'];
  if (blocks is! int ||
      blocks < 1 ||
      blocks > 36 ||
      embedding is! int ||
      embedding < 1 ||
      embedding > 2560) {
    throw const FormatException('模型过大或结构不受支持，请使用推荐的小型模型。');
  }
  final heads = values['$architecture.attention.head_count'];
  final kvHeads = values['$architecture.attention.head_count_kv'];
  final feedForward = values['$architecture.feed_forward_length'];
  if (heads is! int ||
      heads < 1 ||
      heads > 64 ||
      kvHeads is! int ||
      kvHeads < 1 ||
      kvHeads > heads ||
      heads % kvHeads != 0 ||
      feedForward is! int ||
      feedForward < 1 ||
      feedForward > 16384) {
    throw const FormatException('模型的注意力或前馈层结构不合理。');
  }
  for (final suffix in [
    'attention.key_length',
    'attention.value_length',
    'rope.dimension_count',
  ]) {
    final value = values['$architecture.$suffix'];
    if (value != null && (value is! int || value < 1 || value > 256)) {
      throw const FormatException('模型的注意力维度不受支持。');
    }
  }
  final alignment = values['general.alignment'] ?? 32;
  if (alignment is! int ||
      alignment < 8 ||
      alignment > 4096 ||
      alignment & (alignment - 1) != 0) {
    throw const FormatException('模型数据对齐信息无效。');
  }
  final tensors = <({int offset, int bytes})>[];
  var parameters = 0;
  for (var i = 0; i < tensorCount; i++) {
    reader.string(maximumLength: 256);
    final dimensions = reader.uint32();
    if (dimensions < 1 || dimensions > 4) {
      throw const FormatException('模型张量维数无效。');
    }
    var elements = 1;
    var firstDimension = 0;
    for (var d = 0; d < dimensions; d++) {
      final size = reader.uint64();
      if (size < 1 || size > 200000) {
        throw const FormatException('模型张量大小不合理。');
      }
      if (d == 0) firstDimension = size;
      elements *= size;
      if (elements > 500000000) {
        throw const FormatException('模型张量过大。');
      }
    }
    parameters += elements;
    // Some GGUF conversions store a tied vocabulary projection separately,
    // so a 1.7B model can contain more than 2B stored tensor elements.
    if (parameters > 4500000000) {
      throw const FormatException('模型的张量总量超出支持范围，请使用推荐模型。');
    }
    final type = reader.uint32();
    final layout = _tensorLayouts[type];
    if (layout == null || firstDimension % layout.$1 != 0) {
      throw const FormatException('模型使用了不支持的量化格式。');
    }
    final offset = reader.uint64();
    if (offset % alignment != 0) {
      throw const FormatException('模型张量偏移无效。');
    }
    tensors.add((offset: offset, bytes: elements ~/ layout.$1 * layout.$2));
  }
  final dataStart = (reader.position + alignment - 1) ~/ alignment * alignment;
  tensors.sort((a, b) => a.offset.compareTo(b.offset));
  var previousEnd = 0;
  for (final tensor in tensors) {
    final end = tensor.offset + tensor.bytes;
    if (tensor.offset < previousEnd || dataStart + end > length) {
      throw const FormatException('模型文件不完整或张量数据无效。');
    }
    previousEnd = end;
  }
}

// GGML block length and stored byte size for the supported GGUF tensor types.
const _tensorLayouts = <int, (int, int)>{
  0: (1, 4), // F32
  1: (1, 2), // F16
  2: (32, 18), // Q4_0
  3: (32, 20), // Q4_1
  6: (32, 22), // Q5_0
  7: (32, 24), // Q5_1
  8: (32, 34), // Q8_0
  10: (256, 84), // Q2_K
  11: (256, 110), // Q3_K
  12: (256, 144), // Q4_K
  13: (256, 176), // Q5_K
  14: (256, 210), // Q6_K
  15: (256, 292), // Q8_K
  30: (1, 2), // BF16
};

class _GgufReader {
  _GgufReader(this.bytes) : data = ByteData.sublistView(bytes);

  final Uint8List bytes;
  final ByteData data;
  int position = 0;

  void skip(int count) {
    if (count < 0 || position + count > bytes.length) {
      throw const FormatException('GGUF 元数据不完整或过大。');
    }
    position += count;
  }

  int uint32() {
    final start = position;
    skip(4);
    return data.getUint32(start, Endian.little);
  }

  int uint64() {
    final start = position;
    skip(8);
    final value = data.getUint64(start, Endian.little);
    if (value < 0) throw const FormatException('GGUF 数值超出范围。');
    return value;
  }

  String string({required int maximumLength}) {
    final length = uint64();
    if (length > maximumLength) {
      throw const FormatException('GGUF 元数据字段过长。');
    }
    final start = position;
    skip(length);
    return utf8.decode(Uint8List.sublistView(bytes, start, position));
  }

  int integer(int type) {
    final start = position;
    switch (type) {
      case 0:
        skip(1);
        return data.getUint8(start);
      case 1:
        skip(1);
        return data.getInt8(start);
      case 2:
        skip(2);
        return data.getUint16(start, Endian.little);
      case 3:
        skip(2);
        return data.getInt16(start, Endian.little);
      case 4:
        return uint32();
      case 5:
        skip(4);
        return data.getInt32(start, Endian.little);
      case 10:
        return uint64();
      case 11:
        skip(8);
        return data.getInt64(start, Endian.little);
      default:
        throw const FormatException('GGUF 数值字段类型无效。');
    }
  }

  void skipValue(int type) {
    if (type == 8) {
      final length = uint64();
      skip(length);
    } else if (type == 9) {
      final elementType = uint32();
      final count = uint64();
      if (count > 300000 || elementType == 9) {
        throw const FormatException('GGUF 元数据数组不受支持。');
      }
      final size = _primitiveSizes[elementType];
      if (size != null) {
        skip(count * size);
      } else if (elementType == 8) {
        for (var i = 0; i < count; i++) {
          skipValue(8);
        }
      } else {
        throw const FormatException('GGUF 元数据类型无效。');
      }
    } else {
      final size = _primitiveSizes[type];
      if (size == null) throw const FormatException('GGUF 元数据类型无效。');
      skip(size);
    }
  }

  static const _primitiveSizes = <int, int>{
    0: 1,
    1: 1,
    2: 2,
    3: 2,
    4: 4,
    5: 4,
    6: 4,
    7: 1,
    10: 8,
    11: 8,
    12: 8,
  };
}
