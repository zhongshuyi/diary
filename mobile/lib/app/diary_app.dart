import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_lock_gate.dart';
import 'package:diary/app/diary_shell.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/isar_diary_repository.dart';
import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/demo_data.dart';

class MyApp extends StatefulWidget {
  const MyApp({this.repository, this.settingsStore, super.key});

  final DiaryRepository? repository;
  final DiarySettingsStore? settingsStore;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final SettingsController _settingsController;
  final _lockCoordinator = DiaryLockCoordinator();

  @override
  void initState() {
    super.initState();
    _settingsController =
        SettingsController(
            store:
                widget.settingsStore ?? SharedPreferencesDiarySettingsStore(),
          )
          ..addListener(_onSettingsChanged)
          ..initialize();
  }

  @override
  void dispose() {
    _settingsController
      ..removeListener(_onSettingsChanged)
      ..dispose();
    _lockCoordinator.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeRepository =
        widget.repository ?? MemoryDiaryRepository(demoEntries);
    final settings = _settingsController.settings;
    return MaterialApp(
      title: '此刻 · diary',
      debugShowCheckedModeBanner: false,
      theme: DiaryTheme.lightFor(
        settings.themePreset,
        customAccent: settings.customThemeColor,
      ),
      darkTheme: DiaryTheme.darkFor(
        settings.themePreset,
        customAccent: settings.customThemeColor,
      ),
      themeMode: settings.themeMode.materialMode,
      localizationsDelegates:
          quill.FlutterQuillLocalizations.localizationsDelegates,
      supportedLocales: quill.FlutterQuillLocalizations.supportedLocales,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(settings.fontScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: DiaryLockGate(
        controller: _settingsController,
        coordinator: _lockCoordinator,
        child: DiaryShell(
          repository: activeRepository,
          settingsController: _settingsController,
          lockCoordinator: _lockCoordinator,
        ),
      ),
    );
  }
}

/// Opens the platform repository after the first Flutter frame is available.
///
/// Android keeps showing its launch window until Flutter draws a frame. Doing
/// database I/O before [runApp] therefore makes a slow or locked database look
/// like a frozen splash screen. The timeout keeps the app usable and switches
/// to the persistent key-value repository when Isar cannot be opened in time.
class DiaryBootstrapApp extends StatefulWidget {
  const DiaryBootstrapApp({super.key});

  @override
  State<DiaryBootstrapApp> createState() => _DiaryBootstrapAppState();
}

class _DiaryBootstrapAppState extends State<DiaryBootstrapApp> {
  late final Future<DiaryRepository> _repositoryFuture = _openRepository();

  Future<DiaryRepository> _openRepository() async {
    try {
      return await IsarDiaryRepository.open(
        initialEntries: demoEntries,
      ).timeout(const Duration(seconds: 8));
    } on Object {
      final fallback = SharedPreferencesDiaryRepository(
        initialEntries: demoEntries,
      );
      await fallback.load();
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DiaryRepository>(
      future: _repositoryFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MyApp(repository: snapshot.data);
        }
        if (snapshot.hasError) {
          return const _StartupErrorApp();
        }
        return const _StartupLoadingApp();
      },
    );
  }
}

class _StartupLoadingApp extends StatelessWidget {
  const _StartupLoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DiaryTheme.light,
      home: Scaffold(
        backgroundColor: DiaryPalette.paper,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: DiaryPalette.ink,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: DiaryPalette.butter,
                  size: 29,
                ),
              ),
              const SizedBox(height: 20),
              Text('正在打开你的日记本', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              const SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  color: DiaryPalette.terracotta,
                  backgroundColor: DiaryPalette.line,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DiaryTheme.light,
      home: Scaffold(
        backgroundColor: DiaryPalette.paper,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              '日记本暂时无法打开，请重新启动应用。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
