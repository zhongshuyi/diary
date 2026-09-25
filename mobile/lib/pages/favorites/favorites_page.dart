import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/favorites_filter.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/entry_card.dart';
import 'package:diary/widgets/page_intro.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({
    required this.entriesListenable,
    required this.onOpenEntry,
    required this.onToggleFavorite,
    super.key,
  });

  final ValueListenable<List<DiaryEntry>> entriesListenable;
  final Future<void> Function(DiaryEntry entry) onOpenEntry;
  final Future<void> Function(DiaryEntry entry) onToggleFavorite;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _searchController = TextEditingController();
  FavoritesFilter _filter = FavoritesFilter();
  List<DiaryEntry>? _cachedSource;
  List<DiaryEntry> _cachedFavorites = const [];
  List<String> _cachedCategories = const [];
  List<String> _cachedTags = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<DiaryEntry>>(
      valueListenable: widget.entriesListenable,
      builder: (context, entries, _) {
        _updateFavoritesCache(entries);
        final saved = _cachedFavorites;
        final visible = _visibleEntries(saved);
        final categories = _cachedCategories;
        final tags = _cachedTags;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
          itemCount: visible.length + 1,
          itemBuilder: (context, index) {
            final entry = index == 0 ? null : visible[index - 1];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: index == 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DiaryPageIntro(
                            eyebrow: 'THE MOMENTS YOU KEPT',
                            title: '收藏夹',
                            description: saved.isEmpty
                                ? '把想反复读的日记留在这里。'
                                : '这里有 ${saved.length} 篇你想留住的日记。',
                          ),
                          const SizedBox(height: 18),
                          _FavoritesSummary(count: saved.length),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('favorites-search-field'),
                                  controller: _searchController,
                                  onChanged: (value) => setState(
                                    () => _filter = _filter.copyWith(
                                      query: value,
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '搜索收藏的日记',
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: _filter.query.trim().isEmpty
                                        ? null
                                        : IconButton(
                                            tooltip: '清除收藏搜索',
                                            onPressed: () {
                                              _searchController.clear();
                                              setState(
                                                () => _filter = _filter
                                                    .copyWith(query: ''),
                                              );
                                            },
                                            icon: const Icon(Icons.close),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filledTonal(
                                key: const Key('favorites-filter-button'),
                                tooltip: '筛选收藏',
                                onPressed: saved.isEmpty
                                    ? null
                                    : () => unawaited(
                                        _openFilter(
                                          categories: categories,
                                          tags: tags,
                                        ),
                                      ),
                                icon: Badge(
                                  isLabelVisible: _filter.hasActiveConditions,
                                  child: const Icon(Icons.tune_outlined),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (saved.isEmpty)
                            const _FavoritesEmptyState()
                          else if (visible.isEmpty)
                            _FilteredFavoritesEmptyState(
                              onClear: _clearConditions,
                            ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DiaryEntryCard(
                          key: ValueKey(entry!.id),
                          entry: entry,
                          onTap: () => unawaited(widget.onOpenEntry(entry)),
                          onFavorite: () => unawaited(_removeFavorite(entry)),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  void _updateFavoritesCache(List<DiaryEntry> entries) {
    if (identical(_cachedSource, entries)) return;
    _cachedSource = entries;
    _cachedFavorites = _allFavorites(entries);
    _cachedCategories = _categories(_cachedFavorites);
    _cachedTags = _tags(_cachedFavorites);
  }

  List<DiaryEntry> _allFavorites(List<DiaryEntry> entries) {
    final visibleFavorites = FavoritesFilter();
    return entries.where(visibleFavorites.matches).toList(growable: false)
      ..sort(
        (first, second) =>
            second.effectiveOccurredAt.compareTo(first.effectiveOccurredAt),
      );
  }

  List<DiaryEntry> _visibleEntries(List<DiaryEntry> favorites) =>
      favorites.where(_filter.matches).toList(growable: false);

  List<String> _categories(List<DiaryEntry> entries) {
    final categories = entries.map((entry) => entry.category).toSet().toList()
      ..sort();
    return ['全部', ...categories];
  }

  List<String> _tags(List<DiaryEntry> entries) {
    final tags = entries.expand((entry) => entry.tags).toSet().toList()..sort();
    return tags;
  }

  Future<void> _openFilter({
    required List<String> categories,
    required List<String> tags,
  }) async {
    final selected = await showModalBottomSheet<FavoritesFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FavoritesFilterSheet(
        initialFilter: _filter,
        categories: categories,
        tags: tags,
      ),
    );
    if (!mounted || selected == null) return;
    setState(() => _filter = selected);
  }

  void _clearConditions() {
    setState(() => _filter = _filter.clearConditions());
  }

  Future<void> _removeFavorite(DiaryEntry entry) async {
    try {
      await widget.onToggleFavorite(entry);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂时无法更新收藏，请稍后重试')));
    }
  }
}

class _FavoritesSummary extends StatelessWidget {
  const _FavoritesSummary({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.terracottaSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(Icons.bookmark_outline, color: colors.terracotta),
            ),
            const SizedBox(width: 12),
            Text('$count 篇已收藏', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('按日记日期', style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      key: const Key('favorites-empty'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.bookmark_border, color: colors.mutedInk),
            const SizedBox(width: 12),
            const Expanded(child: Text('看到特别想留住的日记时，点一下书签就会出现在这里。')),
          ],
        ),
      ),
    );
  }
}

class _FilteredFavoritesEmptyState extends StatelessWidget {
  const _FilteredFavoritesEmptyState({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      key: const Key('favorites-filtered-empty'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.search_off_outlined, color: colors.mutedInk),
            const SizedBox(width: 12),
            const Expanded(child: Text('没有符合当前搜索或筛选条件的收藏。')),
            TextButton(onPressed: onClear, child: const Text('清除条件')),
          ],
        ),
      ),
    );
  }
}

class _FavoritesFilterSheet extends StatefulWidget {
  const _FavoritesFilterSheet({
    required this.initialFilter,
    required this.categories,
    required this.tags,
  });

  final FavoritesFilter initialFilter;
  final List<String> categories;
  final List<String> tags;

  @override
  State<_FavoritesFilterSheet> createState() => _FavoritesFilterSheetState();
}

class _FavoritesFilterSheetState extends State<_FavoritesFilterSheet> {
  late FavoritesFilter _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .62,
      minChildSize: .42,
      maxChildSize: .9,
      builder: (context, scrollController) => Material(
        color: colors.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  children: [
                    Text(
                      '筛选收藏',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '按分类和标签找到想重读的片段。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Text('分类', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in widget.categories)
                          ChoiceChip(
                            label: Text(category),
                            selected: _filter.category == category,
                            showCheckmark: false,
                            onSelected: (_) => setState(
                              () => _filter = _filter.copyWith(
                                category: category,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.tags.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        '标签',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in widget.tags)
                            FilterChip(
                              label: Text('#$tag'),
                              selected: _filter.tags.contains(tag),
                              showCheckmark: false,
                              onSelected: (_) => _toggleTag(tag),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Divider(height: 1, color: colors.line),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  children: [
                    TextButton(
                      key: const Key('favorites-filter-clear'),
                      onPressed: () =>
                          setState(() => _filter = _filter.clearConditions()),
                      child: const Text('清除条件'),
                    ),
                    const Spacer(),
                    FilledButton(
                      key: const Key('favorites-filter-apply'),
                      onPressed: () => Navigator.of(context).pop(_filter),
                      child: const Text('应用筛选'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTag(String tag) {
    final tags = Set<String>.from(_filter.tags);
    if (!tags.add(tag)) tags.remove(tag);
    setState(() => _filter = _filter.copyWith(tags: tags));
  }
}
