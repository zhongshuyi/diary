// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/main.dart';

void main() {
  testWidgets('Quill editor smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('富文本测试'), findsWidgets);
    final codeButtonFinder = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.code),
    );
    expect(codeButtonFinder, findsOneWidget);

    await tester.tap(codeButtonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Delta JSON'), findsOneWidget);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
  });
}
