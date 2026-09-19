import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/pages/settings/settings_page.dart';

void main() {
  test(
    'settings controller persists user preferences through its store',
    () async {
      final store = _MemorySettingsStore();
      final controller = SettingsController(store: store);

      await controller.initialize();
      await controller.setThemeMode(DiaryThemeMode.dark);
      await controller.setThemePreset(DiaryThemePreset.mistBlue);
      await controller.setCustomThemeColor(0xFF3E7895);
      await controller.setChatBackground(
        const DiaryChatBackground(imagePath: 'wallpaper.jpg', scale: 1.3),
      );
      await controller.setFontScale(1.2);
      await controller.setDefaultEditorType(DiaryEditorType.markdown);
      await controller.setShowWordCount(false);
      await controller.setQuickCaptureSide(QuickCaptureSide.left);
      await controller.setDefaultHomeMode(DiaryHomeMode.chat);
      await controller.setChatTitle('睡前片刻');

      expect(store.value.themeMode, DiaryThemeMode.dark);
      expect(store.value.themePreset, DiaryThemePreset.mistBlue);
      expect(store.value.customThemeColor, 0xFF3E7895);
      expect(store.value.chatBackground.imagePath, 'wallpaper.jpg');
      expect(store.value.chatBackground.scale, 1.3);
      expect(store.value.fontScale, 1.2);
      expect(store.value.defaultEditorType, DiaryEditorType.markdown);
      expect(store.value.showWordCount, isFalse);
      expect(store.value.quickCaptureSide, QuickCaptureSide.left);
      expect(store.value.defaultHomeMode, DiaryHomeMode.chat);
      expect(store.value.chatTitle, '睡前片刻');
    },
  );

  test(
    'settings keep the public update endpoint separate from sync credentials',
    () async {
      final store = _MemorySettingsStore();
      final controller = SettingsController(store: store);
      final observedConnections = <DiarySettings>[];

      await controller.initialize();
      controller.addListener(
        () => observedConnections.add(controller.settings),
      );
      await controller.saveConnectionSettings(
        syncEndpoint: 'https://sync.example.com/',
        syncToken: 'private-sync-token',
        updateEndpoint: 'https://updates.example.com/',
      );

      expect(controller.settings.syncEndpoint, 'https://sync.example.com');
      expect(controller.settings.syncToken, 'private-sync-token');
      expect(controller.settings.updateEndpoint, 'https://updates.example.com');
      expect(observedConnections, hasLength(1));
      expect(observedConnections.single.syncToken, 'private-sync-token');

      final reopened = SettingsController(store: store);
      await reopened.initialize();
      expect(reopened.settings.updateEndpoint, 'https://updates.example.com');
    },
  );

  test(
    'quick capture defaults to the right and survives controller reload',
    () async {
      final store = _MemorySettingsStore();
      final first = SettingsController(store: store);
      await first.initialize();
      expect(first.settings.quickCaptureSide, QuickCaptureSide.right);
      await first.setQuickCaptureSide(QuickCaptureSide.left);

      final reopened = SettingsController(store: store);
      await reopened.initialize();
      expect(reopened.settings.quickCaptureSide, QuickCaptureSide.left);
    },
  );

  test(
    'settings store falls back to safe values for invalid font scale',
    () async {
      final store = _MemorySettingsStore(const DiarySettings(fontScale: 5));
      final controller = SettingsController(store: store);

      await controller.initialize();

      expect(controller.settings.fontScale, 1.3);
    },
  );

  test('saved button side round trips through device preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesDiarySettingsStore();
    await store.save(
      const DiarySettings(quickCaptureSide: QuickCaptureSide.left),
    );
    expect((await store.load()).quickCaptureSide, QuickCaptureSide.left);
  });

  test(
    'saved default home mode round trips through device preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesDiarySettingsStore();
      await store.save(
        const DiarySettings(defaultHomeMode: DiaryHomeMode.chat),
      );
      expect((await store.load()).defaultHomeMode, DiaryHomeMode.chat);
    },
  );

  test('saved chat title round trips through device preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesDiarySettingsStore();
    await store.save(const DiarySettings(chatTitle: '晚安日记'));
    expect((await store.load()).chatTitle, '晚安日记');
  });

  test('saved chat wallpaper round trips through device preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesDiarySettingsStore();
    await store.save(
      const DiarySettings(
        chatBackground: DiaryChatBackground(
          imagePath: 'stored-wallpaper.jpg',
          scale: 1.7,
          alignmentX: .4,
          alignmentY: -.2,
          opacity: .3,
        ),
      ),
    );

    final restored = (await store.load()).chatBackground;
    expect(restored.imagePath, 'stored-wallpaper.jpg');
    expect(restored.scale, 1.7);
    expect(restored.alignmentX, .4);
    expect(restored.alignmentY, -.2);
    expect(restored.opacity, .3);
  });

  test('chat wallpaper values are normalized before persistence', () async {
    final store = _MemorySettingsStore();
    final controller = SettingsController(store: store);
    await controller.initialize();

    await controller.setChatBackground(
      const DiaryChatBackground(
        imagePath: '  wallpaper.jpg  ',
        scale: 5,
        alignmentX: -2,
        alignmentY: 2,
        opacity: 1,
      ),
    );

    expect(store.value.chatBackground.imagePath, 'wallpaper.jpg');
    expect(store.value.chatBackground.scale, 2.5);
    expect(store.value.chatBackground.alignmentX, -1);
    expect(store.value.chatBackground.alignmentY, 1);
    expect(store.value.chatBackground.opacity, .5);
  });

  test('saved theme preset round trips through device preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesDiarySettingsStore();
    await store.save(
      const DiarySettings(themePreset: DiaryThemePreset.evergreen),
    );

    expect((await store.load()).themePreset, DiaryThemePreset.evergreen);
  });

  test('custom theme color can be saved and reset', () async {
    final store = _MemorySettingsStore();
    final controller = SettingsController(store: store);
    await controller.initialize();

    await controller.setCustomThemeColor(0xFF6C7DE8);
    expect(store.value.customThemeColor, 0xFF6C7DE8);

    await controller.clearCustomThemeColor();
    expect(store.value.customThemeColor, isNull);
  });

  test(
    'saved custom theme color round trips through device preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SharedPreferencesDiarySettingsStore();
      await store.save(const DiarySettings(customThemeColor: 0xFF6C7DE8));

      expect((await store.load()).customThemeColor, 0xFF6C7DE8);
    },
  );

  test('theme presets update light and dark semantic color tokens', () {
    final light = DiaryTheme.lightFor(DiaryThemePreset.mistBlue);
    final dark = DiaryTheme.darkFor(DiaryThemePreset.mistBlue);

    expect(
      light.extension<DiaryThemeColors>()?.terracotta,
      const Color(0xFF3E7895),
    );
    expect(
      dark.extension<DiaryThemeColors>()?.terracotta,
      const Color(0xFF7DBAD4),
    );
  });

  testWidgets('custom color picker stores the selected accent color', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    final controller = SettingsController(store: store);
    await controller.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: SettingsPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('自定义主题色'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('custom-theme-hue-slider')), findsOneWidget);
    await tester.tap(find.byKey(const Key('custom-theme-save-button')));
    await tester.pumpAndSettle();

    expect(store.value.customThemeColor, isNotNull);
  });

  testWidgets('settings separates chat choices from connection details', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    final controller = SettingsController(store: store);
    await controller.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: SettingsPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('外观'), findsOneWidget);
    expect(find.text('记录与对话'), findsOneWidget);
    expect(find.text('服务器地址'), findsNothing);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-sync')),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('数据'), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-sync')));
    await tester.pumpAndSettle();

    expect(find.text('连接设置'), findsOneWidget);
    expect(find.text('服务器地址'), findsOneWidget);
  });

  testWidgets('chat background picker imports and stores the selected photo', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    final controller = SettingsController(store: store);
    await controller.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: SettingsPage(
          controller: controller,
          pickChatBackgroundPhoto: () async => const ['source-photo.jpg'],
          onImportPhotos: (paths) async => const ['stored-photo.jpg'],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-chat-background')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('chat-background-crop-canvas')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('chat-background-select')));
    await tester.pumpAndSettle();
    expect(find.text('拖动调整 · 双指缩放'), findsOneWidget);
    expect(find.byKey(const Key('chat-background-fine-tune')), findsOneWidget);
    final applyButton = find.byKey(const Key('chat-background-apply'));
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(store.value.chatBackground.imagePath, 'stored-photo.jpg');
  });
}

class _MemorySettingsStore implements DiarySettingsStore {
  _MemorySettingsStore([DiarySettings? initial])
    : value = initial ?? const DiarySettings();

  DiarySettings value;

  @override
  Future<DiarySettings> load() async => value;

  @override
  Future<void> save(DiarySettings settings) async => value = settings;
}
