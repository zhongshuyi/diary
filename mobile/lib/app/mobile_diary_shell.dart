import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/app/diary_shell.dart';
import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/domain/sync_state.dart';
import 'package:diary/pages/calendar/calendar_page.dart';
import 'package:diary/pages/chat/chat_page.dart';
import 'package:diary/pages/entry/quick_capture_sheet.dart';
import 'package:diary/pages/favorites/favorites_page.dart';
import 'package:diary/pages/home/home_page.dart';
import 'package:diary/pages/insights/insights_page.dart';
import 'package:diary/pages/media/media_page.dart';
import 'package:diary/pages/profile/profile_page.dart';
import 'package:diary/widgets/diary_navigation.dart';
import 'package:diary/widgets/draggable_quick_capture.dart';

/// The phone shell keeps navigation close to the thumb and makes quick capture
/// the first-class action. It intentionally does not share the desktop shell's
/// navigation or window chrome.
class MobileDiaryShell extends StatefulWidget {
  const MobileDiaryShell({
    required this.entries,
    required this.trash,
    required this.actions,
    this.shortcutRequest,
    this.quickCaptureSide = QuickCaptureSide.right,
    this.defaultHomeMode = DiaryHomeMode.timeline,
    this.chatTitle = diaryDefaultChatTitle,
    this.amapAndroidKey = '',
    this.chatBackground = const DiaryChatBackground(),
    this.conflictCount = 0,
    this.syncState = const SyncState(),
    this.onSyncNow,
    this.onOpenSyncSettings,
    this.profileAvatarPath,
    this.onPickAvatar,
    this.onClearAvatar,
    this.showChatAvatar = true,
    super.key,
  });

  final List<DiaryEntry> entries;
  final List<DiaryEntry> trash;
  final DiaryShellActions actions;
  final ValueNotifier<String?>? shortcutRequest;
  final QuickCaptureSide quickCaptureSide;
  final DiaryHomeMode defaultHomeMode;
  final String chatTitle;
  final String amapAndroidKey;
  final DiaryChatBackground chatBackground;
  final int conflictCount;
  final SyncState syncState;
  final Future<void> Function()? onSyncNow;
  final Future<void> Function()? onOpenSyncSettings;
  final String? profileAvatarPath;
  final Future<void> Function()? onPickAvatar;
  final Future<void> Function()? onClearAvatar;
  final bool showChatAvatar;

  @override
  State<MobileDiaryShell> createState() => _MobileDiaryShellState();
}

class _MobileDiaryShellState extends State<MobileDiaryShell> {
  static const _quickCaptureXKey = 'diary.mobile.quick_capture.x';
  static const _quickCaptureYKey = 'diary.mobile.quick_capture.y';
  static const _timelineIndex = 0;
  static const _chatIndex = 1;
  static const _calendarIndex = 2;
  static const _profileIndex = 3;

  int _selectedIndex = _timelineIndex;
  bool _selectedByUser = false;
  Offset? _quickCapturePosition;
  late final ValueNotifier<List<DiaryEntry>> _favoritesEntries;

  @override
  void initState() {
    super.initState();
    _favoritesEntries = ValueNotifier(List.unmodifiable(widget.entries));
    _selectedIndex = _indexForHomeMode(widget.defaultHomeMode);
    _loadQuickCapturePosition();
    widget.shortcutRequest?.addListener(_handleShortcut);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleShortcut());
  }

  @override
  void didUpdateWidget(covariant MobileDiaryShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.entries, oldWidget.entries)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _favoritesEntries.value = List.unmodifiable(widget.entries);
        }
      });
    }
    if (oldWidget.defaultHomeMode != widget.defaultHomeMode &&
        !_selectedByUser) {
      setState(
        () => _selectedIndex = _indexForHomeMode(widget.defaultHomeMode),
      );
    }
  }

  int _indexForHomeMode(DiaryHomeMode mode) {
    return switch (mode) {
      DiaryHomeMode.timeline => _timelineIndex,
      DiaryHomeMode.chat => _chatIndex,
    };
  }

  @override
  void dispose() {
    widget.shortcutRequest?.removeListener(_handleShortcut);
    _favoritesEntries.dispose();
    super.dispose();
  }

  void _handleShortcut() {
    if (!mounted) return;
    final shortcut = widget.shortcutRequest?.value;
    if (shortcut == null) return;
    widget.shortcutRequest!.value = null;
    switch (shortcut) {
      case 'quick-capture':
        unawaited(_openQuickCapture());
        return;
      case 'open-chat':
        _selectPage(_chatIndex);
        return;
      case 'new-entry':
        unawaited(widget.actions.openEditor());
        return;
    }
  }

  Future<void> _loadQuickCapturePosition() async {
    final preferences = await SharedPreferences.getInstance();
    final x = preferences.getDouble(_quickCaptureXKey);
    final y = preferences.getDouble(_quickCaptureYKey);
    if (!mounted || x == null || y == null) return;
    setState(() => _quickCapturePosition = Offset(x, y));
  }

  Future<void> _saveQuickCapturePosition(Offset position) async {
    _quickCapturePosition = position;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_quickCaptureXKey, position.dx);
    await preferences.setDouble(_quickCaptureYKey, position.dy);
  }

  Future<void> _openQuickCapture() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      requestFocus: false,
      showDragHandle: true,
      backgroundColor: DiaryThemeColors.of(context).surface,
      builder: (_) => QuickCaptureSheet(
        onSave: widget.actions.saveQuickCaptureWithPhotos,
        onSaveWithAudio: widget.actions.saveQuickCaptureWithMedia,
        importPhotos: widget.actions.importQuickPhotos,
        onLoadDraft: widget.actions.loadDraft,
        onSaveDraft: widget.actions.saveDraft,
        onClearDraft: widget.actions.clearDraft,
        onExternalActivityStart: widget.actions.beginExternalActivity,
        onExternalActivityEnd: widget.actions.endExternalActivity,
        onOpenEditor: widget.actions.openEditorFromQuick,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final pages = [
      HomePage(
        desktopLayout: false,
        entries: widget.entries,
        onOpenEditor: () => unawaited(widget.actions.openEditor()),
        onOpenEntry: (entry) => unawaited(widget.actions.openEntry(entry)),
        onToggleFavorite: (entry) =>
            unawaited(widget.actions.toggleFavorite(entry)),
        onShare: (entry) => unawaited(widget.actions.openShare(entry)),
        onDelete: (entry) => unawaited(widget.actions.moveToTrash(entry)),
        onQuickCapture: widget.actions.saveQuickCapture,
        onBatchFavorite: widget.actions.batchSetFavorite,
        onBatchDelete: widget.actions.batchMoveToTrash,
        syncState: widget.syncState,
        onSyncNow: widget.onSyncNow,
      ),
      ChatPage(
        entries: widget.entries,
        title: widget.chatTitle,
        chatBackground: widget.chatBackground,
        showChatAvatar: widget.showChatAvatar,
        profileAvatarPath: widget.profileAvatarPath,
        onSend: widget.actions.saveChatMessage,
        onSendLocation: widget.actions.saveChatLocation,
        amapAndroidKey: widget.amapAndroidKey,
        onLoadDraft: widget.actions.loadDraft,
        onSaveDraft: widget.actions.saveDraft,
        onClearDraft: widget.actions.clearDraft,
        onOpenEntry: (entry) => unawaited(widget.actions.openEntry(entry)),
        onEdit: (entry) => widget.actions.openEditor(entry),
        onDelete: widget.actions.moveToTrash,
        onOpenEditor: () => unawaited(widget.actions.openEditor()),
        onImportAttachments: widget.actions.importQuickPhotos,
        onExternalActivityStart: widget.actions.beginExternalActivity,
        onExternalActivityEnd: widget.actions.endExternalActivity,
        onNavigate: _navigateFromChat,
      ),
      CalendarPage(
        entries: widget.entries,
        onOpenEntry: (entry) => unawaited(widget.actions.openEntry(entry)),
      ),
      ProfilePage(
        entryCount: widget.entries.length,
        trashCount: widget.trash.length,
        onOpenRecycle: widget.actions.openRecycle,
        onOpenSettings: widget.actions.openSettings,
        onOpenCategories: widget.actions.openCategories,
        onOpenBackup: widget.actions.openBackup,
        onOpenAbout: widget.actions.openAbout,
        conflictCount: widget.conflictCount,
        onOpenConflicts: widget.actions.openConflicts,
        syncState: widget.syncState,
        onOpenSyncSettings: widget.onOpenSyncSettings == null
            ? null
            : () => unawaited(widget.onOpenSyncSettings!()),
        profileAvatarPath: widget.profileAvatarPath,
        onPickAvatar: widget.onPickAvatar,
        onClearAvatar: widget.onClearAvatar,
        onOpenMedia: () => unawaited(_openMedia()),
        onOpenInsights: () => unawaited(_openInsights()),
        favoriteCount: _favoriteCount,
        onOpenFavorites: () => unawaited(_openFavorites()),
      ),
    ];

    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: _selectedIndex == _chatIndex
            ? colors.surface
            : Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _selectedIndex == _chatIndex
            ? colors.surface
            : colors.paper,
        body: SafeArea(
          top: true,
          bottom: false,
          child: Stack(
            children: [
              _AnimatedTabStack(index: _selectedIndex, pages: pages),
              if (_selectedIndex != _chatIndex)
                DraggableQuickCaptureFab(
                  buttonKey: const Key('mobile-quick-capture-fab'),
                  initialPosition: _quickCapturePosition,
                  initialSide: widget.quickCaptureSide,
                  onPositionChanged: (position) {
                    unawaited(_saveQuickCapturePosition(position));
                  },
                  onSubmit: widget.actions.saveQuickCapture,
                  onOpen: _openQuickCapture,
                ),
            ],
          ),
        ),
        bottomNavigationBar: _selectedIndex == _chatIndex
            ? null
            : DiaryBottomNavigation(
                selectedIndex: _selectedIndex,
                onSelected: _selectPage,
              ),
      ),
    );
  }

  void _selectPage(int index) {
    setState(() {
      _selectedByUser = true;
      _selectedIndex = index;
    });
  }

  void _navigateFromChat(ChatPageDestination destination) {
    switch (destination) {
      case ChatPageDestination.timeline:
        _selectPage(_timelineIndex);
        break;
      case ChatPageDestination.calendar:
        _selectPage(_calendarIndex);
        break;
      case ChatPageDestination.media:
        unawaited(_openMedia());
        break;
      case ChatPageDestination.insights:
        unawaited(_openInsights());
        break;
      case ChatPageDestination.profile:
        _selectPage(_profileIndex);
        break;
    }
  }

  Future<void> _openMedia() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: DiaryThemeColors.of(context).paper,
          body: SafeArea(
            child: MediaPage(
              entries: widget.entries,
              onOpenEntry: (entry) =>
                  unawaited(widget.actions.openEntry(entry)),
            ),
          ),
        ),
      ),
    );
  }

  int get _favoriteCount => widget.entries
      .where(
        (entry) =>
            entry.isFavorite &&
            !entry.isInTrash &&
            !entry.isDeleted &&
            !entry.isConflict,
      )
      .length;

  Future<void> _openFavorites() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: DiaryThemeColors.of(context).paper,
          body: SafeArea(
            child: FavoritesPage(
              entriesListenable: _favoritesEntries,
              onOpenEntry: widget.actions.openEntry,
              onToggleFavorite: widget.actions.toggleFavorite,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openInsights() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: DiaryThemeColors.of(context).paper,
          body: SafeArea(child: InsightsPage(entries: widget.entries)),
        ),
      ),
    );
  }
}

class _AnimatedTabStack extends StatefulWidget {
  const _AnimatedTabStack({required this.index, required this.pages});

  final int index;
  final List<Widget> pages;

  @override
  State<_AnimatedTabStack> createState() => _AnimatedTabStackState();
}

class _AnimatedTabStackState extends State<_AnimatedTabStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DiaryMotion.standard,
    )..value = 1;
    _pageController = PageController(initialPage: widget.index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = DiaryMotion.duration(context, DiaryMotion.standard);
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _pageController.jumpToPage(widget.index);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: DiaryMotion.curve(context, Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: animation,
      child: RepaintBoundary(
        child: PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.pages.length,
          itemBuilder: (context, index) => _KeepAliveTabPage(
            key: ValueKey('mobile-tab-$index'),
            child: widget.pages[index],
          ),
        ),
      ),
      builder: (context, child) {
        final value = animation.value;
        return Transform.translate(
          offset: Offset(14 * (1 - value), 0),
          child: child,
        );
      },
    );
  }
}

class _KeepAliveTabPage extends StatefulWidget {
  const _KeepAliveTabPage({required this.child, super.key});

  final Widget child;

  @override
  State<_KeepAliveTabPage> createState() => _KeepAliveTabPageState();
}

class _KeepAliveTabPageState extends State<_KeepAliveTabPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
