import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_shell.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/calendar/calendar_page.dart';
import 'package:diary/pages/entry/entry_detail_page.dart';
import 'package:diary/pages/entry/entry_editor_page.dart';
import 'package:diary/pages/home/home_page.dart';
import 'package:diary/pages/insights/insights_page.dart';
import 'package:diary/pages/media/media_page.dart';
import 'package:diary/pages/profile/profile_page.dart';
import 'package:diary/pages/recycle/recycle_page.dart';
import 'package:diary/pages/settings/about_page.dart';
import 'package:diary/pages/settings/backup_page.dart';
import 'package:diary/pages/settings/category_page.dart';
import 'package:diary/pages/settings/settings_page.dart';
import 'package:diary/pages/share/share_page.dart';
import 'package:diary/widgets/desktop_window_bar.dart';
import 'package:diary/widgets/diary_navigation.dart';

/// The Windows shell is a real workspace: persistent navigation, keyboard
/// commands, an internal page stack, and custom window chrome.
class DesktopDiaryShell extends StatefulWidget {
  const DesktopDiaryShell({
    required this.entries,
    required this.trash,
    required this.categories,
    required this.settingsController,
    required this.actions,
    super.key,
  });

  final List<DiaryEntry> entries;
  final List<DiaryEntry> trash;
  final List<String> categories;
  final SettingsController settingsController;
  final DiaryShellActions actions;

  @override
  State<DesktopDiaryShell> createState() => _DesktopDiaryShellState();
}

class _DesktopDiaryShellState extends State<DesktopDiaryShell> {
  final _homeKey = GlobalKey<HomePageState>();
  final _workspaceNavigatorKey = GlobalKey<NavigatorState>();
  final _workspaceTitles = <String>[];
  WidgetBuilder? _workspaceBuilder;
  int _selectedIndex = 0;

  static const _pageTitles = ['今天', '日历', '媒体', '洞察', '我的'];

  bool get _inWorkspace => _workspaceTitles.isNotEmpty;
  String? get _workspaceTitle =>
      _workspaceTitles.isEmpty ? null : _workspaceTitles.last;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final mainPages = _buildMainPages();
    final inWorkspace = _inWorkspace;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          unawaited(_openEditor());
        },
        SingleActivator(LogicalKeyboardKey.keyK, control: true): _focusSearch,
        SingleActivator(LogicalKeyboardKey.escape): _handleWorkspaceBack,
      },
      child: Scaffold(
        backgroundColor: colors.paper,
        body: Column(
          children: [
            DesktopWindowBar(
              title: _workspaceTitle ?? _pageTitles[_selectedIndex],
              isDark: Theme.of(context).brightness == Brightness.dark,
              onToggleTheme: widget.actions.toggleTheme,
              onBack: inWorkspace ? _handleWorkspaceBack : null,
              onNewEntry: inWorkspace ? null : () => unawaited(_openEditor()),
            ),
            Expanded(
              child: Row(
                children: [
                  DiarySideNavigation(
                    selectedIndex: _selectedIndex,
                    settingsSelected: inWorkspace && _workspaceTitle == '应用设置',
                    onSelected: _selectPage,
                    onNewEntry: () => unawaited(_openEditor()),
                    onOpenSettings: _openSettings,
                  ),
                  Expanded(
                    child: inWorkspace
                        ? _workspaceNavigator()
                        : IndexedStack(
                            index: _selectedIndex,
                            children: mainPages,
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMainPages() {
    return [
      HomePage(
        key: _homeKey,
        desktopLayout: true,
        entries: widget.entries,
        onOpenEditor: () => unawaited(_openEditor()),
        onOpenEntry: (entry) => unawaited(_openEntry(entry)),
        onToggleFavorite: (entry) =>
            unawaited(widget.actions.toggleFavorite(entry)),
        onShare: (entry) => unawaited(_openShare(entry)),
        onDelete: (entry) => unawaited(widget.actions.moveToTrash(entry)),
        onQuickCapture: widget.actions.saveQuickCapture,
      ),
      CalendarPage(
        entries: widget.entries,
        onOpenEntry: (entry) => unawaited(_openEntry(entry)),
      ),
      MediaPage(
        entries: widget.entries,
        onOpenEntry: (entry) => unawaited(_openEntry(entry)),
      ),
      InsightsPage(entries: widget.entries),
      ProfilePage(
        desktopLayout: true,
        entryCount: widget.entries.length,
        trashCount: widget.trash.length,
        onOpenRecycle: () => unawaited(_openRecycle()),
        onOpenSettings: _openSettings,
        onOpenCategories: _openCategories,
        onOpenBackup: _openBackup,
        onOpenAbout: _openAbout,
      ),
    ];
  }

  Widget _workspaceNavigator() {
    final builder = _workspaceBuilder;
    if (builder == null) return const SizedBox.shrink();
    return Navigator(
      key: _workspaceNavigatorKey,
      observers: [_WorkspaceObserver(onPop: _onWorkspacePopped)],
      onGenerateRoute: (settings) =>
          MaterialPageRoute(settings: settings, builder: builder),
    );
  }

  void _selectPage(int index) {
    if (_inWorkspace) {
      setState(() {
        _workspaceTitles.clear();
        _workspaceBuilder = null;
        _selectedIndex = index;
      });
      return;
    }
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
  }

  void _focusSearch() {
    if (_inWorkspace) {
      setState(() {
        _workspaceTitles.clear();
        _workspaceBuilder = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _homeKey.currentState?.focusSearch();
      });
      return;
    }
    if (_selectedIndex != 0) setState(() => _selectedIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _homeKey.currentState?.focusSearch();
    });
  }

  Future<void> _openEntry(DiaryEntry entry) async {
    if (_inWorkspace) return;
    _openWorkspacePage('日记详情', (context) => _detailPage(context, entry));
  }

  Future<DiaryEntry?> _openEditor([DiaryEntry? entry]) async {
    Widget page(BuildContext context) => _editorPage(context, entry);
    if (!_inWorkspace) {
      _openWorkspacePage(entry == null ? '写下此刻' : '编辑日记', page);
      return null;
    }
    return _pushWorkspacePage(entry == null ? '写下此刻' : '编辑日记', page);
  }

  Widget _detailPage(BuildContext context, DiaryEntry entry) {
    return EntryDetailPage(
      entry: entry,
      onEdit: (value) => _openEditor(value),
      onShare: () => unawaited(_openShare(entry)),
      onDelete: () => unawaited(widget.actions.moveToTrash(entry)),
      onToggleFavorite: () => unawaited(widget.actions.toggleFavorite(entry)),
      showWordCount: widget.settingsController.settings.showWordCount,
    );
  }

  Widget _editorPage(BuildContext context, DiaryEntry? entry) {
    return EntryEditorPage(
      entry: entry,
      desktopLayout: true,
      showDesktopWindowBar: false,
      onToggleTheme: widget.actions.toggleTheme,
      onDesktopBack: _handleWorkspaceBack,
      categories: widget.categories,
      defaultEditorType:
          entry?.editorType ??
          widget.settingsController.settings.defaultEditorType,
      onExternalActivityStart: widget.actions.beginExternalActivity,
      onExternalActivityEnd: widget.actions.endExternalActivity,
      onSave: widget.actions.saveEntry,
    );
  }

  Future<void> _openShare(DiaryEntry entry) async {
    await _pushOrReplaceWorkspacePage(
      '分享日记',
      (context) => SharePage(
        entry: entry,
        onExternalActivityStart: widget.actions.beginExternalActivity,
        onExternalActivityEnd: widget.actions.endExternalActivity,
      ),
    );
  }

  void _openSettings() {
    _replaceWorkspacePage(
      '应用设置',
      (context) => SettingsPage(
        controller: widget.settingsController,
        onOpenCategories: () => unawaited(_openCategories()),
        onOpenBackup: () => unawaited(_openBackup()),
        onOpenAbout: () => unawaited(_openAbout()),
      ),
    );
  }

  Future<void> _openCategories() async {
    await _pushOrReplaceWorkspacePage(
      '分类与标签',
      (context) => CategoryPage(categories: widget.categories),
    );
  }

  Future<void> _openBackup() async {
    await _pushOrReplaceWorkspacePage(
      '备份与恢复',
      (context) => BackupPage(
        entries: widget.entries,
        onExternalActivityStart: widget.actions.beginExternalActivity,
        onExternalActivityEnd: widget.actions.endExternalActivity,
        onImport: widget.actions.replaceEntries,
      ),
    );
  }

  Future<void> _openAbout() async {
    await _pushOrReplaceWorkspacePage('关于此刻', (context) => const AboutPage());
  }

  Future<void> _openRecycle() async {
    await _pushOrReplaceWorkspacePage(
      '回收站',
      (context) => RecyclePage(
        entries: widget.trash,
        onRestore: widget.actions.restoreEntry,
        onDelete: widget.actions.deleteEntryPermanently,
      ),
    );
  }

  void _openWorkspacePage(String title, WidgetBuilder builder) {
    if (!mounted) return;
    setState(() {
      _workspaceTitles
        ..clear()
        ..add(title);
      _workspaceBuilder = builder;
    });
  }

  Future<void> _pushOrReplaceWorkspacePage(
    String title,
    WidgetBuilder builder,
  ) async {
    if (!_inWorkspace) {
      _openWorkspacePage(title, builder);
      return;
    }
    await _pushWorkspacePage(title, builder);
  }

  Future<DiaryEntry?> _pushWorkspacePage(
    String title,
    WidgetBuilder builder,
  ) async {
    if (!mounted) return null;
    _workspaceTitles.add(title);
    setState(() {});
    return _workspaceNavigatorKey.currentState?.push<DiaryEntry>(
      MaterialPageRoute(
        settings: RouteSettings(name: title),
        builder: builder,
      ),
    );
  }

  void _replaceWorkspacePage(String title, WidgetBuilder builder) {
    if (!_inWorkspace) {
      _openWorkspacePage(title, builder);
      return;
    }
    setState(() {
      _workspaceTitles.clear();
      _workspaceBuilder = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openWorkspacePage(title, builder);
    });
  }

  void _handleWorkspaceBack() {
    if (!_inWorkspace) return;
    if (_workspaceTitles.length > 1 &&
        (_workspaceNavigatorKey.currentState?.canPop() ?? false)) {
      _workspaceNavigatorKey.currentState!.pop();
      return;
    }
    setState(() {
      _workspaceTitles.clear();
      _workspaceBuilder = null;
    });
  }

  void _onWorkspacePopped() {
    if (!mounted || !_inWorkspace) return;
    if (_workspaceTitles.length > 1) {
      setState(() => _workspaceTitles.removeLast());
    } else {
      setState(() {
        _workspaceTitles.clear();
        _workspaceBuilder = null;
      });
    }
  }
}

class _WorkspaceObserver extends NavigatorObserver {
  _WorkspaceObserver({required this.onPop});

  final VoidCallback onPop;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    onPop();
    super.didPop(route, previousRoute);
  }
}
