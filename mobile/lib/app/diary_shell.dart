import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_routes.dart';
import 'package:diary/app/app_theme.dart';
import 'package:diary/app/desktop_diary_shell.dart';
import 'package:diary/app/mobile_diary_shell.dart';
import 'package:diary/application/diary_controller.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/quick_photo_importer.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/conflict.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/domain/sync_state.dart';
import 'package:diary/sync/sync_client.dart';
import 'package:diary/sync/sync_engine.dart';
import 'package:diary/pages/entry/entry_detail_page.dart';
import 'package:diary/pages/entry/entry_editor_page.dart';
import 'package:diary/pages/conflicts/conflicts_page.dart';
import 'package:diary/pages/recycle/recycle_page.dart';
import 'package:diary/pages/settings/about_page.dart';
import 'package:diary/pages/settings/backup_page.dart';
import 'package:diary/pages/settings/category_page.dart';
import 'package:diary/pages/settings/settings_page.dart';
import 'package:diary/pages/share/share_page.dart';

bool diaryUsesDesktopShell(BuildContext context) {
  final mobilePlatform =
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.fuchsia;
  return defaultTargetPlatform == TargetPlatform.windows ||
      (!mobilePlatform && MediaQuery.sizeOf(context).width >= 900);
}

/// Callbacks shared by the two platform shells. The shells own different
/// navigation and interaction state, while this object keeps data operations
/// in one place.
class DiaryShellActions {
  const DiaryShellActions({
    required this.openEditor,
    required this.openEditorFromQuick,
    required this.openEntry,
    required this.toggleFavorite,
    required this.openShare,
    required this.moveToTrash,
    required this.saveQuickCapture,
    required this.saveQuickCaptureWithPhotos,
    required this.importQuickPhotos,
    required this.loadDraft,
    required this.saveDraft,
    required this.clearDraft,
    required this.openRecycle,
    required this.openSettings,
    required this.openCategories,
    required this.openBackup,
    required this.openAbout,
    required this.toggleTheme,
    required this.saveEntry,
    required this.beginExternalActivity,
    required this.endExternalActivity,
    required this.replaceEntries,
    required this.restoreEntry,
    required this.deleteEntryPermanently,
    required this.openConflicts,
    this.batchSetFavorite,
    this.batchMoveToTrash,
  });

  final Future<void> Function([DiaryEntry? entry]) openEditor;
  final Future<void> Function(String content, List<String> imagePaths)
  openEditorFromQuick;
  final Future<void> Function(DiaryEntry entry) openEntry;
  final Future<void> Function(DiaryEntry entry) toggleFavorite;
  final Future<void> Function(DiaryEntry entry) openShare;
  final Future<void> Function(DiaryEntry entry) moveToTrash;
  final Future<void> Function(String content) saveQuickCapture;
  final Future<void> Function(String content, List<String> imagePaths)
  saveQuickCaptureWithPhotos;
  final Future<List<String>> Function(List<String> paths) importQuickPhotos;
  final Future<DraftPayload?> Function(String id) loadDraft;
  final Future<void> Function(DraftPayload draft) saveDraft;
  final Future<void> Function(String id) clearDraft;
  final Future<void> Function() openRecycle;
  final Future<void> Function() openSettings;
  final Future<void> Function() openCategories;
  final Future<void> Function() openBackup;
  final Future<void> Function() openAbout;
  final Future<void> Function() toggleTheme;
  final Future<void> Function(DiaryEntry entry) saveEntry;
  final VoidCallback beginExternalActivity;
  final VoidCallback endExternalActivity;
  final Future<void> Function(List<DiaryEntry> entries) replaceEntries;
  final Future<void> Function(DiaryEntry entry) restoreEntry;
  final Future<void> Function(DiaryEntry entry) deleteEntryPermanently;
  final Future<void> Function() openConflicts;
  final Future<void> Function(Iterable<String> ids, bool value)?
  batchSetFavorite;
  final Future<void> Function(Iterable<String> ids)? batchMoveToTrash;
}

class DiaryShell extends StatefulWidget {
  const DiaryShell({
    required this.repository,
    required this.settingsController,
    required this.lockCoordinator,
    super.key,
  });

  final DiaryRepository repository;
  final SettingsController settingsController;
  final DiaryLockCoordinator lockCoordinator;

  @override
  State<DiaryShell> createState() => _DiaryShellState();
}

class _DiaryShellState extends State<DiaryShell> with WidgetsBindingObserver {
  late final DiaryController _controller;
  SyncEngine? _syncEngine;
  SyncState _syncState = const SyncState();

  List<DiaryEntry> get _entries => _controller.entries;
  List<DiaryEntry> get _trash => _controller.trash;
  List<String> get _categories => _controller.categories;
  List<Conflict> _conflicts = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DiaryController(repository: widget.repository)
      ..addListener(_onControllerChanged);
    widget.settingsController.addListener(_onSettingsChanged);
    _controller.initialize();
    _refreshConflicts();
    WidgetsBinding.instance.addPostFrameCallback((_) => _configureSync());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    widget.settingsController.removeListener(_onSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _syncEngine?.stop();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
    _configureSync();
  }

  void _configureSync() {
    if (_syncEngine != null) return;
    final settings = widget.settingsController.settings;
    const envUrl = String.fromEnvironment('DIARY_SYNC_URL');
    final endpoint = settings.syncEndpoint.trim().isNotEmpty
        ? settings.syncEndpoint.trim()
        : envUrl;
    if (endpoint.isEmpty) return;
    _syncEngine = SyncEngine(
      repository: widget.repository,
      client: SyncClient(
        baseUrl: endpoint,
        token: settings.syncToken.isNotEmpty
            ? settings.syncToken
            : const String.fromEnvironment('DIARY_SYNC_TOKEN'),
      ),
      onStateChanged: _onSyncStateChanged,
    )..start();
    unawaited(_syncNow());
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading && _entries.isEmpty && _trash.isEmpty) {
      return const _LoadingView();
    }
    if (_controller.error != null && _entries.isEmpty && _trash.isEmpty) {
      return _ErrorView(onRetry: _controller.refresh);
    }

    return LayoutBuilder(
      builder: (context, _) {
        final desktop = diaryUsesDesktopShell(context);
        final actions = DiaryShellActions(
          openEditor: _openEditor,
          openEditorFromQuick: _openEditorFromQuick,
          openEntry: _openEntry,
          toggleFavorite: _toggleFavorite,
          openShare: _openShare,
          moveToTrash: _moveToTrash,
          saveQuickCapture: _saveQuickCapture,
          saveQuickCaptureWithPhotos: _saveQuickCaptureWithPhotos,
          importQuickPhotos: importQuickPhotos,
          loadDraft: widget.repository.loadDraft,
          saveDraft: widget.repository.saveDraft,
          clearDraft: widget.repository.clearDraft,
          openRecycle: _openRecycle,
          openSettings: _openSettings,
          openCategories: _openCategories,
          openBackup: _openBackup,
          openAbout: _openAbout,
          toggleTheme: _toggleTheme,
          saveEntry: (entry) => _controller.save(entry),
          beginExternalActivity: widget.lockCoordinator.beginExternalActivity,
          endExternalActivity: widget.lockCoordinator.endExternalActivity,
          replaceEntries: (entries) => _controller.replaceAll(entries),
          restoreEntry: _restoreFromRecycle,
          deleteEntryPermanently: _deleteFromRecycle,
          openConflicts: _openConflicts,
          batchSetFavorite: (ids, value) =>
              _controller.batchSetFavorite(ids, value),
          batchMoveToTrash: (ids) => _controller.batchMoveToTrash(ids),
        );
        if (desktop) {
          return DesktopDiaryShell(
            entries: _entries,
            trash: _trash,
            categories: _categories,
            settingsController: widget.settingsController,
            actions: actions,
            conflictCount: _conflicts.length,
          );
        }
        return MobileDiaryShell(
          entries: _entries,
          trash: _trash,
          quickCaptureSide: widget.settingsController.settings.quickCaptureSide,
          syncState: _syncState,
          onSyncNow: _syncEngine == null ? null : _syncNow,
          actions: actions,
          conflictCount: _conflicts.length,
        );
      },
    );
  }

  void _onSyncStateChanged(SyncState state) {
    if (!mounted) return;
    setState(() => _syncState = state);
    if (state.status == SyncStatus.synced ||
        state.status == SyncStatus.conflict) {
      _controller.refresh();
      _refreshConflicts();
    }
  }

  Future<void> _syncNow() async {
    await _syncEngine?.syncNow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_syncNow());
  }

  Future<void> _refreshConflicts() async {
    final conflicts = await widget.repository.listConflicts();
    if (mounted) setState(() => _conflicts = conflicts);
  }

  Future<void> _openConflicts() async {
    await _refreshConflicts();
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ConflictsPage(
          conflicts: _conflicts,
          onResolve: (id, entry) async {
            await widget.repository.resolveConflict(id, entry);
            await _refreshConflicts();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _saveQuickCapture(String content) async {
    await _saveQuickCaptureWithPhotos(content, const []);
  }

  Future<void> _saveQuickCaptureWithPhotos(
    String content,
    List<String> imagePaths,
  ) async {
    final text = content.trim();
    if (text.isEmpty && imagePaths.isEmpty) return;
    final now = DateTime.now();
    final timeLabel = diaryTimeLabel(now);
    await _controller.save(
      DiaryEntry(
        id: now.microsecondsSinceEpoch.toString(),
        createdAt: now,
        updatedAt: now,
        title: text.isEmpty ? '$timeLabel 的照片' : '$timeLabel 的一个念头',
        content: text,
        contentText: text,
        category: '生活',
        imagePaths: imagePaths,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已保存在本机')));
  }

  Future<void> _openEditorFromQuick(String content, List<String> imagePaths) =>
      _openEditor(null, content, imagePaths);

  Future<void> _openEditor([
    DiaryEntry? entry,
    String initialContent = '',
    List<String> initialImagePaths = const [],
  ]) async {
    final desktop = diaryUsesDesktopShell(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.entryEditor),
        builder: (_) => EntryEditorPage(
          entry: entry,
          initialContent: initialContent,
          initialImagePaths: initialImagePaths,
          restoreInitialDraft:
              initialContent.isNotEmpty || initialImagePaths.isNotEmpty,
          desktopLayout: desktop,
          onToggleTheme: desktop ? _toggleTheme : null,
          categories: _categories,
          defaultEditorType:
              entry?.editorType ??
              widget.settingsController.settings.defaultEditorType,
          onExternalActivityStart: widget.lockCoordinator.beginExternalActivity,
          onExternalActivityEnd: widget.lockCoordinator.endExternalActivity,
          onImportPhotos: importQuickPhotos,
          onSave: (saved) async {
            await _controller.save(saved);
            if (initialContent.isNotEmpty || initialImagePaths.isNotEmpty) {
              await widget.repository.clearDraft('mobile-quick-capture');
            }
          },
          draftId: initialContent.isNotEmpty || initialImagePaths.isNotEmpty
              ? 'mobile-quick-capture'
              : 'compose-${entry?.id ?? 'new'}',
          onLoadDraft: widget.repository.loadDraft,
          onSaveDraft: widget.repository.saveDraft,
          onClearDraft: widget.repository.clearDraft,
        ),
      ),
    );
  }

  Future<void> _openEntry(DiaryEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.entryDetail),
        builder: (_) => EntryDetailPage(
          entry: entry,
          onEdit: _editEntry,
          onShare: () => _openShare(entry),
          onDelete: () => _moveToTrash(entry),
          onToggleFavorite: () => _toggleFavorite(entry),
          showWordCount: widget.settingsController.settings.showWordCount,
        ),
      ),
    );
  }

  Future<DiaryEntry?> _editEntry(DiaryEntry entry) async {
    await _openEditor(entry);
    return null;
  }

  Future<void> _openShare(DiaryEntry entry) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.share),
        builder: (_) => SharePage(
          entry: entry,
          onExternalActivityStart: widget.lockCoordinator.beginExternalActivity,
          onExternalActivityEnd: widget.lockCoordinator.endExternalActivity,
        ),
      ),
    );
  }

  Future<void> _openRecycle() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.recycle),
        builder: (_) => RecyclePage(
          entries: _trash,
          onRestore: _restoreFromRecycle,
          onDelete: _deleteFromRecycle,
        ),
      ),
    );
  }

  Future<void> _moveToTrash(DiaryEntry entry) async {
    await _controller.moveToTrash(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('日记已移入回收站')));
  }

  Future<void> _restoreFromRecycle(DiaryEntry entry) async {
    await _controller.restore(entry);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteFromRecycle(DiaryEntry entry) async {
    await _controller.deletePermanently(entry);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _toggleFavorite(DiaryEntry entry) async {
    await _controller.toggleFavorite(entry);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.settings),
        builder: (_) => SettingsPage(controller: widget.settingsController),
      ),
    );
  }

  Future<void> _openCategories() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.categories),
        builder: (_) => CategoryPage(
          categories: _categories,
          tags: _entries
              .expand((entry) => entry.tags)
              .toSet()
              .toList(growable: false),
        ),
      ),
    );
  }

  Future<void> _openBackup() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.backup),
        builder: (_) => BackupPage(
          entries: _entries,
          onExternalActivityStart: widget.lockCoordinator.beginExternalActivity,
          onExternalActivityEnd: widget.lockCoordinator.endExternalActivity,
          onImport: (entries) async {
            await _controller.replaceAll(entries);
          },
        ),
      ),
    );
  }

  Future<void> _openAbout() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.about),
        builder: (_) => const AboutPage(),
      ),
    );
  }

  Future<void> _toggleTheme() async {
    final current = widget.settingsController.settings.themeMode;
    final next = current == DiaryThemeMode.dark
        ? DiaryThemeMode.light
        : DiaryThemeMode.dark;
    await widget.settingsController.setThemeMode(next);
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      body: Center(child: CircularProgressIndicator(color: colors.terracotta)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.paper,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_outlined,
                size: 42,
                color: colors.terracotta,
              ),
              const SizedBox(height: 12),
              Text('日记暂时打不开', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '本地数据读取失败，请重试。',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('重新加载')),
            ],
          ),
        ),
      ),
    );
  }
}
