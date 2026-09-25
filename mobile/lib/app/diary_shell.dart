import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_routes.dart';
import 'package:diary/app/app_theme.dart';
import 'package:diary/app/desktop_diary_shell.dart';
import 'package:diary/app/mobile_diary_shell.dart';
import 'package:diary/application/diary_controller.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/application/incoming_share_bridge.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/amap_location_bridge.dart';
import 'package:diary/data/profile_avatar_store.dart';
import 'package:diary/data/quick_photo_importer.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_place.dart';
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
import 'package:diary/widgets/avatar_cropper.dart';
import 'package:diary/widgets/trash_feedback_toast.dart';
import 'package:diary/widgets/in_app_photo_picker.dart';

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
    required this.saveQuickCaptureWithMedia,
    required this.saveChatMessage,
    this.saveChatLocation,
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
    required this.clearTrash,
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
  final Future<void> Function(
    String content,
    List<String> imagePaths,
    List<String> audioPaths,
  )
  saveQuickCaptureWithMedia;
  final Future<void> Function(
    String content,
    List<String> imagePaths,
    List<String> audioPaths,
    List<String> videoPaths,
    double mood,
    String? moodLabel,
  )
  saveChatMessage;
  final Future<void> Function(DiaryPlace place)? saveChatLocation;
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
  final Future<void> Function() clearTrash;
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
  final IncomingShareBridge _incomingShareBridge = IncomingShareBridge();
  final ValueNotifier<String?> _shortcutRequest = ValueNotifier(null);
  bool _handlingIncomingShare = false;
  bool _handlingShortcut = false;
  SyncEngine? _syncEngine;
  Timer? _chatSyncTimer;
  Timer? _trashFeedbackTimer;
  OverlayEntry? _trashFeedbackEntry;
  _SyncConnection? _syncConnection;
  SyncState _syncState = const SyncState();
  final ProfileAvatarStore _profileAvatarStore = ProfileAvatarStore();

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
    _incomingShareBridge.listen(
      onShareAvailable: () => unawaited(_consumeIncomingShares()),
      onShortcutAvailable: () => unawaited(_consumeShortcuts()),
    );
    _shortcutRequest.addListener(_onShortcutRequestChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_consumeIncomingShares());
      unawaited(_consumeShortcuts());
    });
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
    _chatSyncTimer?.cancel();
    _removeTrashFeedback();
    _resetSyncEngine();
    _incomingShareBridge.dispose();
    _shortcutRequest.removeListener(_onShortcutRequestChanged);
    _shortcutRequest.dispose();
    super.dispose();
  }

  void _onShortcutRequestChanged() {
    if (_shortcutRequest.value == null) unawaited(_consumeShortcuts());
  }

  Future<void> _consumeShortcuts() async {
    if (_handlingShortcut || _shortcutRequest.value != null || !mounted) return;
    _handlingShortcut = true;
    String? shortcut;
    try {
      shortcut = await _incomingShareBridge.takePendingShortcut();
      if (mounted && shortcut != null) _shortcutRequest.value = shortcut;
    } catch (_) {
      // The bridge is unavailable on platforms without Android shortcuts.
    } finally {
      _handlingShortcut = false;
      if (mounted && shortcut != null && _shortcutRequest.value == null) {
        unawaited(_consumeShortcuts());
      }
    }
  }

  Future<void> _consumeIncomingShares() async {
    if (_handlingIncomingShare || !mounted) return;
    _handlingIncomingShare = true;
    try {
      while (mounted) {
        final share = await _incomingShareBridge.takePendingShare();
        if (share == null || !mounted) break;
        await _openIncomingShare(share);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法读取分享内容，请重试')));
      }
    } finally {
      _handlingIncomingShare = false;
    }
  }

  Future<void> _openIncomingShare(IncomingShare share) async {
    const draftId = 'incoming-share';
    final existing = await widget.repository.loadDraft(draftId);
    final previousContent = existing?.payload['content'];
    final previousImages = existing?.payload['attachments'];
    final alreadySaved = existing?.payload['shareId'] == share.id;
    final imagePaths = alreadySaved
        ? const <String>[]
        : await importQuickPhotos(share.imagePaths);
    final content = [
      if (previousContent is String && previousContent.trim().isNotEmpty)
        previousContent.trim(),
      if (!alreadySaved && share.text.trim().isNotEmpty) share.text.trim(),
    ].join('\n\n');
    final images = <String>{
      if (previousImages is List) ...previousImages.whereType<String>(),
      if (!alreadySaved) ...imagePaths,
    }.toList(growable: false);
    await widget.repository.saveDraft(
      DraftPayload(
        id: draftId,
        payload: {
          'content': content,
          'attachments': images,
          'shareId': share.id,
        },
        updatedAt: DateTime.now(),
      ),
    );
    await _incomingShareBridge.completePendingShare(share.id);
    if (mounted) await _openEditor(null, content, images, draftId);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
    _configureSync();
  }

  void _configureSync() {
    final settings = widget.settingsController.settings;
    const envUrl = String.fromEnvironment('DIARY_SYNC_URL');
    final endpoint = settings.syncEndpoint.trim().isNotEmpty
        ? settings.syncEndpoint.trim()
        : envUrl;
    if (endpoint.isEmpty) {
      _resetSyncEngine();
      return;
    }
    final connection = _SyncConnection(
      endpoint: endpoint,
      token: settings.syncToken.isNotEmpty
          ? settings.syncToken
          : const String.fromEnvironment('DIARY_SYNC_TOKEN'),
    );
    if (_syncEngine != null && _syncConnection == connection) return;
    _resetSyncEngine();
    _syncConnection = connection;
    _syncEngine = SyncEngine(
      repository: widget.repository,
      client: SyncClient(baseUrl: connection.endpoint, token: connection.token),
      onStateChanged: _onSyncStateChanged,
    )..start();
    unawaited(_syncNow());
    if (mounted) setState(() {});
  }

  void _resetSyncEngine() {
    _syncEngine?.stop();
    _syncEngine = null;
    _syncConnection = null;
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
          saveQuickCaptureWithMedia: _saveQuickCaptureWithMedia,
          saveChatMessage: _saveChatMessage,
          saveChatLocation: _saveChatLocation,
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
          saveEntry: _saveEntryAndSync,
          beginExternalActivity: widget.lockCoordinator.beginExternalActivity,
          endExternalActivity: widget.lockCoordinator.endExternalActivity,
          replaceEntries: (entries) => _controller.replaceAll(entries),
          restoreEntry: _restoreFromRecycle,
          deleteEntryPermanently: _deleteFromRecycle,
          clearTrash: _clearTrashAndSync,
          openConflicts: _openConflicts,
          batchSetFavorite: (ids, value) =>
              _controller.batchSetFavorite(ids, value),
          batchMoveToTrash: _batchMoveToTrash,
        );
        if (desktop) {
          return DesktopDiaryShell(
            entries: _entries,
            trash: _trash,
            categories: _categories,
            settingsController: widget.settingsController,
            actions: actions,
            defaultHomeMode: widget.settingsController.settings.defaultHomeMode,
            chatTitle: widget.settingsController.settings.chatTitle,
            chatBackground: widget.settingsController.settings.chatBackground,
            conflictCount: _conflicts.length,
          );
        }
        return MobileDiaryShell(
          entries: _entries,
          entriesLoading: _controller.isLoading,
          profileSignature: widget.settingsController.settings.profileSignature,
          showProfileSignature:
              widget.settingsController.settings.showProfileSignature,
          onSaveProfile: widget.settingsController.setProfileDetails,
          trash: _trash,
          quickCaptureSide: widget.settingsController.settings.quickCaptureSide,
          defaultHomeMode: widget.settingsController.settings.defaultHomeMode,
          chatTitle: widget.settingsController.settings.chatTitle,
          amapAndroidKey: widget.settingsController.settings.amapAndroidKey,
          chatBackground: widget.settingsController.settings.chatBackground,
          syncState: _syncState,
          onSyncNow: _syncEngine == null ? null : _syncNow,
          onOpenSyncSettings: _openSyncSettings,
          profileAvatarPath:
              widget.settingsController.settings.profileAvatarPath,
          onPickAvatar: _pickProfileAvatar,
          onClearAvatar: _clearProfileAvatar,
          showChatAvatar: widget.settingsController.settings.showChatAvatar,
          actions: actions,
          shortcutRequest: _shortcutRequest,
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
      _controller.refresh(notifyBeforeLoad: false);
      _refreshConflicts();
    }
  }

  Future<void> _syncNow() async {
    await _syncEngine?.syncNow();
  }

  void _scheduleChatSync() {
    _chatSyncTimer?.cancel();
    _chatSyncTimer = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_syncNow()),
    );
  }

  Future<void> _saveEntryAndSync(DiaryEntry entry) async {
    await _controller.save(entry);
    unawaited(_syncNow());
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
  ) => _saveQuickCaptureWithMedia(content, imagePaths, const []);

  Future<void> _saveQuickCaptureWithMedia(
    String content,
    List<String> imagePaths,
    List<String> audioPaths,
  ) async {
    final text = content.trim();
    if (text.isEmpty && imagePaths.isEmpty && audioPaths.isEmpty) return;
    final now = DateTime.now();
    final timeLabel = diaryTimeLabel(now);
    await _controller.save(
      DiaryEntry(
        id: now.microsecondsSinceEpoch.toString(),
        createdAt: now,
        updatedAt: now,
        title: text.isEmpty
            ? imagePaths.isNotEmpty
                  ? '$timeLabel 的照片'
                  : '$timeLabel 的录音'
            : '$timeLabel 的一个念头',
        content: text,
        contentText: text,
        category: '生活',
        imagePaths: imagePaths,
        audioPaths: audioPaths,
      ),
    );
    unawaited(_syncNow());
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('已保存在本机')));
  }

  Future<void> _saveChatMessage(
    String content,
    List<String> imagePaths,
    List<String> audioPaths,
    List<String> videoPaths,
    double mood,
    String? moodLabel,
  ) async {
    final text = content.trim();
    if (text.isEmpty &&
        imagePaths.isEmpty &&
        audioPaths.isEmpty &&
        videoPaths.isEmpty &&
        moodLabel == null) {
      return;
    }
    final now = DateTime.now();
    final timeLabel = diaryTimeLabel(now);
    await _controller.saveNewChatEntry(
      DiaryEntry(
        id: now.microsecondsSinceEpoch.toString(),
        createdAt: now,
        updatedAt: now,
        title: text.isNotEmpty
            ? '$timeLabel 的片段'
            : imagePaths.isNotEmpty
            ? '$timeLabel 的照片'
            : videoPaths.isNotEmpty
            ? '$timeLabel 的视频'
            : audioPaths.isNotEmpty
            ? '$timeLabel 的语音'
            : '$timeLabel 的心情',
        content: text,
        contentText: text,
        mood: mood,
        moodLabel: moodLabel,
        category: '生活',
        imagePaths: imagePaths,
        audioPaths: audioPaths,
        videoPaths: videoPaths,
      ),
    );
    _scheduleChatSync();
  }

  Future<void> _saveChatLocation(DiaryPlace place) async {
    if (!place.isValid) return;
    final now = DateTime.now();
    await _controller.saveNewChatEntry(
      DiaryEntry(
        id: now.microsecondsSinceEpoch.toString(),
        createdAt: now,
        updatedAt: now,
        title: place.name.trim(),
        content: '',
        contentText: '',
        category: '生活',
        positions: [place.name.trim(), place.address.trim()],
        latitude: place.latitude,
        longitude: place.longitude,
        imagePaths: place.thumbnailPath?.isNotEmpty == true
            ? [place.thumbnailPath!]
            : const [],
      ),
    );
    _scheduleChatSync();
  }

  Future<void> _openEditorFromQuick(String content, List<String> imagePaths) =>
      _openEditor(null, content, imagePaths);

  Future<void> _openEditor([
    DiaryEntry? entry,
    String initialContent = '',
    List<String> initialImagePaths = const [],
    String? sourceDraftId,
  ]) async {
    final desktop = diaryUsesDesktopShell(context);
    final draftId =
        sourceDraftId ??
        (initialContent.isNotEmpty || initialImagePaths.isNotEmpty
            ? 'mobile-quick-capture'
            : 'compose-${entry?.id ?? 'new'}');
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
          onPickLocation: defaultTargetPlatform == TargetPlatform.android
              ? (editorContext) => AmapLocationBridge.pick(
                  editorContext,
                  widget.settingsController.settings.amapAndroidKey,
                  includeThumbnail: false,
                )
              : null,
          onSave: (saved) async {
            await _saveEntryAndSync(saved);
            if (initialContent.isNotEmpty || initialImagePaths.isNotEmpty) {
              await widget.repository.clearDraft(draftId);
            }
          },
          draftId: draftId,
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
          onEmpty: _emptyRecycle,
        ),
      ),
    );
  }

  Future<void> _moveToTrash(DiaryEntry entry) async {
    await _controller.moveToTrash(entry);
    if (!mounted) return;
    _showTrashFeedback(1);
  }

  Future<void> _batchMoveToTrash(Iterable<String> ids) async {
    final selectedIds = ids.toSet();
    if (selectedIds.isEmpty) return;
    await _controller.batchMoveToTrash(selectedIds);
    if (!mounted) return;
    _showTrashFeedback(selectedIds.length);
  }

  void _showTrashFeedback(int count) {
    _removeTrashFeedback();
    final entry = OverlayEntry(
      builder: (context) => TrashFeedbackToast(count: count),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    _trashFeedbackEntry = entry;
    _trashFeedbackTimer = Timer(
      const Duration(milliseconds: 1300),
      _removeTrashFeedback,
    );
  }

  void _removeTrashFeedback() {
    _trashFeedbackTimer?.cancel();
    _trashFeedbackTimer = null;
    _trashFeedbackEntry?.remove();
    _trashFeedbackEntry?.dispose();
    _trashFeedbackEntry = null;
  }

  Future<void> _restoreFromRecycle(DiaryEntry entry) async {
    await _controller.restore(entry);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteFromRecycle(DiaryEntry entry) async {
    await _controller.deletePermanently(entry);
    unawaited(_syncNow());
    if (mounted) Navigator.pop(context);
  }

  Future<void> _emptyRecycle() async {
    await _clearTrashAndSync();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('回收站已清空')));
  }

  Future<void> _clearTrashAndSync() async {
    await _controller.clearTrash();
    unawaited(_syncNow());
  }

  Future<void> _toggleFavorite(DiaryEntry entry) async {
    await _controller.toggleFavorite(entry);
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.settings),
        builder: (_) => SettingsPage(
          controller: widget.settingsController,
          onImportPhotos: importQuickPhotos,
          showDataControls: false,
        ),
      ),
    );
  }

  Future<void> _openSyncSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SyncSettingsPage(controller: widget.settingsController),
      ),
    );
  }

  Future<void> _pickProfileAvatar() async {
    try {
      final source = await chooseDiaryPhotoSource(context, title: '更换头像');
      if (source == null || !mounted) return;
      final runsOutsideApp = source == DiaryPhotoSource.camera;
      final photos = await (() async {
        if (runsOutsideApp) widget.lockCoordinator.beginExternalActivity();
        try {
          return await pickDiaryPhotoSource(
            context,
            source: source,
            maxAssets: 1,
          );
        } finally {
          if (runsOutsideApp) widget.lockCoordinator.endExternalActivity();
        }
      })();
      if (!mounted || photos.isEmpty) return;
      final cropped = await cropDiaryAvatar(context, photos.single);
      if (!mounted || cropped == null) return;
      final storedPath = await _profileAvatarStore.savePng(cropped);
      await widget.settingsController.setProfileAvatarPath(storedPath);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('头像已更新')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('头像更新失败，请重试')));
    }
  }

  Future<void> _clearProfileAvatar() async {
    try {
      await _profileAvatarStore.clear();
      await widget.settingsController.clearProfileAvatarPath();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已恢复默认头像')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('恢复默认头像失败，请重试')));
    }
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
        builder: (_) => AboutPage(
          updateEndpoint: widget.settingsController.settings.updateEndpoint,
        ),
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

class _SyncConnection {
  const _SyncConnection({required this.endpoint, required this.token});

  final String endpoint;
  final String token;

  @override
  bool operator ==(Object other) =>
      other is _SyncConnection &&
      other.endpoint == endpoint &&
      other.token == token;

  @override
  int get hashCode => Object.hash(endpoint, token);
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
