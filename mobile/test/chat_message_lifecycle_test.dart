import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/chat/chat_page.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_image_viewer.dart';
import 'package:diary/widgets/rich_text_viewer.dart';

void main() {
  testWidgets('successive sends preserve existing message renderer states', (
    tester,
  ) async {
    final harness = GlobalKey<_LifecycleHarnessState>();
    await tester.pumpWidget(_LifecycleHarness(key: harness));
    await tester.pumpAndSettle();
    final originalState = _rendererState(tester, 'original');
    final originalAudioState = _audioState(tester, 'original');

    await _send(tester, 'first');
    final firstState = _rendererState(tester, 'sent-1');
    final firstAudioState = _audioState(tester, 'sent-1');
    expect(_rendererState(tester, 'original'), same(originalState));
    expect(_audioState(tester, 'original'), same(originalAudioState));

    await _send(tester, 'second');
    expect(_rendererState(tester, 'original'), same(originalState));
    expect(_rendererState(tester, 'sent-1'), same(firstState));
    expect(_audioState(tester, 'original'), same(originalAudioState));
    expect(_audioState(tester, 'sent-1'), same(firstAudioState));
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed entrance keeps its renderer across parent refreshes', (
    tester,
  ) async {
    final harness = GlobalKey<_LifecycleHarnessState>();
    await tester.pumpWidget(_LifecycleHarness(key: harness));
    await tester.pumpAndSettle();

    await _send(tester, 'first');
    final stateDuringEntrance = _rendererState(tester, 'sent-1');
    final audioStateDuringEntrance = _audioState(tester, 'sent-1');
    await tester.pump(const Duration(milliseconds: 350));
    harness.currentState!.refresh();
    await tester.pump();

    expect(_rendererState(tester, 'sent-1'), same(stateDuringEntrance));
    expect(_audioState(tester, 'sent-1'), same(audioStateDuringEntrance));
    await tester.pump(const Duration(milliseconds: 100));
    harness.currentState!.refresh();
    await tester.pump();
    expect(_rendererState(tester, 'sent-1'), same(stateDuringEntrance));
    expect(_audioState(tester, 'sent-1'), same(audioStateDuringEntrance));
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh during entrance continues progress without replay', (
    tester,
  ) async {
    final harness = GlobalKey<_LifecycleHarnessState>();
    await tester.pumpWidget(_LifecycleHarness(key: harness));
    await tester.pumpAndSettle();
    expect(_entranceOpacity(tester, 'original'), 1);

    await _send(tester, 'first');
    final state = _rendererState(tester, 'sent-1');
    await tester.pump(const Duration(milliseconds: 120));
    final progressBeforeRefresh = _entranceOpacity(tester, 'sent-1');
    expect(progressBeforeRefresh, inExclusiveRange(.4, 1));
    harness.currentState!.refresh();
    await tester.pump();

    expect(_rendererState(tester, 'sent-1'), same(state));
    expect(_entranceOpacity(tester, 'sent-1'), progressBeforeRefresh);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_entranceOpacity(tester, 'sent-1'), 1);
    harness.currentState!.refresh();
    await tester.pump();
    expect(_entranceOpacity(tester, 'sent-1'), 1);
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editing embedded rich images updates attachment deduplication', (
    tester,
  ) async {
    final directory = await tester.runAsync(
      () => Directory.systemTemp.createTemp('diary-chat-rich-images-'),
    );
    if (directory == null) fail('Could not create test image directory');
    addTearDown(() => directory.delete(recursive: true));
    final firstImage = File('${directory.path}/first.png');
    final secondImage = File('${directory.path}/second.png');
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/lXcAAAAASUVORK5CYII=',
    );
    await tester.runAsync(() async {
      await firstImage.writeAsBytes(bytes);
      await secondImage.writeAsBytes(bytes);
    });
    final harness = GlobalKey<_LifecycleHarnessState>();
    await tester.pumpWidget(_LifecycleHarness(key: harness));
    await tester.pumpAndSettle();

    String contentWithImage(String imagePath) => jsonEncode([
      {
        'insert': {'image': imagePath},
      },
      {'insert': '\n图片说明\n'},
    ]);
    final original = _richEntry('original', '图片说明', 0).copyWith(
      content: contentWithImage(firstImage.path),
      imagePaths: [firstImage.path, secondImage.path],
      audioPaths: const [],
    );
    harness.currentState!.replaceEntry(original);
    await tester.pumpAndSettle();
    final renderer = _rendererState(tester, 'original');
    final attachments = find.descendant(
      of: find.byKey(const ValueKey('chat-entry-original')),
      matching: find.byType(DiaryImageThumbnail),
    );
    expect(attachments, findsOneWidget);
    expect(tester.widget<DiaryImageThumbnail>(attachments).imagePaths, [
      secondImage.path,
    ]);

    harness.currentState!.refresh();
    await tester.pumpAndSettle();
    expect(tester.widget<DiaryImageThumbnail>(attachments).imagePaths, [
      secondImage.path,
    ]);

    harness.currentState!.replaceEntry(
      original.copyWith(content: contentWithImage(secondImage.path)),
    );
    await tester.pumpAndSettle();
    expect(_rendererState(tester, 'original'), same(renderer));
    expect(tester.widget<DiaryImageThumbnail>(attachments).imagePaths, [
      firstImage.path,
    ]);
    expect(tester.takeException(), isNull);
  });
}

State<StatefulWidget> _rendererState(WidgetTester tester, String id) =>
    tester.state(
      find.descendant(
        of: find.byKey(ValueKey('chat-entry-$id')),
        matching: find.byType(DiaryRichTextViewer),
      ),
    );

State<StatefulWidget> _audioState(WidgetTester tester, String id) =>
    tester.state(
      find.descendant(
        of: find.byKey(ValueKey('chat-entry-$id')),
        matching: find.byType(DiaryAudioPlayer),
      ),
    );

double _entranceOpacity(WidgetTester tester, String id) => tester
    .widget<FadeTransition>(
      find
          .descendant(
            of: find.byKey(ValueKey('chat-entry-$id')),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

Future<void> _send(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(const Key('chat-message-field')), text);
  await tester.testTextInput.receiveAction(TextInputAction.send);
  await tester.pump();
}

DiaryEntry _richEntry(String id, String text, int minute) {
  final timestamp = DateTime(2026, 10, 7, 12, minute);
  return DiaryEntry(
    id: id,
    createdAt: timestamp,
    updatedAt: timestamp,
    title: text,
    content: jsonEncode([
      {'insert': '$text\n'},
    ]),
    contentText: text,
    editorType: DiaryEditorType.richText,
    category: '生活',
    audioPaths: ['$id.m4a'],
  );
}

class _LifecycleHarness extends StatefulWidget {
  const _LifecycleHarness({super.key});

  @override
  State<_LifecycleHarness> createState() => _LifecycleHarnessState();
}

class _LifecycleHarnessState extends State<_LifecycleHarness> {
  List<DiaryEntry> entries = [_richEntry('original', 'original', 0)];
  int sentCount = 0;

  void refresh() => setState(() => entries = List.of(entries));

  void replaceEntry(DiaryEntry updated) => setState(() {
    entries = [
      for (final entry in entries) entry.id == updated.id ? updated : entry,
    ];
  });

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: ChatPage(
        entries: entries,
        onSend: (content, images, audio, videos, mood, moodLabel) async {
          setState(() {
            sentCount += 1;
            entries = [
              ...entries,
              _richEntry('sent-$sentCount', content, sentCount),
            ];
          });
        },
        onOpenEntry: (_) {},
        onEdit: (_) async {},
        onDelete: (_) async {},
        onOpenEditor: () {},
        onImportAttachments: (paths) async => paths,
        onNavigate: (_) {},
      ),
    ),
  );
}
