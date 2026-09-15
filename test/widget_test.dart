import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/main.dart';
import 'package:diary/pages/entry/entry_detail_page.dart';

void main() {
  testWidgets('shows the diary timeline and primary action', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('MY / DIARY'), findsOneWidget);
    expect(find.text('今天，写给自己'), findsOneWidget);
    expect(find.text('写一篇'), findsOneWidget);
    expect(find.text('最近的日记'), findsOneWidget);
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
