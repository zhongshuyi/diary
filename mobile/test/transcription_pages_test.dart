import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/transcription_controller.dart';
import 'package:diary/pages/settings/transcription_settings_page.dart';
import 'package:diary/widgets/audio_transcript.dart';

void main() {
  testWidgets(
    'voice-bubble foreground applies to transcript, status, actions and progress',
    (tester) async {
      final controller = _Controller()..hasModel = true;
      controller.states['entry-1:/voice/a.m4a'] = const AudioTranscriptionState(
        stage: AudioTranscriptionStage.transcribing,
        progress: .3,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: DiaryTheme.light,
          home: Scaffold(
            body: Material(
              color: const Color(0xff286450),
              child: AudioTranscript(
                entryId: 'entry-1',
                audioPath: '/voice/a.m4a',
                controller: controller,
                text: '录音文字应当清晰可读',
                foreground: Colors.white,
                mutedColor: Colors.white,
              ),
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<SelectableText>(
              find.byKey(
                const ValueKey('audio-transcript-text-entry-1-/voice/a.m4a'),
              ),
            )
            .style!
            .color,
        Colors.white,
      );
      expect(
        tester.widget<Text>(find.text('正在离线转写…')).style!.color,
        Colors.white,
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .color,
        Colors.white,
      );
      final button = tester.widget<TextButton>(
        find.byKey(
          const ValueKey('audio-transcript-cancel-entry-1-/voice/a.m4a'),
        ),
      );
      expect(button.style!.foregroundColor!.resolve({}), Colors.white);
    },
  );

  testWidgets(
    'retry and later transcription updates cannot reopen the composer keyboard',
    (tester) async {
      final controller = _Controller()..hasModel = true;
      final focus = FocusNode();
      final draft = TextEditingController();
      addTearDown(focus.dispose);
      addTearDown(draft.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AudioTranscript(
                  entryId: 'entry-1',
                  audioPath: '/voice/a.m4a',
                  controller: controller,
                ),
                TextField(
                  key: const Key('draft'),
                  focusNode: focus,
                  controller: draft,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byKey(const Key('draft')), '保留日记草稿');
      expect(focus.hasFocus, isTrue);
      await tester.tap(
        find.byKey(
          const ValueKey('audio-transcript-retry-entry-1-/voice/a.m4a'),
        ),
      );
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      controller.states['entry-1:/voice/a.m4a'] = const AudioTranscriptionState(
        stage: AudioTranscriptionStage.completed,
        text: '转写完成的文字',
      );
      controller.notifyListeners();
      await tester.pump();
      expect(focus.hasFocus, isFalse);
      expect(draft.text, '保留日记草稿');
      expect(controller.retries, ['entry-1:/voice/a.m4a']);
    },
  );

  testWidgets(
    'offline transcription is opt-in and requires an explicit model download',
    (tester) async {
      final controller = _Controller();
      await _openSettings(tester, controller);
      expect(controller.downloadCalls, 0);
      expect(controller.autoTranscribe, isFalse);
      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(const Key('transcription-auto-enabled')),
      );
      expect(switchTile.onChanged, isNull);
      await tester.tap(find.byKey(const Key('transcription-download-model')));
      await tester.pumpAndSettle();
      expect(controller.downloadCalls, 1);
      expect(controller.autoTranscribe, isFalse);
      controller.hasModel = true;
      controller.downloading = false;
      controller.notifyListeners();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('transcription-auto-enabled')));
      await tester.pumpAndSettle();
      expect(controller.autoChanges, [true]);
    },
  );

  testWidgets(
    'model progress reflects bytes transferred and can be cancelled',
    (tester) async {
      final controller = _Controller()
        ..downloading = true
        ..downloadProgress = .65;
      await _openSettings(tester, controller);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byKey(const Key('transcription-download-progress')),
            )
            .value,
        .65,
      );
      expect(find.text('正在下载 65%'), findsOneWidget);
      await tester.tap(find.byKey(const Key('transcription-cancel-download')));
      await tester.pumpAndSettle();
      expect(controller.cancelDownloadCalls, 1);
      expect(controller.hasModel, isFalse);
      expect(controller.autoTranscribe, isFalse);
    },
  );

  testWidgets(
    'removing a speech model is confirmed and does not remove recorded text',
    (tester) async {
      final controller = _Controller()
        ..hasModel = true
        ..autoTranscribe = true;
      await _openSettings(tester, controller);
      await tester.tap(find.byKey(const Key('transcription-remove-model')));
      await tester.pumpAndSettle();
      expect(controller.removeCalls, 0);
      expect(find.textContaining('录音和已保存的文字会保留'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, '移除模型'));
      await tester.pumpAndSettle();
      expect(controller.removeCalls, 1);
      expect(controller.hasModel, isFalse);
      expect(controller.autoTranscribe, isFalse);
    },
  );

  testWidgets(
    'unsupported devices keep the download and auto options disabled',
    (tester) async {
      final controller = _Controller()..supported = false;
      await _openSettings(tester, controller);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('transcription-download-model')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('transcription-auto-enabled')),
            )
            .onChanged,
        isNull,
      );
      expect(find.textContaining('当前设备暂不支持'), findsOneWidget);
      expect(controller.downloadCalls, 0);
    },
  );

  testWidgets(
    'transcripts and failures belong only to their matching recording',
    (tester) async {
      final controller = _Controller()..hasModel = true;
      controller.states['entry-2:/voice/b.m4a'] = const AudioTranscriptionState(
        stage: AudioTranscriptionStage.failed,
        error: '这段录音没有识别到清晰语音，可以重新转写。',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: DiaryTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                AudioTranscript(
                  entryId: 'entry-1',
                  audioPath: '/voice/a.m4a',
                  controller: controller,
                  text: '今天去了公园',
                ),
                AudioTranscript(
                  entryId: 'entry-2',
                  audioPath: '/voice/b.m4a',
                  controller: controller,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('今天去了公园'), findsOneWidget);
      expect(find.text('这段录音没有识别到清晰语音，可以重新转写。'), findsOneWidget);
      await tester.tap(
        find.byKey(
          const ValueKey('audio-transcript-retry-entry-2-/voice/b.m4a'),
        ),
      );
      await tester.pump();
      expect(controller.retries, ['entry-2:/voice/b.m4a']);
      expect(controller.downloadCalls, 0);
      expect(controller.autoChanges, isEmpty);
    },
  );

  testWidgets('completed retry text replaces a stale detail-page snapshot', (
    tester,
  ) async {
    final controller = _Controller()..hasModel = true;
    controller.states['entry-1:/voice/a.m4a'] = const AudioTranscriptionState(
      stage: AudioTranscriptionStage.completed,
      text: '重新识别的文字',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: DiaryTheme.light,
        home: Scaffold(
          body: AudioTranscript(
            entryId: 'entry-1',
            audioPath: '/voice/a.m4a',
            controller: controller,
            text: '旧的识别文字',
          ),
        ),
      ),
    );
    expect(find.text('重新识别的文字'), findsOneWidget);
    expect(find.text('旧的识别文字'), findsNothing);
  });

  testWidgets(
    'an active transcription exposes cancellation and retains saved text',
    (tester) async {
      final controller = _Controller()..hasModel = true;
      controller.states['entry-1:/voice/a.m4a'] = const AudioTranscriptionState(
        stage: AudioTranscriptionStage.transcribing,
        progress: .3,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: DiaryTheme.light,
          home: Scaffold(
            body: AudioTranscript(
              entryId: 'entry-1',
              audioPath: '/voice/a.m4a',
              controller: controller,
              text: '原来的文字',
            ),
          ),
        ),
      );
      expect(find.text('原来的文字'), findsOneWidget);
      expect(find.text('正在离线转写…'), findsOneWidget);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        .3,
      );
      await tester.tap(
        find.byKey(
          const ValueKey('audio-transcript-cancel-entry-1-/voice/a.m4a'),
        ),
      );
      await tester.pump();
      expect(controller.cancellations, ['entry-1:/voice/a.m4a']);
      expect(find.text('原来的文字'), findsOneWidget);
    },
  );

  testWidgets(
    'missing-model transcript shortcut opens settings without downloading',
    (tester) async {
      final controller = _Controller();
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AudioTranscript(
              entryId: 'entry-1',
              audioPath: '/voice/a.m4a',
              controller: controller,
              onOpenSettings: () => opened++,
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(
          const ValueKey('audio-transcript-setup-entry-1-/voice/a.m4a'),
        ),
      );
      expect(opened, 1);
      expect(controller.downloadCalls, 0);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      '320px large-text speech settings ${dark ? 'dark' : 'light'} do not overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _openSettings(tester, _Controller(), dark: dark, textScale: 1.8);
        expect(tester.takeException(), isNull);
        for (final key in [
          'transcription-download-model',
          'transcription-auto-enabled',
        ]) {
          await tester.scrollUntilVisible(
            find.byKey(Key(key)),
            180,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}

Future<void> _openSettings(
  WidgetTester tester,
  _Controller controller, {
  bool dark = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? DiaryTheme.dark : DiaryTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: TranscriptionSettingsPage(controller: controller),
    ),
  );
  await tester.pump();
}

class _Controller extends ChangeNotifier implements TranscriptionController {
  @override
  bool initialized = true;
  @override
  bool supported = true;
  @override
  bool hasModel = false;
  @override
  bool autoTranscribe = false;
  @override
  bool downloading = false;
  @override
  double? downloadProgress;
  @override
  String? error;
  @override
  bool transcribing = false;
  @override
  int queuedCount = 0;
  @override
  bool get busy => downloading;
  final states = <String, AudioTranscriptionState>{};
  final retries = <String>[];
  final cancellations = <String>[];
  final autoChanges = <bool>[];
  int downloadCalls = 0;
  int cancelDownloadCalls = 0;
  int removeCalls = 0;
  @override
  Future<void> initialize() async {}
  @override
  AudioTranscriptionState? stateFor(String entryId, String audioPath) =>
      states['$entryId:$audioPath'];
  @override
  Future<void> downloadModel() async {
    downloadCalls++;
    downloading = true;
    downloadProgress = .5;
    notifyListeners();
  }

  @override
  Future<void> cancelDownload() async {
    cancelDownloadCalls++;
    downloading = false;
    downloadProgress = null;
    notifyListeners();
  }

  @override
  Future<void> setAutoTranscribe(bool enabled) async {
    autoChanges.add(enabled);
    autoTranscribe = enabled;
    notifyListeners();
  }

  @override
  Future<void> removeModel() async {
    removeCalls++;
    hasModel = false;
    autoTranscribe = false;
    notifyListeners();
  }

  @override
  Future<void> retry(String entryId, String audioPath) async =>
      retries.add('$entryId:$audioPath');
  @override
  Future<void> cancel(String entryId, String audioPath) async =>
      cancellations.add('$entryId:$audioPath');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
