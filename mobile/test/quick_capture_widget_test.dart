import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/main.dart';
import 'package:diary/widgets/draggable_quick_capture.dart';

void main() {
  testWidgets('shows a global quick capture action in the mobile shell', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('floating-quick-capture')), findsOneWidget);
    expect(find.bySemanticsLabel('快速记录'), findsOneWidget);

    await tester.tap(find.byKey(const Key('floating-quick-capture')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('quick-capture-sheet-field')), findsOneWidget);
  });

  testWidgets('submits the quick capture sheet text to its callback', (
    tester,
  ) async {
    String? submitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DraggableQuickCaptureFab(
            onSubmit: (value) async => submitted = value,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('floating-quick-capture')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('quick-capture-sheet-field')),
      '今天的一个瞬间',
    );
    await tester.tap(find.widgetWithText(FilledButton, '记下'));
    await tester.pumpAndSettle();

    expect(submitted, '今天的一个瞬间');
  });

  testWidgets('keeps the draggable action inside its layout', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 480,
            child: DraggableQuickCaptureFab(onSubmit: _noopSubmit),
          ),
        ),
      ),
    );

    final fab = find.byKey(const Key('floating-quick-capture'));
    await tester.drag(fab, const Offset(-500, -500));
    await tester.pumpAndSettle();

    final rect = tester.getRect(fab);
    expect(rect.left, greaterThanOrEqualTo(16));
    expect(rect.top, greaterThanOrEqualTo(16));
    expect(rect.right, lessThanOrEqualTo(320 - 16));
    expect(rect.bottom, lessThanOrEqualTo(480 - 16));
  });
}

Future<void> _noopSubmit(String _) async {}
