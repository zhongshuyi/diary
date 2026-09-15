import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/entry_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    required this.entries,
    required this.onOpenEditor,
    required this.onOpenEntry,
    required this.onToggleFavorite,
    required this.onShare,
    required this.onDelete,
    super.key,
  });

  final List<DiaryEntry> entries;
  final VoidCallback onOpenEditor;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final ValueChanged<DiaryEntry> onToggleFavorite;
  final ValueChanged<DiaryEntry> onShare;
  final ValueChanged<DiaryEntry> onDelete;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _category = '全部';
  bool _onlyFavorites = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DiaryEntry> get _filteredEntries {
    return widget.entries
        .where((entry) {
          final categoryMatch =
              _category == '全部' || entry.category == _category;
          final favoriteMatch = !_onlyFavorites || entry.isFavorite;
          return categoryMatch && favoriteMatch && entry.matches(_query);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final entries = _filteredEntries;
    final categories = <String>{
      '全部',
      ...widget.entries.map((entry) => entry.category),
    }.toList(growable: false);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onOpenEditor: widget.onOpenEditor),
              const SizedBox(height: 25),
              _WritingPrompt(onOpenEditor: widget.onOpenEditor),
              const SizedBox(height: 28),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '最近的日记',
                          style: Theme.of(context).textTheme.headlineSmall,
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
                    onPressed: () =>
                        setState(() => _onlyFavorites = !_onlyFavorites),
                    tooltip: '只看收藏',
                    icon: Icon(
                      _onlyFavorites ? Icons.bookmark : Icons.bookmark_border,
                      color: _onlyFavorites
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
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: '搜索标题、正文、分类或标签',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: Icon(Icons.tune),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((category) {
                    final selected = category == _category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) => setState(() => _category = category),
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
              const SizedBox(height: 18),
              if (entries.isEmpty)
                _EmptyState(query: _query, onOpenEditor: widget.onOpenEditor)
              else
                ..._buildEntryGroups(context, entries),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEntryGroups(
    BuildContext context,
    List<DiaryEntry> entries,
  ) {
    final result = <Widget>[];
    DateTime? currentDay;
    for (final entry in entries) {
      final entryDay = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      if (currentDay == null || currentDay != entryDay) {
        currentDay = entryDay;
        result.add(_DateMarker(date: entryDay));
      }
      result.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DiaryEntryCard(
            entry: entry,
            onTap: () => widget.onOpenEntry(entry),
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

class _Header extends StatelessWidget {
  const _Header({required this.onOpenEditor});

  final VoidCallback onOpenEditor;

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
        IconButton(
          onPressed: onOpenEditor,
          tooltip: '写一篇',
          icon: Icon(Icons.add_circle_outline, color: colors.terracotta),
        ),
      ],
    );
  }
}

class _WritingPrompt extends StatelessWidget {
  const _WritingPrompt({required this.onOpenEditor});

  final VoidCallback onOpenEditor;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 19),
      decoration: BoxDecoration(
        color: colors.hero,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TODAY, FOR YOURSELF',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: colors.butter),
                ),
                const SizedBox(height: 11),
                Text(
                  '今天，写给自己',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(color: colors.onHero),
                ),
                const SizedBox(height: 6),
                Text(
                  '不需要完整，也不需要漂亮。想到什么，就写下什么。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onHero.withValues(alpha: .72),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: onOpenEditor,
            style: FilledButton.styleFrom(
              backgroundColor: colors.butter,
              foregroundColor: colors.hero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            ),
            child: const Text('写一篇'),
          ),
        ],
      ),
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
  const _EmptyState({required this.query, required this.onOpenEditor});

  final String query;
  final VoidCallback onOpenEditor;

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
          OutlinedButton(onPressed: onOpenEditor, child: const Text('写下第一句')),
        ],
      ),
    );
  }
}
