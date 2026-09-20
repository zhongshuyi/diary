import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/quick_audio_recorder.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/demo_data.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/main.dart';
import 'package:diary/pages/calendar/calendar_page.dart';
import 'package:diary/pages/entry/entry_detail_page.dart';
import 'package:diary/pages/entry/entry_editor_page.dart';
import 'package:diary/pages/entry/quick_capture_sheet.dart';
import 'package:diary/pages/home/home_page.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_image_viewer.dart';
import 'package:diary/widgets/diary_navigation.dart';
import 'package:diary/widgets/entry_card.dart';

Future<void> _runAsWindows(Future<void> Function() body) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  try {
    await body();
  } finally {
    // Reset before the test framework verifies its global invariants.
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  testWidgets('shows the diary timeline and primary action', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('MY / DIARY'), findsOneWidget);
    expect(find.byKey(const Key('mobile-quick-capture-fab')), findsOneWidget);
    expect(find.text('快速记一句'), findsNothing);
    expect(find.text('最近的日记'), findsOneWidget);
  });

  testWidgets('uses the mobile shell without desktop window chrome', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(DiaryBottomNavigation), findsOneWidget);
    expect(find.byKey(const Key('desktop-window-bar')), findsNothing);
  });

  testWidgets('replaces queued trash feedback after consecutive deletions', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MyApp(
        repository: MemoryDiaryRepository([
          DiaryEntry(
            id: 'trash-first',
            createdAt: now,
            updatedAt: now,
            title: '第一篇',
            content: '第一篇',
            contentText: '第一篇',
            category: '生活',
          ),
          DiaryEntry(
            id: 'trash-second',
            createdAt: now.subtract(const Duration(minutes: 1)),
            updatedAt: now.subtract(const Duration(minutes: 1)),
            title: '第二篇',
            content: '第二篇',
            contentText: '第二篇',
            category: '生活',
          ),
        ]),
        settingsStore: _TestSettingsStore(),
      ),
    );
    await tester.pumpAndSettle();

    for (final title in ['第一篇', '第二篇']) {
      await tester.tap(find.byTooltip('更多操作：$title'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('移入回收站').last);
      await tester.pumpAndSettle();
    }

    expect(find.text('查看'), findsOneWidget);
    await tester.tap(find.text('查看'));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('summarizes a multi-select trash action once', (tester) async {
    final now = DateTime.now();
    final repository = MemoryDiaryRepository([
      DiaryEntry(
        id: 'batch-first',
        createdAt: now,
        updatedAt: now,
        title: '甲',
        content: '甲',
        contentText: '甲',
        category: '生活',
      ),
      DiaryEntry(
        id: 'batch-second',
        createdAt: now.subtract(const Duration(minutes: 1)),
        updatedAt: now.subtract(const Duration(minutes: 1)),
        title: '乙',
        content: '乙',
        contentText: '乙',
        category: '生活',
      ),
    ]);
    await tester.pumpWidget(
      MyApp(repository: repository, settingsStore: _TestSettingsStore()),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('mobile-entry-row-batch-first')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('mobile-entry-row-batch-second')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('移入回收站'));
    await tester.pumpAndSettle();

    expect(find.text('已移入回收站，共 2 篇'), findsOneWidget);
    expect(await repository.load(), isEmpty);
  });

  testWidgets('opens the saved chat homepage by default', (tester) async {
    final store = _TestSettingsStore()
      ..value = const DiarySettings(defaultHomeMode: DiaryHomeMode.chat);
    await tester.pumpWidget(MyApp(settingsStore: store));
    await tester.pumpAndSettle();

    expect(find.text('我的日记'), findsOneWidget);
    expect(find.byKey(const Key('mobile-quick-capture-fab')), findsNothing);
    expect(find.byType(DiaryBottomNavigation), findsNothing);
  });

  testWidgets('quick action follows the saved left or right setting', (
    tester,
  ) async {
    final store = _TestSettingsStore();
    await tester.pumpWidget(MyApp(settingsStore: store));
    await tester.pumpAndSettle();
    final button = find.byKey(const Key('mobile-quick-capture-fab'));
    expect(tester.getCenter(button).dx, greaterThan(400));

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('偏好设置'));
    await tester.tap(find.text('偏好设置'));
    await tester.pumpAndSettle();
    final quickCaptureSetting = find.byKey(
      const Key('settings-quick-capture-side'),
    );
    await tester.scrollUntilVisible(quickCaptureSetting, 250);
    await tester.ensureVisible(quickCaptureSetting);
    await tester.pumpAndSettle();
    await tester.tap(quickCaptureSetting);
    await tester.pumpAndSettle();
    await tester.tap(find.text('左侧'));
    await tester.pumpAndSettle();
    expect(store.value.quickCaptureSide, QuickCaptureSide.left);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(MyApp(settingsStore: store));
    await tester.pumpAndSettle();
    expect(tester.getCenter(button).dx, lessThan(400));
  });

  testWidgets('keeps the desktop shell when its window is narrow', (
    tester,
  ) async {
    await _runAsWindows(() async {
      tester.view.physicalSize = const Size(1120, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('desktop-window-bar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('can create and save a diary entry', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mobile-quick-capture-fab')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('写完整日记'));
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

  testWidgets('can capture a text fragment without opening the editor', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mobile-quick-capture-fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('quick-capture-text')),
      '路边的树影很好看。',
    );
    await tester.tap(find.text('记下'));
    await tester.pumpAndSettle();

    expect(find.text('路边的树影很好看。'), findsOneWidget);
  });

  testWidgets('quick capture waits for its entrance before requesting focus', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mobile-quick-capture-fab')));
    await tester.pump();

    TextField field() =>
        tester.widget<TextField>(find.byKey(const Key('quick-capture-text')));

    expect(field().autofocus, isFalse);
    expect(field().focusNode!.hasFocus, isFalse);

    await tester.pump(const Duration(milliseconds: 259));
    expect(field().focusNode!.hasFocus, isFalse);

    await tester.pump(const Duration(milliseconds: 1));
    expect(field().focusNode!.hasFocus, isTrue);
  });

  testWidgets('quick capture saves a held recording as audio', (tester) async {
    final recorder = _FakeQuickAudioRecorder();
    List<String>? savedAudio;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickCaptureSheet(
            onSave: (_, _) async {},
            onSaveWithAudio: (_, _, audioPaths) async {
              savedAudio = audioPaths;
            },
            onOpenEditor: (_, _) async {},
            importPhotos: (paths) async => paths,
            audioRecorder: recorder,
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('quick-capture-hold-record'))),
    );
    await tester.pump();
    expect(recorder.started, isTrue);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.text('录音 1'), findsOneWidget);

    await tester.tap(find.text('记下'));
    await tester.pumpAndSettle();
    expect(savedAudio, const ['stored-recording.m4a']);
  });

  testWidgets('quick capture saves an imported photo without text', (
    tester,
  ) async {
    String? savedText;
    List<String>? savedPhotos;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => QuickCaptureSheet(
                  onSave: (text, photos) async {
                    savedText = text;
                    savedPhotos = photos;
                  },
                  onOpenEditor: (_, _) async {},
                  pickPhotos: (source) async =>
                      source == ImageSource.gallery ? ['picker-photo.jpg'] : [],
                  importPhotos: (paths) async => ['stable-photo.jpg'],
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('相册'));
    await tester.pumpAndSettle();
    expect(find.text('已选 1 张'), findsOneWidget);

    await tester.tap(find.text('记下'));
    await tester.pumpAndSettle();
    expect(savedText, '');
    expect(savedPhotos, ['stable-photo.jpg']);
  });

  testWidgets('a failed quick save keeps the draft and shows an inline error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => QuickCaptureSheet(
                  onSave: (_, _) async => throw StateError('save failed'),
                  onOpenEditor: (_, _) async {},
                  importPhotos: (_) async => [],
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('quick-capture-text')),
      '保留这句话',
    );
    await tester.tap(find.text('记下'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(QuickCaptureSheet),
        matching: find.text('保存失败，内容仍在这里，请重试'),
      ),
      findsOneWidget,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('保留这句话'), findsOneWidget);
  });

  testWidgets('quick capture restores interrupted text and photo', (
    tester,
  ) async {
    final repository = MemoryDiaryRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => QuickCaptureSheet(
                  onSave: (_, _) async {},
                  onOpenEditor: (_, _) async {},
                  pickPhotos: (_) async => ['picked.jpg'],
                  importPhotos: (_) async => ['stored.jpg'],
                  onLoadDraft: repository.loadDraft,
                  onSaveDraft: repository.saveDraft,
                  onClearDraft: repository.clearDraft,
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('quick-capture-text')),
      '半途想到的事',
    );
    await tester.tap(find.text('相册'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.tap(find.byTooltip('关闭速记'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('半途想到的事'), findsOneWidget);
    expect(find.text('已选 1 张'), findsOneWidget);
  });

  testWidgets('opening the full editor carries quick text and photos', (
    tester,
  ) async {
    String? editorText;
    List<String>? editorPhotos;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => QuickCaptureSheet(
                  onSave: (_, _) async {},
                  onOpenEditor: (text, photos) async {
                    editorText = text;
                    editorPhotos = photos;
                  },
                  pickPhotos: (_) async => ['picked.jpg'],
                  importPhotos: (_) async => ['stored.jpg'],
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('quick-capture-text')),
      '带进完整日记',
    );
    await tester.tap(find.text('相册'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写完整日记'));
    await tester.pumpAndSettle();
    expect(editorText, '带进完整日记');
    expect(editorPhotos, ['stored.jpg']);
  });

  testWidgets('in-app album does not suspend the diary lock', (tester) async {
    var externalStarts = 0;
    var externalEnds = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => QuickCaptureSheet(
                  onSave: (_, _) async {},
                  onOpenEditor: (_, _) async {},
                  pickPhotos: (_) async => const [],
                  importPhotos: (paths) async => paths,
                  onExternalActivityStart: () => externalStarts++,
                  onExternalActivityEnd: () => externalEnds++,
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('相册'));
    await tester.pumpAndSettle();
    expect(externalStarts, 0);
    expect(externalEnds, 0);
  });

  testWidgets('quick capture waits for photo import before saving', (
    tester,
  ) async {
    final importFinished = Completer<List<String>>();
    List<String>? savedPhotos;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => QuickCaptureSheet(
                  onSave: (_, paths) async => savedPhotos = paths,
                  onOpenEditor: (_, _) async {},
                  pickPhotos: (_) async => ['picked.jpg'],
                  importPhotos: (_) => importFinished.future,
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('quick-capture-text')),
      '图片和文字',
    );
    await tester.tap(find.text('相册'));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(
            find.ancestor(
              of: find.text('写完整日记'),
              matching: find.byType(TextButton),
            ),
          )
          .onPressed,
      isNull,
    );
    importFinished.complete(['stored.jpg']);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('记下'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('记下'));
    await tester.pumpAndSettle();
    expect(savedPhotos, ['stored.jpg']);
  });

  testWidgets('quick capture restores full-editor text and photos', (
    tester,
  ) async {
    final repository = MemoryDiaryRepository();
    await repository.saveDraft(
      DraftPayload(
        id: 'mobile-quick-capture',
        updatedAt: DateTime.now(),
        payload: {
          'editorType': 'richText',
          'content': jsonEncode([
            {'insert': '完整编辑后的文字\n'},
          ]),
          'attachments': ['stored.jpg'],
        },
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => QuickCaptureSheet(
                  onSave: (_, _) async {},
                  onOpenEditor: (_, _) async {},
                  importPhotos: (paths) async => paths,
                  onLoadDraft: repository.loadDraft,
                  onSaveDraft: repository.saveDraft,
                  onClearDraft: repository.clearDraft,
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('完整编辑后的文字'), findsOneWidget);
    expect(find.text('已选 1 张'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭速记'));
    await tester.pumpAndSettle();
    final draft = await repository.loadDraft('mobile-quick-capture');
    expect(draft?.payload['editorType'], 'richText');
  });

  testWidgets('quick media selection previews in order and removes mistakes', (
    tester,
  ) async {
    List<String>? savedPhotos;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => QuickCaptureSheet(
                  onSave: (_, photos) async => savedPhotos = photos,
                  onOpenEditor: (_, _) async {},
                  pickPhotos: (_) async => ['first', 'second', 'third'],
                  importPhotos: (_) async => [
                    'one.jpg',
                    'two.jpg',
                    'three.jpg',
                  ],
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('相册'));
    await tester.pumpAndSettle();
    expect(find.text('已选 3 张'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quick-photo-preview-0')));
    await tester.pumpAndSettle();
    expect(find.text('1 / 3'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('selected-photo-pages')),
      const Offset(-450, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsOneWidget);
    await tester.tapAt(const Offset(8, 180));
    await tester.pumpAndSettle();
    expect(find.text('2 / 3'), findsNothing);

    await tester.tap(find.byTooltip('移除第 2 张照片'));
    await tester.pumpAndSettle();
    expect(find.text('已选 2 张'), findsOneWidget);
    await tester.tap(find.text('记下'));
    await tester.pumpAndSettle();
    expect(savedPhotos, ['one.jpg', 'three.jpg']);
  });

  testWidgets('photo-only quick capture reads as a photo in the timeline', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 17);
    final entry = DiaryEntry(
      id: 'photo-only',
      createdAt: now,
      updatedAt: now,
      title: '此刻的照片',
      content: '',
      contentText: '',
      category: '生活',
      imagePaths: const ['photo.jpg'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiaryEntryCard(entry: entry, onTap: () {}),
        ),
      ),
    );

    expect(find.text('1 张照片'), findsOneWidget);
    expect(find.text('这一天还没有留下文字。'), findsNothing);
  });

  testWidgets('full editor also saves an image-only entry', (tester) async {
    final now = DateTime(2026, 9, 17);
    final photo = DiaryEntry(
      id: 'image-only-draft',
      createdAt: now,
      updatedAt: now,
      title: '',
      content: '',
      contentText: '',
      category: '生活',
      imagePaths: const ['stored.jpg'],
    );
    DiaryEntry? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: EntryEditorPage(
          entry: photo,
          categories: const ['生活'],
          onSave: (entry) async => saved = entry,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存日记'));
    await tester.pumpAndSettle();
    expect(saved?.imagePaths, ['stored.jpg']);
    expect(saved?.contentText, '');
  });

  testWidgets('full editor saves a held recording as audio', (tester) async {
    final recorder = _FakeQuickAudioRecorder();
    DiaryEntry? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: EntryEditorPage(
          categories: const ['生活'],
          onSave: (entry) async => saved = entry,
          audioRecorder: recorder,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final recordButton = find.byKey(const Key('entry-hold-record'));
    await tester.ensureVisible(recordButton);

    final gesture = await tester.startGesture(tester.getCenter(recordButton));
    await tester.pump();
    expect(recorder.started, isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(recorder.stopCalls, 1);
    expect(find.text('语音'), findsOneWidget);
    expect(find.text('stored-recording.m4a'), findsNothing);

    await tester.tap(find.text('保存日记'));
    await tester.pumpAndSettle();
    expect(saved?.audioPaths, const ['stored-recording.m4a']);
  });

  testWidgets('quick handoff keeps text when rich text is the default', (
    tester,
  ) async {
    DiaryEntry? saved;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            quill.FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
        home: EntryEditorPage(
          initialContent: '刚才看到的一句话',
          initialImagePaths: const ['stored.jpg'],
          defaultEditorType: DiaryEditorType.richText,
          categories: const ['生活'],
          onSave: (entry) async => saved = entry,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存日记'));
    await tester.pumpAndSettle();
    expect(saved?.contentText, '刚才看到的一句话');
    expect(saved?.imagePaths, ['stored.jpg']);
  });

  testWidgets('full editor resumes newer quick-handoff draft', (tester) async {
    final repository = MemoryDiaryRepository();
    await repository.saveDraft(
      DraftPayload(
        id: 'mobile-quick-capture',
        updatedAt: DateTime.now(),
        payload: {
          'editorType': 'richText',
          'content': jsonEncode([
            {'insert': '后来修改的文字\n'},
          ]),
          'attachments': ['stored.jpg'],
        },
      ),
    );
    DiaryEntry? saved;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates:
            quill.FlutterQuillLocalizations.localizationsDelegates,
        supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
        home: EntryEditorPage(
          initialContent: '原来的文字',
          restoreInitialDraft: true,
          draftId: 'mobile-quick-capture',
          onLoadDraft: repository.loadDraft,
          onSaveDraft: repository.saveDraft,
          onClearDraft: repository.clearDraft,
          defaultEditorType: DiaryEditorType.richText,
          categories: const ['生活'],
          onSave: (entry) async => saved = entry,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存日记'));
    await tester.pumpAndSettle();
    expect(saved?.contentText, '后来修改的文字');
    expect(saved?.imagePaths, ['stored.jpg']);
  });

  testWidgets('full editor waits for selected photo before saving', (
    tester,
  ) async {
    final importFinished = Completer<List<String>>();
    DiaryEntry? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: EntryEditorPage(
          initialContent: '这张图片',
          categories: const ['生活'],
          pickGalleryPhotos: () async => ['picked.jpg'],
          onImportPhotos: (_) => importFinished.future,
          onSave: (entry) async => saved = entry,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('添加附件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('添加附件'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('从相册选择图片'));
    await tester.pumpAndSettle();
    final saveButton = find.ancestor(
      of: find.text('保存日记'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    importFinished.complete(['stored.jpg']);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('保存日记'));
    await tester.tap(find.text('保存日记'));
    await tester.pumpAndSettle();
    expect(saved?.imagePaths, ['stored.jpg']);
  });

  testWidgets('uses the desktop writing workspace on a wide window', (
    tester,
  ) async {
    await _runAsWindows(() async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('新建日记  Ctrl + N'), findsOneWidget);
      expect(find.textContaining('TODAY /'), findsOneWidget);
      expect(find.text('一条就是一个瞬间'), findsOneWidget);
      expect(find.byKey(const Key('desktop-window-bar')), findsOneWidget);
      expect(find.byTooltip('切换到深色模式'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('opens the desktop editor with metadata beside the canvas', (
    tester,
  ) async {
    await _runAsWindows(() async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('新建日记  Ctrl + N'));
      await tester.pumpAndSettle();

      expect(find.text('这篇日记'), findsOneWidget);
      expect(find.text('Ctrl + Enter 保存 · Esc 返回'), findsOneWidget);
      expect(find.text('添加附件'), findsOneWidget);
      expect(find.byKey(const Key('desktop-window-bar')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets(
    'opens desktop settings from the app area and returns to the workspace',
    (tester) async {
      await _runAsWindows(() async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        await tester.tap(find.text('应用设置'));
        await tester.pumpAndSettle();

        expect(find.text('设置'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('管理与关于'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('管理与关于'), findsOneWidget);
        expect(find.byTooltip('返回'), findsOneWidget);

        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        expect(find.text('最近的日记'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    },
  );

  testWidgets('filters entries with the search field', (tester) async {
    await tester.pumpWidget(
      MyApp(repository: MemoryDiaryRepository(demoEntries)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('diary-search-field')), '慢下来');
    await tester.pumpAndSettle();

    expect(find.text('慢下来，生活才会发光'), findsOneWidget);
    expect(find.text('把周末留给自己'), findsNothing);
  });

  testWidgets('mobile timeline keeps each day in one card and opens its moment', (
    tester,
  ) async {
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    DiaryEntry makeEntry(String id, DateTime time) => DiaryEntry(
      id: id,
      createdAt: time,
      updatedAt: today,
      title: id,
      content: id,
      contentText: id,
      category: '生活',
    );
    final entries = [
      makeEntry('早上', yesterday.add(const Duration(hours: 8))),
      makeEntry('今天早上', DateTime(today.year, today.month, today.day, 9)),
      makeEntry('晚上', yesterday.add(const Duration(hours: 21))),
      makeEntry('午后', yesterday.add(const Duration(hours: 14))),
      makeEntry('今天晚上', DateTime(today.year, today.month, today.day, 19)),
      makeEntry('中午', yesterday.add(const Duration(hours: 12))),
    ];
    DiaryEntry? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            entries: entries,
            onOpenEditor: () {},
            onOpenEntry: (entry) => opened = entry,
            onToggleFavorite: (_) {},
            onShare: (_) {},
            onDelete: (_) {},
            onQuickCapture: (_) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiaryEntryCard), findsNothing);
    expect(
      find.byKey(
        Key('mobile-day-card-${today.year}-${today.month}-${today.day}'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        Key(
          'mobile-day-card-${yesterday.year}-${yesterday.month}-${yesterday.day}',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('2 条'), findsOneWidget);
    expect(find.text('4 条'), findsOneWidget);
    expect(find.byKey(const Key('mobile-entry-row-今天早上')), findsOneWidget);
    expect(find.byKey(const Key('mobile-entry-row-今天晚上')), findsOneWidget);
    expect(find.byKey(const Key('mobile-entry-row-早上')), findsNothing);
    expect(tester.getSize(find.text('19:00')).height, lessThan(24));

    await tester.ensureVisible(find.text('展开剩余 1 条'));
    await tester.tap(find.text('展开剩余 1 条'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mobile-entry-row-早上')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('mobile-entry-row-早上')));
    await tester.tap(find.byKey(const Key('mobile-entry-row-早上')));
    expect(opened?.id, '早上');
  });

  testWidgets(
    'mobile day card selection and search act on individual entries',
    (tester) async {
      final now = DateTime.now();
      final entries = [
        for (final (index, name) in ['工作截图', '午后句子', '夜间心情'].indexed)
          DiaryEntry(
            id: '$index',
            createdAt: DateTime(now.year, now.month, now.day, 9 + index),
            updatedAt: now,
            title: name,
            content: name,
            contentText: name,
            category: index == 0 ? '工作' : '生活',
          ),
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

      await tester.ensureVisible(find.byKey(const Key('mobile-entry-row-0')));
      await tester.longPress(find.byKey(const Key('mobile-entry-row-0')));
      await tester.pumpAndSettle();
      expect(find.text('已选择 1 篇'), findsOneWidget);
      expect(
        tester
            .getSemantics(find.byKey(const Key('mobile-entry-row-0')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      await tester.tap(find.byKey(const Key('mobile-entry-row-1')));
      await tester.pumpAndSettle();
      expect(find.text('已选择 2 篇'), findsOneWidget);

      await tester.ensureVisible(find.text('已选择 2 篇'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();
      expect(find.text('已选择 2 篇'), findsNothing);
      await tester.enterText(
        find.byKey(const Key('diary-search-field')),
        '工作截图',
      );
      await tester.pumpAndSettle();
      expect(find.text('1 条'), findsOneWidget);
      expect(find.byKey(const Key('mobile-entry-row-0')), findsOneWidget);
      expect(find.byKey(const Key('mobile-entry-row-1')), findsNothing);
    },
  );

  testWidgets(
    'filtered day shows every matching moment without a dead collapse action',
    (tester) async {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final entries = [
        for (var i = 0; i < 4; i++)
          DiaryEntry(
            id: '$i',
            createdAt: yesterday.add(Duration(hours: 8 + i)),
            updatedAt: now,
            title: '记录 $i',
            content: '记录 $i',
            contentText: '记录 $i',
            category: '工作',
          ),
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
      expect(find.byKey(const Key('mobile-entry-row-0')), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, '工作'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-entry-row-0')), findsOneWidget);
      expect(find.text('4 条'), findsOneWidget);
      expect(find.text('收起'), findsNothing);
    },
  );

  testWidgets('wide mobile shell still uses day cards', (tester) async {
    tester.view.physicalSize = const Size(1100, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            entries: [
              DiaryEntry(
                id: 'wide',
                createdAt: now,
                updatedAt: now,
                title: '平板上的一刻',
                content: '平板上的一刻',
                contentText: '平板上的一刻',
                category: '生活',
              ),
            ],
            desktopLayout: false,
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
    expect(find.byKey(const Key('mobile-entry-row-wide')), findsOneWidget);
    expect(find.byType(DiaryEntryCard), findsNothing);
  });

  testWidgets('a text moment reveals how many photos it carries', (
    tester,
  ) async {
    final now = DateTime.now();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            entries: [
              DiaryEntry(
                id: 'with-photos',
                createdAt: now,
                updatedAt: now,
                title: '路上看到的句子',
                content: '想把这一刻留下来',
                contentText: '想把这一刻留下来',
                category: '生活',
                imagePaths: const ['one.jpg', 'two.jpg'],
              ),
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
    await tester.pumpAndSettle();
    expect(find.textContaining('2 张照片'), findsOneWidget);
  });

  testWidgets(
    'home thumbnail opens only its entry images in a looping preview',
    (tester) async {
      final now = DateTime.now();
      DiaryEntry? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomePage(
              entries: [
                DiaryEntry(
                  id: 'home-images',
                  createdAt: now,
                  updatedAt: now,
                  title: '两张截图',
                  content: '',
                  contentText: '',
                  category: '工作',
                  imagePaths: const ['first.jpg', 'second.jpg'],
                ),
                DiaryEntry(
                  id: 'another-entry',
                  createdAt: now.subtract(const Duration(minutes: 1)),
                  updatedAt: now,
                  title: '另一条日记',
                  content: '',
                  contentText: '',
                  category: '生活',
                  imagePaths: const ['third.jpg'],
                ),
              ],
              onOpenEditor: () {},
              onOpenEntry: (entry) => opened = entry,
              onToggleFavorite: (_) {},
              onShare: (_) {},
              onDelete: (_) {},
              onQuickCapture: (_) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Hero &&
              widget.tag ==
                  diaryImageHeroTag('home-images', 0, scope: 'timeline'),
        ),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const Key('diary-image-thumbnail-home-images-0')),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diary-image-viewer')), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Hero &&
              widget.tag ==
                  diaryImageHeroTag('home-images', 0, scope: 'timeline'),
        ),
        findsOneWidget,
      );
      expect(find.text('1 / 2'), findsOneWidget);
      expect(opened, isNull);

      await tester.drag(
        find.byKey(const Key('diary-image-pager')),
        const Offset(-450, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('diary-image-pager')),
        const Offset(-450, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 / 2'), findsOneWidget);

      await tester.tapAt(const Offset(8, 120));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('diary-image-viewer')), findsNothing);
    },
  );

  testWidgets('detail gallery opens the image that was tapped', (tester) async {
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: 'detail-images',
      createdAt: now,
      updatedAt: now,
      title: '带图日记',
      content: '图片在这里。',
      contentText: '图片在这里。',
      category: '生活',
      imagePaths: const ['first.jpg', 'second.jpg'],
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

    expect(find.text('照片'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('diary-image-thumbnail-detail-images-1')),
    );
    await tester.tap(
      find.byKey(const Key('diary-image-thumbnail-detail-images-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets(
    'calendar moments keep image preview separate from opening entry',
    (tester) async {
      final now = DateTime.now();
      DiaryEntry? opened;
      final entry = DiaryEntry(
        id: 'calendar-images',
        createdAt: now,
        updatedAt: now,
        title: '午后照片',
        content: '这天的片段',
        contentText: '这天的片段',
        category: '生活',
        imagePaths: const ['first.jpg', 'second.jpg'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarPage(
              entries: [entry],
              onOpenEntry: (value) => opened = value,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calendar-day-moments')), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('diary-image-thumbnail-calendar-images-1')),
      );
      await tester.tap(
        find.byKey(const Key('diary-image-thumbnail-calendar-images-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      expect(opened, isNull);
    },
  );

  testWidgets('image previews remain usable on a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime.now();
    final entry = DiaryEntry(
      id: 'narrow-images',
      createdAt: now,
      updatedAt: now,
      title: '窄屏照片片段',
      content: '一段比较长的说明文字，用来确认小屏幕下的布局仍然清晰。',
      contentText: '一段比较长的说明文字，用来确认小屏幕下的布局仍然清晰。',
      category: '生活',
      tags: const ['随手记'],
      imagePaths: const ['first.jpg', 'second.jpg'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            entries: [entry],
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
    expect(tester.takeException(), isNull);
    await tester.tap(
      find.byKey(const Key('diary-image-thumbnail-narrow-images-0')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('diary-image-viewer')), findsOneWidget);
    await tester.tap(find.byTooltip('关闭图片预览'));
    await tester.pumpAndSettle();

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
    await tester.ensureVisible(
      find.byKey(const Key('diary-image-thumbnail-narrow-images-1')),
    );
    await tester.tap(
      find.byKey(const Key('diary-image-thumbnail-narrow-images-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭图片预览'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarPage(entries: [entry], onOpenEntry: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('跳转到某一天'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('diary-image-thumbnail-narrow-images-1')),
    );
    await tester.tap(
      find.byKey(const Key('diary-image-thumbnail-narrow-images-1')),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('opens the calendar tab', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('日历'));
    await tester.pumpAndSettle();

    expect(find.text('我的日历'), findsOneWidget);
    expect(find.text('2026年 9月'), findsOneWidget);
  });

  testWidgets('opens the media library from profile tools', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('媒体库'), 250);
    await tester.tap(find.text('媒体库'));
    await tester.pumpAndSettle();

    expect(find.text('媒体库'), findsOneWidget);
    expect(find.text('你的媒体库还是空的'), findsOneWidget);
  });

  testWidgets('editor exposes format, category, tag and attachment controls', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('mobile-quick-capture-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('写完整日记'));
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

  testWidgets('renders an in-app player for a saved voice attachment', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 15);
    final entry = DiaryEntry(
      id: 'voice-entry',
      createdAt: now,
      updatedAt: now,
      title: '一段录音',
      content: '',
      contentText: '',
      category: '生活',
      audioPaths: const ['attachments/voice-note.m4a'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EntryDetailPage(
          entry: entry,
          onEdit: (_) async => null,
          onShare: () {},
          onDelete: () {},
          onToggleFavorite: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DiaryAudioPlayer), findsOneWidget);
    expect(find.text('语音片段'), findsOneWidget);
    expect(find.text('voice-note.m4a'), findsNothing);
    expect(find.byTooltip('播放'), findsOneWidget);
  });

  testWidgets('detail gives mixed media their own reading sections', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 19, 20, 18);
    final entry = DiaryEntry(
      id: 'mixed-detail',
      createdAt: now,
      updatedAt: now,
      title: '晚上的片段',
      content: '今天的风很舒服。',
      contentText: '今天的风很舒服。',
      category: '生活',
      mood: .9,
      moodLabel: '明亮',
      imagePaths: const ['sunset.jpg'],
      audioPaths: const ['voice.m4a'],
      videoPaths: const ['street.mp4'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EntryDetailPage(
          entry: entry,
          onEdit: (_) async => null,
          onShare: () {},
          onDelete: () {},
          onToggleFavorite: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('entry-detail-header')), findsOneWidget);
    expect(find.text('此刻心情 · 明亮'), findsOneWidget);
    expect(find.text('文字'), findsOneWidget);
    expect(find.text('照片'), findsOneWidget);
    expect(find.text('声音'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('entry-detail-video-mixed-detail-0')),
    );
    expect(find.text('视频'), findsOneWidget);
    expect(find.text('视频片段 1'), findsOneWidget);
  });

  testWidgets('a mood-only detail reads as a focused moment', (tester) async {
    final now = DateTime(2026, 9, 19, 21);
    final entry = DiaryEntry(
      id: 'mood-only-detail',
      createdAt: now,
      updatedAt: now,
      title: '21:00 的心情',
      content: '',
      contentText: '',
      category: '生活',
      mood: .7,
      moodLabel: '平静',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EntryDetailPage(
          entry: entry,
          onEdit: (_) async => null,
          onShare: () {},
          onDelete: () {},
          onToggleFavorite: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('此刻的心情'), findsOneWidget);
    expect(find.text('平静'), findsOneWidget);
    expect(find.text('文字'), findsNothing);
    expect(find.text('照片'), findsNothing);
  });
}

class _TestSettingsStore implements DiarySettingsStore {
  DiarySettings value = const DiarySettings();

  @override
  Future<DiarySettings> load() async => value;

  @override
  Future<void> save(DiarySettings settings) async => value = settings;
}

class _FakeQuickAudioRecorder implements QuickAudioRecorder {
  bool started = false;
  int stopCalls = 0;

  @override
  Future<void> cancel() async => started = false;

  @override
  Future<void> dispose() async {}

  @override
  Future<bool> start() async {
    started = true;
    return true;
  }

  @override
  Future<String?> stop() async {
    stopCalls++;
    if (!started) return null;
    started = false;
    return 'stored-recording.m4a';
  }
}
