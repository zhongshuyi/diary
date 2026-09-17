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
    required this.onQuickCapture,
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
  final bool desktopLayout;

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final _quickController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _quickFocusNode = FocusNode();
  String _query = '';
  String _category = '全部';
  bool _onlyFavorites = false;
  bool _quickSaving = false;

  bool get _hasActiveFilters => _category != '全部' || _onlyFavorites;

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

  Future<void> _openFilters() async {
    var category = _category;
    var onlyFavorites = _onlyFavorites;
    final result = await showModalBottomSheet<_HomeFilterSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final colors = DiaryThemeColors.of(context);
          final categories = {
            '全部',
            ...widget.entries.map((entry) => entry.category),
          };
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '筛选日记',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '缩小范围，只看现在想回到的记录。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Text('分类', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final value in categories)
                        ChoiceChip(
                          label: Text(value),
                          selected: category == value,
                          onSelected: (_) =>
                              setSheetState(() => category = value),
                          selectedColor: colors.hero,
                          backgroundColor: colors.surface,
                          side: BorderSide(
                            color: category == value
                                ? colors.hero
                                : colors.line,
                          ),
                          labelStyle: TextStyle(
                            color: category == value
                                ? colors.onHero
                                : colors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                          showCheckmark: false,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    key: const Key('home-favorites-filter'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('只看收藏'),
                    subtitle: const Text('隐藏未收藏的日记'),
                    value: onlyFavorites,
                    onChanged: (value) =>
                        setSheetState(() => onlyFavorites = value),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setSheetState(() {
                          category = '全部';
                          onlyFavorites = false;
                        }),
                        child: const Text('清除条件'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(
                          context,
                          _HomeFilterSelection(
                            category: category,
                            onlyFavorites: onlyFavorites,
                          ),
                        ),
                        child: const Text('应用筛选'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (!mounted || result == null) return;
    setState(() {
      _category = result.category;
      _onlyFavorites = result.onlyFavorites;
    });
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
    final desktop =
        widget.desktopLayout || MediaQuery.sizeOf(context).width >= 900;
    if (desktop) {
      return _buildDesktop(context, entries, categories);
    }
    return _buildMobile(context, entries, categories, colors);
  }

  Widget _buildMobile(
    BuildContext context,
    List<DiaryEntry> entries,
    List<String> categories,
    DiaryThemeColors colors,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(onOpenEditor: widget.onOpenEditor),
              const SizedBox(height: 16),
              _WritingPrompt(onOpenEditor: widget.onOpenEditor),
              const SizedBox(height: 24),
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
                focusNode: _searchFocusNode,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: '搜索标题、正文、分类或标签',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: '筛选',
                    onPressed: _openFilters,
                    icon: Icon(
                      _hasActiveFilters ? Icons.filter_alt : Icons.tune,
                      color: _hasActiveFilters
                          ? colors.terracotta
                          : colors.mutedInk,
                    ),
                  ),
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

  Widget _buildDesktop(
    BuildContext context,
    List<DiaryEntry> entries,
    List<String> categories,
  ) {
    final colors = DiaryThemeColors.of(context);
    final today = DateTime.now();
    final todayEntries = widget.entries
        .where(
          (entry) =>
              entry.createdAt.year == today.year &&
              entry.createdAt.month == today.month &&
              entry.createdAt.day == today.day,
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
                                () => _onlyFavorites = !_onlyFavorites,
                              ),
                              tooltip: '只看收藏',
                              icon: Icon(
                                _onlyFavorites
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: _onlyFavorites
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
                          onChanged: (value) => setState(() => _query = value),
                          decoration: const InputDecoration(
                            hintText: '搜索标题、正文、分类或标签（Ctrl + K）',
                            prefixIcon: Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CategoryFilters(
                          categories: categories,
                          selected: _category,
                          onSelected: (category) =>
                              setState(() => _category = category),
                        ),
                        const SizedBox(height: 18),
                        if (entries.isEmpty)
                          _EmptyState(
                            query: _query,
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

class _HomeFilterSelection {
  const _HomeFilterSelection({
    required this.category,
    required this.onlyFavorites,
  });

  final String category;
  final bool onlyFavorites;
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
