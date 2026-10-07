import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/local_assistant_controller.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/pages/chat/chat_page.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_chat_appearance.dart';
import 'package:diary/widgets/diary_chat_background.dart';
import 'package:diary/widgets/local_media_preview.dart';
import 'package:diary/widgets/rich_text_viewer.dart';

void main() {
  testWidgets('both people keep their own avatar and navigation target', (
    tester,
  ) async {
    final harness = GlobalKey<_AppearanceHarnessState>();
    final assistant = _ReplyController()..replies['original'] = '慢慢来，你已经做得很好。';
    await tester.pumpWidget(
      _AppearanceHarness(key: harness, assistant: assistant),
    );
    await tester.pumpAndSettle();

    final self = find.descendant(
      of: find.byKey(const ValueKey('chat-profile-avatar-original')),
      matching: find.byType(DiaryChatParticipantAvatar),
    );
    final companion = find.byKey(
      const ValueKey('chat-companion-avatar-original'),
    );
    final selfAvatar = tester.widget<DiaryChatParticipantAvatar>(self);
    final companionAvatar = tester.widget<DiaryChatParticipantAvatar>(
      companion,
    );
    expect(selfAvatar.imagePath, 'missing-self.png');
    expect(companionAvatar.imagePath, 'missing-companion.png');
    expect(selfAvatar.companion, isFalse);
    expect(companionAvatar.companion, isTrue);
    expect(find.text('暖暖'), findsNothing);
    expect(find.text('个人页配置的标题'), findsOneWidget);
    expect(
      tester.getCenter(self).dx,
      greaterThan(tester.getCenter(companion).dx),
    );
    for (final avatar in [self, companion]) {
      final image = tester.widget<Image>(
        find.descendant(of: avatar, matching: find.byType(Image)),
      );
      expect(image.image, isA<ResizeImage>());
      expect((image.image as ResizeImage).width, inInclusiveRange(48, 192));
      expect((image.image as ResizeImage).height, inInclusiveRange(48, 192));
    }

    await tester.tap(self);
    await tester.pumpAndSettle();
    expect(harness.currentState!.destinations, [ChatPageDestination.profile]);
    await tester.tap(companion);
    await tester.pumpAndSettle();
    expect(harness.currentState!.appearanceOpens, 1);

    await tester.longPress(
      find.byKey(const ValueKey('assistant-reply-bubble-original')),
    );
    await tester.pumpAndSettle();
    expect(find.text('删除'), findsNothing);
    expect(harness.currentState!.deleted, isEmpty);

    harness.currentState!.updateAppearance(showAvatars: false);
    await tester.pumpAndSettle();
    expect(find.byType(DiaryChatParticipantAvatar), findsNothing);
    expect(find.text('慢慢来，你已经做得很好。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('changing appearance preserves focus, draft and media state', (
    tester,
  ) async {
    final harness = GlobalKey<_AppearanceHarnessState>();
    final assistant = _ReplyController()..replies['original'] = '你记录的每一步都值得珍惜。';
    await tester.pumpWidget(
      _AppearanceHarness(
        key: harness,
        assistant: assistant,
        initialStyle: DiaryChatStyle.diary,
        entries: [_richEntry()],
      ),
    );
    await tester.pumpAndSettle();
    final renderer = _entryRendererState(tester, DiaryRichTextViewer);
    final audio = _entryRendererState(tester, DiaryAudioPlayer);
    final field = find.byKey(const Key('chat-message-field'));
    await tester.enterText(field, '保留正在写的日记');
    await tester.pump();
    final focus = tester.widget<TextField>(field).focusNode!;
    expect(focus.hasFocus, isTrue);

    for (final style in [DiaryChatStyle.messenger, DiaryChatStyle.soft]) {
      harness.currentState!.updateAppearance(style: style, name: '新的陪伴名字');
      await tester.pump();
      expect(_entryRendererState(tester, DiaryRichTextViewer), same(renderer));
      expect(_entryRendererState(tester, DiaryAudioPlayer), same(audio));
      expect(tester.widget<TextField>(field).controller!.text, '保留正在写的日记');
      expect(focus.hasFocus, isTrue);
      expect(_entranceOpacity(tester), 1);
      expect(harness.currentState!.sent, isEmpty);
    }

    assistant.replies['original'] = '更新的回应';
    assistant.notifyListeners();
    await tester.pump();
    expect(_entryRendererState(tester, DiaryRichTextViewer), same(renderer));
    expect(_entryRendererState(tester, DiaryAudioPlayer), same(audio));
    expect(focus.hasFocus, isTrue);
    expect(find.text('更新的回应'), findsOneWidget);
    expect(harness.currentState!.sent, isEmpty);

    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(harness.currentState!.sent, ['保留正在写的日记']);
    expect(harness.currentState!.entries.single.contentText, '富文本日记');
    expect(harness.currentState!.entries.single.content, _richEntry().content);
    expect(tester.takeException(), isNull);
  });

  testWidgets('private chat shows its configured title only in the header', (
    tester,
  ) async {
    final harness = GlobalKey<_AppearanceHarnessState>();
    final assistant = _ReplyController()
      ..replies['original'] = '我在。'
      ..replies['second'] = '已经很努力了。';
    await tester.pumpWidget(
      _AppearanceHarness(
        key: harness,
        assistant: assistant,
        initialStyle: DiaryChatStyle.diary,
        title: '个人页配置的标题',
        entries: [
          _entry(),
          _entry(text: '第二条记录').copyWith(id: 'second'),
        ],
      ),
    );
    await tester.pumpAndSettle();
    for (final style in DiaryChatStyle.values) {
      harness.currentState!.updateAppearance(style: style);
      await tester.pumpAndSettle();
      expect(find.text('个人页配置的标题'), findsOneWidget);
      expect(find.text('暖暖'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('chat-title-profile-button')),
          matching: find.text('个人页配置的标题'),
        ),
        findsOneWidget,
      );
    }
    harness.currentState!.updateAppearance(title: '新的对话标题', name: '未显示的称呼');
    await tester.pumpAndSettle();
    expect(find.text('新的对话标题'), findsOneWidget);
    expect(find.text('个人页配置的标题'), findsNothing);
    expect(find.text('未显示的称呼'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short chat bubbles remain compact with rounded shapes', (
    tester,
  ) async {
    final harness = GlobalKey<_AppearanceHarnessState>();
    final assistant = _ReplyController()..replies['original'] = '我在。';
    await tester.pumpWidget(
      _AppearanceHarness(
        key: harness,
        assistant: assistant,
        entries: [_entry(text: '好')],
      ),
    );
    await tester.pumpAndSettle();
    final outgoing = find.byKey(const Key('chat-bubble-original'));
    final incoming = find.byKey(
      const ValueKey('assistant-reply-bubble-original'),
    );
    for (final style in DiaryChatStyle.values) {
      harness.currentState!.updateAppearance(style: style);
      await tester.pumpAndSettle();
      expect(tester.getSize(outgoing).width, lessThan(100));
      expect(
        tester.widget<Material>(outgoing).shape,
        isA<RoundedRectangleBorder>(),
      );
      expect(
        tester.widget<Material>(incoming).shape,
        isA<RoundedRectangleBorder>(),
      );
      expect(
        tester.getCenter(outgoing).dx,
        greaterThan(tester.getCenter(incoming).dx),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('layouts keep theme background, bubble and text colors', (
    tester,
  ) async {
    final assistant = _ReplyController()..replies['original'] = '我在。';
    final usedThemeColors = <List<Color?>>[];
    for (final dark in [false, true]) {
      for (final preset in DiaryThemePreset.values) {
        final harness = GlobalKey<_AppearanceHarnessState>();
        final colors = dark
            ? DiaryThemeColors.darkFor(preset)
            : DiaryThemeColors.lightFor(preset);
        await tester.pumpWidget(
          _AppearanceHarness(
            key: harness,
            assistant: assistant,
            initialStyle: DiaryChatStyle.diary,
            dark: dark,
            colors: colors,
          ),
        );
        await tester.pumpAndSettle();
        final baseline = _renderedChatColors(tester);
        expect(baseline[0], colors.paper);
        expect(baseline[1], colors.surface);
        usedThemeColors.add(baseline);
        for (final style in [DiaryChatStyle.messenger, DiaryChatStyle.soft]) {
          harness.currentState!.updateAppearance(style: style);
          await tester.pumpAndSettle();
          expect(
            _renderedChatColors(tester),
            baseline,
            reason:
                '${preset.name} ${dark ? 'dark' : 'light'} ignores layout for colors',
          );
        }
      }
    }
    expect(usedThemeColors.first, isNot(usedThemeColors.last));
    expect(tester.takeException(), isNull);
  });

  testWidgets('layout changes preserve custom theme and wallpaper settings', (
    tester,
  ) async {
    final harness = GlobalKey<_AppearanceHarnessState>();
    final assistant = _ReplyController()..replies['original'] = '我在。';
    final colors = DiaryThemeColors.light
        .withCustomAccent(0xFF5581AD, brightness: Brightness.light)
        .copyWith(paper: const Color(0xFFE8EDF4));
    const wallpaper = DiaryChatBackground(
      imagePath: 'custom-wallpaper.jpg',
      opacity: .34,
      scale: 1.6,
      alignmentX: -.4,
      alignmentY: .7,
    );
    for (final background in [const DiaryChatBackground(), wallpaper]) {
      await tester.pumpWidget(
        _AppearanceHarness(
          key: harness,
          assistant: assistant,
          initialStyle: DiaryChatStyle.diary,
          colors: colors,
          background: background,
        ),
      );
      await tester.pumpAndSettle();
      final baseline = _renderedChatColors(tester);
      expect(baseline[0], colors.paper);
      final imageFinder = find.byKey(
        const ValueKey('chat-background-image-custom-wallpaper.jpg'),
      );
      final imageState = background.hasImage ? tester.state(imageFinder) : null;
      for (final style in DiaryChatStyle.values) {
        harness.currentState!.updateAppearance(style: style);
        await tester.pumpAndSettle();
        final layer = tester.widget<DiaryChatBackgroundLayer>(
          find.byType(DiaryChatBackgroundLayer),
        );
        expect(layer.background, same(background));
        expect(_renderedChatColors(tester), baseline);
        if (background.hasImage) {
          expect(tester.state(imageFinder), same(imageState));
          expect(
            tester.widget<LocalMediaPreview>(imageFinder).path,
            wallpaper.imagePath,
          );
          final opacity = tester.widget<Opacity>(
            find
                .ancestor(of: imageFinder, matching: find.byType(Opacity))
                .first,
          );
          expect(opacity.opacity, wallpaper.opacity);
        } else {
          expect(imageFinder, findsNothing);
        }
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('appearance menu preserves an active composer', (tester) async {
    final harness = GlobalKey<_AppearanceHarnessState>();
    await tester.pumpWidget(_AppearanceHarness(key: harness));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('chat-message-field'));
    await tester.enterText(field, '还没写完');
    await tester.tap(find.byKey(const Key('chat-more-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('对话外观'));
    await tester.pumpAndSettle();
    expect(harness.currentState!.appearanceOpens, 1);
    expect(tester.widget<TextField>(field).controller!.text, '还没写完');
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
    expect(harness.currentState!.sent, isEmpty);
  });

  testWidgets(
    'stopping a streaming companion keeps composer and avatars stable',
    (tester) async {
      final assistant = _ReplyController()
        ..replyingEntryId = 'original'
        ..generating = true;
      await tester.pumpWidget(_AppearanceHarness(assistant: assistant));
      await tester.pumpAndSettle();
      final field = find.byKey(const Key('chat-message-field'));
      await tester.enterText(field, '下一条日记');
      final avatar = tester.element(
        find.byKey(const ValueKey('chat-companion-avatar-original')),
      );
      assistant.replies['original'] = '正在读到你的心情';
      assistant.notifyListeners();
      await tester.pump();
      expect(
        tester.element(
          find.byKey(const ValueKey('chat-companion-avatar-original')),
        ),
        same(avatar),
      );
      await tester.tap(find.byKey(const ValueKey('assistant-stop-original')));
      await tester.pump();
      expect(assistant.stopCalls, 1);
      expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);
      expect(tester.widget<TextField>(field).controller!.text, '下一条日记');
      expect(find.text('正在读到你的心情'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('assistant-stop-original')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  for (final style in [DiaryChatStyle.messenger, DiaryChatStyle.soft]) {
    testWidgets('${style.name} applies both avatars to every entry type', (
      tester,
    ) async {
      final harness = GlobalKey<_AppearanceHarnessState>();
      final assistant = _ReplyController();
      await tester.pumpWidget(
        _AppearanceHarness(
          key: harness,
          assistant: assistant,
          initialStyle: style,
        ),
      );
      await tester.pumpAndSettle();
      final variants = <DiaryEntry>[
        _entry(),
        _entry(text: '').copyWith(imagePaths: const ['missing-photo.jpg']),
        _entry(text: '').copyWith(audioPaths: const ['missing-voice.m4a']),
        _entry(text: '').copyWith(videoPaths: const ['missing-video.mp4']),
        _entry(text: '').copyWith(
          title: '公园',
          positions: const ['公园', '很长的地址'],
          latitude: 31.2,
          longitude: 121.4,
        ),
        _entry(text: '').copyWith(mood: .8, moodLabel: '开心'),
      ];
      for (final entry in variants) {
        assistant.replies[entry.id] = '今天也辛苦了。';
        harness.currentState!.replaceEntries([entry]);
        await tester.pumpAndSettle();
        expect(find.byType(DiaryChatParticipantAvatar), findsNWidgets(2));
        final avatars = tester.widgetList<DiaryChatParticipantAvatar>(
          find.byType(DiaryChatParticipantAvatar),
        );
        expect(avatars.every((avatar) => avatar.style == style), isTrue);
        expect(avatars.where((avatar) => avatar.companion).length, 1);
        expect(tester.takeException(), isNull);
      }
    });
  }

  for (final style in DiaryChatStyle.values) {
    for (final dark in [false, true]) {
      testWidgets(
        '${style.name} ${dark ? 'dark' : 'light'} fits small large-text chat',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final assistant = _ReplyController()
            ..replies['original'] = '今天已经努力过了，允许自己慢下来，留一点时间好好休息。';
          await tester.pumpWidget(
            _AppearanceHarness(
              assistant: assistant,
              initialStyle: style,
              dark: dark,
              textScale: 1.6,
              title: '一位名字很长但始终认真倾听你的朋友',
              companionName: '不应出现的头像旁称呼',
              entries: [_entry(text: '今天完成了很久以来想做的事情，虽然还有一点疲惫，但很开心。')],
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(DiaryChatParticipantAvatar), findsNWidgets(2));
          expect(find.text('一位名字很长但始终认真倾听你的朋友'), findsOneWidget);
          expect(find.text('不应出现的头像旁称呼'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(
            MaterialApp(
              theme: _theme(dark),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.6)),
                child: child!,
              ),
              home: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(14),
                  child: DiaryChatAppearancePreview(
                    style: style,
                    title: '一位名字很长但始终认真倾听你的朋友',
                    companionName: '不应出现的头像旁称呼',
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(DiaryChatParticipantAvatar), findsNWidgets(2));
          expect(find.text('一位名字很长但始终认真倾听你的朋友'), findsOneWidget);
          expect(find.text('不应出现的头像旁称呼'), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

State<StatefulWidget> _entryRendererState(WidgetTester tester, Type type) =>
    tester.state(
      find.descendant(
        of: find.byKey(const ValueKey('chat-entry-original')),
        matching: find.byType(type),
      ),
    );

List<Color?> _renderedChatColors(WidgetTester tester) {
  final outgoing = find.byKey(const Key('chat-bubble-original'));
  final incoming = find.byKey(
    const ValueKey('assistant-reply-bubble-original'),
  );
  final rootBackground = find
      .ancestor(
        of: find.byKey(const Key('chat-title-profile-button')),
        matching: find.byType(ColoredBox),
      )
      .first;
  return [
    tester
        .widget<DiaryChatBackgroundLayer>(find.byType(DiaryChatBackgroundLayer))
        .fallbackColor,
    tester.widget<Material>(incoming).color,
    tester.widget<Material>(outgoing).color,
    tester
        .widget<Text>(
          find.descendant(of: outgoing, matching: find.text('记录今天')),
        )
        .style
        ?.color,
    tester
        .widget<Text>(find.descendant(of: incoming, matching: find.text('我在。')))
        .style
        ?.color,
    tester.widget<ColoredBox>(rootBackground).color,
  ];
}

double _entranceOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find
          .descendant(
            of: find.byKey(const ValueKey('chat-entry-original')),
            matching: find.byType(FadeTransition),
          )
          .first,
    )
    .opacity
    .value;

DiaryEntry _entry({String text = '记录今天'}) => DiaryEntry(
  id: 'original',
  createdAt: DateTime(2026, 10, 7, 12),
  updatedAt: DateTime(2026, 10, 7, 12),
  title: text,
  content: text,
  contentText: text,
  category: '生活',
);

DiaryEntry _richEntry() => _entry(text: '富文本日记').copyWith(
  editorType: DiaryEditorType.richText,
  content: jsonEncode([
    {'insert': '富文本日记\n'},
  ]),
  audioPaths: const ['voice.m4a'],
);

ThemeData _theme(bool dark, {DiaryThemeColors? colors}) => ThemeData(
  brightness: dark ? Brightness.dark : Brightness.light,
  extensions: [
    colors ?? (dark ? DiaryThemeColors.dark : DiaryThemeColors.light),
  ],
);

class _AppearanceHarness extends StatefulWidget {
  const _AppearanceHarness({
    this.assistant,
    this.initialStyle = DiaryChatStyle.messenger,
    this.entries,
    this.dark = false,
    this.textScale = 1,
    this.companionName = '暖暖',
    this.title = '个人页配置的标题',
    this.colors,
    this.background = const DiaryChatBackground(),
    super.key,
  });
  final LocalAssistantController? assistant;
  final DiaryChatStyle initialStyle;
  final List<DiaryEntry>? entries;
  final bool dark;
  final double textScale;
  final String companionName;
  final String title;
  final DiaryThemeColors? colors;
  final DiaryChatBackground background;
  @override
  State<_AppearanceHarness> createState() => _AppearanceHarnessState();
}

class _AppearanceHarnessState extends State<_AppearanceHarness> {
  late DiaryChatStyle style = widget.initialStyle;
  late String name = widget.companionName;
  late String title = widget.title;
  late List<DiaryEntry> entries = widget.entries ?? [_entry()];
  bool showAvatars = true;
  int appearanceOpens = 0;
  final destinations = <ChatPageDestination>[];
  final sent = <String>[];
  final deleted = <String>[];

  void updateAppearance({
    DiaryChatStyle? style,
    String? name,
    String? title,
    bool? showAvatars,
  }) => setState(() {
    if (style != null) this.style = style;
    if (name != null) this.name = name;
    if (title != null) this.title = title;
    if (showAvatars != null) this.showAvatars = showAvatars;
  });
  void replaceEntries(List<DiaryEntry> entries) =>
      setState(() => this.entries = entries);

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: _theme(widget.dark, colors: widget.colors),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(widget.textScale)),
      child: child!,
    ),
    home: Scaffold(
      body: ChatPage(
        entries: entries,
        title: title,
        chatBackground: widget.background,
        chatStyle: style,
        showChatAvatar: showAvatars,
        profileAvatarPath: 'missing-self.png',
        companionAvatarPath: 'missing-companion.png',
        companionName: name,
        localAssistantController: widget.assistant,
        onOpenChatAppearance: () => appearanceOpens++,
        onSend: (content, images, audio, videos, mood, label) async =>
            sent.add(content),
        onOpenEntry: (_) {},
        onEdit: (_) async {},
        onDelete: (entry) async => deleted.add(entry.id),
        onOpenEditor: () {},
        onImportAttachments: (paths) async => paths,
        onNavigate: destinations.add,
      ),
    ),
  );
}

class _ReplyController extends ChangeNotifier
    implements LocalAssistantController {
  final replies = <String, String>{};
  @override
  String? replyingEntryId;
  @override
  bool generating = false;
  @override
  bool loading = false;
  int stopCalls = 0;
  @override
  String? replyFor(String entryId) => replies[entryId];
  @override
  String? replyErrorFor(String entryId) => null;
  @override
  Future<void> stop() async {
    stopCalls++;
    generating = false;
    loading = false;
    replyingEntryId = null;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
