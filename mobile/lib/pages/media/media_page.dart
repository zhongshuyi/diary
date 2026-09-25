import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_video_player.dart';
import 'package:diary/widgets/local_media_preview.dart';
import 'package:diary/widgets/page_intro.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({
    required this.entries,
    required this.onOpenEntry,
    super.key,
  });

  final List<DiaryEntry> entries;
  final ValueChanged<DiaryEntry> onOpenEntry;

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  final _searchController = TextEditingController();
  DiaryMediaKind? _filter;
  String _query = '';
  late List<_MediaItem> _allItems;

  List<_MediaItem> _collectItems(List<DiaryEntry> entries) {
    final result = <_MediaItem>[];
    for (final entry in entries) {
      if (entry.isStandaloneLocation) continue;
      for (final path in entry.imagePaths) {
        result.add(
          _MediaItem(
            entry: entry,
            path: path,
            kind: diaryMediaKindForPath(path),
          ),
        );
      }
      for (final path in entry.audioPaths) {
        result.add(
          _MediaItem(entry: entry, path: path, kind: DiaryMediaKind.audio),
        );
      }
      for (final path in entry.videoPaths) {
        result.add(
          _MediaItem(entry: entry, path: path, kind: DiaryMediaKind.video),
        );
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _allItems = _collectItems(widget.entries);
  }

  @override
  void didUpdateWidget(covariant MediaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.entries, widget.entries)) {
      _allItems = _collectItems(widget.entries);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _allItems
        .where(
          (item) =>
              (_filter == null || item.kind == _filter) && item.matches(_query),
        )
        .toList(growable: false);
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(980.0, constraints.maxWidth - 40);
        final horizontalPadding = math.max(
          20.0,
          (constraints.maxWidth - contentWidth) / 2,
        );
        final columns = contentWidth >= 720 ? 4 : 2;
        final header = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DiaryPageIntro(
              eyebrow: 'EVERYTHING YOU KEPT',
              title: '媒体库',
              description: '把图片、声音和文件放在一起，回到那一天。',
            ),
            const SizedBox(height: 20),
            _MediaSummary(items: _allItems),
            const SizedBox(height: 16),
            TextField(
              key: const Key('media-search-field'),
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: '搜索文件名、日记标题或内容',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '清除媒体搜索',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip(context, '全部', null),
                  for (final kind in DiaryMediaKind.values)
                    _filterChip(context, diaryMediaKindLabel(kind), kind),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              _EmptyMediaState(
                hasMedia: _allItems.isNotEmpty,
                hasQuery: _query.trim().isNotEmpty,
              )
            else
              const SizedBox(height: 0),
          ],
        );
        return CustomScrollView(
          cacheExtent: 500,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                28,
                horizontalPadding,
                items.isEmpty ? 110 : 16,
              ),
              sliver: SliverToBoxAdapter(child: header),
            ),
            if (items.isNotEmpty)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  110,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: .82,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MediaCard(
                      item: item,
                      onTap: () => widget.onOpenEntry(item.entry),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _filterChip(BuildContext context, String label, DiaryMediaKind? kind) {
    final colors = DiaryThemeColors.of(context);
    final selected = _filter == kind;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = kind),
        showCheckmark: false,
        selectedColor: colors.hero,
        backgroundColor: colors.surface,
        side: BorderSide(color: selected ? colors.hero : colors.line),
        labelStyle: TextStyle(
          color: selected ? colors.onHero : colors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MediaItem {
  _MediaItem({required this.entry, required this.path, required this.kind})
    : _searchableText = [
        path.split(RegExp(r'[\\/]')).last,
        entry.title,
        entry.contentText,
        entry.category,
        ...entry.tags,
      ].join(' ').toLowerCase();

  final DiaryEntry entry;
  final String path;
  final DiaryMediaKind kind;
  final String _searchableText;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return _searchableText.contains(normalized);
  }
}

class _MediaSummary extends StatelessWidget {
  const _MediaSummary({required this.items});

  final List<_MediaItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final imageCount = items
        .where((item) => item.kind == DiaryMediaKind.image)
        .length;
    final audioCount = items
        .where((item) => item.kind == DiaryMediaKind.audio)
        .length;
    final videoCount = items
        .where((item) => item.kind == DiaryMediaKind.video)
        .length;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.image_outlined,
            count: imageCount,
            label: '图片',
            tint: colors.sage,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.graphic_eq,
            count: audioCount,
            label: '声音',
            tint: colors.butter,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryCard(
            icon: Icons.movie_outlined,
            count: videoCount,
            label: '视频',
            tint: colors.terracottaSoft,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.count,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final int count;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: colors.ink),
          const SizedBox(width: 8),
          Text('$count', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 5),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({required this.item, required this.onTap});

  final _MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final colors = DiaryThemeColors.of(context);
        final fileName = item.path.split(RegExp(r'[\\/]')).last;
        final isImage = item.kind == DiaryMediaKind.image;
        final entryTitle = item.entry.title.trim();
        final entryContent = item.entry.contentText.trim();
        final imageTitle =
            entryTitle.isNotEmpty && entryTitle != '无题' && entryTitle != '此刻的照片'
            ? entryTitle
            : entryContent.isNotEmpty
            ? entryContent
            : '这一天的照片';
        final occurredAt = item.entry.effectiveOccurredAt.toLocal();
        final imageContext =
            '${occurredAt.year}年${occurredAt.month}月${occurredAt.day}日 · '
            '${item.entry.category.isEmpty ? '未分类' : item.entry.category}';
        final cacheWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                  .round()
            : null;
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: switch (item.kind) {
                    DiaryMediaKind.audio => Padding(
                      padding: const EdgeInsets.all(10),
                      child: DiaryAudioPlayer(
                        path: item.path,
                        label: '语音',
                        compact: true,
                        loadMetadata: false,
                        loadWaveform: false,
                      ),
                    ),
                    DiaryMediaKind.video => DiaryVideoPreview(
                      path: item.path,
                      label: '视频片段',
                      compact: true,
                    ),
                    _ => SizedBox.expand(
                      child: LocalMediaPreview(
                        path: item.path,
                        kind: item.kind,
                        showRetry: true,
                        cacheWidth: cacheWidth,
                      ),
                    ),
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        diaryMediaKindLabel(item.kind),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.terracotta,
                          letterSpacing: .3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isImage
                            ? imageTitle
                            : item.kind == DiaryMediaKind.audio
                            ? '语音'
                            : item.kind == DiaryMediaKind.video
                            ? '视频片段'
                            : fileName.isEmpty
                            ? '未命名附件'
                            : fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isImage ? imageContext : item.entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyMediaState extends StatelessWidget {
  const _EmptyMediaState({required this.hasMedia, required this.hasQuery});

  final bool hasMedia;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.collections_outlined,
              size: 38,
              color: colors.terracotta,
            ),
            const SizedBox(height: 12),
            Text(
              hasQuery
                  ? '没有找到匹配的附件'
                  : hasMedia
                  ? '这个筛选下还没有附件'
                  : '你的媒体库还是空的',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              '在日记里添加图片或文件，它们会自动出现在这里。',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
