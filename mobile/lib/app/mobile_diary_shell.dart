import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/app/diary_shell.dart';
import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/pages/calendar/calendar_page.dart';
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
    super.key,
  });

  final List<DiaryEntry> entries;
  final List<DiaryEntry> trash;
  final DiaryShellActions actions;

  @override
  State<MobileDiaryShell> createState() => _MobileDiaryShellState();
}

class _MobileDiaryShellState extends State<MobileDiaryShell> {
  static const _quickCaptureXKey = 'diary.mobile.quick_capture.x';
  static const _quickCaptureYKey = 'diary.mobile.quick_capture.y';

  int _selectedIndex = 0;
  Offset? _quickCapturePosition;

  @override
  void initState() {
    super.initState();
    _loadQuickCapturePosition();
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
        onOpenEditor: () => unawaited(widget.actions.openEditor()),
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
      body: Stack(
        children: [
          _AnimatedTabStack(index: _selectedIndex, pages: pages),
          DraggableQuickCaptureFab(
            initialPosition: _quickCapturePosition,
            onPositionChanged: (position) {
              unawaited(_saveQuickCapturePosition(position));
            },
            onSubmit: widget.actions.saveQuickCapture,
          ),
        ],
      ),
      bottomNavigationBar: DiaryBottomNavigation(
        selectedIndex: _selectedIndex,
        onSelected: (index) => setState(() => _selectedIndex = index),
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DiaryMotion.standard,
    )..value = 1;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = DiaryMotion.duration(context, DiaryMotion.standard);
  }

  @override
  void didUpdateWidget(covariant _AnimatedTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
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
      child: IndexedStack(index: widget.index, children: widget.pages),
      builder: (context, child) {
        final value = animation.value;
        return Opacity(
          opacity: .92 + (.08 * value),
          child: Transform.translate(
            offset: Offset(14 * (1 - value), 0),
            child: child,
          ),
        );
      },
    );
  }
}
