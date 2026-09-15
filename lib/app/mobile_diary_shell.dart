import 'dart:async';

import 'package:flutter/material.dart';

import 'package:diary/app/diary_shell.dart';
import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/calendar/calendar_page.dart';
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
    super.key,
  });

  final List<DiaryEntry> entries;
  final List<DiaryEntry> trash;
  final DiaryShellActions actions;

  @override
  State<MobileDiaryShell> createState() => _MobileDiaryShellState();
}

class _MobileDiaryShellState extends State<MobileDiaryShell> {
  int _selectedIndex = 0;

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
      ),
    ];

    return Scaffold(
      backgroundColor: colors.paper,
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: DiaryBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
      ),
    );
  }
}
