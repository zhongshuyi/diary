import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/daily_reminder_scheduler.dart';
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
      final carbon = DiaryThemePresetCodec.fromWireValue('carbon');
      await controller.setThemePreset(carbon);
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
      expect(store.value.themePreset.wireValue, 'carbon');
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

  test('saved reminder time round trips through device preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPreferencesDiarySettingsStore();
    await store.save(
      const DiarySettings(
        dailyReminder: true,
        dailyReminderTime: DiaryReminderTime(hour: 6, minute: 45),
      ),
    );

    final restored = await store.load();
    expect(restored.dailyReminder, isTrue);
    expect(restored.dailyReminderTime.label, '06:45');
  });

  testWidgets('mobile preferences do not repeat data and sync controls', (
    tester,
  ) async {
    final controller = SettingsController(store: _MemorySettingsStore());
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: SettingsPage(controller: controller, showDataControls: false),
      ),
    );

    expect(find.text('同步与更新'), findsNothing);
    expect(find.text('清理临时缓存'), findsNothing);
    expect(find.text('偏好设置'), findsNothing);
    expect(find.textContaining('阅读、记录和应用习惯'), findsOneWidget);
  });

  test(
    'keeps the reminder disabled when notification permission is denied',
    () async {
      final store = _MemorySettingsStore();
      final scheduler = _FakeDailyReminderScheduler(
        scheduleResult: DailyReminderScheduleResult.permissionDenied,
      );
      final controller = SettingsController(
        store: store,
        dailyReminderScheduler: scheduler,
      );
      await controller.initialize();

      final result = await controller.setDailyReminder(true);

      expect(result, DailyReminderScheduleResult.permissionDenied);
      expect(controller.settings.dailyReminder, isFalse);
      expect(store.value.dailyReminder, isFalse);
      expect(scheduler.requestPermissionValues, [true]);
      expect(scheduler.scheduledTimes.single.label, '21:30');
    },
  );

  test('reschedules an enabled reminder when its time changes', () async {
    final store = _MemorySettingsStore();
    final scheduler = _FakeDailyReminderScheduler();
    final controller = SettingsController(
      store: store,
      dailyReminderScheduler: scheduler,
    );
    await controller.initialize();
    await controller.setDailyReminder(true);

    final result = await controller.setDailyReminderTime(
      const DiaryReminderTime(hour: 7, minute: 15),
    );

    expect(result, DailyReminderScheduleResult.scheduled);
    expect(controller.settings.dailyReminder, isTrue);
    expect(controller.settings.dailyReminderTime.label, '07:15');
    expect(store.value.dailyReminderTime.minuteOfDay, 435);
    expect(scheduler.requestPermissionValues, [true, false]);
    expect(scheduler.scheduledTimes.last.label, '07:15');
  });

  test(
    'restores an enabled reminder without prompting at app launch',
    () async {
      final scheduler = _FakeDailyReminderScheduler();
      final controller = SettingsController(
        store: _MemorySettingsStore(
          const DiarySettings(
            dailyReminder: true,
            dailyReminderTime: DiaryReminderTime(hour: 8, minute: 0),
          ),
        ),
        dailyReminderScheduler: scheduler,
      );

      await controller.initialize();

      expect(scheduler.requestPermissionValues, [false]);
      expect(scheduler.scheduledTimes.single.label, '08:00');
    },
  );

  test('cancels the scheduled reminder before saving it as disabled', () async {
    final store = _MemorySettingsStore(
      const DiarySettings(dailyReminder: true),
    );
    final scheduler = _FakeDailyReminderScheduler();
    final controller = SettingsController(
      store: store,
      dailyReminderScheduler: scheduler,
    );
    await controller.initialize();

    final result = await controller.setDailyReminder(false);

    expect(result, DailyReminderScheduleResult.cancelled);
    expect(controller.settings.dailyReminder, isFalse);
    expect(store.value.dailyReminder, isFalse);
    expect(scheduler.cancelCallCount, 1);
  });

  test('keeps the reminder enabled when cancellation fails', () async {
    final store = _MemorySettingsStore(
      const DiarySettings(dailyReminder: true),
    );
    final scheduler = _FakeDailyReminderScheduler(
      cancelResult: DailyReminderScheduleResult.failed,
    );
    final controller = SettingsController(
      store: store,
      dailyReminderScheduler: scheduler,
    );
    await controller.initialize();

    final result = await controller.setDailyReminder(false);

    expect(result, DailyReminderScheduleResult.failed);
    expect(controller.settings.dailyReminder, isTrue);
    expect(store.value.dailyReminder, isTrue);
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
      DiarySettings(
        themePreset: DiaryThemePresetCodec.fromWireValue('deepSea'),
      ),
    );

    expect((await store.load()).themePreset.wireValue, 'deepSea');
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

  test('theme presets replace the old palette and keep warm paper default', () {
    expect(
      DiaryThemePreset.values.map((preset) => preset.wireValue),
      equals([
        'warmPaper',
        'carbon',
        'deepSea',
        'pine',
        'dusk',
        'terracotta',
        'roseMist',
        'moonstone',
      ]),
    );
    expect(
      DiaryThemePresetCodec.fromWireValue('mistBlue'),
      DiaryThemePreset.warmPaper,
    );
    expect(
      DiaryThemePresetCodec.fromWireValue('evergreen'),
      DiaryThemePreset.warmPaper,
    );
    expect(
      DiaryThemePresetCodec.fromWireValue('lavender'),
      DiaryThemePreset.warmPaper,
    );
  });

  test(
    'carbon theme provides a #181818 dark surface and paired light mode',
    () {
      final carbon = DiaryThemePresetCodec.fromWireValue('carbon');
      final light = DiaryTheme.lightFor(carbon);
      final dark = DiaryTheme.darkFor(carbon);

      expect(
        light.extension<DiaryThemeColors>()?.terracotta,
        const Color(0xFF8A5A2B),
      );
      expect(
        light.extension<DiaryThemeColors>()?.paper,
        const Color(0xFFF5F5F3),
      );
      expect(
        dark.extension<DiaryThemeColors>()?.paper,
        const Color(0xFF181818),
      );
      expect(dark.colorScheme.onPrimary, const Color(0xFF101010));
    },
  );

  test('warm paper primary actions use a high-contrast label', () {
    expect(DiaryTheme.light.colorScheme.primary, const Color(0xFFB55C44));
    expect(DiaryTheme.light.colorScheme.onPrimary, Colors.white);
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

  testWidgets('enabling the daily reminder reveals its default time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    final dailyReminder = find.text('每日提醒');
    await tester.tap(dailyReminder);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('settings-daily-reminder-time')),
      findsOneWidget,
    );
    expect(find.text('每天 21:30'), findsOneWidget);
  });

  testWidgets(
    'theme picker presents the full visual theme grid and saves a choice',
    (tester) async {
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

      await tester.tap(find.text('主题配色').first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('theme-preset-grid')), findsOneWidget);
      expect(
        find.byKey(const Key('settings-theme-preset-warmPaper')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-theme-preset-carbon')),
        findsOneWidget,
      );
      expect(
        tester.widget<Text>(find.text('默认')).style?.color,
        DiaryPalette.ink,
      );

      await tester.tap(find.byKey(const Key('settings-theme-preset-carbon')));
      await tester.pumpAndSettle();

      expect(store.value.themePreset.wireValue, 'carbon');

      await tester.tap(find.text('主题配色').first);
      await tester.pumpAndSettle();

      final themeGrid = find.byKey(const Key('theme-preset-grid'));
      final themeScrollable = find.descendant(
        of: themeGrid,
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-theme-preset-deepSea')),
        240,
        scrollable: themeScrollable,
      );
      expect(
        find.byKey(const Key('settings-theme-preset-deepSea')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-theme-preset-pine')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-theme-preset-dusk')),
        240,
        scrollable: themeScrollable,
      );
      expect(
        find.byKey(const Key('settings-theme-preset-dusk')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-theme-preset-terracotta')),
        findsOneWidget,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings-theme-preset-moonstone')),
        240,
        scrollable: themeScrollable,
      );
      expect(
        find.byKey(const Key('settings-theme-preset-roseMist')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('settings-theme-preset-moonstone')),
        findsOneWidget,
      );
    },
  );

  testWidgets('theme picker accommodates narrow screens and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _MemorySettingsStore();
    final controller = SettingsController(store: store);
    await controller.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: SettingsPage(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('主题配色').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('theme-preset-grid')), findsOneWidget);
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

class _FakeDailyReminderScheduler implements DailyReminderScheduler {
  _FakeDailyReminderScheduler({
    this.scheduleResult = DailyReminderScheduleResult.scheduled,
    this.cancelResult = DailyReminderScheduleResult.cancelled,
  });

  final DailyReminderScheduleResult scheduleResult;
  final DailyReminderScheduleResult cancelResult;
  final List<DiaryReminderTime> scheduledTimes = [];
  final List<bool> requestPermissionValues = [];
  int cancelCallCount = 0;

  @override
  Future<DailyReminderScheduleResult> cancel() async {
    cancelCallCount += 1;
    return cancelResult;
  }

  @override
  Future<DailyReminderScheduleResult> schedule(
    DiaryReminderTime time, {
    required bool requestPermission,
  }) async {
    scheduledTimes.add(time);
    requestPermissionValues.add(requestPermission);
    return scheduleResult;
  }
}
