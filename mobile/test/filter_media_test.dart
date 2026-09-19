import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/home/home_page.dart';
import 'package:diary/pages/media/media_page.dart';
import 'package:diary/widgets/diary_audio_player.dart';

DiaryEntry _entry({
  required String id,
  required String title,
  required String category,
  bool isFavorite = false,
  List<String> imagePaths = const [],
  List<String> audioPaths = const [],
}) {
  final now = DateTime(2026, 9, 17, 10, 0);
  return DiaryEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    title: title,
    content: '正文内容',
    contentText: '正文内容',
    category: category,
    isFavorite: isFavorite,
    imagePaths: imagePaths,
    audioPaths: audioPaths,
  );
}

void main() {
  testWidgets('applies favorite filters from the mobile filter sheet', (
    tester,
  ) async {
    final entries = [
      _entry(id: 'favorite', title: '工作记录', category: '工作', isFavorite: true),
      _entry(id: 'ordinary', title: '周末散步', category: '生活'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            entries: entries,
            onOpenEditor: () {},
            onOpenEntry: (_) {},
            onToggleFavorite: (_) {},
            onShare: (_) {},
            onDelete: (_) {},
            onQuickCapture: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('筛选'));
    await tester.pumpAndSettle();
    expect(find.text('筛选日记'), findsOneWidget);

    await tester.tap(find.byKey(const Key('home-favorites-filter')));
    await tester.tap(find.text('应用筛选'));
    await tester.pumpAndSettle();

    expect(find.text('工作记录'), findsOneWidget);
    expect(find.text('周末散步'), findsNothing);
  });

  testWidgets('searches media by attachment and entry text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaPage(
            entries: [
              _entry(
                id: 'media',
                title: '山里的早晨',
                category: '旅行',
                imagePaths: const ['sunrise.jpg'],
              ),
            ],
            onOpenEntry: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('media-search-field')),
      '不存在的附件',
    );
    await tester.pumpAndSettle();

    expect(find.text('没有找到匹配的附件'), findsOneWidget);
  });

  testWidgets('shows direct audio controls in the media library', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaPage(
            entries: [
              _entry(
                id: 'voice',
                title: '声音',
                category: '生活',
                audioPaths: const ['attachments/voice-note.m4a'],
              ),
            ],
            onOpenEntry: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiaryAudioPlayer), findsOneWidget);
    expect(find.text('语音'), findsWidgets);
    expect(find.text('voice-note.m4a'), findsNothing);
    expect(find.byTooltip('播放'), findsOneWidget);
  });

  testWidgets('shows a missing media state with a retry affordance', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaPage(
            entries: [
              _entry(
                id: 'missing-media',
                title: '找不到的照片',
                category: '生活',
                imagePaths: const ['missing-photo.jpg'],
              ),
            ],
            onOpenEntry: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('文件不可用'), findsOneWidget);
    expect(find.byTooltip('重新加载'), findsOneWidget);
  });
}
