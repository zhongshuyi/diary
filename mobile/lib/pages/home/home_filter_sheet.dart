import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/home_timeline_filter.dart';

class HomeFilterSheet extends StatefulWidget {
  const HomeFilterSheet({
    required this.initialFilter,
    required this.categories,
    required this.tags,
    required this.now,
    super.key,
  });

  final HomeTimelineFilter initialFilter;
  final List<String> categories;
  final List<String> tags;
  final DateTime now;

  @override
  State<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<HomeFilterSheet> {
  late HomeTimelineFilter _filter = widget.initialFilter;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .72,
      minChildSize: .45,
      maxChildSize: .92,
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
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
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
                    const SizedBox(height: 20),
                    _SectionTitle('时间'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DateChip(
                          label: '全部时间',
                          selected:
                              _filter.dateFilter.preset == HomeDatePreset.all,
                          onSelected: () =>
                              _setDate(const HomeDateFilter.all()),
                        ),
                        _DateChip(
                          key: const Key('home-filter-date-today'),
                          label: '今天',
                          selected:
                              _filter.dateFilter.preset == HomeDatePreset.today,
                          onSelected: () => _setDate(
                            const HomeDateFilter.preset(HomeDatePreset.today),
                          ),
                        ),
                        _DateChip(
                          key: const Key('home-filter-date-last-seven-days'),
                          label: '近 7 天',
                          selected:
                              _filter.dateFilter.preset ==
                              HomeDatePreset.lastSevenDays,
                          onSelected: () => _setDate(
                            const HomeDateFilter.preset(
                              HomeDatePreset.lastSevenDays,
                            ),
                          ),
                        ),
                        _DateChip(
                          key: const Key('home-filter-date-this-month'),
                          label: '本月',
                          selected:
                              _filter.dateFilter.preset ==
                              HomeDatePreset.thisMonth,
                          onSelected: () => _setDate(
                            const HomeDateFilter.preset(
                              HomeDatePreset.thisMonth,
                            ),
                          ),
                        ),
                        _DateChip(
                          key: const Key('home-filter-date-this-year'),
                          label: '今年',
                          selected:
                              _filter.dateFilter.preset ==
                              HomeDatePreset.thisYear,
                          onSelected: () => _setDate(
                            const HomeDateFilter.preset(
                              HomeDatePreset.thisYear,
                            ),
                          ),
                        ),
                        _DateChip(
                          key: const Key('home-filter-date-custom'),
                          label: '自定义日期',
                          selected:
                              _filter.dateFilter.preset ==
                              HomeDatePreset.custom,
                          onSelected: _pickCustomDateRange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SwitchListTile.adaptive(
                      key: const Key('home-favorites-filter'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('只看收藏'),
                      subtitle: const Text('隐藏未收藏的日记'),
                      value: _filter.favoriteOnly,
                      onChanged: (value) => setState(
                        () => _filter = _filter.copyWith(favoriteOnly: value),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SectionTitle('心情'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChoiceChip(
                          label: '全部心情',
                          selected: _filter.moodFilter == HomeMoodFilter.all,
                          onSelected: () => _setMood(HomeMoodFilter.all),
                        ),
                        _ChoiceChip(
                          key: const Key('home-filter-mood-low'),
                          label: '低落',
                          selected: _filter.moodFilter == HomeMoodFilter.low,
                          onSelected: () => _setMood(HomeMoodFilter.low),
                        ),
                        _ChoiceChip(
                          key: const Key('home-filter-mood-calm'),
                          label: '平静',
                          selected: _filter.moodFilter == HomeMoodFilter.calm,
                          onSelected: () => _setMood(HomeMoodFilter.calm),
                        ),
                        _ChoiceChip(
                          key: const Key('home-filter-mood-bright'),
                          label: '愉悦',
                          selected: _filter.moodFilter == HomeMoodFilter.bright,
                          onSelected: () => _setMood(HomeMoodFilter.bright),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle('媒体'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ChoiceChip(
                          label: '全部媒体',
                          selected: _filter.mediaFilter == HomeMediaFilter.all,
                          onSelected: () => _setMedia(HomeMediaFilter.all),
                        ),
                        _ChoiceChip(
                          key: const Key('home-filter-media-any'),
                          label: '有任意媒体',
                          selected:
                              _filter.mediaFilter == HomeMediaFilter.anyMedia,
                          onSelected: () => _setMedia(HomeMediaFilter.anyMedia),
                        ),
                        _ChoiceChip(
                          key: const Key('home-filter-media-image'),
                          label: '仅图片',
                          selected:
                              _filter.mediaFilter == HomeMediaFilter.image,
                          onSelected: () => _setMedia(HomeMediaFilter.image),
                        ),
                        _ChoiceChip(
                          key: const Key('home-filter-media-audio'),
                          label: '仅音频',
                          selected:
                              _filter.mediaFilter == HomeMediaFilter.audio,
                          onSelected: () => _setMedia(HomeMediaFilter.audio),
                        ),
                        _ChoiceChip(
                          key: const Key('home-filter-media-video'),
                          label: '仅视频',
                          selected:
                              _filter.mediaFilter == HomeMediaFilter.video,
                          onSelected: () => _setMedia(HomeMediaFilter.video),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SectionTitle('分类'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in widget.categories)
                          _ChoiceChip(
                            label: category,
                            selected: _filter.category == category,
                            onSelected: () => setState(
                              () => _filter = _filter.copyWith(
                                category: category,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.tags.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _SectionTitle('标签'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final tag in widget.tags)
                            FilterChip(
                              label: Text('#$tag'),
                              selected: _filter.tags.contains(tag),
                              onSelected: (_) => _toggleTag(tag),
                              showCheckmark: false,
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
                      key: const Key('home-filter-clear'),
                      onPressed: () =>
                          setState(() => _filter = _filter.clearConditions()),
                      child: const Text('清除条件'),
                    ),
                    const Spacer(),
                    FilledButton(
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

  void _setDate(HomeDateFilter value) {
    setState(() => _filter = _filter.copyWith(dateFilter: value));
  }

  void _setMood(HomeMoodFilter value) {
    setState(() => _filter = _filter.copyWith(moodFilter: value));
  }

  void _setMedia(HomeMediaFilter value) {
    setState(() => _filter = _filter.copyWith(mediaFilter: value));
  }

  void _toggleTag(String tag) {
    final tags = Set<String>.of(_filter.tags);
    if (!tags.add(tag)) tags.remove(tag);
    setState(() => _filter = _filter.copyWith(tags: tags));
  }

  Future<void> _pickCustomDateRange() async {
    final now = widget.now;
    final existing = _filter.dateFilter;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: existing.preset == HomeDatePreset.custom
          ? DateTimeRange(start: existing.start!, end: existing.end!)
          : DateTimeRange(start: now, end: now),
    );
    if (!mounted || picked == null) return;
    _setDate(HomeDateFilter.custom(picked.start, picked.end));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: Theme.of(context).textTheme.titleMedium);
}

class _DateChip extends _ChoiceChip {
  const _DateChip({
    super.key,
    required super.label,
    required super.selected,
    required super.onSelected,
  });
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: colors.hero,
      backgroundColor: colors.surface,
      side: BorderSide(color: selected ? colors.hero : colors.line),
      labelStyle: TextStyle(
        color: selected ? colors.onHero : colors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
      showCheckmark: false,
    );
  }
}
