import 'dart:async';

import 'package:diary/domain/assistant_provider_settings.dart';
import 'package:diary/domain/local_assistant_message.dart';
import 'package:diary/services/diary_reply_strategy.dart';
import 'package:diary/services/local_llm_engine.dart';
import 'package:diary/services/online_model_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const configuration = OnlineModelConfiguration(
    provider: OnlineModelProvider.compatible,
    baseUrl: 'https://example.com/v1',
    model: 'fixture-model',
    sendImages: true,
  );

  LocalAssistantMessage message(
    String text, {
    LocalAssistantRole role = LocalAssistantRole.user,
    List<String> imagePaths = const [],
  }) => LocalAssistantMessage(
    id: 'private-id-$text',
    role: role,
    text: text,
    createdAt: DateTime.utc(2026),
    imagePaths: imagePaths,
  );

  test('online prepare validates locally without calling adapter', () async {
    final adapter = _Adapter();
    final strategy = OnlineDiaryReplyStrategy(
      configuration: configuration,
      apiKey: 'fixture-key',
      adapter: adapter,
    );
    await strategy.prepare();
    expect(adapter.diary, isNull);
    expect(adapter.cancelCount, 0);
    final missingKey = OnlineDiaryReplyStrategy(
      configuration: configuration,
      apiKey: ' ',
      adapter: adapter,
    );
    await expectLater(
      missingKey.prepare(),
      throwsA(isA<OnlineModelException>()),
    );
  });

  test('online strategy sends only current diary text and images', () async {
    final adapter = _Adapter();
    final strategy = OnlineDiaryReplyStrategy(
      configuration: configuration,
      apiKey: 'fixture-key',
      adapter: adapter,
    );
    final replies = await strategy
        .generate(
          [
            message('earlier private entry', imagePaths: ['old-image.jpg']),
            message('earlier reply', role: LocalAssistantRole.assistant),
            message('current diary', imagePaths: ['current-image.jpg']),
          ],
          tone: LocalAssistantTone.calm,
          persona: '认真听我碎念。',
        )
        .toList();
    expect(replies, ['fixture reply']);
    expect(adapter.diary, 'current diary');
    expect(adapter.images, ['current-image.jpg']);
    expect(adapter.tone, LocalAssistantTone.calm);
    expect(adapter.persona, '认真听我碎念。');
  });

  test('online strategy permits an image-only current diary', () async {
    final adapter = _Adapter();
    final strategy = OnlineDiaryReplyStrategy(
      configuration: configuration,
      apiKey: 'fixture-key',
      adapter: adapter,
    );
    await strategy.generate([
      message('', imagePaths: ['photo.jpg']),
    ]).drain<void>();
    expect(adapter.diary, '');
    expect(adapter.images, ['photo.jpg']);
  });

  test('online strategy rejects an assistant as latest input', () async {
    final adapter = _Adapter();
    final strategy = OnlineDiaryReplyStrategy(
      configuration: configuration,
      apiKey: 'fixture-key',
      adapter: adapter,
    );
    await expectLater(
      strategy.generate([
        message('reply', role: LocalAssistantRole.assistant),
      ]).toList(),
      throwsA(isA<OnlineModelException>()),
    );
    expect(adapter.diary, isNull);
  });

  test(
    'online unload cancels and remains reusable; dispose releases adapter',
    () async {
      final adapter = _Adapter();
      final strategy = OnlineDiaryReplyStrategy(
        configuration: configuration,
        apiKey: 'fixture-key',
        adapter: adapter,
      );
      await strategy.unload();
      await strategy.generate([message('next')]).drain<void>();
      expect(adapter.cancelCount, 1);
      expect(adapter.disposeCount, 0);
      await strategy.dispose();
      expect(adapter.disposeCount, 1);
    },
  );

  test(
    'local wrapper delegates without disposing controller-owned engine',
    () async {
      final engine = _Engine();
      final strategy = LocalDiaryReplyStrategy(
        engine: engine,
        modelPath: 'model.gguf',
      );
      await strategy.prepare();
      await strategy.generate([
        message('diary'),
      ], tone: LocalAssistantTone.cheerful).drain<void>();
      await strategy.cancel();
      await strategy.unload();
      await strategy.dispose();
      expect(engine.loadedPath, 'model.gguf');
      expect(engine.tone, LocalAssistantTone.cheerful);
      expect(engine.cancelCount, 1);
      expect(engine.unloadCount, 2);
      expect(engine.disposeCount, 0);
    },
  );
}

class _Adapter implements OnlineModelAdapter {
  String? diary;
  String? persona;
  LocalAssistantTone? tone;
  List<String>? images;
  int cancelCount = 0;
  int disposeCount = 0;

  @override
  Stream<String> generate({
    required OnlineModelConfiguration configuration,
    required String apiKey,
    required String diary,
    required LocalAssistantTone tone,
    required String persona,
    List<String> imagePaths = const [],
  }) {
    this.diary = diary;
    this.tone = tone;
    this.persona = persona;
    images = imagePaths;
    return Stream.value('fixture reply');
  }

  @override
  Future<void> cancel() async => cancelCount++;

  @override
  Future<void> dispose() async => disposeCount++;
}

class _Engine implements LocalLlmEngine {
  String? loadedPath;
  LocalAssistantTone? tone;
  int cancelCount = 0;
  int unloadCount = 0;
  int disposeCount = 0;

  @override
  Future<void> load(String path) async => loadedPath = path;

  @override
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  }) {
    this.tone = tone;
    return Stream.value('fixture reply');
  }

  @override
  Future<void> cancel() async => cancelCount++;

  @override
  Future<void> unload() async => unloadCount++;

  @override
  Future<void> dispose() async => disposeCount++;
}
