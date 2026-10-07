import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/chat/chat_page.dart';

void main() {
  testWidgets('confirming message deletion leaves the composer unfocused', (
    tester,
  ) async {
    DiaryEntry? deletedEntry;
    final focusNode = await _openEntryActions(
      tester,
      onDelete: (entry) async => deletedEntry = entry,
    );

    await tester.tap(find.text('移入回收站'));
    await tester.pumpAndSettle();
    expect(find.text('移入回收站？'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '移入回收站'));
    await tester.pumpAndSettle();

    expect(deletedEntry?.id, 'entry-action-focus');
    expect(focusNode.hasFocus, isFalse);
    await _expectComposerCanBeFocusedAgain(tester, focusNode);
  });

  testWidgets('cancelling message deletion leaves the composer unfocused', (
    tester,
  ) async {
    var deleted = false;
    final focusNode = await _openEntryActions(
      tester,
      onDelete: (_) async => deleted = true,
    );

    await tester.tap(find.text('移入回收站'));
    await tester.pumpAndSettle();
    expect(find.text('移入回收站？'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(focusNode.hasFocus, isFalse);
    await _expectComposerCanBeFocusedAgain(tester, focusNode);
  });

  testWidgets('dismissing message actions leaves the composer unfocused', (
    tester,
  ) async {
    var deleted = false;
    final focusNode = await _openEntryActions(
      tester,
      onDelete: (_) async => deleted = true,
    );

    await tester.tapAt(const Offset(20, 100));
    await tester.pumpAndSettle();

    expect(find.text('编辑这条日记'), findsNothing);
    expect(deleted, isFalse);
    expect(focusNode.hasFocus, isFalse);
    await _expectComposerCanBeFocusedAgain(tester, focusNode);
  });
}

Future<FocusNode> _openEntryActions(
  WidgetTester tester, {
  required Future<void> Function(DiaryEntry) onDelete,
}) async {
  await tester.pumpWidget(_EntryActionHarness(onDelete: onDelete));
  await tester.pumpAndSettle();

  final field = find.byKey(const Key('chat-message-field'));
  final focusNode = tester.widget<TextField>(field).focusNode!;
  await tester.tap(field);
  await tester.pumpAndSettle();
  expect(focusNode.hasFocus, isTrue);

  await tester.longPress(
    find.byKey(const Key('chat-bubble-entry-action-focus')),
  );
  await tester.pumpAndSettle();
  expect(find.text('编辑这条日记'), findsOneWidget);
  expect(focusNode.hasFocus, isFalse);
  return focusNode;
}

Future<void> _expectComposerCanBeFocusedAgain(
  WidgetTester tester,
  FocusNode focusNode,
) async {
  await tester.tap(find.byKey(const Key('chat-message-field')));
  await tester.pumpAndSettle();
  expect(focusNode.hasFocus, isTrue);
  expect(tester.takeException(), isNull);
}

class _EntryActionHarness extends StatelessWidget {
  const _EntryActionHarness({required this.onDelete});

  final Future<void> Function(DiaryEntry) onDelete;

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime(2026, 10, 7, 12);
    return MaterialApp(
      home: Scaffold(
        body: ChatPage(
          entries: [
            DiaryEntry(
              id: 'entry-action-focus',
              createdAt: timestamp,
              updatedAt: timestamp,
              title: '待删除消息',
              content: '长按后不应重新弹出键盘。',
              contentText: '长按后不应重新弹出键盘。',
              category: '生活',
            ),
          ],
          onSend: (content, images, audio, videos, mood, moodLabel) async {},
          onOpenEntry: (_) {},
          onEdit: (_) async {},
          onDelete: onDelete,
          onOpenEditor: () {},
          onImportAttachments: (paths) async => paths,
          onNavigate: (_) {},
        ),
      ),
    );
  }
}
