import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/app/app_routes.dart';
import 'package:diary/app/desktop_diary_shell.dart';
import 'package:diary/app/diary_shell.dart';
import 'package:diary/app/mobile_diary_shell.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/main.dart';
import 'package:diary/pages/assistant/local_assistant_settings_page.dart';
import 'package:diary/pages/profile/profile_page.dart';
import 'package:diary/pages/settings/backup_page.dart';
import 'package:diary/pages/settings/chat_appearance_settings_page.dart';
import 'package:diary/pages/settings/settings_page.dart';
import 'package:diary/pages/settings/transcription_settings_page.dart';
import 'package:diary/widgets/diary_navigation.dart';

const _paths = MethodChannel('plugins.flutter.io/path_provider');
const _localAssistant = MethodChannel('com.ling.diary/local_assistant');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory testDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    testDirectory = await Directory.systemTemp.createTemp(
      'diary-profile-navigation-',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_paths, (call) async {
      switch (call.method) {
        case 'getApplicationSupportDirectory':
        case 'getApplicationDocumentsDirectory':
        case 'getTemporaryDirectory':
          return testDirectory.path;
        default:
          return null;
      }
    });
    messenger.setMockMethodCallHandler(_localAssistant, (call) async {
      if (call.method == 'capabilities') return {'supported': false};
      return null;
    });
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_paths, null);
    messenger.setMockMethodCallHandler(_localAssistant, null);
    await testDirectory.delete(recursive: true);
  });

  for (final destination in [
    (
      key: 'profile-assistant-button',
      page: LocalAssistantSettingsPage,
      route: AppRoutes.localAssistantSettings,
    ),
    (
      key: 'profile-transcription-button',
      page: TranscriptionSettingsPage,
      route: AppRoutes.transcriptionSettings,
    ),
    (
      key: 'profile-chat-appearance-button',
      page: ChatAppearanceSettingsPage,
      route: AppRoutes.chatAppearance,
    ),
  ]) {
    testWidgets('profile opens ${destination.route} without a settings hop', (
      tester,
    ) async {
      await _openMobileProfile(tester);
      final button = find.byKey(Key(destination.key));
      await tester.ensureVisible(button);
      await tester.tap(button);
      await _pumpWithFileIo(tester);

      final page = find.byType(destination.page);
      expect(page, findsOneWidget);
      expect(find.byType(SettingsPage), findsNothing);
      expect(
        ModalRoute.of(tester.element(page))?.settings.name,
        destination.route,
      );

      await _popToMobileProfile(tester, page);
      await _unmount(tester);
    });
  }

  testWidgets('profile header opens settings and one back returns to profile', (
    tester,
  ) async {
    await _openMobileProfile(tester);
    await tester.tap(find.byKey(const Key('profile-settings-button')));
    await tester.pumpAndSettle();

    final page = find.byType(SettingsPage);
    expect(page, findsOneWidget);
    expect(
      ModalRoute.of(tester.element(page))?.settings.name,
      AppRoutes.settings,
    );
    await _popToMobileProfile(tester, page);
    await _unmount(tester);
  });

  testWidgets('profile backup stays direct and returns to profile', (
    tester,
  ) async {
    await _openMobileProfile(tester);
    final button = find.text('备份与恢复');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    final page = find.byType(BackupPage);
    expect(page, findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
    expect(
      ModalRoute.of(tester.element(page))?.settings.name,
      AppRoutes.backup,
    );
    await _popToMobileProfile(tester, page);
    await _unmount(tester);
  });

  testWidgets('profile sync stays direct and returns to profile', (
    tester,
  ) async {
    await _openMobileProfile(tester);
    final button = find.text('同步');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();

    final page = find.byType(SyncSettingsPage);
    expect(page, findsOneWidget);
    expect(find.byType(SettingsPage), findsNothing);
    await _popToMobileProfile(tester, page);
    await _unmount(tester);
  });

  testWidgets(
    'desktop profile exposes direct tools and settings returns to it',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        tester.view.physicalSize = const Size(1440, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final settings = SettingsController(store: _MemorySettingsStore());
        await settings.initialize();
        var assistantOpened = 0;
        var transcriptionOpened = 0;
        var appearanceOpened = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: DesktopDiaryShell(
              entries: const [],
              trash: const [],
              categories: const [],
              settingsController: settings,
              actions: _actions(
                onOpenAssistant: () async => assistantOpened++,
                onOpenTranscription: () async => transcriptionOpened++,
                onOpenAppearance: () async => appearanceOpened++,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(DiarySideNavigation),
            matching: find.text('我的'),
          ),
        );
        await tester.pumpAndSettle();
        for (final label in ['日记陪伴', '录音转文字', '对话外观']) {
          final button = find.text(label);
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
        }
        expect(assistantOpened, 1);
        expect(transcriptionOpened, 1);
        expect(appearanceOpened, 1);
        expect(find.byType(SettingsPage), findsNothing);

        await tester.tap(
          find.descendant(
            of: find.byType(DiarySideNavigation),
            matching: find.text('应用设置'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SettingsPage), findsOneWidget);
        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfilePage), findsOneWidget);
        expect(find.byType(SettingsPage), findsNothing);
        expect(tester.takeException(), isNull);
        await _unmount(tester);
        settings.dispose();
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );
}

Future<void> _openMobileProfile(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MyApp(
      repository: MemoryDiaryRepository(),
      settingsStore: _MemorySettingsStore(),
    ),
  );
  // Support initialization reads only the empty temporary test directory. No
  // models, downloads, credentials or real user settings are used by this test.
  for (var attempt = 0; attempt < 30; attempt++) {
    await _pumpWithFileIo(tester);
    final shell = tester.widget<MobileDiaryShell>(
      find.byType(MobileDiaryShell),
    );
    if (shell.localAssistantController?.initialized == true &&
        shell.transcriptionController?.initialized == true) {
      break;
    }
  }
  final shell = tester.widget<MobileDiaryShell>(find.byType(MobileDiaryShell));
  expect(shell.localAssistantController?.initialized, isTrue);
  expect(shell.transcriptionController?.initialized, isTrue);
  await tester.tap(
    find.descendant(
      of: find.byType(DiaryBottomNavigation),
      matching: find.text('我的'),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.byType(ProfilePage), findsOneWidget);
}

Future<void> _popToMobileProfile(WidgetTester tester, Finder page) async {
  final navigator = Navigator.of(tester.element(page));
  navigator.pop();
  await tester.pumpAndSettle();
  expect(find.byType(ProfilePage), findsOneWidget);
  expect(find.byType(SettingsPage), findsNothing);
  expect(find.byKey(const Key('profile-settings-button')), findsOneWidget);
  // A settings route between home/profile and the destination would remain.
  expect(navigator.canPop(), isFalse);
  expect(tester.takeException(), isNull);
}

Future<void> _pumpWithFileIo(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 10)),
  );
  await tester.pumpAndSettle();
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await _pumpWithFileIo(tester);
}

DiaryShellActions _actions({
  required Future<void> Function() onOpenAssistant,
  required Future<void> Function() onOpenTranscription,
  required Future<void> Function() onOpenAppearance,
}) => DiaryShellActions(
  openEditor: ([DiaryEntry? _]) async {},
  openEditorFromQuick: (_, _) async {},
  openEntry: (_) async {},
  toggleFavorite: (_) async {},
  openShare: (_) async {},
  moveToTrash: (_) async {},
  saveQuickCapture: (_) async {},
  saveQuickCaptureWithPhotos: (_, _) async {},
  saveQuickCaptureWithMedia: (_, _, _) async {},
  saveChatMessage: (_, _, _, _, _, _) async {},
  importQuickPhotos: (paths) async => paths,
  loadDraft: (_) async => null,
  saveDraft: (_) async {},
  clearDraft: (_) async {},
  openRecycle: () async {},
  openSettings: () async {},
  openCategories: () async {},
  openBackup: () async {},
  openAbout: () async {},
  openLocalAssistant: onOpenAssistant,
  openTranscription: onOpenTranscription,
  openChatAppearance: onOpenAppearance,
  toggleTheme: () async {},
  saveEntry: (_) async {},
  beginExternalActivity: () {},
  endExternalActivity: () {},
  replaceEntries: (_) async {},
  restoreEntry: (_) async {},
  deleteEntryPermanently: (_) async {},
  clearTrash: () async {},
  openConflicts: () async {},
);

class _MemorySettingsStore implements DiarySettingsStore {
  DiarySettings _settings = const DiarySettings(
    themeMode: DiaryThemeMode.light,
  );

  @override
  Future<DiarySettings> load() async => _settings;

  @override
  Future<void> save(DiarySettings settings) async => _settings = settings;
}
