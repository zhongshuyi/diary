import 'dart:async';

import 'package:diary/application/local_assistant_controller.dart';
import 'package:diary/data/local_assistant_store.dart';
import 'package:diary/data/assistant_provider_store.dart';
import 'package:diary/domain/assistant_provider_settings.dart';
import 'package:diary/data/local_model_store.dart';
import 'package:diary/domain/local_assistant_message.dart';
import 'package:diary/services/local_llm_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> until(bool Function() predicate) async {
    for (var i = 0; i < 1000 && !predicate(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    expect(predicate(), isTrue);
  }

  LocalAssistantController create(
    _Engine engine,
    _ReplyStore store,
    _ModelStore models, {
    bool supported = true,
    Duration delay = Duration.zero,
    bool Function()? canStart,
  }) => LocalAssistantController(
    engine: engine,
    store: store,
    models: models,
    providers: _Providers(),
    supportedOverride: supported,
    replyDelay: delay,
    canStart: canStart,
  );

  test(
    'initialization does not load, infer, or replay old diary entries',
    () async {
      final engine = _Engine();
      final controller = create(
        engine,
        _ReplyStore([_reply('older', '已保存回应')]),
        _ModelStore(enabled: false),
      );
      await controller.initialize();
      controller.scheduleReply('new', '日记正文');
      await controller.replyToEntry('new', '日记正文');
      expect(engine.loads, isEmpty);
      expect(engine.contexts, isEmpty);
      expect(controller.replyFor('older'), '已保存回应');
      await controller.enable(true);
      expect(engine.loads, ['old.gguf']);
      expect(engine.contexts, isEmpty);
      controller.dispose();
    },
  );

  test('unsupported devices do not install models or generate', () async {
    final engine = _Engine();
    final models = _ModelStore();
    final controller = create(engine, _ReplyStore(), models, supported: false);
    await controller.initialize();
    await controller.enable(true);
    await controller.importModel('source.gguf');
    await controller.downloadRecommendedModel();
    await controller.replyToEntry('one', '日记');
    expect(controller.enabled, isFalse);
    expect(models.installs, 0);
    expect(engine.loads, isEmpty);
    controller.dispose();
  });

  test(
    'local inference waits while offline transcription is using native CPU',
    () async {
      var transcriptionBusy = true;
      final engine = _Engine()..automatic = true;
      final controller = create(
        engine,
        _ReplyStore(),
        _ModelStore(),
        canStart: () => !transcriptionBusy,
      );
      await controller.initialize();
      controller.scheduleReply('entry', '今天散步了。');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(engine.contexts, isEmpty);
      expect(engine.loads, isEmpty);
      transcriptionBusy = false;
      await until(() => controller.replyFor('entry') != null);
      expect(engine.contexts.single.single.text, '今天散步了。');
      controller.dispose();
    },
  );

  test(
    'one entry alone reaches inference and only its assistant reply is persisted',
    () async {
      final engine = _Engine();
      final store = _ReplyStore([_reply('older', '历史回应不能进prompt')]);
      final controller = create(engine, store, _ModelStore());
      await controller.initialize();
      final response = controller.replyToEntry('entry-one', '今天收到了一个好消息');
      await until(() => controller.generating);
      expect(controller.replyingEntryId, 'entry-one');
      expect(engine.contexts.single, hasLength(1));
      expect(engine.contexts.single.single.role, LocalAssistantRole.user);
      expect(engine.contexts.single.single.text, '今天收到了一个好消息');
      expect(store.saves, isEmpty);
      var notifications = 0;
      controller.addListener(() => notifications++);
      engine.output!.add('真');
      engine.output!.add('真好，愿这份开心陪你久一点。');
      await Future<void>.delayed(Duration.zero);
      expect(notifications, 0);
      expect(controller.replyFor('entry-one'), '真好，愿这份开心陪你久一点。');
      await engine.output!.close();
      await response;
      await until(() => !controller.busy);
      expect(store.saves, hasLength(1));
      expect(
        store.saves.single.every(
          (message) => message.role == LocalAssistantRole.assistant,
        ),
        isTrue,
      );
      expect(
        store.saves.single.any((message) => message.text.contains('收到了一个好消息')),
        isFalse,
      );
      expect(store.saves.single.last.id, 'entry-one');
      expect(engine.unloads, 1);
      controller.dispose();
    },
  );

  test(
    'response is deferred until after the diary insertion and keyboard animations',
    () async {
      final engine = _Engine()..automatic = true;
      final controller = create(
        engine,
        _ReplyStore(),
        _ModelStore(),
        delay: const Duration(milliseconds: 80),
      );
      await controller.initialize();
      controller.scheduleReply('one', '一段日记');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(engine.loads, isEmpty);
      await until(() => engine.contexts.isNotEmpty && !controller.busy);
      controller.dispose();
    },
  );

  test(
    'a rapid burst retains only the latest three requests and runs them sequentially',
    () async {
      final engine = _Engine()..automatic = true;
      final controller = create(
        engine,
        _ReplyStore(),
        _ModelStore(),
        delay: const Duration(milliseconds: 40),
      );
      await controller.initialize();
      for (var i = 1; i <= 5; i++) {
        controller.scheduleReply('entry-$i', '正文 $i');
      }
      await until(() => engine.contexts.length == 3 && !controller.busy);
      expect(engine.contexts.map((context) => context.single.id), [
        'entry-3',
        'entry-4',
        'entry-5',
      ]);
      expect(engine.loads, ['old.gguf']);
      expect(engine.unloads, 1);
      expect(engine.maximumConcurrentGenerations, 1);
      controller.dispose();
    },
  );

  test(
    'stop keeps a partial response, cancels the queue, and does not replay later',
    () async {
      final engine = _Engine();
      final store = _ReplyStore();
      final controller = create(engine, store, _ModelStore());
      await controller.initialize();
      final response = controller.replyToEntry('active', '正文');
      await until(() => controller.generating);
      engine.output!.add('辛苦了');
      await Future<void>.delayed(Duration.zero);
      controller.scheduleReply('pending', '另一条正文');
      await controller.stop();
      await response;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.replyFor('active'), '辛苦了');
      expect(controller.replyFor('pending'), isNull);
      expect(engine.contexts, hasLength(1));
      expect(store.saves, hasLength(1));
      expect(controller.busy, isFalse);
      expect(engine.unloads, 1);
      controller.dispose();
    },
  );

  test(
    'backgrounding cancels a deferred response instead of replaying it on return',
    () async {
      final engine = _Engine();
      final controller = create(
        engine,
        _ReplyStore(),
        _ModelStore(),
        delay: const Duration(milliseconds: 50),
      );
      await controller.initialize();
      controller.scheduleReply('one', '正文');
      await controller.suspend();
      await Future<void>.delayed(const Duration(milliseconds: 90));
      expect(engine.contexts, isEmpty);
      expect(engine.loads, isEmpty);
      expect(controller.messages, isEmpty);
      controller.dispose();
    },
  );

  test(
    'failed load stores no user text and associates failure with its entry only',
    () async {
      final engine = _Engine()..loadFailure = StateError('native failed');
      final store = _ReplyStore();
      final controller = create(engine, store, _ModelStore());
      await controller.initialize();
      await controller.replyToEntry('failed', '这段日记不能复制存储');
      await until(() => !controller.busy);
      expect(controller.messages, isEmpty);
      expect(store.saves, isEmpty);
      expect(controller.replyErrorFor('failed'), isNotNull);
      expect(controller.replyErrorFor('other'), isNull);
      await controller.stop();
      expect(controller.replyErrorFor('failed'), isNull);
      controller.dispose();
    },
  );

  test(
    'tone and persona persist, are passed to inference, and survive model removal',
    () async {
      final engine = _Engine()..automatic = true;
      final models = _ModelStore();
      final controller = create(
        engine,
        _ReplyStore([_reply('older', '回应')]),
        models,
      );
      await controller.initialize();
      await controller.setReplyStyle(
        tone: LocalAssistantTone.calm,
        persona: '像一位安静的老朋友',
      );
      expect(models.settings.tone, LocalAssistantTone.calm);
      expect(models.settings.persona, '像一位安静的老朋友');
      expect(models.settings.path, 'old.gguf');
      await controller.replyToEntry('new', '日记');
      await until(() => !controller.busy);
      expect(engine.tones.single, LocalAssistantTone.calm);
      expect(engine.personas.single, '像一位安静的老朋友');
      await controller.removeModel();
      expect(controller.replyFor('older'), '回应');
      expect(models.settings.path, isNull);
      expect(models.settings.persona, '像一位安静的老朋友');
      expect(models.settings.tone, LocalAssistantTone.calm);
      controller.dispose();
    },
  );

  test(
    'invalid persona leaves old style intact and empty persona restores the default',
    () async {
      final models = _ModelStore();
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      await controller.setReplyStyle(
        tone: LocalAssistantTone.cheerful,
        persona: '字' * 601,
      );
      expect(controller.tone, LocalAssistantTone.gentle);
      expect(controller.error, contains('600'));
      await controller.setReplyStyle(
        tone: LocalAssistantTone.cheerful,
        persona: '  ',
      );
      expect(controller.persona, defaultLocalAssistantPersona);
      expect(models.settings.tone, LocalAssistantTone.cheerful);
      controller.dispose();
    },
  );

  test(
    'failed replacement preserves old model and custom response style',
    () async {
      final engine = _Engine()..loadFailure = const FormatException('不支持此模型');
      final models = _ModelStore(tone: LocalAssistantTone.calm, persona: '旧人设');
      final controller = create(engine, _ReplyStore(), models);
      await controller.initialize();
      await controller.importModel('new.gguf');
      expect(controller.modelPath, 'old.gguf');
      expect(models.settings.path, 'old.gguf');
      expect(models.settings.tone, LocalAssistantTone.calm);
      expect(models.settings.persona, '旧人设');
      expect(models.removed, ['new.gguf']);
      controller.dispose();
    },
  );

  test(
    'cancelling a model installation waits for cleanup and preserves preferences',
    () async {
      final models = _ModelStore()
        ..installation = Completer<InstalledLocalModel>();
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      final install = controller.downloadRecommendedModel();
      await until(() => controller.installing);
      final stop = controller.stop();
      await Future<void>.delayed(Duration.zero);
      expect(models.operation!.cancelled, isTrue);
      models.installation!.complete(
        const InstalledLocalModel(path: 'new.gguf', name: 'candidate'),
      );
      await Future.wait([install, stop]);
      expect(controller.modelPath, 'old.gguf');
      expect(models.removed, ['new.gguf']);
      expect(controller.busy, isFalse);
      controller.dispose();
    },
  );

  test(
    'forget cancels the selected active response without restoring it from late callbacks',
    () async {
      final engine = _Engine();
      final store = _ReplyStore();
      final controller = create(engine, store, _ModelStore());
      await controller.initialize();
      final response = controller.replyToEntry('deleted', '正文');
      await until(() => controller.generating);
      engine.output!.add('正在生成的回应');
      await Future<void>.delayed(Duration.zero);
      await controller.forgetReply('deleted');
      await response;
      await until(() => !controller.busy);
      expect(controller.replyFor('deleted'), isNull);
      expect(store.saves.last, isEmpty);
      expect(controller.replyErrorFor('deleted'), isNull);
      controller.dispose();
    },
  );

  test('clear removes replies but keeps model, tone and persona', () async {
    final store = _ReplyStore([_reply('old', '回应')]);
    final models = _ModelStore(
      tone: LocalAssistantTone.cheerful,
      persona: '朋友',
    );
    final controller = create(_Engine(), store, models);
    await controller.initialize();
    await controller.clearConversation();
    expect(controller.messages, isEmpty);
    expect(controller.modelPath, 'old.gguf');
    expect(controller.tone, LocalAssistantTone.cheerful);
    expect(controller.persona, '朋友');
    expect(store.saves.last, isEmpty);
    controller.dispose();
  });

  test(
    'backgrounding during native load rejects the late completion and releases memory',
    () async {
      final engine = _Engine()..loading = Completer<void>();
      final controller = create(engine, _ReplyStore(), _ModelStore());
      await controller.initialize();
      final response = controller.replyToEntry('one', '正文');
      await until(() => controller.loading);
      final suspension = controller.suspend();
      engine.loading!.complete();
      await Future.wait([response, suspension]);
      expect(engine.contexts, isEmpty);
      expect(controller.messages, isEmpty);
      expect(controller.busy, isFalse);
      expect(engine.unloads, greaterThan(0));
      controller.dispose();
    },
  );

  test(
    'editing an active entry replaces old text while preserving other queued entries',
    () async {
      final engine = _Engine();
      final controller = create(engine, _ReplyStore(), _ModelStore());
      await controller.initialize();
      final original = controller.replyToEntry('edited', '旧日记内容');
      await until(() => controller.generating);
      engine.output!.add('旧内容生成的回应');
      await Future<void>.delayed(Duration.zero);
      controller.scheduleReply('other', '其他日记内容');
      engine.automatic = true;
      await controller.updateEntryReply('edited', '修改后的新内容');
      await original;
      await until(() => engine.contexts.length == 3 && !controller.busy);
      expect(
        engine.contexts.map((context) => context.single.text),
        containsAll(['其他日记内容', '修改后的新内容']),
      );
      expect(controller.replyFor('edited'), isNot(contains('旧内容')));
      expect(controller.replyFor('other'), isNotNull);
      controller.dispose();
    },
  );

  test(
    'rapid edits coalesce to latest text even while an earlier deletion awaits storage',
    () async {
      final engine = _Engine();
      final store = _ReplyStore();
      final controller = create(engine, store, _ModelStore());
      await controller.initialize();
      final original = controller.replyToEntry('edited', '原始内容');
      await until(() => controller.generating);
      engine.output!.add('原内容回应');
      await Future<void>.delayed(Duration.zero);
      store.writeBarrier = Completer<void>();
      final earlier = controller.updateEntryReply('edited', '第一次编辑');
      final latest = controller.updateEntryReply('edited', '最新编辑');
      await latest;
      await until(() => engine.contexts.length == 2);
      expect(engine.contexts.last.single.text, '最新编辑');
      store.writeBarrier!.complete();
      await earlier;
      engine.output!.add('最新内容的回应');
      await engine.output!.close();
      await original;
      await until(() => !controller.busy);
      expect(engine.contexts, hasLength(2));
      expect(controller.replyFor('edited'), '最新内容的回应');
      controller.dispose();
    },
  );

  test(
    'changing an entry to empty text removes old response without generating again',
    () async {
      final engine = _Engine();
      final controller = create(engine, _ReplyStore(), _ModelStore());
      await controller.initialize();
      final original = controller.replyToEntry('edited', '旧内容');
      await until(() => controller.generating);
      engine.output!.add('旧回应');
      await Future<void>.delayed(Duration.zero);
      await controller.updateEntryReply('edited', '  ');
      await original;
      await until(() => !controller.busy);
      expect(engine.contexts, hasLength(1));
      expect(controller.replyFor('edited'), isNull);
      controller.dispose();
    },
  );

  test(
    'forget during native loading waits for that entry and cannot resurrect it',
    () async {
      final engine = _Engine()..loading = Completer<void>();
      final controller = create(engine, _ReplyStore(), _ModelStore());
      await controller.initialize();
      final original = controller.replyToEntry('deleted', '旧内容');
      await until(() => controller.loading);
      final deletion = controller.forgetReply('deleted');
      await Future<void>.delayed(Duration.zero);
      engine.loading!.complete();
      await Future.wait([deletion, original]);
      await until(() => !controller.busy);
      expect(engine.contexts, isEmpty);
      expect(controller.replyFor('deleted'), isNull);
      controller.dispose();
    },
  );
  test(
    'enable requires a selected existing model and keeps the toggle off',
    () async {
      final engine = _Engine();
      final models = _ModelStore(enabled: false)..catalog.clear();
      models.settings = const LocalModelSettings();
      final controller = create(engine, _ReplyStore(), models);
      await controller.initialize();
      await controller.enable(true);
      expect(controller.enabled, isFalse);
      expect(controller.hasModel, isFalse);
      expect(controller.error, contains('先选择'));
      expect(engine.loads, isEmpty);
      controller.dispose();
    },
  );

  test(
    'a missing legacy selected model disables the persisted feature safely',
    () async {
      final models = _ModelStore(tone: LocalAssistantTone.calm, persona: '老朋友')
        ..missing = true;
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      expect(controller.enabled, isFalse);
      expect(models.settings.enabled, isFalse);
      expect(controller.currentModel, isNull);
      expect(models.settings.tone, LocalAssistantTone.calm);
      expect(models.settings.persona, '老朋友');
      controller.dispose();
    },
  );

  test(
    'catalog initialization failure cannot leave an enabled model-less state',
    () async {
      final models = _ModelStore()
        ..catalogFailure = const FormatException('列表读取失败');
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      expect(controller.initialized, isTrue);
      expect(controller.enabled, isFalse);
      expect(controller.currentModel, isNull);
      expect(controller.error, '列表读取失败');
      controller.dispose();
    },
  );

  test(
    'failed enable validation preserves the selected model but never enables inference',
    () async {
      final engine = _Engine();
      final models = _ModelStore(enabled: false)
        ..validationFailure = const FormatException('模型损坏');
      final controller = create(engine, _ReplyStore(), models);
      await controller.initialize();
      await controller.enable(true);
      expect(controller.enabled, isFalse);
      expect(controller.currentModel!.path, 'old.gguf');
      expect(controller.error, '模型损坏');
      expect(engine.loads, isEmpty);
      controller.dispose();
    },
  );

  test(
    'cancel during enable validation prevents a late opt-in commit',
    () async {
      final engine = _Engine();
      final models = _ModelStore(enabled: false)
        ..validationBarrier = Completer<void>();
      final controller = create(engine, _ReplyStore(), models);
      await controller.initialize();
      final enabling = controller.enable(true);
      await until(
        () =>
            controller.installProgress?.stage ==
            LocalModelInstallStage.verifying,
      );
      await controller.stop();
      models.validationBarrier!.complete();
      await enabling;
      expect(controller.enabled, isFalse);
      expect(
        models.writtenSettings.any((settings) => settings.enabled),
        isFalse,
      );
      expect(engine.loads, isEmpty);
      controller.dispose();
    },
  );

  test(
    'successful installation retains both old and new models for later selection',
    () async {
      final models = _ModelStore(
        enabled: false,
        tone: LocalAssistantTone.calm,
        persona: '朋友',
      );
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      await controller.importModel('second.gguf');
      expect(controller.installedModels.map((model) => model.path), [
        'old.gguf',
        'new.gguf',
      ]);
      expect(controller.currentModel!.path, 'new.gguf');
      expect(models.removed, isEmpty);
      await controller.selectModel('old.gguf');
      expect(controller.currentModel!.path, 'old.gguf');
      expect(controller.enabled, isFalse);
      expect(models.settings.tone, LocalAssistantTone.calm);
      expect(models.settings.persona, '朋友');
      controller.dispose();
    },
  );

  test('invalid selection preserves the old active model and opt-in', () async {
    final models = _ModelStore();
    models.catalog.add(
      const InstalledLocalModel(path: 'other.gguf', name: 'other'),
    );
    final controller = create(_Engine(), _ReplyStore(), models);
    await controller.initialize();
    models.validationFailure = const FormatException('无法读取候选模型');
    await controller.selectModel('other.gguf');
    expect(controller.currentModel!.path, 'old.gguf');
    expect(controller.enabled, isTrue);
    expect(models.settings.path, 'old.gguf');
    controller.dispose();
  });

  test(
    'cancelling a selection while metadata writes restores the old selection',
    () async {
      final models = _ModelStore(enabled: false);
      models.catalog.add(
        const InstalledLocalModel(path: 'other.gguf', name: 'other'),
      );
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      models.settingsBarrier = Completer<void>();
      final selection = controller.selectModel('other.gguf');
      await until(() => models.writtenSettings.isNotEmpty);
      await controller.stop();
      models.settingsBarrier!.complete();
      await selection;
      expect(controller.currentModel!.path, 'old.gguf');
      expect(models.settings.path, 'old.gguf');
      expect(models.removed, isEmpty);
      controller.dispose();
    },
  );

  test(
    'cancelling an installation during metadata writes restores old selection and cleans candidate',
    () async {
      final models = _ModelStore(enabled: false);
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      models.settingsBarrier = Completer<void>();
      final installation = controller.importModel('candidate.gguf');
      await until(() => models.writtenSettings.isNotEmpty);
      final stopping = controller.stop();
      models.settingsBarrier!.complete();
      await Future.wait([installation, stopping]);
      expect(controller.currentModel!.path, 'old.gguf');
      expect(models.settings.path, 'old.gguf');
      expect(models.removed, ['new.gguf']);
      controller.dispose();
    },
  );

  test(
    'removing an inactive library model preserves current generation and opt-in',
    () async {
      final engine = _Engine();
      final models = _ModelStore();
      models.catalog.add(
        const InstalledLocalModel(path: 'other.gguf', name: 'other'),
      );
      final controller = create(engine, _ReplyStore(), models);
      await controller.initialize();
      final response = controller.replyToEntry('entry', '日记');
      await until(() => controller.generating);
      await controller.removeInstalledModel('other.gguf');
      expect(controller.enabled, isTrue);
      expect(controller.currentModel!.path, 'old.gguf');
      expect(controller.generating, isTrue);
      engine.output!.add('一份温暖的回应。');
      await engine.output!.close();
      await response;
      await until(() => !controller.busy);
      controller.dispose();
    },
  );

  test(
    'failed active model deletion restores selected model and enabled preferences',
    () async {
      final models = _ModelStore()
        ..removalFailure = StateError('cannot delete');
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      await controller.removeInstalledModel('old.gguf');
      expect(controller.enabled, isTrue);
      expect(controller.currentModel!.path, 'old.gguf');
      expect(models.settings.enabled, isTrue);
      expect(models.settings.path, 'old.gguf');
      expect(controller.error, isNotNull);
      controller.dispose();
    },
  );

  test(
    'recommended model already in library is selected without a repeated download',
    () async {
      final models = _ModelStore(enabled: false);
      models.catalog[0] = InstalledLocalModel(
        path: 'old.gguf',
        name: 'Qwen',
        isRecommended: true,
        modelId: localQualityModel.id,
      );
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      await controller.downloadRecommendedModel();
      expect(models.installs, 0);
      expect(controller.currentModel!.path, 'old.gguf');
      controller.dispose();
    },
  );

  test(
    'the new default recommendation leaves an existing lightweight selection unchanged',
    () async {
      final engine = _Engine();
      final models = _ModelStore(enabled: false);
      models.catalog[0] = const InstalledLocalModel(
        path: 'old.gguf',
        name: 'diary-Qwen3-0.6B-Q4_0.gguf',
        isRecommended: true,
      );
      final controller = create(engine, _ReplyStore(), models);
      await controller.initialize();

      expect(controller.currentModel!.path, 'old.gguf');
      expect(controller.recommendedModels.first.id, localQualityModel.id);
      expect(controller.enabled, isFalse);
      expect(models.installs, 0);
      expect(engine.loads, isEmpty);
      controller.dispose();
    },
  );

  test(
    'an installed legacy lightweight model does not suppress a quality download',
    () async {
      final models = _ModelStore(enabled: false);
      models.catalog[0] = const InstalledLocalModel(
        path: 'old.gguf',
        name: 'Qwen3-0.6B · Q4_0',
        isRecommended: true,
      );
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      await controller.downloadRecommendedModel();

      expect(models.downloadedDescriptors.single.id, localQualityModel.id);
      expect(models.installs, 1);
      expect(controller.installedModels, hasLength(2));
      expect(controller.currentModel!.modelId, localQualityModel.id);
      expect(models.removed, isEmpty);
      controller.dispose();
    },
  );

  test(
    'the 4B recommendation preserves the old balanced selection and opt-in',
    () async {
      final engine = _Engine();
      final models = _ModelStore();
      models.settings = const LocalModelSettings(
        enabled: true,
        path: 'old.gguf',
        name: 'Qwen3-1.7B · 质量优先',
      );
      models.catalog[0] = InstalledLocalModel(
        path: 'old.gguf',
        name: 'Qwen3-1.7B · 质量优先',
        modelId: localBalancedModel.id,
        isRecommended: true,
      );
      final controller = create(engine, _ReplyStore(), models);
      await controller.initialize();
      expect(controller.currentModel!.modelId, localBalancedModel.id);
      expect(controller.currentModel!.path, 'old.gguf');
      expect(controller.recommendedModels.first.id, localInstructModel.id);
      expect(controller.enabled, isTrue);
      expect(models.writtenSettings, isEmpty);
      expect(models.installs, 0);
      expect(engine.loads, isEmpty);
      controller.dispose();
    },
  );

  test(
    'explicit lightweight selection reuses only the matching installed model',
    () async {
      final models = _ModelStore(enabled: false);
      models.catalog[0] = const InstalledLocalModel(
        path: 'old.gguf',
        name: 'diary-Qwen3-0.6B-Q4_0.gguf',
        isRecommended: true,
      );
      models.catalog.add(
        InstalledLocalModel(
          path: 'quality.gguf',
          name: localQualityModel.name,
          modelId: localQualityModel.id,
          isRecommended: true,
        ),
      );
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      await controller.selectModel('quality.gguf');
      await controller.downloadRecommendedModel(localLightweightModel);

      expect(controller.currentModel!.path, 'old.gguf');
      expect(models.installs, 0);
      expect(models.downloadedDescriptors, isEmpty);
      expect(controller.installedModels, hasLength(2));
      controller.dispose();
    },
  );

  test(
    'a failed quality download retains the selected lightweight model',
    () async {
      final models = _ModelStore(enabled: false);
      models.catalog[0] = InstalledLocalModel(
        path: 'old.gguf',
        name: localLightweightModel.name,
        modelId: localLightweightModel.id,
      );
      models.installation = Completer<InstalledLocalModel>();
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      final downloading = controller.downloadRecommendedModel(
        localQualityModel,
      );
      await until(() => controller.installing);
      expect(controller.installingModelName, localQualityModel.name);
      models.installation!.completeError(const FormatException('下载失败'));
      await downloading;

      expect(controller.currentModel!.path, 'old.gguf');
      expect(models.settings.path, 'old.gguf');
      expect(controller.installedModels, hasLength(1));
      expect(controller.error, '下载失败');
      controller.dispose();
    },
  );

  test(
    'background cancellation during initialization cannot start a late model download',
    () async {
      final models = _ModelStore(enabled: false)
        ..readBarrier = Completer<LocalModelSettings>();
      final controller = create(_Engine(), _ReplyStore(), models);
      final downloading = controller.downloadRecommendedModel(
        localQualityModel,
      );
      await until(() => models.settingsReadStarted);
      await controller.stop();
      models.readBarrier!.complete(models.settings);
      await downloading;
      expect(models.installs, 0);
      expect(controller.currentModel!.path, 'old.gguf');
      expect(controller.busy, isFalse);
      controller.dispose();
    },
  );

  test(
    'explicit instruct download coexists with balanced and lightweight models',
    () async {
      final models = _ModelStore(enabled: false);
      models.catalog[0] = InstalledLocalModel(
        path: 'old.gguf',
        name: localLightweightModel.name,
        modelId: localLightweightModel.id,
      );
      models.catalog.add(
        InstalledLocalModel(
          path: 'balanced.gguf',
          name: localBalancedModel.name,
          modelId: localBalancedModel.id,
        ),
      );
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      await controller.downloadRecommendedModel(localInstructModel);
      expect(models.downloadedDescriptors.single.id, localInstructModel.id);
      expect(controller.currentModel!.modelId, localInstructModel.id);
      expect(controller.installedModels, hasLength(3));
      expect(models.removed, isEmpty);
      expect(controller.enabled, isFalse);
      controller.dispose();
    },
  );

  test(
    'catalog refresh failure during cancelled install cannot hang stop',
    () async {
      final models = _ModelStore()
        ..installation = Completer<InstalledLocalModel>();
      final controller = create(_Engine(), _ReplyStore(), models);
      await controller.initialize();
      final installation = controller.downloadRecommendedModel();
      await until(() => controller.installing);
      final stopping = controller.stop();
      models.catalogFailure = StateError('refresh unavailable');
      models.installation!.complete(
        const InstalledLocalModel(path: 'new.gguf', name: 'candidate'),
      );
      await Future.wait([
        installation,
        stopping,
      ]).timeout(const Duration(seconds: 1));
      expect(controller.busy, isFalse);
      expect(controller.modelPath, 'old.gguf');
      controller.dispose();
    },
  );
  test(
    'an external stop joining the initial enable stop cannot restart validation afterward',
    () async {
      final engine = _Engine()..cancellationBarrier = Completer<void>();
      final models = _ModelStore(enabled: false);
      final controller = create(engine, _ReplyStore(), models);
      await controller.initialize();
      final enabling = controller.enable(true);
      await until(() => engine.cancellationCalls > 0);
      final backgroundStop = controller.stop();
      engine.cancellationBarrier!.complete();
      await Future.wait([enabling, backgroundStop]);
      expect(controller.enabled, isFalse);
      expect(models.settings.enabled, isFalse);
      expect(engine.loads, isEmpty);
      expect(controller.busy, isFalse);
      controller.dispose();
    },
  );
}

LocalAssistantMessage _reply(String id, String text) => LocalAssistantMessage(
  id: id,
  role: LocalAssistantRole.assistant,
  text: text,
  createdAt: DateTime.utc(2026),
);

class _ReplyStore extends LocalAssistantStore {
  _ReplyStore([this.history = const []]);
  final List<LocalAssistantMessage> history;
  final List<List<LocalAssistantMessage>> saves = [];
  Completer<void>? writeBarrier;
  @override
  Future<List<LocalAssistantMessage>> load() async => history;
  @override
  Future<void> save(List<LocalAssistantMessage> messages) async {
    saves.add(List.of(messages));
    if (writeBarrier != null) await writeBarrier!.future;
  }
}

class _ModelStore extends LocalModelStore {
  _ModelStore({
    bool enabled = true,
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  }) : settings = LocalModelSettings(
         enabled: enabled,
         path: 'old.gguf',
         name: 'previous',
         tone: tone,
         persona: persona,
       ) {
    catalog.add(
      const InstalledLocalModel(
        path: 'old.gguf',
        name: 'previous',
        sizeBytes: 400,
      ),
    );
  }
  LocalModelSettings settings;
  final List<InstalledLocalModel> catalog = [];
  bool missing = false;
  Object? validationFailure;
  Object? removalFailure;
  Object? catalogFailure;
  Completer<void>? validationBarrier;
  Completer<void>? settingsBarrier;
  final List<LocalModelSettings> writtenSettings = [];
  final List<String> removed = [];
  int installs = 0;
  final List<LocalModelDescriptor> downloadedDescriptors = [];
  Completer<InstalledLocalModel>? installation;
  LocalModelOperation? operation;
  Completer<LocalModelSettings>? readBarrier;
  bool settingsReadStarted = false;
  @override
  Future<LocalModelSettings> readSettings() async {
    settingsReadStarted = true;
    return readBarrier == null ? settings : await readBarrier!.future;
  }

  @override
  Future<void> writeSettings(LocalModelSettings settings) async {
    writtenSettings.add(settings);
    if (settingsBarrier != null && !settingsBarrier!.isCompleted) {
      await settingsBarrier!.future;
    }
    this.settings = settings;
  }

  @override
  Future<bool> exists(String path) async =>
      !missing && catalog.any((model) => model.path == path);
  @override
  Future<List<InstalledLocalModel>> listInstalledModels({
    LocalModelSettings? settings,
  }) async {
    if (catalogFailure != null) throw catalogFailure!;
    return missing ? [] : List.unmodifiable(catalog);
  }

  @override
  Future<void> validateModel(String path) async {
    if (validationBarrier != null) await validationBarrier!.future;
    if (validationFailure != null) throw validationFailure!;
    if (!await exists(path)) throw const FormatException('模型不存在');
  }

  @override
  Future<void> removeModel(String path) async {
    if (removalFailure != null) throw removalFailure!;
    removed.add(path);
    catalog.removeWhere((model) => model.path == path);
  }

  Future<InstalledLocalModel> _install(
    LocalModelOperation operation, {
    LocalModelDescriptor? descriptor,
  }) async {
    this.operation = operation;
    installs++;
    final model =
        await (installation?.future ??
            Future.value(
              InstalledLocalModel(
                path: 'new.gguf',
                name: descriptor?.name ?? 'candidate',
                modelId: descriptor?.id,
                isRecommended: descriptor?.isRecommended ?? false,
              ),
            ));
    catalog.add(model);
    return model;
  }

  @override
  Future<InstalledLocalModel> importModel(
    String path, {
    required LocalModelOperation operation,
    void Function(double?)? onProgress,
    void Function(LocalModelInstallProgress)? onInstallProgress,
  }) => _install(operation);
  @override
  Future<InstalledLocalModel> downloadRecommendedModel({
    LocalModelDescriptor? model,
    required LocalModelOperation operation,
    void Function(double?)? onProgress,
    void Function(LocalModelInstallProgress)? onInstallProgress,
  }) {
    final descriptor = model ?? recommendedModels.first;
    downloadedDescriptors.add(descriptor);
    return _install(operation, descriptor: descriptor);
  }
}

class _Providers extends AssistantProviderStore {
  @override
  Future<AssistantProviderSettings> readSettings() async =>
      const AssistantProviderSettings();
  @override
  Future<String?> readApiKey(OnlineModelProvider provider) async => null;
}

class _Engine implements LocalLlmEngine {
  final List<String> loads = [];
  final List<List<LocalAssistantMessage>> contexts = [];
  final List<LocalAssistantTone> tones = [];
  final List<String> personas = [];
  Completer<void>? loading;
  Object? loadFailure;
  StreamController<String>? output;
  bool automatic = false;
  int unloads = 0;
  Completer<void>? cancellationBarrier;
  int cancellationCalls = 0;
  int concurrentGenerations = 0;
  int maximumConcurrentGenerations = 0;
  @override
  Future<void> load(String path) async {
    loads.add(path);
    if (loading != null) await loading!.future;
    if (loadFailure != null) throw loadFailure!;
  }

  @override
  Stream<String> generate(
    List<LocalAssistantMessage> messages, {
    LocalAssistantTone tone = LocalAssistantTone.gentle,
    String persona = defaultLocalAssistantPersona,
  }) {
    contexts.add(messages);
    tones.add(tone);
    personas.add(persona);
    concurrentGenerations++;
    if (concurrentGenerations > maximumConcurrentGenerations) {
      maximumConcurrentGenerations = concurrentGenerations;
    }
    final current = StreamController<String>(
      onCancel: () => concurrentGenerations--,
    );
    output = current;
    if (automatic) {
      scheduleMicrotask(() {
        current.add('辛苦了，愿今晚的休息给你一点温暖。');
        unawaited(current.close());
      });
    }
    return current.stream;
  }

  @override
  Future<void> cancel() async {
    cancellationCalls++;
    if (cancellationBarrier != null) await cancellationBarrier!.future;
    if (output != null && !output!.isClosed) await output!.close();
  }

  @override
  Future<void> unload() async => unloads++;
  @override
  Future<void> dispose() async {}
}
