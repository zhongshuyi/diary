import 'package:flutter/material.dart';

import 'package:diary/app/app_routes.dart';
import 'package:diary/app/app_theme.dart';
import 'package:diary/application/diary_lock_coordinator.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/application/diary_controller.dart';
import 'package:diary/application/settings_controller.dart';
import 'package:diary/pages/calendar/calendar_page.dart';
import 'package:diary/pages/entry/entry_detail_page.dart';
import 'package:diary/pages/entry/entry_editor_page.dart';
import 'package:diary/pages/home/home_page.dart';
import 'package:diary/pages/insights/insights_page.dart';
import 'package:diary/pages/media/media_page.dart';
import 'package:diary/pages/profile/profile_page.dart';
import 'package:diary/pages/recycle/recycle_page.dart';
import 'package:diary/pages/share/share_page.dart';
import 'package:diary/pages/settings/about_page.dart';
import 'package:diary/pages/settings/backup_page.dart';
import 'package:diary/pages/settings/category_page.dart';
import 'package:diary/pages/settings/settings_page.dart';
import 'package:diary/widgets/diary_navigation.dart';

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

class _DiaryShellState extends State<DiaryShell> {
  late final DiaryController _controller;
  int _selectedIndex = 0;

  List<DiaryEntry> get _entries => _controller.entries;
  List<DiaryEntry> get _trash => _controller.trash;
  List<String> get _categories => _controller.categories;

  @override
  void initState() {
    super.initState();
    _controller = DiaryController(repository: widget.repository)
      ..addListener(_onControllerChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    if (_controller.isLoading && _entries.isEmpty && _trash.isEmpty) {
      return const _LoadingView();
    }
    if (_controller.error != null && _entries.isEmpty && _trash.isEmpty) {
      return _ErrorView(onRetry: _controller.refresh);
    }
    final page = IndexedStack(
      index: _selectedIndex,
      children: [
        HomePage(
          entries: _entries,
          onOpenEditor: () => _openEditor(),
          onOpenEntry: _openEntry,
          onToggleFavorite: _toggleFavorite,
          onShare: _openShare,
          onDelete: _moveToTrash,
        ),
        CalendarPage(entries: _entries, onOpenEntry: _openEntry),
        MediaPage(entries: _entries, onOpenEntry: _openEntry),
        InsightsPage(entries: _entries),
        ProfilePage(
          entryCount: _entries.length,
          trashCount: _trash.length,
          onOpenRecycle: _openRecycle,
          onOpenSettings: _openSettings,
          onOpenCategories: _openCategories,
          onOpenBackup: _openBackup,
          onOpenAbout: _openAbout,
        ),
      ],
    );
    return Scaffold(
      backgroundColor: colors.paper,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 900;
          return Row(
            children: [
              if (desktop)
                DiarySideNavigation(
                  selectedIndex: _selectedIndex,
                  onSelected: _selectPage,
                  onNewEntry: () => _openEditor(),
                ),
              Expanded(child: page),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? DiaryBottomNavigation(
              selectedIndex: _selectedIndex,
              onSelected: _selectPage,
            )
          : null,
    );
  }

  void _selectPage(int index) => setState(() => _selectedIndex = index);

  Future<void> _openEditor([DiaryEntry? entry]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.entryEditor),
        builder: (_) => EntryEditorPage(
          entry: entry,
          categories: _categories,
          defaultEditorType:
              entry?.editorType ??
              widget.settingsController.settings.defaultEditorType,
          onExternalActivityStart: widget.lockCoordinator.beginExternalActivity,
          onExternalActivityEnd: widget.lockCoordinator.endExternalActivity,
          onSave: (saved) async {
            await _controller.save(saved);
          },
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
          onEdit: _openEditor,
          onShare: () => _openShare(entry),
          onDelete: () => _moveToTrash(entry),
          onToggleFavorite: () => _toggleFavorite(entry),
          showWordCount: widget.settingsController.settings.showWordCount,
        ),
      ),
    );
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
        builder: (_) => CategoryPage(categories: _categories),
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
