import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/application/home_timeline_filter.dart';
import 'package:diary/application/timeline_reflection.dart';
import 'package:diary/application/weekly_summary.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/sync_state.dart';
import 'package:diary/pages/home/home_filter_sheet.dart';
import 'package:diary/pages/home/timeline_reflection_section.dart';
import 'package:diary/widgets/day_entry_card.dart';
import 'package:diary/widgets/entry_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.entries,
    required this.onOpenEditor,
    required this.onOpenEntry,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onDelete,
    required this.onQuickCapture,
    this.onBatchFavorite,
    this.onBatchDelete,
    this.syncState = const SyncState(),
    this.onSyncNow,
    this.desktopLayout = false,
    super.key,
  });

  final List<DiaryEntry> entries;
  final VoidCallback onOpenEditor;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final ValueChanged<DiaryEntry> onToggleFavorite;
  final ValueChanged<DiaryEntry> onShare;
  final ValueChanged<DiaryEntry> onDelete;
  final Future<void> Function(String content) onQuickCapture;
  final Future<void> Function(Iterable<String> ids, bool value)?
  onBatchFavorite;
  final Future<void> Function(Iterable<String> ids)? onBatchDelete;
  final SyncState syncState;
  final Future<void> Function()? onSyncNow;
  final bool desktopLayout;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final _quickController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _quickFocusNode = FocusNode();
  HomeTimelineFilter _filter = HomeTimelineFilter();
  int _randomRotation = 0;
  bool _quickSaving = false;
  bool _selectionMode = false;
  final Set<String> _selectedIds = <String>{};
  final Set<DateTime> _toggledDays = <DateTime>{};
  List<DiaryEntry>? _overviewSource;
  DateTime? _overviewDay;
  ({
    TimelineReflection reflection,
    WeeklySummary? weeklySummary,
    List<String> categories,
    List<String> tags,
  })?
  _overview;

  void focusSearch() {
    _searchFocusNode.requestFocus();
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _quickController.dispose();
    _searchFocusNode.dispose();
    _quickFocusNode.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters => _filter.hasActiveConditions;

  Future<void> _openFilters() async {
    final overview = _overviewFor(DateTime.now());
    final result = await showModalBottomSheet<HomeTimelineFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => HomeFilterSheet(
        initialFilter: _filter,
        categories: overview.categories,
        tags: overview.tags,
        now: DateTime.now(),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _filter = result);
  }

  List<DiaryEntry> get _filteredEntries {
    final now = DateTime.now();
    return widget.entries
        .where((entry) => _filter.matches(entry, now: now))
        .toList(growable: false);
  }

  ({
    TimelineReflection reflection,
    WeeklySummary? weeklySummary,
    List<String> categories,
    List<String> tags,
  })
  _overviewFor(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    if (!identical(_overviewSource, widget.entries) || _overviewDay != day) {
      _overviewSource = widget.entries;
      _overviewDay = day;
      _overview = (
        reflection: calculateTimelineReflection(
          entries: widget.entries,
          now: now,
        ),
        weeklySummary: calculateWeeklySummary(
          entries: widget.entries,
          now: now,
        ),
        categories: _sortedCategories(widget.entries),
        tags: _sortedTags(widget.entries),
      );
    }
    return _overview!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final entries = _filteredEntries;
    final overview = _overviewFor(DateTime.now());
    final categories = overview.categories;
    final tags = overview.tags;
    if (widget.desktopLayout) {
      return _buildDesktop(context, entries, categories, tags);
    }
    return _buildMobile(
      context,
      entries,
      categories,
      tags,
      colors,
      overview.reflection,
      overview.weeklySummary,
    );
  }

  Widget _buildMobile(
    BuildContext context,
    List<DiaryEntry> entries,
    List<String> categories,
    List<String> tags,
    DiaryThemeColors colors,
    TimelineReflection reflection,
    WeeklySummary? weeklySummary,
  ) {
    final dayGroups = entries.isEmpty
        ? <Widget>[]
        : _buildMobileDayGroups(entries);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSize(
                      duration: DiaryMotion.duration(
                        context,
                        DiaryMotion.standard,
                      ),
                      curve: DiaryMotion.curve(context, Curves.easeOutCubic),
                      alignment: Alignment.topCenter,
                      child: _selectionMode
                          ? _SelectionToolbar(
                              count: _selectedIds.length,
                              onFavorite: widget.onBatchFavorite == null
                                  ? null
                                  : () async {
                                      await widget.onBatchFavorite!(
                                        _selectedIds,
                                        true,
                                      );
                                      if (mounted) {
                                        setState(() {
                                          _selectionMode = false;
                                          _selectedIds.clear();
                                        });
                                      }
                                    },
                              onDelete: widget.onBatchDelete == null
                                  ? null
                                  : () async {
                                      await widget.onBatchDelete!(_selectedIds);
                                      if (mounted) {
                                        setState(() {
                                          _selectionMode = false;
                                          _selectedIds.clear();
                                        });
                                      }
                                    },
                              onClose: () => setState(() {
                                _selectionMode = false;
                                _selectedIds.clear();
                              }),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _Header(
                            onOpenEditor: widget.onOpenEditor,
                            showAction: false,
                          ),
                        ),
                        _SyncIndicator(
                          state: widget.syncState,
                          onSyncNow: widget.onSyncNow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '最近的日记',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${widget.entries.length} 个被你认真生活过的瞬间',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(
                            () => _filter = _filter.copyWith(
                              favoriteOnly: !_filter.favoriteOnly,
                            ),
                          ),
                          tooltip: '只看收藏',
                          icon: Icon(
                            _filter.favoriteOnly
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: _filter.favoriteOnly
                                ? colors.terracotta
                                : colors.mutedInk,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      key: const Key('diary-search-field'),
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: (value) => setState(
                        () => _filter = _filter.copyWith(query: value),
                      ),
                      decoration: InputDecoration(
                        hintText: '搜索标题、正文、分类或标签',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                key: const Key('diary-search-clear'),
                                tooltip: '清除搜索',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(
                                    () => _filter = _filter.copyWith(query: ''),
                                  );
                                  _searchFocusNode.requestFocus();
                                },
                                icon: const Icon(Icons.close_rounded, size: 18),
                              ),
                            _filter.advancedFilterCount > 0
                                ? Badge(
                                    label: Text(
                                      '${_filter.advancedFilterCount}',
                                    ),
                                    child: _buildFilterButton(colors),
                                  )
                                : _buildFilterButton(colors),
                          ],
                        ),
                      ),
                    ),
                    if (!_filter.hidesReflections &&
                        (reflection.featuredOnThisDay != null ||
                            reflection.randomEntryAt(_randomRotation) != null ||
                            weeklySummary != null)) ...[
                      const SizedBox(height: 12),
                      TimelineReflectionSection(
                        reflection: reflection,
                        weeklySummary: weeklySummary,
                        randomRotation: _randomRotation,
                        onOpenEntry: widget.onOpenEntry,
                        onRotateRandom: () =>
                            setState(() => _randomRotation += 1),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          final selected = category == _filter.category;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: selected,
                              onSelected: (_) => setState(
                                () => _filter = _filter.copyWith(
                                  category: category,
                                ),
                              ),
                              selectedColor: colors.hero,
                              labelStyle: TextStyle(
                                color: selected ? colors.onHero : colors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide(
                                color: selected ? colors.hero : colors.line,
                              ),
                              backgroundColor: colors.surface,
                              showCheckmark: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _TagFilters(
                        tags: tags,
                        selected: _filter.tags,
                        onToggle: _toggleTag,
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (entries.isEmpty)
                      _EmptyState(
                        query: _filter.query,
                        onOpenEditor: widget.onOpenEditor,
                        onClearFilters: _filter.hasActiveConditions
                            ? () => setState(
                                () => _filter = _filter.clearConditions(),
                              )
                            : null,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (dayGroups.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
            sliver: SliverList.builder(
              itemCount: dayGroups.length,
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: dayGroups[index],
                ),
              ),
            ),
          )
        else
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }

  Widget _buildFilterButton(DiaryThemeColors colors) {
    return IconButton(
      tooltip: '筛选',
      onPressed: _openFilters,
      icon: Icon(
        _hasActiveFilters ? Icons.filter_alt : Icons.tune,
        color: _hasActiveFilters ? colors.terracotta : colors.mutedInk,
      ),
    );
  }

  void _toggleTag(String tag) {
    final tags = Set<String>.of(_filter.tags);
    if (!tags.add(tag)) tags.remove(tag);
    setState(() => _filter = _filter.copyWith(tags: tags));
  }

  void _toggleMobileSelection(DiaryEntry entry) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.add(entry.id)) _selectedIds.remove(entry.id);
      _selectionMode = _selectedIds.isNotEmpty;
    });
  }

  Widget _buildDesktop(
    BuildContext context,
    List<DiaryEntry> entries,
    List<String> categories,
    List<String> tags,
  ) {
    final colors = DiaryThemeColors.of(context);
    final today = DateTime.now();
    final todayEntries = widget.entries
        .where(
          (entry) =>
              entry.effectiveOccurredAt.year == today.year &&
              entry.effectiveOccurredAt.month == today.month &&
              entry.effectiveOccurredAt.day == today.day,
        )
        .toList(growable: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(34, 30, 34, 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1220),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Header(onOpenEditor: widget.onOpenEditor)),
                  const SizedBox(width: 24),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenEditor,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('新建日记  Ctrl + N'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '最近的日记',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${widget.entries.length} 个被你认真生活过的瞬间',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(
                                () => _filter = _filter.copyWith(
                                  favoriteOnly: !_filter.favoriteOnly,
                                ),
                              ),
                              tooltip: '只看收藏',
                              icon: Icon(
                                _filter.favoriteOnly
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: _filter.favoriteOnly
                                    ? colors.terracotta
                                    : colors.mutedInk,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          key: const Key('diary-search-field'),
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: (value) => setState(
                            () => _filter = _filter.copyWith(query: value),
                          ),
                          decoration: const InputDecoration(
                            hintText: '搜索标题、正文、分类或标签（Ctrl + K）',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CategoryFilters(
                          categories: categories,
                          selected: _filter.category,
                          onSelected: (category) => setState(
                            () =>
                                _filter = _filter.copyWith(category: category),
                          ),
                        ),
                        if (tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _TagFilters(
                            tags: tags,
                            selected: _filter.tags,
                            onToggle: _toggleTag,
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (entries.isEmpty)
                          _EmptyState(
                            query: _filter.query,
                            onOpenEditor: widget.onOpenEditor,
                          )
                        else
                          ..._buildEntryGroups(context, entries),
                      ],
                    ),
                  ),
                  const SizedBox(width: 26),
                  SizedBox(
                    width: 300,
                    child: _DesktopQuickPanel(
                      todayEntries: todayEntries,
                      controller: _quickController,
                      focusNode: _quickFocusNode,
                      saving: _quickSaving,
                      onSubmit: _submitQuickCapture,
                      onOpenEditor: widget.onOpenEditor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitQuickCapture() async {
    final content = _quickController.text.trim();
    if (content.isEmpty || _quickSaving) {
      _quickFocusNode.requestFocus();
      return;
    }
    setState(() => _quickSaving = true);
    try {
      await widget.onQuickCapture(content);
      if (mounted) {
        _quickController.clear();
        _quickFocusNode.unfocus();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('暂时没记下来，请再试一次')));
      }
    } finally {
      if (mounted) setState(() => _quickSaving = false);
    }
  }

  List<Widget> _buildMobileDayGroups(List<DiaryEntry> entries) {
    final sorted = List<DiaryEntry>.of(entries)
      ..sort((a, b) {
        final byTime = b.effectiveOccurredAt.compareTo(a.effectiveOccurredAt);
        return byTime != 0 ? byTime : a.id.compareTo(b.id);
      });
    final days = <DateTime, List<DiaryEntry>>{};
    for (final entry in sorted) {
      final local = entry.effectiveOccurredAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      days.putIfAbsent(day, () => []).add(entry);
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final filtering = _filter.hidesReflections;
    return [
      for (final day in days.keys)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: DayEntryCard(
            date: day,
            entries: days[day]!,
            expanded:
                filtering ||
                (day == today
                    ? !_toggledDays.contains(day)
                    : _toggledDays.contains(day)),
            showExpandControl: !filtering,
            onToggleExpanded: () => setState(() {
              if (!_toggledDays.add(day)) _toggledDays.remove(day);
            }),
            onOpenEntry: (entry) => _selectionMode
                ? _toggleMobileSelection(entry)
                : widget.onOpenEntry(entry),
            onLongPressEntry: _toggleMobileSelection,
            onFavorite: widget.onToggleFavorite,
            onShare: widget.onShare,
            onDelete: widget.onDelete,
            selectedIds: _selectedIds,
            selectionMode: _selectionMode,
          ),
        ),
    ];
  }

  List<Widget> _buildEntryGroups(
    BuildContext context,
    List<DiaryEntry> entries,
  ) {
    final result = <Widget>[];
    DateTime? currentDay;
    for (final entry in entries) {
      final occurred = entry.effectiveOccurredAt;
      final entryDay = DateTime(occurred.year, occurred.month, occurred.day);
      if (currentDay == null || currentDay != entryDay) {
        currentDay = entryDay;
        result.add(_DateMarker(date: entryDay));
      }
      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DiaryEntryCard(
            entry: entry,
            onTap: () => _selectionMode
                ? setState(() {
                    if (!_selectedIds.add(entry.id)) {
                      _selectedIds.remove(entry.id);
                    }
                  })
                : widget.onOpenEntry(entry),
            onLongPress: () => setState(() {
              _selectionMode = true;
              if (!_selectedIds.add(entry.id)) _selectedIds.remove(entry.id);
            }),
            selected: _selectedIds.contains(entry.id),
            onFavorite: () => widget.onToggleFavorite(entry),
            onShare: () => widget.onShare(entry),
            onDelete: () => widget.onDelete(entry),
          ),
        ),
      );
    }
    return result;
  }
}

class _CategoryFilters extends StatelessWidget {
  const _CategoryFilters({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) => onSelected(category),
              selectedColor: colors.hero,
              labelStyle: TextStyle(
                color: isSelected ? colors.onHero : colors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(color: isSelected ? colors.hero : colors.line),
              backgroundColor: colors.surface,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TagFilters extends StatelessWidget {
  const _TagFilters({
    required this.tags,
    required this.selected,
    required this.onToggle,
  });

  final List<String> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags
            .map((tag) {
              final isSelected = selected.contains(tag);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text('#$tag'),
                  selected: isSelected,
                  onSelected: (_) => onToggle(tag),
                  showCheckmark: false,
                  selectedColor: colors.sage,
                  backgroundColor: colors.surface,
                  side: BorderSide(
                    color: isSelected ? colors.sage : colors.line,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? colors.ink : colors.mutedInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

List<String> _sortedTags(List<DiaryEntry> entries) {
  final usage = <String, _Usage>{};
  for (final entry in entries.where(
    (item) => !item.isInTrash && !item.isConflict,
  )) {
    for (final tag in entry.tags) {
      final old = usage[tag];
      usage[tag] = _Usage(
        (old?.count ?? 0) + 1,
        _latestDate(old?.latest, entry.effectiveOccurredAt),
      );
    }
  }
  final values = usage.keys.toList();
  values.sort((a, b) {
    final left = usage[a]!;
    final right = usage[b]!;
    return right.count.compareTo(left.count) != 0
        ? right.count.compareTo(left.count)
        : right.latest.compareTo(left.latest) != 0
        ? right.latest.compareTo(left.latest)
        : a.compareTo(b);
  });
  return values;
}

List<String> _sortedCategories(List<DiaryEntry> entries) {
  final usage = <String, _Usage>{};
  final categories = <String>{'全部'};
  for (final entry in entries) {
    categories.add(entry.category);
    if (entry.isInTrash) continue;
    final old = usage[entry.category];
    usage[entry.category] = _Usage(
      (old?.count ?? 0) + 1,
      _latestDate(old?.latest, entry.effectiveOccurredAt),
    );
  }
  return categories.toList()..sort((a, b) {
    if (a == '全部') return -1;
    if (b == '全部') return 1;
    final countCompare = (usage[b]?.count ?? 0).compareTo(usage[a]?.count ?? 0);
    if (countCompare != 0) return countCompare;
    final latestCompare = (usage[b]?.latest ?? DateTime(1970)).compareTo(
      usage[a]?.latest ?? DateTime(1970),
    );
    return latestCompare != 0 ? latestCompare : a.compareTo(b);
  });
}

DateTime _latestDate(DateTime? old, DateTime next) =>
    old == null || next.isAfter(old) ? next : old;

class _Usage {
  const _Usage(this.count, this.latest);
  final int count;
  final DateTime latest;
}

class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator({required this.state, this.onSyncNow});

  final SyncState state;
  final Future<void> Function()? onSyncNow;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final (label, icon, tint) = switch (state.status) {
      SyncStatus.syncing => ('同步中', Icons.sync, colors.terracotta),
      SyncStatus.synced => ('已同步', Icons.cloud_done_outlined, colors.sage),
      SyncStatus.pending => (
        '待同步',
        Icons.cloud_upload_outlined,
        colors.terracotta,
      ),
      SyncStatus.conflict => (
        '有冲突',
        Icons.warning_amber_outlined,
        colors.terracotta,
      ),
      SyncStatus.failed => (
        '同步失败',
        Icons.cloud_off_outlined,
        colors.terracotta,
      ),
      SyncStatus.idle => ('本地优先', Icons.cloud_outlined, colors.mutedInk),
    };
    return Tooltip(
      message: onSyncNow == null ? label : '$label · 点击立即同步',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onSyncNow == null ? null : () => onSyncNow!(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 17, color: tint),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.count,
    required this.onFavorite,
    required this.onDelete,
    required this.onClose,
  });

  final int count;
  final VoidCallback? onFavorite;
  final VoidCallback? onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
            Text('已选择 $count 篇', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            IconButton(
              onPressed: count == 0 ? null : onFavorite,
              tooltip: '收藏',
              icon: const Icon(Icons.bookmark_add_outlined),
            ),
            IconButton(
              onPressed: count == 0 ? null : onDelete,
              tooltip: '移入回收站',
              color: colors.terracotta,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCaptureBar extends StatelessWidget {
  const _QuickCaptureBar({
    required this.controller,
    required this.focusNode,
    required this.saving,
    required this.compact,
    required this.onSubmit,
    required this.onOpenEditor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool saving;
  final bool compact;
  final VoidCallback onSubmit;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(15, compact ? 16 : 13, 12, 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_outlined, size: 18, color: colors.terracotta),
              const SizedBox(width: 7),
              Text('快速记一句', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                compact ? '一条就是一个瞬间' : '不用标题，想到就记',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('quick-capture-field'),
            controller: controller,
            focusNode: focusNode,
            minLines: compact ? 4 : 1,
            maxLines: compact ? 8 : 4,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 4),
              hintText: '此刻想到什么？先写下来……',
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: onOpenEditor,
                tooltip: '添加图片或打开完整编辑器',
                icon: Icon(
                  Icons.add_photo_alternate_outlined,
                  color: colors.mutedInk,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: saving ? null : onSubmit,
                icon: saving
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_upward, size: 17),
                label: Text(saving ? '保存中' : '记下'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopQuickPanel extends StatelessWidget {
  const _DesktopQuickPanel({
    required this.todayEntries,
    required this.controller,
    required this.focusNode,
    required this.saving,
    required this.onSubmit,
    required this.onOpenEditor,
  });

  final List<DiaryEntry> todayEntries;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool saving;
  final VoidCallback onSubmit;
  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
          decoration: BoxDecoration(
            color: colors.hero,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TODAY / ${today.month}.${today.day}',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.butter),
              ),
              const SizedBox(height: 11),
              Text(
                todayEntries.isEmpty
                    ? '今天还没有留下文字'
                    : '今天已经记下 ${todayEntries.length} 个瞬间',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: colors.onHero),
              ),
              const SizedBox(height: 7),
              Text(
                '不必等到晚上，任何时刻都值得被留下。',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onHero.withValues(alpha: .72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _QuickCaptureBar(
          controller: controller,
          focusNode: focusNode,
          saving: saving,
          compact: true,
          onSubmit: onSubmit,
          onOpenEditor: onOpenEditor,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onOpenEditor,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(46),
          ),
          icon: const Icon(Icons.edit_note_outlined, size: 18),
          label: const Text('打开完整编辑器 · 图片 / 标签 / 情绪'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onOpenEditor, this.showAction = true});

  final VoidCallback onOpenEditor;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.hero,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.auto_stories_outlined, color: colors.onHero),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MY / DIARY',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.terracotta),
              ),
              const SizedBox(height: 3),
              Text('把今天留给自己', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        if (showAction)
          IconButton(
            onPressed: onOpenEditor,
            tooltip: '写一篇',
            icon: Icon(Icons.add_circle_outline, color: colors.terracotta),
          ),
      ],
    );
  }
}

class _DateMarker extends StatelessWidget {
  const _DateMarker({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 8, 3, 10),
      child: Row(
        children: [
          Text(
            diaryDateLabel(date),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.query,
    required this.onOpenEditor,
    this.onClearFilters,
  });

  final String query;
  final VoidCallback onOpenEditor;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Icon(Icons.edit_note, size: 36, color: colors.terracotta),
          const SizedBox(height: 10),
          Text(
            query.isEmpty ? '还没有符合筛选的日记' : '没有找到“$query”',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text('给今天留下一句话吧。', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (onClearFilters != null)
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('清除筛选条件'),
                ),
              OutlinedButton(
                onPressed: onOpenEditor,
                child: const Text('写下第一句'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
