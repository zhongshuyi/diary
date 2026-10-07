import 'dart:async';

import 'package:diary/application/local_assistant_controller.dart';
import 'package:diary/data/assistant_provider_store.dart';
import 'package:diary/data/local_assistant_store.dart';
import 'package:diary/data/local_model_store.dart';
import 'package:diary/domain/assistant_provider_settings.dart';
import 'package:diary/domain/local_assistant_message.dart';
import 'package:diary/services/diary_reply_strategy.dart';
import 'package:diary/services/local_llm_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _deepSeek = OnlineModelProvider.deepSeek;
const _compatible = OnlineModelProvider.compatible;
const _configuration = OnlineModelConfiguration(
  provider: _deepSeek,
  baseUrl: 'https://api.deepseek.com',
  model: 'deepseek-flash',
);

void main() {
  Future<void> until(bool Function() predicate) async {
    for (var i = 0; i < 1000 && !predicate(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(predicate(), isTrue);
  }

  _Harness create({
    bool localSupported = true,
    bool enabled = false,
    bool hasLocalModel = true,
    AssistantReplySource source = AssistantReplySource.local,
    bool hasKey = true,
    OnlineModelConfiguration configuration = _configuration,
    Duration delay = Duration.zero,
    List<LocalAssistantMessage> history = const [],
  }) {
    final harness = _Harness(
      models: _ModelStore(enabled: enabled, hasModel: hasLocalModel),
      providers: _ProviderStore(
        settings: AssistantProviderSettings(
          source: source,
          provider: configuration.provider,
          configurations: {configuration.provider: configuration},
        ),
        keys: hasKey ? {configuration.provider: 'test-provider-key'} : {},
      ),
      replies: _ReplyStore(history),
    );
    harness.controller = LocalAssistantController(
      engine: harness.engine,
      models: harness.models,
      store: harness.replies,
      providers: harness.providers,
      supportedOverride: localSupported,
      replyDelay: delay,
      onlineStrategyFactory: (configuration, key) {
        final strategy = _OnlineStrategy(
          automatic: harness.automatic,
          failure: harness.failure,
        );
        harness.strategies.add(strategy);
        harness.requestedConfigurations.add(configuration);
        harness.requestedKeys.add(key);
        return strategy;
      },
    );
    addTearDown(harness.controller.dispose);
    return harness;
  }

  test(
    'existing local model and response style survive switching sources',
    () async {
      final harness = create(enabled: true);
      final controller = harness.controller;
      await controller.initialize();
      expect(controller.source, AssistantReplySource.local);
      expect(controller.modelPath, 'selected.gguf');
      await controller.setReplyStyle(
        tone: LocalAssistantTone.calm,
        persona: '安静的朋友',
      );
      await controller.setReplySource(AssistantReplySource.online);
      await controller.enable(true);
      expect(controller.source, AssistantReplySource.online);
      expect(controller.enabled, isTrue);
      expect(controller.modelPath, 'selected.gguf');
      expect(controller.tone, LocalAssistantTone.calm);
      expect(controller.persona, '安静的朋友');
      expect(harness.models.settings.path, 'selected.gguf');
      await controller.setReplySource(AssistantReplySource.local);
      await controller.enable(true);
      expect(controller.modelPath, 'selected.gguf');
      expect(controller.enabled, isTrue);
      expect(harness.models.settings.path, 'selected.gguf');
      expect(harness.models.removed, isEmpty);
    },
  );

  test(
    'online replies work without local runtime support or an installed model',
    () async {
      final harness = create(
        localSupported: false,
        hasLocalModel: false,
        source: AssistantReplySource.online,
      )..automatic = true;
      final controller = harness.controller;
      await controller.initialize();
      expect(controller.localSupported, isFalse);
      expect(controller.supported, isTrue);
      expect(controller.canUseSelectedModel, isTrue);
      await controller.enable(true);
      expect(controller.enabled, isTrue);
      await controller.replyToEntry('new', '今天很累');
      await until(() => !controller.busy);
      expect(controller.replyFor('new'), '辛苦了，今晚先歇一会儿。');
      expect(harness.engine.loads, isEmpty);
      expect(harness.engine.contexts, isEmpty);
      expect(harness.requestedKeys, everyElement('test-provider-key'));
    },
  );

  test(
    'online enable validates saved model configuration and API key',
    () async {
      final harness = create(
        source: AssistantReplySource.online,
        hasKey: false,
        hasLocalModel: false,
      );
      final controller = harness.controller;
      await controller.initialize();
      await controller.enable(true);
      expect(controller.enabled, isFalse);
      expect(controller.error, isNotNull);
      expect(controller.hasApiKey, isFalse);
      expect(harness.strategies, isEmpty);
      await controller.saveOnlineConfiguration(
        _configuration,
        apiKey: 'saved-provider-key',
      );
      expect(controller.hasApiKey, isTrue);
      expect(controller.hasApiKeyFor(_deepSeek), isTrue);
      await controller.enable(true);
      expect(controller.enabled, isTrue);
      expect(harness.engine.loads, isEmpty);
    },
  );

  test(
    'invalid draft configuration leaves the previous settings and key intact',
    () async {
      final harness = create(source: AssistantReplySource.online);
      final controller = harness.controller;
      await controller.initialize();
      final oldSettings = harness.providers.settings.toJson();
      await controller.saveOnlineConfiguration(
        _configuration.copyWith(baseUrl: 'https://user:password@example.com'),
        apiKey: 'replacement-key',
      );
      expect(controller.error, isNotNull);
      expect(controller.error, isNot(contains('password')));
      expect(harness.providers.settings.toJson(), oldSettings);
      expect(harness.providers.keys[_deepSeek], 'test-provider-key');
      await controller.saveOnlineConfiguration(
        _configuration.copyWith(model: ''),
        apiKey: 'replacement-key',
      );
      expect(harness.providers.settings.toJson(), oldSettings);
      expect(harness.providers.keys[_deepSeek], 'test-provider-key');
    },
  );

  test(
    'online initialization retains valid saved enablement on unsupported local devices',
    () async {
      final harness = create(
        enabled: true,
        source: AssistantReplySource.online,
        localSupported: false,
        hasLocalModel: false,
      );
      await harness.controller.initialize();
      expect(harness.controller.enabled, isTrue);
      expect(harness.controller.source, AssistantReplySource.online);
      expect(harness.engine.loads, isEmpty);
      expect(harness.strategies, isEmpty);
    },
  );

  test(
    'failed preference save rolls back the key and readiness together',
    () async {
      final harness = create(
        source: AssistantReplySource.online,
        hasKey: false,
      );
      final controller = harness.controller;
      await controller.initialize();
      harness.models.writeFailure = StateError('preferences unavailable');
      await controller.saveOnlineConfiguration(
        _configuration,
        apiKey: 'key-that-cannot-be-committed',
      );
      expect(controller.error, isNotNull);
      expect(harness.providers.keys[_deepSeek], isNull);
      expect(controller.hasApiKeyFor(_deepSeek), isFalse);
      expect(controller.canUseSelectedModel, isFalse);
      expect(controller.enabled, isFalse);
    },
  );

  test(
    'switching the source cancels deferred online requests before any API call',
    () async {
      final harness = create(
        enabled: true,
        source: AssistantReplySource.online,
        delay: const Duration(milliseconds: 50),
      );
      final controller = harness.controller;
      await controller.initialize();
      controller.scheduleReply('pending', '不要在切换之后发送这个正文');
      await controller.setReplySource(AssistantReplySource.local);
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(harness.strategies, isEmpty);
      expect(harness.engine.contexts, isEmpty);
      expect(controller.replyFor('pending'), isNull);
      expect(harness.replies.saves, isEmpty);
    },
  );

  test(
    'a late online response after switching sources cannot replace a diary reply',
    () async {
      final harness = create(
        enabled: true,
        source: AssistantReplySource.online,
      );
      final controller = harness.controller;
      await controller.initialize();
      final reply = controller.replyToEntry('active', '正在回应的正文');
      await until(() => controller.generating);
      final strategy = harness.strategies.single;
      controller.scheduleReply('pending', '排队正文');
      await controller.setReplySource(AssistantReplySource.local);
      await reply;
      strategy.output!.add('过期的在线结果');
      await Future<void>.delayed(Duration.zero);
      expect(strategy.cancels, greaterThan(0));
      expect(controller.replyFor('active'), isNull);
      expect(controller.replyFor('pending'), isNull);
      expect(harness.replies.saves, isEmpty);
      expect(harness.engine.contexts, isEmpty);
    },
  );

  for (final operation in ['disable', 'suspend']) {
    test(
      '$operation cancels the active online request and its queue',
      () async {
        final harness = create(
          enabled: true,
          source: AssistantReplySource.online,
        );
        final controller = harness.controller;
        await controller.initialize();
        final reply = controller.replyToEntry('active', '正文');
        await until(() => controller.generating);
        final strategy = harness.strategies.single;
        controller.scheduleReply('pending', '另一个正文');
        if (operation == 'disable') {
          await controller.enable(false);
          expect(controller.enabled, isFalse);
        } else {
          await controller.suspend();
        }
        await reply;
        strategy.output!.add('取消之后的迟到结果');
        await Future<void>.delayed(Duration.zero);
        expect(strategy.cancels, greaterThan(0));
        expect(controller.replyFor('active'), isNull);
        expect(controller.replyFor('pending'), isNull);
        expect(harness.replies.saves, isEmpty);
        expect(controller.busy, isFalse);
      },
    );
  }

  test(
    'connection test uses a public sample without saving draft keys or configuration',
    () async {
      final harness = create(
        enabled: true,
        source: AssistantReplySource.local,
        history: [_reply('private', '历史回应不应发送')],
      )..automatic = true;
      final controller = harness.controller;
      await controller.initialize();
      final originalSettings = harness.providers.settings.toJson();
      final originalModelPath = controller.modelPath;
      final draft = OnlineModelConfiguration(
        provider: _compatible,
        baseUrl: 'https://example.com/v1',
        model: 'draft-vision-model',
        sendImages: true,
      );
      final result = await controller.testOnlineConnection(
        draft,
        apiKey: 'unsaved-draft-key',
      );
      expect(result, isTrue);
      expect(controller.testingConnection, isFalse);
      expect(controller.connectionStatus, isNotNull);
      expect(controller.source, AssistantReplySource.local);
      expect(controller.enabled, isTrue);
      expect(controller.modelPath, originalModelPath);
      expect(harness.providers.settings.toJson(), originalSettings);
      expect(harness.providers.keys[_compatible], isNull);
      expect(harness.requestedKeys, ['unsaved-draft-key']);
      final prompt = harness.strategies.single.contexts.single;
      expect(prompt, hasLength(1));
      expect(prompt.single.role, LocalAssistantRole.user);
      expect(prompt.single.text, isNot(contains('历史回应')));
      expect(prompt.single.imagePaths, isEmpty);
      expect(controller.messages.single.id, 'private');
      expect(harness.replies.saves, isEmpty);
      expect(harness.engine.contexts, isEmpty);
    },
  );

  test(
    'online failure does not run the local model or switch providers',
    () async {
      final harness = create(enabled: true, source: AssistantReplySource.online)
        ..failure = const FormatException('API 请求失败');
      final controller = harness.controller;
      await controller.initialize();
      await controller.replyToEntry('failed', '这条正文仅向选定服务发送');
      await until(() => !controller.busy);
      expect(controller.replyErrorFor('failed'), isNotNull);
      expect(controller.replyFor('failed'), isNull);
      expect(controller.source, AssistantReplySource.online);
      expect(controller.onlineProvider, _deepSeek);
      expect(harness.engine.loads, isEmpty);
      expect(harness.engine.contexts, isEmpty);
      expect(harness.requestedConfigurations, hasLength(1));
      expect(harness.replies.saves, isEmpty);
    },
  );

  test(
    'local failure never creates a cloud request even with saved API keys',
    () async {
      final harness = create(enabled: true)
        ..engine.loadFailure = const FormatException('本地模型失败');
      final controller = harness.controller;
      await controller.initialize();
      await controller.replyToEntry('failed', '本地选择下不可自动上传的正文');
      await until(() => !controller.busy);
      expect(controller.replyErrorFor('failed'), isNotNull);
      expect(controller.source, AssistantReplySource.local);
      expect(harness.strategies, isEmpty);
      expect(harness.providers.keys[_deepSeek], 'test-provider-key');
    },
  );

  test(
    'deleting an active online key disables replies while preserving other provider keys',
    () async {
      final harness = create(
        enabled: true,
        source: AssistantReplySource.online,
      );
      harness.providers.keys[_compatible] = 'other-provider-key';
      final controller = harness.controller;
      await controller.initialize();
      await controller.removeOnlineApiKey(_deepSeek);
      expect(controller.enabled, isFalse);
      expect(controller.hasApiKeyFor(_deepSeek), isFalse);
      expect(controller.hasApiKeyFor(_compatible), isTrue);
      expect(harness.providers.keys[_compatible], 'other-provider-key');
      expect(controller.configurationFor(_deepSeek).model, 'deepseek-flash');
      expect(controller.modelPath, 'selected.gguf');
      controller.scheduleReply('new', '密钥删除后的正文');
      await Future<void>.delayed(Duration.zero);
      expect(harness.strategies, isEmpty);
      expect(harness.engine.contexts, isEmpty);
    },
  );

  test(
    'deleting an unused online key does not disable active local replies',
    () async {
      final harness = create(enabled: true);
      final controller = harness.controller;
      await controller.initialize();
      await controller.removeOnlineApiKey(_deepSeek);
      expect(controller.enabled, isTrue);
      expect(controller.source, AssistantReplySource.local);
      expect(controller.modelPath, 'selected.gguf');
      expect(controller.hasApiKeyFor(_deepSeek), isFalse);
    },
  );

  test(
    'online strategy receives only the current diary and explicitly enabled images',
    () async {
      final harness = create(
        enabled: true,
        source: AssistantReplySource.online,
        configuration: _configuration.copyWith(sendImages: true),
        history: [_reply('older', '旧的回应不应进 prompt')],
      )..automatic = true;
      final controller = harness.controller;
      await controller.initialize();
      await controller.replyToEntry(
        'first',
        '今天拍了张照片',
        imagePaths: ['/private/current.jpg'],
      );
      await until(() => !controller.busy);
      final firstPrompt = harness.strategies.first.contexts.single;
      expect(firstPrompt, hasLength(1));
      expect(firstPrompt.single.text, '今天拍了张照片');
      expect(firstPrompt.single.imagePaths, ['/private/current.jpg']);
      await controller.replyToEntry(
        'second',
        '第二条记录',
        imagePaths: ['/private/second.jpg'],
      );
      await until(() => !controller.busy);
      final secondPrompt = harness.strategies.last.contexts.single;
      expect(secondPrompt, hasLength(1));
      expect(secondPrompt.single.id, 'second');
      expect(secondPrompt.single.imagePaths, ['/private/second.jpg']);
      expect(
        harness.replies.saves.last.every(
          (message) =>
              message.role == LocalAssistantRole.assistant &&
              message.imagePaths.isEmpty,
        ),
        isTrue,
      );
      expect(
        harness.replies.saves.last.map((message) => message.text).join(),
        isNot(contains('拍了张照片')),
      );
    },
  );

  test(
    'images are omitted when the chosen API model has image uploads disabled',
    () async {
      final harness = create(enabled: true, source: AssistantReplySource.online)
        ..automatic = true;
      final controller = harness.controller;
      await controller.initialize();
      await controller.replyToEntry(
        'entry',
        '这条仅发送文字',
        imagePaths: ['/private/not-authorized.jpg'],
      );
      await until(() => !controller.busy);
      expect(
        harness.strategies.single.contexts.single.single.imagePaths,
        isEmpty,
      );
    },
  );
}

LocalAssistantMessage _reply(String id, String text) => LocalAssistantMessage(
  id: id,
  role: LocalAssistantRole.assistant,
  text: text,
  createdAt: DateTime.utc(2026),
);

class _Harness {
  _Harness({
    required this.models,
    required this.providers,
    required this.replies,
  });
  final _ModelStore models;
  final _ProviderStore providers;
  final _ReplyStore replies;
  final _Engine engine = _Engine();
  final List<_OnlineStrategy> strategies = [];
  final List<OnlineModelConfiguration> requestedConfigurations = [];
  final List<String> requestedKeys = [];
  late LocalAssistantController controller;
  bool automatic = false;
  Object? failure;
}

class _ProviderStore extends AssistantProviderStore {
  _ProviderStore({required this.settings, required this.keys});
  AssistantProviderSettings settings;
  final Map<OnlineModelProvider, String> keys;

  @override
  Future<AssistantProviderSettings> readSettings() async => settings;
  @override
  Future<void> writeSettings(AssistantProviderSettings settings) async =>
      this.settings = settings;
  @override
  Future<String?> readApiKey(OnlineModelProvider provider) async =>
      keys[provider];
  @override
  Future<void> writeApiKey(OnlineModelProvider provider, String value) async =>
      keys[provider] = value;
  @override
  Future<void> deleteApiKey(OnlineModelProvider provider) async =>
      keys.remove(provider);
}

class _ReplyStore extends LocalAssistantStore {
  _ReplyStore(this.history);
  final List<LocalAssistantMessage> history;
  final List<List<LocalAssistantMessage>> saves = [];
  @override
  Future<List<LocalAssistantMessage>> load() async => history;
  @override
  Future<void> save(List<LocalAssistantMessage> messages) async =>
      saves.add(List.of(messages));
}

class _ModelStore extends LocalModelStore {
  _ModelStore({required bool enabled, required this.hasModel})
    : settings = LocalModelSettings(
        enabled: enabled,
        path: hasModel ? 'selected.gguf' : null,
        name: hasModel ? '已选择的本地模型' : null,
      );
  LocalModelSettings settings;
  final bool hasModel;
  final List<String> removed = [];
  Object? writeFailure;
  @override
  Future<LocalModelSettings> readSettings() async => settings;
  @override
  Future<void> writeSettings(LocalModelSettings settings) async {
    if (writeFailure != null) throw writeFailure!;
    this.settings = settings;
  }

  @override
  Future<bool> exists(String path) async => hasModel && path == 'selected.gguf';
  @override
  Future<List<InstalledLocalModel>> listInstalledModels({
    LocalModelSettings? settings,
  }) async => hasModel
      ? const [
          InstalledLocalModel(
            path: 'selected.gguf',
            name: '已选择的本地模型',
            sizeBytes: 400,
          ),
        ]
      : const [];
  @override
  Future<void> validateModel(String path) async {
    if (!await exists(path)) throw const FormatException('模型不存在');
  }

  @override
  Future<void> removeModel(String path) async => removed.add(path);
}

class _Engine implements LocalLlmEngine {
  final List<String> loads = [];
  final List<List<LocalAssistantMessage>> contexts = [];
  Object? loadFailure;
  @override
  Future<void> load(String path) async {
    loads.add(path);
    if (loadFailure != null) throw loadFailure!;
  }

  @override
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  }) {
    contexts.add(List.of(messages));
    return Stream.value('本地回应');
  }

  @override
  Future<void> cancel() async {}
  @override
  Future<void> unload() async {}
  @override
  Future<void> dispose() async {}
}

class _OnlineStrategy implements DiaryReplyStrategy {
  _OnlineStrategy({required this.automatic, this.failure});
  final bool automatic;
  final Object? failure;
  final List<List<LocalAssistantMessage>> contexts = [];
  StreamController<String>? output;
  int cancels = 0;
  @override
  Future<void> prepare() async {}
  @override
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  }) {
    contexts.add(List.of(messages));
    if (failure != null) return Stream.error(failure!);
    if (automatic) return Stream.value('辛苦了，今晚先歇一会儿。');
    final current = StreamController<String>.broadcast();
    output = current;
    return current.stream;
  }

  @override
  Future<void> cancel() async => cancels++;
  @override
  Future<void> unload() async {}
  @override
  Future<void> dispose() async {}
}
