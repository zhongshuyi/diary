import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diary/app/diary_shell.dart';
import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';
import 'package:diary/domain/sync_state.dart';
import 'package:diary/pages/calendar/calendar_page.dart';
import 'package:diary/pages/entry/quick_capture_sheet.dart';
import 'package:diary/pages/home/home_page.dart';
import 'package:diary/pages/insights/insights_page.dart';
import 'package:diary/pages/media/media_page.dart';
import 'package:diary/pages/profile/profile_page.dart';
import 'package:diary/widgets/diary_navigation.dart';

/// The phone shell keeps navigation close to the thumb and makes quick capture
/// the first-class action. It intentionally does not share the desktop shell's
/// navigation or window chrome.
class MobileDiaryShell extends StatefulWidget {
  const MobileDiaryShell({
    required this.entries,
    required this.trash,
    required this.actions,
    this.quickCaptureSide = QuickCaptureSide.right,
    this.conflictCount = 0,
    this.syncState = const SyncState(),
    this.onSyncNow,
    super.key,
  });

  final List<DiaryEntry> entries;
  final List<DiaryEntry> trash;
  final DiaryShellActions actions;
  final QuickCaptureSide quickCaptureSide;
  final int conflictCount;
  final SyncState syncState;
  final Future<void> Function()? onSyncNow;

  @override
  State<MobileDiaryShell> createState() => _MobileDiaryShellState();
}

class _MobileDiaryShellState extends State<MobileDiaryShell> {
  int _selectedIndex = 0;

  Future<void> _openQuickCapture() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: DiaryThemeColors.of(context).surface,
      builder: (_) => QuickCaptureSheet(
        onSave: widget.actions.saveQuickCaptureWithPhotos,
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
      CalendarPage(
        entries: widget.entries,
        onOpenEntry: (entry) => unawaited(widget.actions.openEntry(entry)),
      ),
      MediaPage(
        entries: widget.entries,
        onOpenEntry: (entry) => unawaited(widget.actions.openEntry(entry)),
      ),
      InsightsPage(entries: widget.entries),
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
      ),
    ];

    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: colors.paper,
        body: IndexedStack(index: _selectedIndex, children: pages),
        floatingActionButtonLocation:
            widget.quickCaptureSide == QuickCaptureSide.left
            ? FloatingActionButtonLocation.startFloat
            : FloatingActionButtonLocation.endFloat,
        floatingActionButton: FloatingActionButton.extended(
          key: const Key('mobile-quick-capture-fab'),
          onPressed: _openQuickCapture,
          backgroundColor: colors.terracotta,
          foregroundColor: colors.onHero,
          icon: const Icon(Icons.edit_note_outlined),
          label: const Text('速记'),
        ),
        bottomNavigationBar: DiaryBottomNavigation(
          selectedIndex: _selectedIndex,
          onSelected: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }
}
