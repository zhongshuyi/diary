import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/widgets/desktop_window_bar.dart';

void main() {
  final commands = <String>[];

  setUp(() {
    commands.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('diary/window'), (
          call,
        ) async {
          commands.add(call.method);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('diary/window'), null);
  });

  _windowsTest(
    'back, new entry, theme and custom controls respond without a double-tap delay',
    (tester) async {
      var back = 0;
      var newEntry = 0;
      var theme = 0;
      var custom = 0;
      await _open(
        tester,
        DesktopWindowBar(
          title: '设置',
          isDark: false,
          onBack: () => back++,
          onNewEntry: () => newEntry++,
          onToggleTheme: () => theme++,
          actions: [
            IconButton(
              tooltip: '自定义操作',
              onPressed: () => custom++,
              icon: const Icon(Icons.search),
            ),
          ],
        ),
      );

      await tester.tap(find.byTooltip('返回'));
      expect(back, 1);
      await tester.tap(find.widgetWithText(FilledButton, '新建日记'));
      expect(newEntry, 1);
      await tester.tap(find.byTooltip('切换到深色模式'));
      expect(theme, 1);
      await tester.tap(find.byTooltip('自定义操作'));
      expect(custom, 1);
      expect(commands, isEmpty);
    },
  );

  _windowsTest(
    'native window controls run on a single click without entering the double-tap arena',
    (tester) async {
      await _open(
        tester,
        DesktopWindowBar(title: '工作区', isDark: false, onToggleTheme: () {}),
      );
      await tester.tap(find.byTooltip('最小化'));
      await tester.pump();
      expect(commands, ['minimizeWindow']);
      await tester.tap(find.byTooltip('最大化或还原'));
      await tester.pump();
      expect(commands, ['minimizeWindow', 'toggleMaximizeWindow']);
      await tester.tap(find.byTooltip('关闭'));
      await tester.pump();
      expect(commands, [
        'minimizeWindow',
        'toggleMaximizeWindow',
        'closeWindow',
      ]);
    },
  );

  _windowsTest(
    'double clicking free title-bar space still maximizes the native window',
    (tester) async {
      await _open(
        tester,
        DesktopWindowBar(title: '工作区', isDark: false, onToggleTheme: () {}),
      );
      final freeArea = find.byKey(const Key('desktop-window-drag-area'));
      final point = tester.getTopRight(freeArea) + const Offset(-20, 30);
      await tester.tapAt(point);
      await tester.pump(const Duration(milliseconds: 80));
      expect(commands, isEmpty);
      await tester.tapAt(point);
      await tester.pump();
      expect(commands, ['toggleMaximizeWindow']);
    },
  );

  _windowsTest(
    'dragging free title-bar space still begins a native window drag',
    (tester) async {
      await _open(
        tester,
        DesktopWindowBar(title: '工作区', isDark: false, onToggleTheme: () {}),
      );
      final freeArea = find.byKey(const Key('desktop-window-drag-area'));
      final point = tester.getTopRight(freeArea) + const Offset(-20, 30);
      await tester.dragFrom(point, const Offset(40, 12));
      await tester.pump();
      expect(commands, ['startWindowDrag']);
    },
  );

  _windowsTest('dragging a control does not start a native title-bar drag', (
    tester,
  ) async {
    await _open(
      tester,
      DesktopWindowBar(
        title: '工作区',
        isDark: false,
        onBack: () {},
        onToggleTheme: () {},
      ),
    );
    await tester.drag(find.byTooltip('返回'), const Offset(40, 12));
    await tester.pump();
    expect(commands, isEmpty);
  });
}

void _windowsTest(
  String description,
  Future<void> Function(WidgetTester) body,
) {
  testWidgets(description, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body(tester);
      // DoubleTapGestureRecognizer leaves a short minimum-tap tracker timer.
      await tester.pump(const Duration(milliseconds: 50));
    } finally {
      // Restore before Flutter verifies global invariants, not in tearDown.
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

Future<void> _open(WidgetTester tester, DesktopWindowBar bar) async {
  tester.view.physicalSize = const Size(1000, 680);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: DiaryTheme.light,
      home: Scaffold(
        body: Column(
          children: [
            bar,
            const Expanded(child: SizedBox()),
          ],
        ),
      ),
    ),
  );
}
