import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/application/update_service.dart';
import 'package:diary/main.dart';
import 'package:diary/pages/entry/entry_detail_page.dart';
import 'package:diary/pages/settings/about_page.dart';
import 'package:diary/widgets/diary_navigation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Future<void> _runAsWindows(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  try {
    await body();
  } finally {
    // Reset before the test framework verifies its global invariants.
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  testWidgets('shows the diary timeline and primary action', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('MY / DIARY'), findsOneWidget);
    expect(find.text('今天，写给自己'), findsOneWidget);
    expect(find.text('写一篇'), findsOneWidget);
    expect(find.text('最近的日记'), findsOneWidget);
  });

  testWidgets('uses the mobile shell without desktop window chrome', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(DiaryBottomNavigation), findsOneWidget);
    expect(find.byKey(const Key('desktop-window-bar')), findsNothing);
  });

  testWidgets('keeps the desktop shell when its window is narrow', (
    tester,
  ) async {
    await _runAsWindows(() async {
      tester.view.physicalSize = const Size(1120, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('desktop-window-bar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('can create and save a diary entry', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('写一篇'));
    await tester.pumpAndSettle();

    expect(find.text('写下此刻'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('entry-title-field')),
      '给未来的自己',
    );
    await tester.enterText(
      find.byKey(const Key('entry-content-field')),
      '今天也有好好生活。',
    );
    await tester.tap(find.text('保存日记'));
    await tester.pumpAndSettle();

    expect(find.text('给未来的自己'), findsOneWidget);
    expect(find.text('今天也有好好生活。'), findsOneWidget);
  });

  testWidgets('can capture a text fragment without opening the editor', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('quick-capture-field')),
      '路边的树影很好看。',
    );
    await tester.tap(find.text('记下'));
    await tester.pumpAndSettle();

    expect(find.text('路边的树影很好看。'), findsOneWidget);
  });

  testWidgets('uses the desktop writing workspace on a wide window', (
    tester,
  ) async {
    await _runAsWindows(() async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('新建日记  Ctrl + N'), findsOneWidget);
      expect(find.textContaining('TODAY /'), findsOneWidget);
      expect(find.text('一条就是一个瞬间'), findsOneWidget);
      expect(find.byKey(const Key('desktop-window-bar')), findsOneWidget);
      expect(find.byTooltip('切换到深色模式'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('opens the desktop editor with metadata beside the canvas', (
    tester,
  ) async {
    await _runAsWindows(() async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建日记  Ctrl + N'));
      await tester.pumpAndSettle();

      expect(find.text('这篇日记'), findsOneWidget);
      expect(find.text('Ctrl + Enter 保存 · Esc 返回'), findsOneWidget);
      expect(find.text('添加附件'), findsOneWidget);
      expect(find.byKey(const Key('desktop-window-bar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'opens desktop settings from the app area and returns to the workspace',
    (tester) async {
      await _runAsWindows(() async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        await tester.tap(find.text('应用设置'));
        await tester.pumpAndSettle();

        expect(find.text('偏好设置'), findsNWidgets(2));
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(find.text('应用工具'), findsOneWidget);
        expect(find.byTooltip('返回'), findsOneWidget);

        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        expect(find.text('最近的日记'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('filters entries with the search field', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('diary-search-field')), '慢下来');
    await tester.pumpAndSettle();

    expect(find.text('慢下来，生活才会发光'), findsOneWidget);
    expect(find.text('把周末留给自己'), findsNothing);
  });

  testWidgets('opens the calendar tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('日历'));
    await tester.pumpAndSettle();

    expect(find.text('我的日历'), findsOneWidget);
    expect(find.text('2026年 9月'), findsOneWidget);
  });

  testWidgets('opens the media library tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('媒体库'));
    await tester.pumpAndSettle();

    expect(find.text('媒体库'), findsNWidgets(2));
    expect(find.text('你的媒体库还是空的'), findsOneWidget);
  });

  testWidgets('editor exposes format, category, tag and attachment controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('写一篇'));
    await tester.pumpAndSettle();

    expect(find.text('编辑方式'), findsOneWidget);
    expect(find.text('纯文本'), findsOneWidget);
    expect(find.text('富文本'), findsOneWidget);
    expect(find.text('分类'), findsOneWidget);
    expect(find.byKey(const Key('entry-tags-field')), findsOneWidget);
    expect(find.text('添加附件'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the recycle bin from the profile tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('回收站'));
    await tester.pumpAndSettle();

    expect(find.text('回收站').last, findsOneWidget);
    expect(find.text('这里还没有被丢弃的日记'), findsOneWidget);
  });

  testWidgets('offers an update check from the about page', (tester) async {
    final service = AppUpdateService(
      baseUrl: 'https://sync.example.com',
      client: MockClient(
        (_) async => http.Response(
          '{"data":{"platform":"mobile","version":"1.1.0","downloadUrl":"https://download.example.com","notes":"修复问题"}}',
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(home: AboutPage(updateService: service)),
    );
    await tester.pumpAndSettle();

    expect(find.text('检查更新'), findsOneWidget);
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();
    expect(find.textContaining('发现新版本'), findsOneWidget);
  });

  testWidgets('uses the actual loaded app version when checking for updates', (
    tester,
  ) async {
    final service = AppUpdateService(
      baseUrl: 'https://sync.example.com',
      client: MockClient(
        (_) async => http.Response(
          '{"data":{"platform":"mobile","version":"1.0.0","downloadUrl":"https://download.example.com","notes":""}}',
          200,
          headers: const {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: AboutPage(
          updateService: service,
          loadCurrentVersion: () async => '1.1.0',
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('检查更新'));
    await tester.pumpAndSettle();

    expect(find.text('当前已是最新版本'), findsOneWidget);
  });

  testWidgets('renders a saved rich-text delta in the detail page', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 15);
    final entry = DiaryEntry(
      id: 'rich-text-entry',
      createdAt: now,
      updatedAt: now,
      title: '富文本测试',
      content: jsonEncode([
        {
          'insert': '今天值得记住',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]),
      contentText: '今天值得记住',
      editorType: DiaryEditorType.richText,
      category: '生活',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EntryDetailPage(
          entry: entry,
          onEdit: (_) async {},
          onShare: () {},
          onDelete: () {},
          onToggleFavorite: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains('今天值得记住'),
      ),
      findsOneWidget,
    );
  });
}
