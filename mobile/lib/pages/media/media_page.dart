import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/diary_audio_player.dart';
import 'package:diary/widgets/diary_image_viewer.dart';
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
  late _MediaCatalog _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = _MediaCatalog.fromEntries(widget.entries);
  }

  @override
  void didUpdateWidget(covariant MediaPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.entries, widget.entries)) {
      _catalog = _MediaCatalog.fromEntries(widget.entries);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final visible = _catalog.items
        .where(
          (item) =>
              (_filter == null || item.kind == _filter) &&
              item.matches(normalizedQuery),
        )
        .toList(growable: false);
    final photoAlbums = (_filter == null || _filter == DiaryMediaKind.image)
        ? _catalog.photoAlbums
              .where((album) => album.matches(normalizedQuery))
              .toList(growable: false)
        : const <_PhotoAlbum>[];
    final groups = {
      for (final kind in DiaryMediaKind.values) kind: <_MediaItem>[],
    };
    for (final item in visible) {
      groups[item.kind]!.add(item);
    }
    final matchedEntryCount = {
      for (final item in visible) item.entry.id,
    }.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = math.min(980.0, constraints.maxWidth - 40);
        final horizontalPadding = math.max(
          20.0,
          (constraints.maxWidth - contentWidth) / 2,
        );
        final columns = contentWidth >= 720
            ? 4
            : contentWidth >= 520
            ? 3
            : 2;
        final slivers = <Widget>[
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              28,
              horizontalPadding,
              12,
            ),
            sliver: SliverToBoxAdapter(
              child: _header(context, matchedEntryCount),
            ),
          ),
        ];
        if (visible.isEmpty && photoAlbums.isEmpty) {
          slivers.add(
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                110,
              ),
              sliver: SliverToBoxAdapter(
                child: _EmptyMediaState(
                  hasMedia: _catalog.items.isNotEmpty,
                  hasQuery: normalizedQuery.isNotEmpty,
                ),
              ),
            ),
          );
        } else {
          for (final kind in DiaryMediaKind.values) {
            final items = groups[kind]!;
            if (kind == DiaryMediaKind.image) {
              if (photoAlbums.isEmpty) continue;
              slivers.add(
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    12,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _AlbumSectionHeading(
                      albumCount: photoAlbums.length,
                      photoCount: photoAlbums.fold(
                        0,
                        (count, album) => count + album.photos.length,
                      ),
                    ),
                  ),
                ),
              );
              final albumsByMonth = <DateTime, List<_PhotoAlbum>>{};
              for (final album in photoAlbums) {
                final date = album.entry.effectiveOccurredAt.toLocal();
                final month = DateTime(date.year, date.month);
                albumsByMonth.putIfAbsent(month, () => []).add(album);
              }
              final months = albumsByMonth.keys.toList()
                ..sort((first, second) => second.compareTo(first));
              int? previousYear;
              for (final month in months) {
                final albums = albumsByMonth[month]!;
                slivers.add(
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      previousYear == month.year ? 24 : 32,
                      horizontalPadding,
                      12,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: _AlbumMonthHeading(
                        month: month,
                        showYear: previousYear != month.year,
                        albumCount: albums.length,
                        photoCount: albums.fold(
                          0,
                          (count, album) => count + album.photos.length,
                        ),
                      ),
                    ),
                  ),
                );
                previousYear = month.year;
                slivers.add(
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      0,
                      horizontalPadding,
                      12,
                    ),
                    sliver: SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 9,
                        mainAxisSpacing: 9,
                        childAspectRatio: 1,
                      ),
                      itemCount: albums.length,
                      itemBuilder: (context, index) {
                        final album = albums[index];
                        final initialIndex = album.initialIndexFor(
                          normalizedQuery,
                        );
                        return _PhotoTile(
                          album: album,
                          item: album.photos[initialIndex],
                          onPreview: () => showDiaryImageViewer(
                            context,
                            entryId: album.entry.id,
                            imagePaths: album.paths,
                            initialIndex: initialIndex,
                            heroScope: 'media-library',
                          ),
                          onOpenEntry: () => widget.onOpenEntry(album.entry),
                        );
                      },
                    ),
                  ),
                );
              }
              continue;
            }
            if (items.isEmpty) continue;
            slivers.add(
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  12,
                ),
                sliver: SliverToBoxAdapter(
                  child: _MediaSectionHeading(kind: kind, count: items.length),
                ),
              ),
            );
            slivers.add(
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  10,
                ),
                sliver: SliverList.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MediaRow(
                      item: items[index],
                      onOpenEntry: () => widget.onOpenEntry(items[index].entry),
                    ),
                  ),
                ),
              ),
            );
          }
          slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));
        }
        return CustomScrollView(cacheExtent: 500, slivers: slivers);
      },
    );
  }

  Widget _header(BuildContext context, int resultCount) {
    final colors = DiaryThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DiaryPageIntro(
          eyebrow: 'EVERYTHING YOU KEPT',
          title: '媒体库',
          description: '按年月翻看照片，点开一篇日记的全部画面。',
        ),
        const SizedBox(height: 13),
        Row(
          children: [
            Icon(
              Icons.collections_bookmark_outlined,
              size: 17,
              color: colors.terracotta,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${_catalog.entryCount} 篇有媒体的日记 · ${_catalog.items.length} 个附件',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('media-search-field'),
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: InputDecoration(
            hintText: '搜索年月、文件名或日记内容',
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
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(context, '全部', null, _catalog.entryCount),
              for (final kind in DiaryMediaKind.values)
                _filterChip(
                  context,
                  diaryMediaKindLabel(kind),
                  kind,
                  kind == DiaryMediaKind.image
                      ? _catalog.photoAlbums.length
                      : _catalog.countFor(kind),
                ),
            ],
          ),
        ),
        if (_filter != null || _query.trim().isNotEmpty) ...[
          const SizedBox(height: 13),
          Text(
            '找到 $resultCount 篇相关日记',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.mutedInk),
          ),
        ],
      ],
    );
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    DiaryMediaKind? kind,
    int count,
  ) {
    final colors = DiaryThemeColors.of(context);
    final selected = _filter == kind;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label $count'),
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

class _MediaCatalog {
  const _MediaCatalog({
    required this.items,
    required this.photoAlbums,
    required this.counts,
    required this.entryCount,
  });

  factory _MediaCatalog.fromEntries(List<DiaryEntry> entries) {
    final items = <_MediaItem>[];
    final photoAlbums = <_PhotoAlbum>[];
    final counts = {for (final kind in DiaryMediaKind.values) kind: 0};
    var entryCount = 0;
    for (final entry in entries) {
      if (entry.isStandaloneLocation || !entry.hasMedia) continue;
      entryCount++;
      final date = entry.effectiveOccurredAt.toLocal();
      final month = date.month.toString().padLeft(2, '0');
      final entrySearch = _MediaEntrySearch(
        [
          entry.title,
          entry.contentText,
          entry.category,
          ...entry.tags,
          '${date.year}年${date.month}月${date.day}日',
          '${date.year}-$month',
        ].join(' ').toLowerCase(),
      );
      final photos = <_MediaItem>[];
      for (final path in entry.imagePaths) {
        final kind = diaryMediaKindForPath(path);
        final item = _MediaItem(
          entry: entry,
          path: path,
          kind: kind,
          entrySearch: entrySearch,
        );
        items.add(item);
        if (kind == DiaryMediaKind.image) photos.add(item);
        counts[kind] = counts[kind]! + 1;
      }
      if (photos.isNotEmpty) {
        photoAlbums.add(_PhotoAlbum(entry: entry, photos: photos));
      }
      for (final path in entry.audioPaths) {
        items.add(
          _MediaItem(
            entry: entry,
            path: path,
            kind: DiaryMediaKind.audio,
            entrySearch: entrySearch,
          ),
        );
        counts[DiaryMediaKind.audio] = counts[DiaryMediaKind.audio]! + 1;
      }
      for (final path in entry.videoPaths) {
        items.add(
          _MediaItem(
            entry: entry,
            path: path,
            kind: DiaryMediaKind.video,
            entrySearch: entrySearch,
          ),
        );
        counts[DiaryMediaKind.video] = counts[DiaryMediaKind.video]! + 1;
      }
    }
    photoAlbums.sort((first, second) {
      final byDate = second.entry.effectiveOccurredAt.compareTo(
        first.entry.effectiveOccurredAt,
      );
      return byDate != 0 ? byDate : second.entry.id.compareTo(first.entry.id);
    });
    return _MediaCatalog(
      items: items,
      photoAlbums: photoAlbums,
      counts: counts,
      entryCount: entryCount,
    );
  }

  final List<_MediaItem> items;
  final List<_PhotoAlbum> photoAlbums;
  final Map<DiaryMediaKind, int> counts;
  final int entryCount;

  int countFor(DiaryMediaKind kind) => counts[kind] ?? 0;
}

class _PhotoAlbum {
  const _PhotoAlbum({required this.entry, required this.photos});

  final DiaryEntry entry;
  final List<_MediaItem> photos;

  List<String> get paths => [for (final photo in photos) photo.path];

  bool matches(String normalizedQuery) =>
      normalizedQuery.isEmpty ||
      photos.any((photo) => photo.matches(normalizedQuery));

  int initialIndexFor(String normalizedQuery) {
    if (normalizedQuery.isEmpty) return 0;
    final index = photos.indexWhere(
      (photo) => photo.fileName.toLowerCase().contains(normalizedQuery),
    );
    return index < 0 ? 0 : index;
  }
}

class _MediaItem {
  _MediaItem({
    required this.entry,
    required this.path,
    required this.kind,
    required _MediaEntrySearch entrySearch,
  }) : fileName = path.split(RegExp(r'[\\/]')).last,
       _entrySearch = entrySearch;

  final DiaryEntry entry;
  final String path;
  final DiaryMediaKind kind;
  final String fileName;
  final _MediaEntrySearch _entrySearch;
  late final String _searchableFileName = fileName.toLowerCase();

  bool matches(String normalizedQuery) =>
      normalizedQuery.isEmpty ||
      _searchableFileName.contains(normalizedQuery) ||
      _entrySearch.matches(normalizedQuery);

  String get displayTitle {
    if (kind == DiaryMediaKind.audio) return '语音';
    if (kind == DiaryMediaKind.video) return '视频片段';
    if (kind == DiaryMediaKind.file) {
      return fileName.isEmpty ? '未命名附件' : fileName;
    }
    final title = entry.title.trim();
    if (title.isNotEmpty && title != '无题' && title != '此刻的照片') {
      return title;
    }
    final content = entry.contentText.trim();
    return content.isEmpty ? '这一天的照片' : content;
  }

  String get contextLabel {
    final date = entry.effectiveOccurredAt.toLocal();
    final category = entry.category.isEmpty ? '未分类' : entry.category;
    return '${date.year}年${date.month}月${date.day}日 · $category';
  }
}

class _MediaEntrySearch {
  _MediaEntrySearch(this.text);

  final String text;
  String? _cachedQuery;
  bool _cachedMatch = false;

  bool matches(String normalizedQuery) {
    if (_cachedQuery != normalizedQuery) {
      _cachedQuery = normalizedQuery;
      _cachedMatch = text.contains(normalizedQuery);
    }
    return _cachedMatch;
  }
}

class _AlbumSectionHeading extends StatelessWidget {
  const _AlbumSectionHeading({
    required this.albumCount,
    required this.photoCount,
  });

  final int albumCount;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('照片相册', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            '$albumCount 篇日记 · $photoCount 张照片',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.mutedInk),
          ),
        ),
      ],
    );
  }
}

class _AlbumMonthHeading extends StatelessWidget {
  const _AlbumMonthHeading({
    required this.month,
    required this.showYear,
    required this.albumCount,
    required this.photoCount,
  });

  final DateTime month;
  final bool showYear;
  final int albumCount;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showYear) ...[
          Text(
            '${month.year}年',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Text(
              '${month.month}月',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(height: 1, color: colors.line)),
            const SizedBox(width: 12),
            Text(
              '$albumCount 篇 · $photoCount 张',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.mutedInk),
            ),
          ],
        ),
      ],
    );
  }
}

class _MediaSectionHeading extends StatelessWidget {
  const _MediaSectionHeading({required this.kind, required this.count});

  final DiaryMediaKind kind;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Row(
      children: [
        Text(
          diaryMediaKindLabel(kind),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(width: 8),
        Text(
          '$count',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.mutedInk),
        ),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.album,
    required this.item,
    required this.onPreview,
    required this.onOpenEntry,
  });

  final _PhotoAlbum album;
  final _MediaItem item;
  final VoidCallback onPreview;
  final VoidCallback onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheWidth =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .round();
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: colors.surface,
            child: InkWell(
              key: Key('media-photo-${album.entry.id}'),
              onTap: onPreview,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalMediaPreview(
                    path: item.path,
                    kind: item.kind,
                    showRetry: true,
                    cacheWidth: cacheWidth,
                  ),
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: .7),
                          ],
                          stops: const [.4, 1],
                        ),
                      ),
                    ),
                  ),
                  if (album.photos.length > 1)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${album.photos.length} 张',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: 11,
                    right: 11,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.contextLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: .88),
                              ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton.filledTonal(
                      tooltip: '打开所属日记',
                      onPressed: onOpenEntry,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: .42),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.item, required this.onOpenEntry});

  final _MediaItem item;
  final VoidCallback onOpenEntry;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (item.kind == DiaryMediaKind.video)
                SizedBox(
                  width: 76,
                  height: 70,
                  child: DiaryVideoPreview(
                    path: item.path,
                    label: '视频片段',
                    compact: true,
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.kind == DiaryMediaKind.audio
                        ? colors.butter
                        : colors.lavender,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    item.kind == DiaryMediaKind.audio
                        ? Icons.graphic_eq_rounded
                        : Icons.insert_drive_file_outlined,
                    color: colors.ink,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.entry.title} · ${item.contextLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: '打开所属日记',
                onPressed: onOpenEntry,
                icon: const Icon(Icons.arrow_outward_rounded),
              ),
            ],
          ),
          if (item.kind == DiaryMediaKind.audio) ...[
            const SizedBox(height: 9),
            DiaryAudioPlayer(
              path: item.path,
              label: '语音',
              compact: true,
              loadMetadata: false,
              loadWaveform: false,
            ),
          ],
        ],
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          Icon(Icons.collections_outlined, size: 40, color: colors.terracotta),
          const SizedBox(height: 14),
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
            '在日记里添加照片、声音或文件，它们会自动出现在这里。',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
