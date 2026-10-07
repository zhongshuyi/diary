import 'package:diary/app/app_theme.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/pages/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('model aliases open the companion directly without saving', (
    tester,
  ) async {
    final store = _MemorySettingsStore();
    final controller = await _controller(store);
    var opened = 0;
    await _show(
      tester,
      SettingsPage(
        controller: controller,
        onOpenLocalAssistant: () => opened++,
        onOpenTranscription: () {},
      ),
    );

    await _search(tester, 'DeepSeek API');
    expect(find.byKey(const Key('settings-local-assistant')), findsOneWidget);
    expect(find.byKey(const Key('settings-transcription')), findsNothing);
    expect(find.byKey(const Key('settings-theme-mode')), findsNothing);
    await tester.tap(find.byKey(const Key('settings-local-assistant')));
    expect(opened, 1);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isFalse,
    );
    expect(store.writes, 0);
  });

  testWidgets(
    'search returns matching configured settings and current values',
    (tester) async {
      final store = _MemorySettingsStore(
        const DiarySettings(
          syncEndpoint: 'https://sync.example.com',
          amapAndroidKey: 'example-map-key',
          fontScale: 1.2,
        ),
      );
      final controller = await _controller(store);
      await _show(tester, SettingsPage(controller: controller));

      await _search(tester, '已配置');
      expect(find.byKey(const Key('settings-sync')), findsOneWidget);
      expect(find.byKey(const Key('settings-amap-key')), findsOneWidget);
      expect(find.byKey(const Key('settings-font-scale')), findsNothing);
      expect(find.text('已配置同步连接'), findsOneWidget);
      await _search(tester, '字体');
      expect(find.byKey(const Key('settings-font-scale')), findsOneWidget);
      expect(find.text('120%'), findsOneWidget);
      expect(find.byKey(const Key('settings-sync')), findsNothing);
      expect(store.writes, 0);
    },
  );

  testWidgets('no results can be cleared to restore the settings index', (
    tester,
  ) async {
    final controller = await _controller(_MemorySettingsStore());
    await _show(tester, SettingsPage(controller: controller));
    await _search(tester, '不存在的设置 xyz');
    expect(find.byKey(const Key('settings-search-empty')), findsOneWidget);
    expect(find.byKey(const Key('settings-theme-mode')), findsNothing);

    await tester.tap(find.byKey(const Key('settings-search-clear-empty')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('settings-search-empty')), findsNothing);
    expect(find.byKey(const Key('settings-theme-mode')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('settings-search')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets(
    'group shortcut clears filtering and scrolls to the requested group',
    (tester) async {
      final controller = await _controller(_MemorySettingsStore());
      await _show(
        tester,
        SettingsPage(
          controller: controller,
          onOpenLocalAssistant: () {},
          onOpenTranscription: () {},
          onOpenChatAppearance: () {},
          onOpenBackup: () {},
          onOpenCategories: () {},
          onOpenAbout: () {},
        ),
      );
      await _search(tester, '字体');
      await tester.tap(find.byKey(const Key('settings-group-data')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<TextField>(find.byKey(const Key('settings-search')))
            .controller!
            .text,
        isEmpty,
      );
      final list = find.byKey(const Key('settings-list'));
      final section = find.byKey(const Key('settings-section-data'));
      final sectionY = tester.getTopLeft(section).dy;
      expect(sectionY, greaterThanOrEqualTo(tester.getTopLeft(list).dy));
      expect(sectionY, lessThan(tester.getBottomLeft(list).dy));
      expect(find.byKey(const Key('settings-backup')), findsOneWidget);
      expect(find.byKey(const Key('settings-categories')), findsOneWidget);
    },
  );

  testWidgets(
    'group search shows its rows and filtering never changes switches',
    (tester) async {
      final store = _MemorySettingsStore(
        const DiarySettings(showWordCount: false, showChatAvatar: false),
      );
      final controller = await _controller(store);
      await _show(tester, SettingsPage(controller: controller));
      await _search(tester, '记录与陪伴');
      expect(find.byKey(const Key('settings-default-editor')), findsOneWidget);
      expect(find.byKey(const Key('settings-word-count')), findsOneWidget);
      expect(
        find.byKey(const Key('settings-show-chat-avatar')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('settings-theme-mode')), findsNothing);
      final wordCountSwitch = tester.widget<Switch>(
        find.descendant(
          of: find.byKey(const Key('settings-word-count')),
          matching: find.byType(Switch),
        ),
      );
      expect(wordCountSwitch.value, isFalse);
      await _search(tester, '不存在');
      await _search(tester, '头像');
      expect(controller.settings.showWordCount, isFalse);
      expect(controller.settings.showChatAvatar, isFalse);
      expect(store.writes, 0);
    },
  );

  testWidgets(
    'avatar search leads to appearance and removes the duplicate switch',
    (tester) async {
      final controller = await _controller(_MemorySettingsStore());
      var opened = 0;
      await _show(
        tester,
        SettingsPage(
          controller: controller,
          onOpenChatAppearance: () => opened++,
        ),
      );
      await _search(tester, '头像');
      expect(find.byKey(const Key('settings-show-chat-avatar')), findsNothing);
      await tester.tap(find.byKey(const Key('settings-chat-appearance')));
      expect(opened, 1);
    },
  );

  testWidgets(
    'data visibility only hides sync and keeps supplied management links',
    (tester) async {
      final controller = await _controller(_MemorySettingsStore());
      await _show(
        tester,
        SettingsPage(
          controller: controller,
          showDataControls: false,
          onOpenBackup: () {},
          onOpenCategories: () {},
        ),
      );
      await _search(tester, '数据与服务');
      expect(find.byKey(const Key('settings-sync')), findsNothing);
      expect(find.byKey(const Key('settings-backup')), findsOneWidget);
      expect(find.byKey(const Key('settings-categories')), findsOneWidget);
    },
  );

  testWidgets('settings index fits a narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = await _controller(_MemorySettingsStore());
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: SettingsPage(
          controller: controller,
          onOpenLocalAssistant: () {},
          onOpenTranscription: () {},
          onOpenChatAppearance: () {},
          onOpenBackup: () {},
          onOpenAbout: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await _search(tester, '应用锁');
    expect(find.byKey(const Key('settings-app-pin')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard leaves search results usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final controller = await _controller(_MemorySettingsStore());
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: SettingsPage(
          controller: controller,
          onOpenLocalAssistant: () => opened++,
          onOpenTranscription: () {},
          onOpenChatAppearance: () {},
          onOpenBackup: () {},
          onOpenAbout: () {},
        ),
      ),
    );
    await _search(tester, 'DeepSeek');
    expect(find.byKey(const Key('settings-group-recording')), findsNothing);
    expect(tester.takeException(), isNull);
    final result = find.byKey(const Key('settings-local-assistant'));
    expect(result.hitTestable(), findsOneWidget);
    await tester.tap(result.hitTestable());
    expect(opened, 1);
  });
}

Future<SettingsController> _controller(_MemorySettingsStore store) async {
  final controller = SettingsController(store: store);
  await controller.initialize();
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _show(WidgetTester tester, SettingsPage page) async {
  await tester.pumpWidget(MaterialApp(theme: DiaryTheme.light, home: page));
  await tester.pumpAndSettle();
}

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byKey(const Key('settings-search')), query);
  await tester.pumpAndSettle();
}

class _MemorySettingsStore implements DiarySettingsStore {
  _MemorySettingsStore([this.value = const DiarySettings()]);

  DiarySettings value;
  int writes = 0;

  @override
  Future<DiarySettings> load() async => value;

  @override
  Future<void> save(DiarySettings settings) async {
    writes++;
    value = settings;
  }
}
