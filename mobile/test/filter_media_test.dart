import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/home/home_page.dart';
import 'package:diary/pages/media/media_page.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_image_viewer.dart';

DiaryEntry _entry({
  required String id,
  required String title,
  required String category,
  bool isFavorite = false,
  DateTime? occurredAt,
  List<String> imagePaths = const [],
  List<String> audioPaths = const [],
}) {
  final now = DateTime(2026, 9, 17, 10, 0);
  return DiaryEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    occurredAt: occurredAt,
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

  testWidgets('clears a timeline search without reopening filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            entries: [
              _entry(id: 'work', title: '工作记录', category: '工作'),
              _entry(id: 'walk', title: '周末散步', category: '生活'),
            ],
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
    await tester.enterText(find.byKey(const Key('diary-search-field')), '工作');
    await tester.pumpAndSettle();

    expect(find.text('工作记录'), findsOneWidget);
    expect(find.text('周末散步'), findsNothing);
    await tester.tap(find.byKey(const Key('diary-search-clear')));
    await tester.pumpAndSettle();

    expect(find.text('周末散步'), findsWidgets);
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

    expect(find.text('sunrise.jpg'), findsNothing);
    expect(find.text('山里的早晨'), findsOneWidget);
    expect(find.text('2026年9月17日 · 旅行'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('media-search-field')),
      'sunrise.jpg',
    );
    await tester.pumpAndSettle();
    expect(find.text('山里的早晨'), findsOneWidget);

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

  testWidgets('searches shared entry text across multiple attachments', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaPage(
            entries: [
              _entry(
                id: 'photos',
                title: '山里的早晨',
                category: '旅行',
                imagePaths: const ['first-missing.jpg', 'second-missing.jpg'],
              ),
            ],
            onOpenEntry: (_) {},
          ),
        ),
      ),
    );

    final search = find.byKey(const Key('media-search-field'));
    await tester.enterText(search, '正文内容');
    await tester.pumpAndSettle();
    expect(find.text('山里的早晨'), findsOneWidget);
    expect(find.text('2 张'), findsOneWidget);

    await tester.enterText(search, 'second-missing.jpg');
    await tester.pumpAndSettle();
    expect(find.text('山里的早晨'), findsOneWidget);
    await tester.tap(find.byKey(const Key('media-photo-photos')));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryImageViewer), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭图片预览'));
    await tester.pumpAndSettle();

    await tester.enterText(search, '旅行');
    await tester.pumpAndSettle();
    expect(find.text('山里的早晨'), findsOneWidget);
  });

  testWidgets('groups photo albums by year and month in date order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaPage(
            entries: [
              _entry(
                id: 'old',
                title: '去年的冬天',
                category: '生活',
                occurredAt: DateTime(2025, 12, 8),
                imagePaths: const ['winter-missing.jpg'],
              ),
              _entry(
                id: 'new',
                title: '九月旅行',
                category: '旅行',
                occurredAt: DateTime(2026, 9, 17),
                imagePaths: const ['first-missing.jpg', 'second-missing.jpg'],
              ),
              _entry(
                id: 'middle',
                title: '八月散步',
                category: '生活',
                occurredAt: DateTime(2026, 8, 2),
                imagePaths: const ['walk-missing.jpg'],
              ),
            ],
            onOpenEntry: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 篇日记 · 4 张照片'), findsOneWidget);
    expect(find.text('2026年'), findsOneWidget);
    expect(find.text('2025年'), findsOneWidget);
    expect(find.text('9月'), findsOneWidget);
    expect(find.text('8月'), findsOneWidget);
    expect(find.text('12月'), findsOneWidget);
    expect(find.text('1 篇 · 2 张'), findsOneWidget);
    expect(find.byKey(const Key('media-photo-new')), findsOneWidget);
    expect(find.byKey(const Key('media-photo-middle')), findsOneWidget);
    expect(find.byKey(const Key('media-photo-old')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('media-photo-new'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('media-photo-middle'))).dy,
      ),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('media-photo-middle'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('media-photo-old'))).dy),
    );
  });

  testWidgets('photo preview and source diary are separate actions', (
    tester,
  ) async {
    DiaryEntry? openedEntry;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaPage(
            entries: [
              _entry(
                id: 'photo',
                title: '山里的早晨',
                category: '旅行',
                imagePaths: const ['photo-missing.jpg'],
              ),
            ],
            onOpenEntry: (entry) => openedEntry = entry,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('media-photo-photo')));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryImageViewer), findsOneWidget);
    expect(openedEntry, isNull);

    await tester.tap(find.byTooltip('关闭图片预览'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('打开所属日记'));
    expect(openedEntry?.id, 'photo');
  });

  testWidgets('media sections and type filters fit a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaPage(
            entries: [
              _entry(
                id: 'mixed',
                title: '旅行记录',
                category: '旅行',
                imagePaths: const ['photo-missing.jpg', 'report.pdf'],
                audioPaths: const ['voice-missing.m4a'],
              ),
            ],
            onOpenEntry: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('全部 1'), findsOneWidget);

    await tester.ensureVisible(find.text('文件 1'));
    await tester.tap(find.text('文件 1'));
    await tester.pumpAndSettle();
    expect(find.text('report.pdf'), findsOneWidget);
    expect(find.text('找到 1 篇相关日记'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
