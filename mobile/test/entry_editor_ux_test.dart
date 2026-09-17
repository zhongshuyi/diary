import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/diary_draft_store.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/entry/entry_detail_page.dart';
import 'package:diary/pages/entry/entry_editor_page.dart';

void main() {
  testWidgets('autosaves editor content after the draft debounce', (
    tester,
  ) async {
    final store = MemoryDiaryDraftStore();
    await tester.pumpWidget(_editor(store));

    await tester.enterText(
      find.byKey(const Key('entry-content-field')),
      '留给晚风的一句话。',
    );
    await tester.pump(const Duration(milliseconds: 501));

    final draft = await store.load('new-entry');
    expect(draft?['contentText'], '留给晚风的一句话。');
  });

  testWidgets('offers draft recovery and restores the saved content', (
    tester,
  ) async {
    final store = MemoryDiaryDraftStore();
    await store.save('new-entry', {
      'title': '草稿标题',
      'contentText': '草稿正文',
      'content': '草稿正文',
      'editorType': DiaryEditorType.plainText.wireValue,
      'category': '生活',
      'tags': <String>[],
      'mood': '平常',
      'attachments': <String>[],
    });

    await tester.pumpWidget(_editor(store));
    await tester.pumpAndSettle();

    expect(find.text('恢复草稿'), findsOneWidget);
    await tester.tap(find.text('恢复草稿'));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<TextField>(find.byKey(const Key('entry-title-field')))
          .controller
          ?.text,
      '草稿标题',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('entry-content-field')))
          .controller
          ?.text,
      '草稿正文',
    );
  });

  testWidgets('clears the draft after a successful save', (tester) async {
    final store = MemoryDiaryDraftStore();
    var saved = false;
    await tester.pumpWidget(_editor(store, onSave: (_) async => saved = true));

    await tester.enterText(
      find.byKey(const Key('entry-content-field')),
      '这篇会被保存。',
    );
    await tester.tap(find.text('保存日记'));
    await tester.pumpAndSettle();

    expect(saved, isTrue);
    expect(await store.load('new-entry'), isNull);
  });

  testWidgets('keeps the detail page open after editing an entry', (
    tester,
  ) async {
    final entry = _entry('原来的标题');
    final updated = entry.copyWith(title: '更新后的标题');
    await tester.pumpWidget(
      MaterialApp(
        home: EntryDetailPage(
          entry: entry,
          onEdit: (_) async => updated,
          onShare: () {},
          onDelete: () {},
          onToggleFavorite: () {},
        ),
      ),
    );

    await tester.tap(find.text('编辑这篇'));
    await tester.pumpAndSettle();

    expect(find.text('更新后的标题'), findsOneWidget);
    expect(find.text('日记详情'), findsOneWidget);
  });
}

Widget _editor(
  MemoryDiaryDraftStore store, {
  Future<void> Function(DiaryEntry entry)? onSave,
}) {
  return MaterialApp(
    home: EntryEditorPage(
      categories: const ['生活'],
      draftStore: store,
      draftKey: 'new-entry',
      onSave: onSave ?? (_) async {},
    ),
  );
}

DiaryEntry _entry(String title) => DiaryEntry(
  id: 'entry-ux',
  createdAt: DateTime(2026, 9, 17, 10),
  updatedAt: DateTime(2026, 9, 17, 10),
  title: title,
  content: '正文',
  contentText: '正文',
  category: '生活',
);
