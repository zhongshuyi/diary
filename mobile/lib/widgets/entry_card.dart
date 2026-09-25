import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/local_media_preview.dart';

class DiaryEntryCard extends StatelessWidget {
  const DiaryEntryCard({
    required this.entry,
    required this.onTap,
    this.onFavorite,
    this.onShare,
    this.onDelete,
    this.onLongPress,
    this.selected = false,
    super.key,
  });

  final DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 17, 14, 15),
              child: _cardBody(context, colors),
            ),
            if (selected)
              Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.check_circle,
                  color: colors.terracotta,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardBody(BuildContext context, DiaryThemeColors colors) {
    final tint = Color(entry.colorValue);
    final thumbnailCacheSize = (72 * MediaQuery.devicePixelRatioOf(context))
        .round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(top: 7),
              decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.isStandaloneLocation
                    ? entry.locationDisplayName
                    : entry.title.isEmpty
                    ? '无题'
                    : entry.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.more_horiz, color: colors.mutedInk),
              onSelected: (value) {
                if (value == 'favorite') onFavorite?.call();
                if (value == 'share') onShare?.call();
                if (value == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'favorite',
                  child: Text(entry.isFavorite ? '取消收藏' : '收藏'),
                ),
                const PopupMenuItem(value: 'share', child: Text('分享')),
                const PopupMenuItem(value: 'delete', child: Text('移入回收站')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          entry.isStandaloneLocation
              ? entry.locationDisplayAddress.isNotEmpty
                    ? entry.locationDisplayAddress
                    : '已保存的位置'
              : entry.contentText.isEmpty && entry.imagePaths.isNotEmpty
              ? '${entry.imagePaths.length} 张照片'
              : entry.contentText.isEmpty
              ? '这一天还没有留下文字。'
              : entry.contentText,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.65),
        ),
        if (entry.imagePaths.isNotEmpty && !entry.isStandaloneLocation) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entry.imagePaths.length.clamp(0, 3),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  child: LocalMediaPreview(
                    path: entry.imagePaths[index],
                    kind: DiaryMediaKind.image,
                    cacheWidth: thumbnailCacheSize,
                    cacheHeight: thumbnailCacheSize,
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              diaryTimeLabel(entry.effectiveOccurredAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: 10),
            Text('·', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(width: 10),
            Text(entry.category, style: Theme.of(context).textTheme.labelSmall),
            const Spacer(),
            if (entry.hasMedia && !entry.isStandaloneLocation)
              Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.attach_file,
                  size: 15,
                  color: colors.mutedInk,
                ),
              ),
            AnimatedSwitcher(
              duration: DiaryMotion.duration(context, DiaryMotion.standard),
              switchInCurve: DiaryMotion.curve(context, Curves.easeOutBack),
              switchOutCurve: DiaryMotion.curve(context, Curves.easeIn),
              child: onFavorite == null
                  ? Icon(
                      key: ValueKey(entry.isFavorite),
                      entry.isFavorite ? Icons.bookmark : Icons.bookmark_border,
                      size: 17,
                      color: entry.isFavorite
                          ? colors.terracotta
                          : colors.mutedInk,
                    )
                  : IconButton(
                      key: ValueKey(entry.isFavorite),
                      tooltip: entry.isFavorite ? '取消收藏' : '收藏',
                      onPressed: onFavorite,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 34,
                        height: 34,
                      ),
                      icon: Icon(
                        entry.isFavorite
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        size: 18,
                        color: entry.isFavorite
                            ? colors.terracotta
                            : colors.mutedInk,
                      ),
                    ),
            ),
          ],
        ),
        if (entry.tags.isNotEmpty) ...[
          const SizedBox(height: 13),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: entry.tags.take(4).map((tag) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.paper,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    '#$tag',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(letterSpacing: .2),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
