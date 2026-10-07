import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/local_assistant_controller.dart';
import 'package:diary/data/local_model_store.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/assistant_provider_settings.dart';
import 'package:diary/domain/local_assistant_message.dart';
import 'package:diary/pages/assistant/local_assistant_settings_page.dart';
import 'package:diary/pages/chat/chat_page.dart';
import 'package:diary/widgets/local_assistant_reply.dart';

const _recommended = InstalledLocalModel(
  path: '/private/qwen.gguf',
  name: 'Qwen3-0.6B · Q4_0',
  sizeBytes: 429000000,
  isRecommended: true,
);
final _quality = InstalledLocalModel(
  path: '/private/quality.gguf',
  name: localQualityModel.name,
  sizeBytes: localQualityModel.sizeBytes,
  isRecommended: true,
  modelId: localQualityModel.id,
);
const _custom = InstalledLocalModel(
  path: '/private/another.gguf',
  name: '我的本地模型.gguf',
  sizeBytes: 280000000,
);

void main() {
  testWidgets('MiniMax has editable regional URL and model defaults', (
    tester,
  ) async {
    final controller = _FakeController(
      enabled: false,
      source: AssistantReplySource.online,
      onlineProvider: OnlineModelProvider.miniMax,
    );
    await _openSettings(tester, controller);
    expect(find.text('MiniMax'), findsOneWidget);
    await _show(tester, const Key('assistant-online-base-url'));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('assistant-online-base-url')))
          .controller!
          .text,
      OnlineModelProvider.miniMax.defaultBaseUrl,
    );
    await _show(tester, const Key('assistant-online-model'));
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('assistant-online-model')))
          .controller!
          .text,
      OnlineModelProvider.miniMax.defaultModel,
    );
    expect(find.textContaining('https://api.minimax.io/v1'), findsOneWidget);
    expect(controller.testedConfigurations, isEmpty);
  });

  testWidgets(
    'online source is available without local support or a local model',
    (tester) async {
      final controller = _FakeController(
        enabled: false,
        supported: false,
        models: const [],
        selected: null,
        savedKeys: const {OnlineModelProvider.deepSeek},
      );
      await _openSettings(tester, controller);
      expect(controller.localSupported, isFalse);
      await tester.tap(find.byKey(const Key('assistant-source-online')));
      await tester.pumpAndSettle();
      expect(controller.sourceChanges, [AssistantReplySource.online]);
      expect(controller.hasModel, isFalse);
      expect(find.byKey(const Key('assistant-change-model')), findsNothing);
      await _show(tester, const Key('assistant-enabled'));
      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('assistant-enabled')),
      );
      expect(switchTile.onChanged, isNotNull);
      await tester.tap(find.byKey(const Key('assistant-enabled')));
      await tester.pumpAndSettle();
      expect(controller.enabled, isTrue);
      expect(controller.enableCalls, 1);
      expect(controller.downloadCalls, 0);
      expect(controller.testedConfigurations, isEmpty);
    },
  );

  testWidgets(
    'online enable needs saved credentials and editing never makes requests',
    (tester) async {
      final controller = _FakeController(
        enabled: false,
        source: AssistantReplySource.online,
        models: const [],
        selected: null,
      );
      await _openSettings(tester, controller);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('assistant-online-model')))
            .controller!
            .text,
        OnlineModelProvider.deepSeek.defaultModel,
      );
      await _show(tester, const Key('assistant-online-api-key'));
      await tester.enterText(
        find.byKey(const Key('assistant-online-api-key')),
        'synthetic-new-key',
      );
      await _show(tester, const Key('assistant-enabled'));
      await tester.tap(find.byKey(const Key('assistant-enabled')));
      await tester.pumpAndSettle();
      expect(controller.enableCalls, 0);
      expect(controller.enabled, isFalse);
      expect(controller.onlineSaves, isEmpty);
      expect(controller.testedConfigurations, isEmpty);
      expect(
        find.text('先保存有效的 API 地址、模型 ID 和 API Key，再开启日记陪伴。'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'online save activates a configuration and clears typed credentials',
    (tester) async {
      final controller = _FakeController(
        enabled: false,
        source: AssistantReplySource.online,
      );
      await _openSettings(tester, controller);
      await tester.tap(find.byKey(const Key('assistant-provider-compatible')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('assistant-online-base-url')),
        'https://models.example/v1',
      );
      await _show(tester, const Key('assistant-online-model'));
      await tester.enterText(
        find.byKey(const Key('assistant-online-model')),
        'example-vision-model',
      );
      await _show(tester, const Key('assistant-online-api-key'));
      await tester.enterText(
        find.byKey(const Key('assistant-online-api-key')),
        'synthetic-new-key',
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('assistant-online-api-key')),
            )
            .obscureText,
        isTrue,
      );
      await tester.tap(
        find.byKey(const Key('assistant-online-key-visibility')),
      );
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('assistant-online-api-key')),
            )
            .obscureText,
        isFalse,
      );
      await _show(tester, const Key('assistant-online-send-images'));
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('assistant-online-send-images')),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('assistant-online-send-images')));
      await tester.pump();
      expect(controller.onlineProvider, OnlineModelProvider.deepSeek);
      expect(controller.onlineSaves, isEmpty);
      final input = tester.widget<TextField>(
        find.byKey(const Key('assistant-online-api-key')),
      );
      await _show(tester, const Key('assistant-online-save'));
      await tester.tap(find.byKey(const Key('assistant-online-save')));
      await tester.pumpAndSettle();
      expect(controller.onlineProvider, OnlineModelProvider.compatible);
      expect(
        controller.onlineSaves.single.baseUrl,
        'https://models.example/v1',
      );
      expect(controller.onlineSaves.single.model, 'example-vision-model');
      expect(controller.onlineSaves.single.sendImages, isTrue);
      expect(controller.savedApiKeys, ['synthetic-new-key']);
      expect(input.controller!.text, isEmpty);
      expect(controller.enabled, isFalse);
      expect(controller.testedConfigurations, isEmpty);
      expect(find.byKey(const Key('assistant-online-unsaved')), findsNothing);
    },
  );

  testWidgets(
    'saved keys stay concealed and leaving the field blank retains them',
    (tester) async {
      final controller = _FakeController(
        enabled: false,
        source: AssistantReplySource.online,
        savedKeys: const {OnlineModelProvider.deepSeek},
      );
      await _openSettings(tester, controller);
      await _show(tester, const Key('assistant-online-api-key'));
      final field = find.byKey(const Key('assistant-online-api-key'));
      expect(tester.widget<TextField>(field).controller!.text, isEmpty);
      expect(find.text('synthetic-saved-key'), findsNothing);
      await _show(tester, const Key('assistant-online-save'));
      await tester.tap(find.byKey(const Key('assistant-online-save')));
      await tester.pumpAndSettle();
      expect(controller.savedApiKeys, [null]);
      expect(controller.hasApiKeyFor(OnlineModelProvider.deepSeek), isTrue);
      expect(controller.removedKeys, isEmpty);
      expect(find.text('synthetic-saved-key'), findsNothing);
    },
  );

  testWidgets(
    'provider and source changes retain drafts without saving or activating them',
    (tester) async {
      final controller = _FakeController(
        enabled: false,
        source: AssistantReplySource.online,
      );
      await _openSettings(tester, controller);
      await tester.enterText(
        find.byKey(const Key('assistant-online-base-url')),
        'https://draft.example/v1',
      );
      await tester.tap(find.byKey(const Key('assistant-provider-compatible')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('assistant-online-base-url')),
            )
            .controller!
            .text,
        OnlineModelProvider.compatible.defaultBaseUrl,
      );
      await tester.tap(find.byKey(const Key('assistant-provider-deepSeek')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('assistant-online-base-url')),
            )
            .controller!
            .text,
        'https://draft.example/v1',
      );
      await tester.tap(find.byKey(const Key('assistant-source-local')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('assistant-source-online')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('assistant-online-base-url')),
            )
            .controller!
            .text,
        'https://draft.example/v1',
      );
      expect(controller.onlineSaves, isEmpty);
      expect(controller.onlineProvider, OnlineModelProvider.deepSeek);
      expect(
        controller.onlineConfiguration.baseUrl,
        OnlineModelProvider.deepSeek.defaultBaseUrl,
      );
      expect(controller.testedConfigurations, isEmpty);
    },
  );

  testWidgets(
    'explicit connection test uses the draft and never saves or enables it',
    (tester) async {
      final controller = _FakeController(
        enabled: false,
        source: AssistantReplySource.online,
      );
      await _openSettings(tester, controller);
      await tester.enterText(
        find.byKey(const Key('assistant-online-base-url')),
        'https://draft.example/v1',
      );
      await _show(tester, const Key('assistant-online-api-key'));
      await tester.enterText(
        find.byKey(const Key('assistant-online-api-key')),
        'synthetic-draft-key',
      );
      await _show(tester, const Key('assistant-online-test'));
      expect(find.textContaining('只发送公开样例文字'), findsOneWidget);
      await tester.tap(find.byKey(const Key('assistant-online-test')));
      await tester.pumpAndSettle();
      expect(
        controller.testedConfigurations.single.baseUrl,
        'https://draft.example/v1',
      );
      expect(controller.testedApiKeys, ['synthetic-draft-key']);
      expect(controller.onlineSaves, isEmpty);
      expect(
        controller.onlineConfiguration.baseUrl,
        OnlineModelProvider.deepSeek.defaultBaseUrl,
      );
      expect(controller.enabled, isFalse);
      expect(find.text('公开样例连接成功'), findsOneWidget);
      expect(find.byKey(const Key('assistant-online-unsaved')), findsOneWidget);
    },
  );

  testWidgets('invalid online draft blocks saves and connection requests', (
    tester,
  ) async {
    final controller = _FakeController(
      enabled: false,
      source: AssistantReplySource.online,
    );
    await _openSettings(tester, controller);
    await tester.enterText(
      find.byKey(const Key('assistant-online-base-url')),
      'http://unsafe.example/v1',
    );
    await _show(tester, const Key('assistant-online-api-key'));
    await tester.enterText(
      find.byKey(const Key('assistant-online-api-key')),
      'synthetic-new-key',
    );
    await _show(tester, const Key('assistant-online-save'));
    await tester.tap(find.byKey(const Key('assistant-online-save')));
    await tester.pumpAndSettle();
    expect(find.text('API 地址必须使用 HTTPS'), findsOneWidget);
    await tester.tap(find.byKey(const Key('assistant-online-test')));
    await tester.pumpAndSettle();
    expect(controller.onlineSaves, isEmpty);
    expect(controller.testedConfigurations, isEmpty);
  });

  testWidgets(
    'deleting a saved key does not save a draft or activate another provider',
    (tester) async {
      final controller = _FakeController(
        source: AssistantReplySource.online,
        savedKeys: const {
          OnlineModelProvider.deepSeek,
          OnlineModelProvider.compatible,
        },
      );
      await _openSettings(tester, controller);
      await tester.tap(find.byKey(const Key('assistant-provider-compatible')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('assistant-online-base-url')),
        'https://unsaved.example/v1',
      );
      await _show(tester, const Key('assistant-online-remove-key'));
      await tester.tap(find.byKey(const Key('assistant-online-remove-key')));
      await tester.pumpAndSettle();
      expect(controller.removedKeys, isEmpty);
      await tester.tap(find.widgetWithText(FilledButton, '删除密钥'));
      await tester.pumpAndSettle();
      expect(controller.removedKeys, [OnlineModelProvider.compatible]);
      expect(controller.onlineSaves, isEmpty);
      expect(controller.onlineProvider, OnlineModelProvider.deepSeek);
      expect(controller.enabled, isTrue);
      await _show(tester, const Key('assistant-online-base-url'));
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('assistant-online-base-url')),
            )
            .controller!
            .text,
        'https://unsaved.example/v1',
      );
    },
  );

  testWidgets('local quality limitation is stated plainly', (tester) async {
    await _openSettings(tester, _FakeController(enabled: false));
    await _show(tester, const Key('assistant-local-quality-notice'));
    expect(find.textContaining('理解与表达较弱'), findsOneWidget);
    expect(find.textContaining('优先回复质量'), findsOneWidget);
  });

  for (final dark in [false, true]) {
    testWidgets(
      '320px online form with 1.8 text scale ${dark ? 'dark' : 'light'} fits',
      (tester) async {
        tester.view.physicalSize = const Size(320, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = _FakeController(
          enabled: false,
          source: AssistantReplySource.online,
        );
        await _openSettings(tester, controller, dark: dark, textScale: 1.8);
        expect(tester.takeException(), isNull);
        for (final key in [
          'assistant-provider-compatible',
          'assistant-online-base-url',
          'assistant-online-model',
          'assistant-online-api-key',
          'assistant-online-send-images',
          'assistant-online-save',
          'assistant-online-test',
          'assistant-enabled',
          'assistant-persona',
        ]) {
          await _show(tester, Key(key));
          expect(tester.takeException(), isNull);
        }
      },
    );
  }

  testWidgets('missing model opt-in opens selection and keeps the switch off', (
    tester,
  ) async {
    final controller = _FakeController(
      enabled: false,
      models: const [],
      selected: null,
    );
    await _openSettings(tester, controller);
    expect(find.text('先选一个陪伴模型'), findsOneWidget);
    expect(find.byKey(const Key('assistant-download-model')), findsNothing);
    expect(controller.downloadCalls, 0);
    await _show(tester, const Key('assistant-enabled'));
    await tester.tap(find.byKey(const Key('assistant-enabled')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('assistant-model-library')), findsOneWidget);
    expect(find.text('先选择一个模型，再开启日记陪伴。'), findsOneWidget);
    expect(controller.enableCalls, 0);
    expect(controller.enabled, isFalse);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('assistant-enabled')))
          .value,
      isFalse,
    );
  });

  testWidgets(
    'current lightweight model keeps the quality download available',
    (tester) async {
      final controller = _FakeController(enabled: false);
      await _openSettings(tester, controller);
      expect(find.text(_recommended.name), findsOneWidget);
      expect(find.text('429.0 MB · 保存在这台设备上'), findsOneWidget);
      expect(find.text('已选择'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const Key('assistant-model-status'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('assistant-enabled'))).dy,
        ),
      );
      expect(find.text('更换模型'), findsOneWidget);
      expect(find.byKey(const Key('assistant-import-model')), findsNothing);
      await _openLibrary(tester);
      expect(
        find.byKey(ValueKey('assistant-model-${_recommended.path}')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      await _show(tester, const Key('assistant-download-model'));
      expect(find.byKey(const Key('assistant-download-model')), findsOneWidget);
      expect(find.text(localQualityModel.name), findsOneWidget);
      expect(find.text('2.50 GB · 推荐'), findsOneWidget);
      await _show(
        tester,
        ValueKey('assistant-use-model-${localLightweightModel.id}'),
      );
      expect(
        find.byKey(
          ValueKey('assistant-download-model-${localLightweightModel.id}'),
        ),
        findsNothing,
      );
      expect(controller.downloadCalls, 0);
    },
  );

  testWidgets(
    'all three download choices are visible without changing the model',
    (tester) async {
      final controller = _FakeController(
        enabled: false,
        models: const [],
        selected: null,
      );
      await _openSettings(tester, controller);
      await _openLibrary(tester);
      await _show(tester, const Key('assistant-download-model'));
      expect(find.text(localQualityModel.name), findsOneWidget);
      expect(find.text(localQualityModel.description), findsOneWidget);
      await _show(
        tester,
        ValueKey('assistant-download-model-${localBalancedModel.id}'),
      );
      expect(find.text(localBalancedModel.name), findsOneWidget);
      expect(find.text('1.28 GB'), findsOneWidget);
      await _show(
        tester,
        ValueKey('assistant-download-model-${localLightweightModel.id}'),
      );
      expect(find.text('Qwen3-0.6B · 轻量'), findsOneWidget);
      expect(controller.downloadCalls, 0);
      expect(controller.selectedPaths, isEmpty);
      expect(controller.currentModel, isNull);
      expect(controller.enabled, isFalse);
    },
  );

  testWidgets('an installed quality option selects its path without download', (
    tester,
  ) async {
    final controller = _FakeController(
      enabled: false,
      models: [_recommended, _quality],
    );
    await _openSettings(tester, controller);
    await _openLibrary(tester);
    await _show(
      tester,
      ValueKey('assistant-use-model-${localQualityModel.id}'),
    );
    expect(find.byKey(const Key('assistant-download-model')), findsNothing);
    await tester.tap(
      find.byKey(ValueKey('assistant-use-model-${localQualityModel.id}')),
    );
    await tester.pumpAndSettle();
    expect(controller.selectedPaths, [_quality.path]);
    expect(controller.downloadCalls, 0);
    expect(controller.currentModel, _quality);
    expect(controller.enabled, isFalse);
  });

  testWidgets('the legacy lightweight option never downloads twice', (
    tester,
  ) async {
    final controller = _FakeController(
      models: [_quality, _recommended],
      selected: _quality.path,
    );
    await _openSettings(tester, controller);
    await _openLibrary(tester);
    await _show(
      tester,
      ValueKey('assistant-use-model-${localLightweightModel.id}'),
    );
    await tester.tap(
      find.byKey(ValueKey('assistant-use-model-${localLightweightModel.id}')),
    );
    await tester.pumpAndSettle();
    expect(controller.selectedPaths, [_recommended.path]);
    expect(controller.currentModel, _recommended);
    expect(controller.downloadCalls, 0);
  });

  testWidgets(
    'selecting a downloaded model closes the library without auto enabling',
    (tester) async {
      final controller = _FakeController(
        enabled: false,
        models: const [_recommended, _custom],
      );
      await _openSettings(tester, controller);
      await _openLibrary(tester);
      await tester.tap(find.byKey(ValueKey('assistant-model-${_custom.path}')));
      await tester.pumpAndSettle();
      expect(controller.selectedPaths, [_custom.path]);
      expect(controller.currentModel, _custom);
      expect(controller.installedModels, contains(_recommended));
      expect(controller.enabled, isFalse);
      expect(find.byKey(const Key('assistant-model-library')), findsNothing);
      expect(find.text('已切换为 ${_custom.name}'), findsOneWidget);
      await _show(tester, const Key('assistant-enabled'));
      await tester.tap(find.byKey(const Key('assistant-enabled')));
      await tester.pump();
      expect(controller.enableCalls, 1);
      expect(controller.enabled, isTrue);
    },
  );

  testWidgets(
    'download shows real transfer progress then an independent verification phase',
    (tester) async {
      final controller = _FakeController(
        models: const [_custom],
        selected: _custom.path,
      );
      await _openSettings(tester, controller);
      await _openLibrary(tester);
      await _show(tester, const Key('assistant-download-model'));
      await tester.tap(find.byKey(const Key('assistant-download-model')));
      await tester.pumpAndSettle();
      expect(controller.downloadCalls, 1);
      expect(controller.downloadedModels.single.id, localQualityModel.id);
      expect(find.text(localQualityModel.name), findsOneWidget);
      expect(find.text('25% · 100.0 MB / 400.0 MB'), findsOneWidget);
      expect(find.text('正在下载模型'), findsOneWidget);
      expect(find.byKey(const Key('assistant-model-library')), findsNothing);
      controller.installProgress = const LocalModelInstallProgress(
        stage: LocalModelInstallStage.verifying,
        receivedBytes: 400000000,
        totalBytes: 400000000,
      );
      controller.notifyListeners();
      await tester.pump();
      expect(find.text('正在检查模型文件…'), findsOneWidget);
      expect(
        find.byKey(const Key('assistant-transfer-progress')),
        findsNothing,
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('assistant-install-progress')),
            )
            .value,
        isNull,
      );
      await tester.tap(find.byKey(const Key('assistant-cancel-install')));
      await tester.pumpAndSettle();
      expect(controller.stopCalls, 1);
      expect(controller.currentModel, _custom);
      expect(find.text(_custom.name), findsOneWidget);
      expect(controller.enabled, isTrue);
    },
  );

  testWidgets('unknown size does not invent a percentage or total', (
    tester,
  ) async {
    final controller = _FakeController()
      ..installing = true
      ..installingModelName = '正在导入的模型.gguf'
      ..installProgress = const LocalModelInstallProgress(
        stage: LocalModelInstallStage.importing,
        receivedBytes: 12300000,
      );
    await _openSettings(tester, controller);
    expect(find.text('12.3 MB · 大小暂未提供'), findsOneWidget);
    expect(find.text('正在导入模型'), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(
            find.byKey(const Key('assistant-install-progress')),
          )
          .value,
      isNull,
    );
    await tester.tap(find.byKey(const Key('assistant-cancel-install')));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'a failed download keeps the old model and retries the same source',
    (tester) async {
      final controller = _FakeController(
        models: const [_custom],
        selected: _custom.path,
      )..downloadFailure = '下载失败，请检查网络';
      await _openSettings(tester, controller);
      await _openLibrary(tester);
      await _show(tester, const Key('assistant-download-model'));
      await tester.tap(find.byKey(const Key('assistant-download-model')));
      await tester.pumpAndSettle();
      expect(find.text('下载失败，请检查网络'), findsOneWidget);
      expect(find.text(_custom.name), findsOneWidget);
      expect(controller.currentModel, _custom);
      expect(controller.enabled, isTrue);
      await tester.tap(find.byKey(const Key('assistant-retry-model')));
      await tester.pumpAndSettle();
      expect(controller.downloadCalls, 2);
      expect(controller.downloadedModels.map((model) => model.id), [
        localQualityModel.id,
        localQualityModel.id,
      ]);
      expect(controller.importedPaths, isEmpty);
    },
  );

  testWidgets('a failed lightweight download retries the lightweight source', (
    tester,
  ) async {
    final controller = _FakeController(
      models: [_quality],
      selected: _quality.path,
    )..downloadFailure = '下载失败，请检查网络';
    await _openSettings(tester, controller);
    await _openLibrary(tester);
    await _show(
      tester,
      ValueKey('assistant-download-model-${localLightweightModel.id}'),
    );
    await tester.tap(
      find.byKey(
        ValueKey('assistant-download-model-${localLightweightModel.id}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.currentModel, _quality);
    expect(controller.enabled, isTrue);
    await tester.tap(find.byKey(const Key('assistant-retry-model')));
    await tester.pumpAndSettle();
    expect(controller.downloadedModels.map((model) => model.id), [
      localLightweightModel.id,
      localLightweightModel.id,
    ]);
    expect(controller.selectedPaths, isEmpty);
  });

  testWidgets(
    'a failed balanced download retries that option and retains the selected model',
    (tester) async {
      final controller = _FakeController(
        models: [_quality],
        selected: _quality.path,
      )..downloadFailure = '下载失败，请检查网络';
      await _openSettings(tester, controller);
      await _openLibrary(tester);
      final key = ValueKey('assistant-download-model-${localBalancedModel.id}');
      await _show(tester, key);
      await tester.tap(find.byKey(key));
      await tester.pumpAndSettle();
      expect(controller.currentModel, _quality);
      expect(controller.enabled, isTrue);
      await tester.tap(find.byKey(const Key('assistant-retry-model')));
      await tester.pumpAndSettle();
      expect(controller.downloadedModels.map((model) => model.id), [
        localBalancedModel.id,
        localBalancedModel.id,
      ]);
      expect(controller.selectedPaths, isEmpty);
    },
  );

  testWidgets(
    'failed imports retry with a new picker path and clean the temporary copy',
    (tester) async {
      var picks = 0;
      var cacheClears = 0;
      final events = <String>[];
      _mockModelPicker((call) async {
        if (call.method == 'clear') {
          cacheClears++;
          return true;
        }
        picks++;
        expect((call.arguments as Map)['withData'], isFalse);
        expect((call.arguments as Map)['allowedExtensions'], ['gguf']);
        return [
          {
            'name': 'model.gguf',
            'size': 429000000,
            'path': '/cache/model-$picks.gguf',
          },
        ];
      });
      final controller = _FakeController(enabled: false)
        ..importFailure = '导入文件无法使用';
      await _openSettings(
        tester,
        controller,
        onExternalActivityStart: () => events.add('start'),
        onExternalActivityEnd: () => events.add('end'),
      );
      await _openLibrary(tester);
      await _show(tester, const Key('assistant-import-model'));
      await tester.tap(find.byKey(const Key('assistant-import-model')));
      await tester.pumpAndSettle();
      expect(find.text('重新选择文件'), findsOneWidget);
      expect(controller.currentModel, _recommended);
      controller.importFailure = null;
      await tester.tap(find.byKey(const Key('assistant-retry-model')));
      await tester.pumpAndSettle();
      expect(controller.importedPaths, [
        '/cache/model-1.gguf',
        '/cache/model-2.gguf',
      ]);
      expect(picks, 2);
      expect(cacheClears, 2);
      expect(events, ['start', 'end', 'start', 'end']);
      expect(controller.enabled, isFalse);
      expect(controller.downloadCalls, 0);
    },
  );

  testWidgets(
    'picker failure restores the external activity guard and offers another selection',
    (tester) async {
      _mockModelPicker(
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      final events = <String>[];
      final controller = _FakeController(enabled: false);
      await _openSettings(
        tester,
        controller,
        onExternalActivityStart: () => events.add('start'),
        onExternalActivityEnd: () => events.add('end'),
      );
      await _openLibrary(tester);
      await _show(tester, const Key('assistant-import-model'));
      await tester.tap(find.byKey(const Key('assistant-import-model')));
      await tester.pumpAndSettle();
      expect(events, ['start', 'end']);
      expect(controller.importedPaths, isEmpty);
      expect(find.text('无法打开模型文件，请重新选择。'), findsOneWidget);
      expect(find.text('重新选择文件'), findsOneWidget);
    },
  );

  testWidgets('removing an unused model does not alter the selected model', (
    tester,
  ) async {
    final controller = _FakeController(models: const [_recommended, _custom]);
    await _openSettings(tester, controller);
    await _openLibrary(tester);
    await tester.tap(
      find.byKey(ValueKey('assistant-model-menu-${_custom.path}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('移除模型'));
    await tester.pumpAndSettle();
    expect(controller.removedPaths, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, '移除模型'));
    await tester.pumpAndSettle();
    expect(controller.removedPaths, [_custom.path]);
    expect(controller.currentModel, _recommended);
    expect(controller.enabled, isTrue);
    expect(
      find.byKey(ValueKey('assistant-model-${_custom.path}')),
      findsNothing,
    );
  });

  testWidgets(
    'removing the current model requires confirmation and retains replies',
    (tester) async {
      final controller = _FakeController()..replies['entry-1'] = '今天也辛苦了。';
      await _openSettings(tester, controller);
      await tester.tap(find.byKey(const Key('assistant-current-model-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('移除当前模型'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();
      expect(controller.currentModel, _recommended);
      await tester.tap(find.byKey(const Key('assistant-current-model-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('移除当前模型'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '移除模型'));
      await tester.pumpAndSettle();
      expect(controller.currentModel, isNull);
      expect(controller.enabled, isFalse);
      expect(controller.replyFor('entry-1'), '今天也辛苦了。');
    },
  );

  testWidgets(
    'tone and persona edits survive notifications until explicitly saved',
    (tester) async {
      final controller = _FakeController(enabled: false);
      await _openSettings(tester, controller);
      expect(find.byKey(const Key('assistant-message-field')), findsNothing);
      await _show(tester, const Key('assistant-tone-cheerful'));
      await tester.tap(find.byKey(const Key('assistant-tone-cheerful')));
      await tester.pump();
      final field = find.byKey(const Key('assistant-persona'));
      await tester.enterText(field, '像一位耐心的朋友，给我一句鼓励。');
      await tester.pump();
      controller.selected = _recommended.path;
      controller.notifyListeners();
      await tester.pump();
      expect(controller.styleCalls, 0);
      expect(
        tester.widget<TextField>(field).controller!.text,
        '像一位耐心的朋友，给我一句鼓励。',
      );
      final focus = tester
          .widget<EditableText>(
            find.descendant(of: field, matching: find.byType(EditableText)),
          )
          .focusNode;
      await _show(tester, const Key('assistant-save-style'));
      await tester.tap(find.byKey(const Key('assistant-save-style')));
      await tester.pumpAndSettle();
      expect(controller.styleCalls, 1);
      expect(controller.tone, LocalAssistantTone.cheerful);
      expect(controller.persona, '像一位耐心的朋友，给我一句鼓励。');
      expect(focus.hasFocus, isFalse);
      expect(controller.enabled, isFalse);
    },
  );

  testWidgets('unsupported devices cannot enable or open model selection', (
    tester,
  ) async {
    final controller = _FakeController(enabled: false, supported: false);
    await _openSettings(tester, controller);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('assistant-enabled')))
          .onChanged,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('assistant-change-model')))
          .onPressed,
      isNull,
    );
    expect(find.textContaining('当前设备暂时无法运行模型'), findsOneWidget);
    expect(controller.downloadCalls, 0);
  });

  testWidgets(
    'clearing local replies requires confirmation and keeps the model',
    (tester) async {
      final controller = _FakeController()..replies['entry-1'] = '今天也辛苦了。';
      await _openSettings(tester, controller);
      await _show(tester, const Key('assistant-clear-replies'));
      await tester.tap(find.byKey(const Key('assistant-clear-replies')));
      await tester.pumpAndSettle();
      expect(controller.clearCalls, 0);
      await tester.tap(find.widgetWithText(FilledButton, '清空回应'));
      await tester.pumpAndSettle();
      expect(controller.clearCalls, 1);
      expect(controller.replyFor('entry-1'), isNull);
      expect(controller.currentModel, _recommended);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      '360px large text ${dark ? 'dark' : 'light'} layout and long model list do not overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final models = List.generate(
          12,
          (i) => InstalledLocalModel(
            path: '/private/legacy-$i.gguf',
            name: '这是一份保留下来的很长的本地模型文件名称-$i-Qwen3-0.6B-Instruct.gguf',
            sizeBytes: 429000000,
          ),
        );
        final controller = _FakeController(
          models: models,
          selected: models.first.path,
        );
        await _openSettings(tester, controller, dark: dark, textScale: 1.6);
        expect(tester.takeException(), isNull);
        await _show(tester, const Key('assistant-change-model'));
        await tester.tap(find.byKey(const Key('assistant-change-model')));
        await tester.pumpAndSettle();
        await _show(tester, ValueKey('assistant-model-${models.last.path}'));
        expect(
          find.byKey(ValueKey('assistant-model-${models.last.path}')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await _show(tester, const Key('assistant-download-model'));
        expect(tester.takeException(), isNull);
        await _show(
          tester,
          ValueKey('assistant-download-model-${localBalancedModel.id}'),
        );
        expect(tester.takeException(), isNull);
        await _show(
          tester,
          ValueKey('assistant-download-model-${localLightweightModel.id}'),
        );
        expect(tester.takeException(), isNull);
        await _show(tester, const Key('assistant-import-model'));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'a reply or its failure appears only beside the associated entry',
    (tester) async {
      final controller = _FakeController()
        ..replies['entry-2'] = '允许自己慢一点，今天已经很努力了。'
        ..replyErrors['entry-2'] = '模型文件无法读取';
      await tester.pumpWidget(
        MaterialApp(
          theme: DiaryTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                LocalAssistantReply(entryId: 'entry-1', controller: controller),
                LocalAssistantReply(entryId: 'entry-2', controller: controller),
              ],
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('assistant-reply-entry-1')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('assistant-reply-entry-2')),
        findsOneWidget,
      );
      expect(find.text('允许自己慢一点，今天已经很努力了。'), findsOneWidget);
      expect(find.byTooltip('模型文件无法读取'), findsOneWidget);
      expect(controller.downloadCalls, 0);
    },
  );

  testWidgets(
    'reply updates and stopping keep diary focus and preserve its only send',
    (tester) async {
      final controller = _FakeController();
      String? sent;
      var sendCalls = 0;
      final entry = _entry();
      await _openDiaryChat(
        tester,
        controller,
        entry,
        onSend: (text) async {
          sendCalls++;
          sent = text;
        },
      );
      final field = find.byKey(const Key('chat-message-field'));
      await tester.enterText(field, '下一条日记草稿');
      await tester.pump();
      final input = tester.widget<TextField>(field);
      controller.replyingEntryId = entry.id;
      controller.generating = true;
      controller.replies[entry.id] = '今天也辛苦了，给自己一点休息。';
      controller.notifyListeners();
      await tester.pump();
      expect(input.focusNode!.hasFocus, isTrue);
      expect(input.controller!.text, '下一条日记草稿');
      await tester.tap(find.byKey(ValueKey('assistant-stop-${entry.id}')));
      await tester.pump();
      expect(controller.stopCalls, 1);
      expect(input.focusNode!.hasFocus, isTrue);
      expect(sendCalls, 0);
      await tester.tap(find.byKey(const Key('chat-send-button')));
      await tester.pump();
      expect(sendCalls, 1);
      expect(sent, '下一条日记草稿');
      expect(entry.contentText, '今天有些疲惫');
    },
  );

  testWidgets('long pressing a response cannot delete its diary', (
    tester,
  ) async {
    final controller = _FakeController()..replies['entry-1'] = '今天也辛苦了。';
    var deleted = false;
    await _openDiaryChat(
      tester,
      controller,
      _entry(),
      onDelete: (_) async => deleted = true,
    );
    await tester.longPress(find.text('今天也辛苦了。'));
    await tester.pumpAndSettle();
    expect(find.text('移入回收站'), findsNothing);
    expect(deleted, isFalse);
  });
}

Future<void> _openLibrary(WidgetTester tester) async {
  await _show(tester, const Key('assistant-change-model'));
  await tester.tap(find.byKey(const Key('assistant-change-model')));
  await tester.pumpAndSettle();
}

Future<void> _show(WidgetTester tester, Key key) async {
  final library = find.byKey(const Key('assistant-model-library'));
  final scrollable = library.evaluate().isNotEmpty
      ? find.descendant(of: library, matching: find.byType(Scrollable)).first
      : find.byType(Scrollable).first;
  await tester.scrollUntilVisible(find.byKey(key), 180, scrollable: scrollable);
  await tester.pumpAndSettle();
}

Future<void> _openSettings(
  WidgetTester tester,
  _FakeController controller, {
  VoidCallback? onExternalActivityStart,
  VoidCallback? onExternalActivityEnd,
  bool dark = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? DiaryTheme.dark : DiaryTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: LocalAssistantSettingsPage(
        controller: controller,
        onExternalActivityStart: onExternalActivityStart,
        onExternalActivityEnd: onExternalActivityEnd,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _openDiaryChat(
  WidgetTester tester,
  _FakeController controller,
  DiaryEntry entry, {
  Future<void> Function(String)? onSend,
  Future<void> Function(DiaryEntry)? onDelete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DiaryTheme.light,
      home: Scaffold(
        body: ChatPage(
          entries: [entry],
          localAssistantController: controller,
          onSend: (text, images, audio, videos, mood, moodLabel) async {
            await onSend?.call(text);
          },
          onOpenEntry: (_) {},
          onEdit: (_) async {},
          onDelete: onDelete ?? (_) async {},
          onOpenEditor: () {},
          onImportAttachments: (paths) async => paths,
          onNavigate: (_) {},
        ),
      ),
    ),
  );
  await tester.pump();
}

DiaryEntry _entry() => DiaryEntry(
  id: 'entry-1',
  createdAt: DateTime(2026, 10, 7, 12),
  updatedAt: DateTime(2026, 10, 7, 12),
  title: '疲惫的一天',
  content: '今天有些疲惫',
  contentText: '今天有些疲惫',
  category: '生活',
);

class _FakeController extends ChangeNotifier
    implements LocalAssistantController {
  _FakeController({
    this.enabled = true,
    bool supported = true,
    List<InstalledLocalModel> models = const [_recommended],
    this.selected = '/private/qwen.gguf',
    this.source = AssistantReplySource.local,
    this.onlineProvider = OnlineModelProvider.deepSeek,
    Map<OnlineModelProvider, OnlineModelConfiguration> configurations =
        const {},
    Set<OnlineModelProvider> savedKeys = const {},
  }) : installedModels = List.of(models),
       localSupported = supported,
       onlineConfigurations = Map.of(configurations),
       keys = {
         for (final provider in savedKeys) provider: 'synthetic-saved-key',
       };
  @override
  bool initialized = true;
  @override
  bool get supported => source == AssistantReplySource.online || localSupported;
  @override
  bool localSupported;
  @override
  AssistantReplySource source;
  @override
  OnlineModelProvider onlineProvider;
  final Map<OnlineModelProvider, OnlineModelConfiguration> onlineConfigurations;
  final Map<OnlineModelProvider, String> keys;
  @override
  OnlineModelConfiguration configurationFor(OnlineModelProvider provider) =>
      onlineConfigurations[provider] ??
      OnlineModelConfiguration(
        provider: provider,
        baseUrl: provider.defaultBaseUrl,
        model: provider.defaultModel,
      );
  @override
  bool hasApiKeyFor(OnlineModelProvider provider) => keys.containsKey(provider);
  @override
  OnlineModelConfiguration get onlineConfiguration =>
      configurationFor(onlineProvider);
  @override
  bool get hasApiKey => hasApiKeyFor(onlineProvider);
  @override
  bool get canUseSelectedModel {
    if (source == AssistantReplySource.local) return localSupported && hasModel;
    try {
      onlineConfiguration.validate();
      return hasApiKey;
    } on FormatException {
      return false;
    }
  }

  @override
  bool testingConnection = false;
  @override
  String? connectionStatus;
  @override
  bool enabled;
  @override
  List<InstalledLocalModel> installedModels;
  @override
  List<LocalModelDescriptor> get recommendedModels => localRecommendedModels;
  String? selected;
  @override
  InstalledLocalModel? get currentModel {
    for (final model in installedModels) {
      if (model.path == selected) return model;
    }
    return null;
  }

  @override
  bool get hasModel => currentModel != null;
  @override
  String? get modelPath => currentModel?.path;
  @override
  String? get modelName => currentModel?.name;
  @override
  bool loading = false;
  @override
  bool generating = false;
  @override
  bool installing = false;
  @override
  double? progress;
  @override
  LocalModelInstallProgress? installProgress;
  @override
  String? installingModelName;
  @override
  String? error;
  @override
  bool get busy => loading || generating || installing;
  @override
  LocalAssistantTone tone = LocalAssistantTone.gentle;
  @override
  String persona = '像一位细心的朋友。';
  @override
  String? replyingEntryId;
  final replies = <String, String>{};
  final replyErrors = <String, String>{};
  final selectedPaths = <String>[];
  final removedPaths = <String>[];
  final importedPaths = <String>[];
  int enableCalls = 0;
  int stopCalls = 0;
  int styleCalls = 0;
  int clearCalls = 0;
  int downloadCalls = 0;
  final sourceChanges = <AssistantReplySource>[];
  final onlineSaves = <OnlineModelConfiguration>[];
  final savedApiKeys = <String?>[];
  final removedKeys = <OnlineModelProvider>[];
  final testedConfigurations = <OnlineModelConfiguration>[];
  final testedApiKeys = <String?>[];
  final downloadedModels = <LocalModelDescriptor>[];
  String? downloadFailure;
  String? importFailure;
  @override
  String? replyFor(String entryId) => replies[entryId];
  @override
  String? replyErrorFor(String entryId) => replyErrors[entryId];
  @override
  Future<void> initialize() async {
    initialized = true;
    notifyListeners();
  }

  @override
  Future<void> enable(bool value) async {
    enableCalls++;
    enabled = value;
    notifyListeners();
  }

  @override
  Future<void> setReplySource(AssistantReplySource source) async {
    sourceChanges.add(source);
    this.source = source;
    notifyListeners();
  }

  @override
  Future<void> saveOnlineConfiguration(
    OnlineModelConfiguration configuration, {
    String? apiKey,
    bool removeApiKey = false,
  }) async {
    configuration.validate();
    onlineSaves.add(configuration);
    savedApiKeys.add(apiKey);
    onlineProvider = configuration.provider;
    onlineConfigurations[configuration.provider] = configuration;
    if (removeApiKey) keys.remove(configuration.provider);
    if (apiKey != null) keys[configuration.provider] = apiKey;
    notifyListeners();
  }

  @override
  Future<void> removeOnlineApiKey(OnlineModelProvider provider) async {
    removedKeys.add(provider);
    keys.remove(provider);
    if (source == AssistantReplySource.online && provider == onlineProvider) {
      enabled = false;
    }
    notifyListeners();
  }

  @override
  Future<bool> testOnlineConnection(
    OnlineModelConfiguration configuration, {
    String? apiKey,
  }) async {
    testedConfigurations.add(configuration);
    testedApiKeys.add(apiKey);
    connectionStatus = '公开样例连接成功';
    notifyListeners();
    return true;
  }

  @override
  Future<void> setReplyStyle({
    required LocalAssistantTone tone,
    required String persona,
  }) async {
    styleCalls++;
    this.tone = tone;
    this.persona = persona;
    notifyListeners();
  }

  @override
  Future<void> selectModel(String path) async {
    selectedPaths.add(path);
    selected = path;
    error = null;
    notifyListeners();
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    generating = false;
    installing = false;
    loading = false;
    progress = null;
    installProgress = null;
    installingModelName = null;
    replyingEntryId = null;
    notifyListeners();
  }

  @override
  Future<void> clearConversation() async {
    clearCalls++;
    replies.clear();
    notifyListeners();
  }

  @override
  Future<void> downloadRecommendedModel([LocalModelDescriptor? model]) async {
    downloadCalls++;
    final descriptor = model ?? recommendedModels.first;
    downloadedModels.add(descriptor);
    error = downloadFailure;
    if (error == null) {
      installing = true;
      installingModelName = descriptor.name;
      installProgress = const LocalModelInstallProgress(
        stage: LocalModelInstallStage.downloading,
        receivedBytes: 100000000,
        totalBytes: 400000000,
      );
    }
    notifyListeners();
  }

  @override
  Future<void> importModel(String path) async {
    importedPaths.add(path);
    error = importFailure;
    if (error == null) {
      final model = InstalledLocalModel(
        path: '/private/imported-${importedPaths.length}.gguf',
        name: 'model.gguf',
        sizeBytes: 429000000,
      );
      installedModels = [...installedModels, model];
      selected = model.path;
    }
    notifyListeners();
  }

  @override
  Future<void> removeInstalledModel(String path) async {
    removedPaths.add(path);
    installedModels = installedModels
        .where((model) => model.path != path)
        .toList();
    if (selected == path) {
      selected = null;
      enabled = false;
    }
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void _mockModelPicker(Future<Object?> Function(MethodCall) handler) {
  const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(channel, handler);
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}
