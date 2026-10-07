import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:diary/domain/local_assistant_message.dart';
import 'package:diary/services/local_llm_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporary;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('diary_gguf_test_');
  });
  tearDown(() async {
    final target = p.normalize(temporary.absolute.path);
    final systemTemp = p.normalize(Directory.systemTemp.absolute.path);
    if (!p.equals(p.dirname(target), systemTemp) ||
        !p.basename(target).startsWith('diary_gguf_test_')) {
      throw StateError('Refusing to delete an unexpected temporary directory.');
    }
    await temporary.delete(recursive: true);
  });

  Future<String> writeFixture(Uint8List bytes) async {
    final file = File('${temporary.path}/model.gguf');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  test(
    'preflight checks a supported Qwen tensor table without native loading',
    () async {
      final path = await writeFixture(_fixture());
      await validateLocalLlmModel(path);
    },
  );

  for (final configuration in [
    (
      name: '1.7B',
      blocks: 28,
      embedding: 2048,
      feedForward: 6144,
      heads: 16,
      tensorBytes: 4608,
    ),
    (
      name: '4B',
      blocks: 36,
      embedding: 2560,
      feedForward: 9728,
      heads: 32,
      tensorBytes: 5760,
    ),
  ]) {
    test(
      'accepts ${configuration.name} Qwen3 metadata and Q4_K payload',
      () async {
        final path = await writeFixture(
          _fixture(
            blocks: configuration.blocks,
            embedding: configuration.embedding,
            feedForward: configuration.feedForward,
            heads: configuration.heads,
            kvHeads: 8,
            tensorDimensions: [configuration.embedding, 4],
            tensorType: 12,
            offsets: [0, configuration.tensorBytes],
            payloadBytes: configuration.tensorBytes * 2,
          ),
        );
        await validateLocalLlmModel(path);
      },
    );
  }

  test('keeps Qwen2 models supported', () async {
    final path = await writeFixture(_fixture(architecture: 'qwen2'));
    await validateLocalLlmModel(path);
  });

  test('rejects files that are not GGUF', () async {
    final path = await writeFixture(Uint8List(256));
    await expectLater(validateLocalLlmModel(path), throwsFormatException);
  });

  test('rejects other architectures before native loading', () async {
    final path = await writeFixture(_fixture(architecture: 'llama'));
    await expectLater(validateLocalLlmModel(path), throwsFormatException);
  });

  test('rejects large model metadata', () async {
    for (final bytes in [
      _fixture(blocks: 37),
      _fixture(embedding: 2561),
      _fixture(heads: 65),
      _fixture(feedForward: 16385),
      _fixture(kvHeads: 17),
      _fixture(heads: 15, kvHeads: 8),
    ]) {
      final path = await writeFixture(bytes);
      await expectLater(validateLocalLlmModel(path), throwsFormatException);
    }
  });

  test('accepts the file size limit and rejects one extra byte', () async {
    final path = await writeFixture(_fixture());
    final handle = await File(path).open(mode: FileMode.append);
    try {
      // Extending the temporary file avoids allocating a 3 GiB byte buffer.
      await handle.truncate(3 * 1024 * 1024 * 1024);
      await validateLocalLlmModel(path);
      await handle.truncate(3 * 1024 * 1024 * 1024 + 1);
    } finally {
      await handle.close();
    }
    await expectLater(
      validateLocalLlmModel(path),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('3 GB'),
        ),
      ),
    );
  });

  test('rejects total stored tensor elements above 4.5 billion', () async {
    final path = await writeFixture(
      _fixture(
        tensorDimensions: [200000, 2500],
        tensorType: 2,
        offsets: List<int>.filled(10, 0),
      ),
    );
    await expectLater(
      validateLocalLlmModel(path),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('张量总量'),
        ),
      ),
    );
  });

  test(
    'checks payload completeness at the 4.5 billion element boundary',
    () async {
      final path = await writeFixture(
        _fixture(
          tensorDimensions: [200000, 2500],
          tensorType: 2,
          offsets: List<int>.filled(9, 0),
        ),
      );
      await expectLater(
        validateLocalLlmModel(path),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('模型文件不完整或张量数据无效'),
          ),
        ),
      );
    },
  );

  test('rejects a truncated tensor payload', () async {
    for (final bytes in [
      _fixture(),
      _fixture(
        blocks: 36,
        embedding: 2560,
        feedForward: 9728,
        heads: 32,
        tensorDimensions: [2560, 4],
        tensorType: 12,
        payloadBytes: 5760,
      ),
    ]) {
      final path = await writeFixture(bytes.sublist(0, bytes.length - 1));
      await expectLater(validateLocalLlmModel(path), throwsFormatException);
    }
  });

  test('rejects overlapping tensors', () async {
    final path = await writeFixture(_fixture(offsets: [0, 32]));
    await expectLater(validateLocalLlmModel(path), throwsFormatException);
  });

  test('rejects misaligned tensor offsets', () async {
    final path = await writeFixture(_fixture(offsets: [1]));
    await expectLater(validateLocalLlmModel(path), throwsFormatException);
  });

  test('rejects impossible dimensions and unsupported quantization', () async {
    for (final bytes in [
      _fixture(dimension: 200001),
      _fixture(tensorType: 99),
      _fixture(tensorType: 2, dimension: 31),
      _fixture(tensorType: 12, tensorDimensions: [2559, 4]),
      _fixture(tensorDimensions: [200000, 2501]),
    ]) {
      final path = await writeFixture(bytes);
      await expectLater(validateLocalLlmModel(path), throwsFormatException);
    }
  });

  test('rejects metadata arrays with a forged length', () async {
    final path = await writeFixture(_fixture(forgedArray: true));
    await expectLater(validateLocalLlmModel(path), throwsFormatException);
  });

  // Opt-in: flutter test --dart-define=LOCAL_LLM_SMOKE_MODEL=<absolute GGUF>
  // On Windows flutter_tester set LLAMADART_NATIVE_LIB_DIR to the app's
  // build/native_assets/windows directory so all modules share one registry.
  // This exercises the actual native CPU model, not a mocked reply.
  const model = String.fromEnvironment('LOCAL_LLM_SMOKE_MODEL');
  if (model.isNotEmpty) {
    test(
      'real Qwen gives brief diary comfort, cancels and releases its worker',
      () async {
        final engine = LlamadartLocalLlmEngine(seed: 42);
        final timer = Stopwatch()..start();
        final messages = [
          LocalAssistantMessage(
            id: 'smoke-user',
            role: LocalAssistantRole.user,
            text: '今天散步的时候看到了晚霞，心情很好。',
            createdAt: DateTime.utc(2026),
          ),
        ];
        try {
          await engine.load(model);
          final loadMilliseconds = timer.elapsedMilliseconds;
          final snapshots = await engine
              .generate(messages, tone: LocalAssistantTone.cheerful)
              .toList();
          expect(snapshots, isNotEmpty);
          final reply = snapshots.last;
          expect(reply.trim(), isNotEmpty);
          expect(reply, isNot(contains('<think>')));
          expect(reply, isNot(contains('</think>')));
          for (var i = 1; i < snapshots.length; i++) {
            expect(snapshots[i], startsWith(snapshots[i - 1]));
          }
          debugPrint(
            'LOCAL_LLM_SMOKE load_ms=$loadMilliseconds '
            'total_ms=${timer.elapsedMilliseconds} reply=$reply',
          );

          for (final sample in [
            (
              text: '忙了一整天，明明已经很努力了，还是觉得自己什么都没做好。',
              tone: LocalAssistantTone.gentle,
              persona: defaultLocalAssistantPersona,
            ),
            (
              text: '明天要做汇报，想到要当众说话就紧张。',
              tone: LocalAssistantTone.calm,
              persona: '一位安静、可靠的朋友，表达朴实，不说空泛的大道理。',
            ),
          ]) {
            final replies = await engine
                .generate(
                  [messages.single.copyWith(text: sample.text)],
                  tone: sample.tone,
                  persona: sample.persona,
                )
                .toList();
            expect(replies, isNotEmpty);
            expect(replies.last.trim(), isNotEmpty);
            expect(replies.last, isNot(contains('<think>')));
            debugPrint(
              'LOCAL_DIARY_COMFORT ${sample.tone.name}: ${replies.last}',
            );
          }

          final first = Completer<void>();
          final finished = Completer<void>();
          final subscription = engine
              .generate([messages.single.copyWith(text: '今天的散步让疲惫的我舒服了不少。')])
              .listen(
                (_) {
                  if (!first.isCompleted) first.complete();
                },
                onError: (Object error, StackTrace stack) {
                  if (!first.isCompleted) first.completeError(error, stack);
                  if (!finished.isCompleted) {
                    finished.completeError(error, stack);
                  }
                },
                onDone: () {
                  if (!finished.isCompleted) finished.complete();
                },
              );
          await first.future.timeout(const Duration(seconds: 30));
          await engine.cancel().timeout(const Duration(seconds: 10));
          await finished.future.timeout(const Duration(seconds: 10));
          await subscription.cancel();
          expect(engine.isGenerating, isFalse);
          await engine.unload();
          expect(engine.isLoaded, isFalse);
          await engine.load(model);
          expect(engine.isLoaded, isTrue);
        } finally {
          await engine.dispose();
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
    for (final seed in [7, 101]) {
      test(
        'real diary comfort sample with seed $seed',
        () async {
          final engine = LlamadartLocalLlmEngine(seed: seed);
          try {
            await engine.load(model);
            for (final sample in [
              (text: '今天散步的时候看到了晚霞，心情很好。', tone: LocalAssistantTone.cheerful),
              (
                text: '忙了一整天，明明已经很努力了，还是觉得自己什么都没做好。',
                tone: LocalAssistantTone.gentle,
              ),
              (text: '明天要做汇报，想到要当众说话就紧张。', tone: LocalAssistantTone.calm),
            ]) {
              final snapshots = await engine.generate([
                LocalAssistantMessage(
                  id: 'diary-$seed',
                  role: LocalAssistantRole.user,
                  text: sample.text,
                  createdAt: DateTime.utc(2026),
                ),
              ], tone: sample.tone).toList();
              expect(snapshots, isNotEmpty);
              expect(snapshots.last.trim(), isNotEmpty);
              expect(snapshots.last, isNot(contains('<think>')));
              debugPrint(
                'LOCAL_DIARY_COMFORT seed=$seed ${sample.tone.name}: '
                '${snapshots.last}',
              );
            }
          } finally {
            await engine.dispose();
          }
        },
        timeout: const Timeout(Duration(minutes: 3)),
      );
    }
  }
}

Uint8List _fixture({
  String architecture = 'qwen3',
  int blocks = 28,
  int embedding = 1024,
  int heads = 16,
  int kvHeads = 8,
  int feedForward = 3072,
  int dimension = 32,
  List<int>? tensorDimensions,
  int tensorType = 1,
  List<int> offsets = const [0],
  int? payloadBytes,
  bool forgedArray = false,
}) {
  final builder = BytesBuilder();
  void u32(int value) {
    final data = ByteData(4)..setUint32(0, value, Endian.little);
    builder.add(data.buffer.asUint8List());
  }

  void u64(int value) {
    final data = ByteData(8)..setUint64(0, value, Endian.little);
    builder.add(data.buffer.asUint8List());
  }

  void string(String text) {
    final bytes = utf8.encode(text);
    u64(bytes.length);
    builder.add(bytes);
  }

  u32(0x46554747);
  u32(3);
  u64(offsets.length);
  u64(forgedArray ? 7 : 6);
  string('general.architecture');
  u32(8);
  string(architecture);
  string('$architecture.block_count');
  u32(4);
  u32(blocks);
  string('$architecture.embedding_length');
  u32(4);
  u32(embedding);
  string('$architecture.attention.head_count');
  u32(4);
  u32(heads);
  string('$architecture.attention.head_count_kv');
  u32(4);
  u32(kvHeads);
  string('$architecture.feed_forward_length');
  u32(4);
  u32(feedForward);
  if (forgedArray) {
    string('tokenizer.ggml.tokens');
    u32(9);
    u32(8);
    u64(0x7fffffff);
  }
  for (var i = 0; i < offsets.length; i++) {
    string('test.$i.weight');
    final dimensions = tensorDimensions ?? [dimension];
    u32(dimensions.length);
    for (final size in dimensions) {
      u64(size);
    }
    u32(tensorType);
    u64(offsets[i]);
  }
  builder.add(Uint8List((32 - builder.length % 32) % 32));
  builder.add(
    Uint8List(
      payloadBytes ?? (offsets.length == 1 ? 64 : 64 * offsets.length + 64),
    ),
  );
  return builder.takeBytes();
}
