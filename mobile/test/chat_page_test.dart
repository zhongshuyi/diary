import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/pages/chat/chat_page.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_video_player.dart';

void main() {
  testWidgets('restores an unsent chat draft and clears it after sending', (
    tester,
  ) async {
    DraftPayload? savedDraft;
    final harness = _ChatHarness(
      onLoadDraft: (_) async => savedDraft,
      onSaveDraft: (draft) async {
        savedDraft = draft;
      },
      onClearDraft: (_) async {
        savedDraft = null;
      },
    );
    await tester.pumpWidget(harness);
    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      '还没发出的想法',
    );
    await tester.pump(const Duration(milliseconds: 501));
    expect(savedDraft?.payload['content'], '还没发出的想法');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(harness);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('chat-message-field')))
          .controller
          ?.text,
      '还没发出的想法',
    );

    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();
    expect(savedDraft, isNull);
  });

  testWidgets('keeps the message field clear of the keyboard', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(const _ChatHarness());
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('chat-message-field'));
    expect(tester.getBottomLeft(field).dy, lessThanOrEqualTo(484));
  });

  testWidgets('sends a text message through the shared diary callback', (
    tester,
  ) async {
    String? sentContent;
    await tester.pumpWidget(
      _ChatHarness(
        onSend: (content, images, audio, videos, mood, moodLabel) async {
          sentContent = content;
          expect(images, isEmpty);
          expect(audio, isEmpty);
          expect(videos, isEmpty);
          expect(mood, .5);
          expect(moodLabel, isNull);
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的日记'), findsOneWidget);
    expect(find.byKey(const Key('chat-more-menu')), findsOneWidget);
    expect(find.byKey(const Key('chat-add-button')), findsOneWidget);
    expect(find.byKey(const Key('chat-send-button')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('chat-message-field')),
      '下班路上看到很好看的晚霞。',
    );
    await tester.pump();
    expect(find.byKey(const Key('chat-send-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(sentContent, '下班路上看到很好看的晚霞。');
    expect(find.text('从一句话开始'), findsOneWidget);
  });

  testWidgets('groups diary entries by date and offers edit on long press', (
    tester,
  ) async {
    var edited = false;
    final entry = DiaryEntry(
      id: 'chat-entry',
      createdAt: DateTime(2026, 9, 19, 18, 30),
      updatedAt: DateTime(2026, 9, 19, 18, 30),
      title: '晚霞',
      content: '今天的晚霞很温柔。',
      contentText: '今天的晚霞很温柔。',
      mood: .7,
      moodLabel: '平静',
      category: '生活',
    );
    await tester.pumpWidget(
      _ChatHarness(
        entries: [entry],
        onEdit: (_) async {
          edited = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('09/19 18:30'), findsOneWidget);
    expect(find.text('平静'), findsOneWidget);
    await tester.longPress(find.text('今天的晚霞很温柔。'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('编辑这条日记'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
  });

  testWidgets('shows the configured chat title without a subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(const _ChatHarness(chatTitle: '晚安日记'));
    await tester.pumpAndSettle();

    expect(find.text('晚安日记'), findsOneWidget);
    expect(find.text('只给自己看的对话'), findsNothing);
  });

  testWidgets('header back button returns to the timeline', (tester) async {
    ChatPageDestination? destination;
    await tester.pumpWidget(
      _ChatHarness(onNavigate: (value) => destination = value),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-back-to-timeline')));

    expect(destination, ChatPageDestination.timeline);
  });

  testWidgets('shows the configured wallpaper behind the conversation', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _ChatHarness(
        chatBackground: DiaryChatBackground(imagePath: 'wallpaper.jpg'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chat-background-image-wallpaper.jpg')),
      findsOneWidget,
    );
  });

  testWidgets('shows the profile avatar beside messages only when enabled', (
    tester,
  ) async {
    final entry = DiaryEntry(
      id: 'avatar-message',
      createdAt: DateTime(2026, 9, 20, 19),
      updatedAt: DateTime(2026, 9, 20, 19),
      title: '头像消息',
      content: '这条消息应该显示头像。',
      contentText: '这条消息应该显示头像。',
      category: '生活',
    );

    await tester.pumpWidget(
      _ChatHarness(
        entries: [entry],
        showChatAvatar: true,
        profileAvatarPath: 'missing-avatar.jpg',
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('chat-profile-avatar-avatar-message')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _ChatHarness(entries: [entry], showChatAvatar: false),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('chat-profile-avatar-avatar-message')),
      findsNothing,
    );
  });

  testWidgets('uses a readable 40 pixel avatar beside outgoing messages', (
    tester,
  ) async {
    final entry = DiaryEntry(
      id: 'avatar-size',
      createdAt: DateTime(2026, 9, 20, 19),
      updatedAt: DateTime(2026, 9, 20, 19),
      title: '头像尺寸',
      content: '头像不应挤压对话内容。',
      contentText: '头像不应挤压对话内容。',
      category: '生活',
    );

    await tester.pumpWidget(
      _ChatHarness(
        entries: [entry],
        showChatAvatar: true,
        profileAvatarPath: 'missing-avatar.jpg',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(
        find.byKey(const ValueKey('chat-profile-avatar-avatar-size')),
      ),
      const Size.square(40),
    );
  });
  testWidgets('a mood can be sent as its own diary record', (tester) async {
    double? sentMood;
    String? sentMoodLabel;
    await tester.pumpWidget(
      _ChatHarness(
        onSend: (content, images, audio, videos, mood, moodLabel) async {
          expect(content, isEmpty);
          expect(images, isEmpty);
          expect(audio, isEmpty);
          expect(videos, isEmpty);
          sentMood = mood;
          sentMoodLabel = moodLabel;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-mood-button')));
    await tester.pumpAndSettle();
    expect(find.text('此刻的心情'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('chat-mood-choice-平静')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('chat-send-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-send-button')));
    await tester.pumpAndSettle();

    expect(sentMood, .7);
    expect(sentMoodLabel, '平静');
    expect(find.byKey(const Key('chat-add-button')), findsOneWidget);
  });

  testWidgets('chat photos use the in-app gallery picker flow', (tester) async {
    var requestedMaximum = 0;
    await tester.pumpWidget(
      _ChatHarness(
        pickGalleryPhotos: (maxAssets) async {
          requestedMaximum = maxAssets;
          return const ['selected-photo.jpg'];
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-add-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册添加图片'));
    await tester.pumpAndSettle();

    expect(requestedMaximum, 9);
    expect(find.text('已选 1 张'), findsOneWidget);
  });

  testWidgets('chat camera option imports a captured photo', (tester) async {
    var cameraCalls = 0;
    var externalStarts = 0;
    var externalEnds = 0;
    await tester.pumpWidget(
      _ChatHarness(
        pickCameraPhoto: () async {
          cameraCalls++;
          return 'camera-photo.jpg';
        },
        onExternalActivityStart: () => externalStarts++,
        onExternalActivityEnd: () => externalEnds++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chat-add-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('拍照'));
    await tester.pumpAndSettle();

    expect(cameraCalls, 1);
    expect(externalStarts, 1);
    expect(externalEnds, 1);
    expect(find.text('已选 1 张'), findsOneWidget);
  });

  testWidgets('renders a mood-only diary record as an unwrapped event', (
    tester,
  ) async {
    final entry = DiaryEntry(
      id: 'mood-only-entry',
      createdAt: DateTime(2026, 9, 19, 19),
      updatedAt: DateTime(2026, 9, 19, 19),
      title: '19:00 的心情',
      content: '',
      contentText: '',
      mood: .9,
      moodLabel: '明亮',
      category: '生活',
    );
    await tester.pumpWidget(_ChatHarness(entries: [entry]));
    await tester.pumpAndSettle();

    expect(find.text('此刻 · 明亮'), findsOneWidget);
    expect(find.text('明亮'), findsNothing);
    expect(find.byIcon(Icons.wb_sunny_outlined), findsOneWidget);
  });

  testWidgets('renders an image-only diary record without message chrome', (
    tester,
  ) async {
    final entry = DiaryEntry(
      id: 'image-only-entry',
      createdAt: DateTime(2026, 9, 19, 19, 10),
      updatedAt: DateTime(2026, 9, 19, 19, 10),
      title: '照片',
      content: '',
      contentText: '',
      category: '生活',
      imagePaths: const ['photo.jpg'],
    );
    await tester.pumpWidget(_ChatHarness(entries: [entry]));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chat-image-message-image-only-entry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('diary-image-thumbnail-image-only-entry-0')),
      findsOneWidget,
    );
  });

  testWidgets('renders a playable video cover in the conversation', (
    tester,
  ) async {
    final entry = DiaryEntry(
      id: 'video-entry',
      createdAt: DateTime(2026, 9, 19, 19, 15),
      updatedAt: DateTime(2026, 9, 19, 19, 15),
      title: '街边的风',
      content: '',
      contentText: '',
      category: '生活',
      videoPaths: const ['street.mp4'],
    );
    await tester.pumpWidget(_ChatHarness(entries: [entry]));
    await tester.pumpAndSettle();

    expect(find.byType(DiaryVideoPreview), findsOneWidget);
    expect(find.byKey(const Key('chat-video-video-entry-0')), findsOneWidget);
    expect(find.text('视频'), findsOneWidget);
  });

  testWidgets('stacks multiple chat photos and labels their count', (
    tester,
  ) async {
    final entry = DiaryEntry(
      id: 'multi-image-entry',
      createdAt: DateTime(2026, 9, 19, 19, 20),
      updatedAt: DateTime(2026, 9, 19, 19, 20),
      title: '三张照片',
      content: '',
      contentText: '',
      category: '生活',
      imagePaths: const ['one.jpg', 'two.jpg', 'three.jpg'],
    );
    await tester.pumpWidget(_ChatHarness(entries: [entry]));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('chat-image-stack-multi-image-entry')),
      findsOneWidget,
    );
    expect(find.text('3 张'), findsOneWidget);
    expect(
      find.byKey(const Key('diary-image-thumbnail-multi-image-entry-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('diary-image-thumbnail-multi-image-entry-1')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('diary-image-thumbnail-multi-image-entry-0')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diary-image-viewer')), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.tap(find.byTooltip('下一张'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('newly added messages enter with a brief transition', (
    tester,
  ) async {
    var entries = <DiaryEntry>[];
    late StateSetter updateEntries;
    final entry = DiaryEntry(
      id: 'animated-entry',
      createdAt: DateTime(2026, 9, 19, 20),
      updatedAt: DateTime(2026, 9, 19, 20),
      title: '动画消息',
      content: '这条消息有顺滑的入场效果。',
      contentText: '这条消息有顺滑的入场效果。',
      category: '生活',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateEntries = setState;
              return ChatPage(
                entries: entries,
                onSend:
                    (content, images, audio, videos, mood, moodLabel) async {},
                onOpenEntry: (_) {},
                onEdit: (_) async {},
                onDelete: (_) async {},
                onOpenEditor: () {},
                onImportAttachments: (paths) async => paths,
                onNavigate: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    updateEntries(() => entries = [entry]);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('chat-entry-animated-entry')),
      findsOneWidget,
    );
    expect(find.text('这条消息有顺滑的入场效果。'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('这条消息有顺滑的入场效果。'), findsOneWidget);
  });

  testWidgets('chat-style audio is an inline voice bar without a label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            child: DiaryAudioPlayer(
              path: 'voice-note.m4a',
              chatStyle: true,
              chatStyleHighContrast: true,
              loadMetadata: false,
              loadWaveform: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('语音'), findsNothing);
    expect(find.byTooltip('播放'), findsOneWidget);
  });
}

class _ChatHarness extends StatelessWidget {
  const _ChatHarness({
    this.entries = const [],
    this.onSend,
    this.onEdit,
    this.pickGalleryPhotos,
    this.pickCameraPhoto,
    this.chatTitle = diaryDefaultChatTitle,
    this.chatBackground = const DiaryChatBackground(),
    this.onNavigate,
    this.showChatAvatar = false,
    this.profileAvatarPath,
    this.onExternalActivityStart,
    this.onExternalActivityEnd,
    this.onLoadDraft,
    this.onSaveDraft,
    this.onClearDraft,
  });

  final List<DiaryEntry> entries;
  final ChatMessageSender? onSend;
  final Future<void> Function(DiaryEntry entry)? onEdit;
  final Future<List<String>> Function(int maxAssets)? pickGalleryPhotos;
  final Future<String?> Function()? pickCameraPhoto;
  final String chatTitle;
  final DiaryChatBackground chatBackground;
  final ValueChanged<ChatPageDestination>? onNavigate;
  final bool showChatAvatar;
  final String? profileAvatarPath;
  final VoidCallback? onExternalActivityStart;
  final VoidCallback? onExternalActivityEnd;
  final Future<DraftPayload?> Function(String id)? onLoadDraft;
  final Future<void> Function(DraftPayload draft)? onSaveDraft;
  final Future<void> Function(String id)? onClearDraft;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ChatPage(
          entries: entries,
          title: chatTitle,
          chatBackground: chatBackground,
          showChatAvatar: showChatAvatar,
          profileAvatarPath: profileAvatarPath,
          onSend:
              onSend ??
              (content, images, audio, videos, mood, moodLabel) async {},
          onOpenEntry: (_) {},
          onEdit: onEdit ?? (_) async {},
          onDelete: (_) async {},
          onOpenEditor: () {},
          onImportAttachments: (paths) async => paths,
          pickGalleryPhotos: pickGalleryPhotos,
          pickCameraPhoto: pickCameraPhoto,
          onExternalActivityStart: onExternalActivityStart,
          onExternalActivityEnd: onExternalActivityEnd,
          onLoadDraft: onLoadDraft,
          onSaveDraft: onSaveDraft,
          onClearDraft: onClearDraft,
          onNavigate: onNavigate ?? (_) {},
        ),
      ),
    );
  }
}
