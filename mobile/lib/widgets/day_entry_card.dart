import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/app/diary_motion.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/diary_image_viewer.dart';

/// A single day's timeline surface; each moment remains its own entry.
class DayEntryCard extends StatelessWidget {
  const DayEntryCard({
    required this.date,
    required this.entries,
    required this.expanded,
    required this.showExpandControl,
    required this.onToggleExpanded,
    required this.onOpenEntry,
    required this.onLongPressEntry,
    required this.onFavorite,
    required this.onShare,
    required this.onDelete,
    required this.selectedIds,
    required this.selectionMode,
    super.key,
  });

  final DateTime date;
  final List<DiaryEntry> entries;
  final bool expanded;
  final bool showExpandControl;
  final VoidCallback onToggleExpanded;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final ValueChanged<DiaryEntry> onLongPressEntry;
  final ValueChanged<DiaryEntry> onFavorite;
  final ValueChanged<DiaryEntry> onShare;
  final ValueChanged<DiaryEntry> onDelete;
  final Set<String> selectedIds;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final now = DateTime.now();
    final today =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final label = today
        ? '今天 · ${date.month}月${date.day}日'
        : date.year == now.year
        ? diaryDateLabel(date)
        : '${date.year}年 ${diaryDateLabel(date)}';
    final visibleCount = expanded ? entries.length : entries.length.clamp(0, 3);
    final hiddenCount = entries.length - visibleCount;
    return Material(
      key: Key('mobile-day-card-${date.year}-${date.month}-${date.day}'),
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${entries.length} 条',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.mutedInk,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.line),
          AnimatedSize(
            duration: DiaryMotion.duration(context, DiaryMotion.standard),
            curve: DiaryMotion.curve(context, Curves.easeOutCubic),
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (var index = 0; index < visibleCount; index++) ...[
                  if (index > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: colors.line),
                    ),
                  _MomentRow(
                    entry: entries[index],
                    selected: selectedIds.contains(entries[index].id),
                    selectionMode: selectionMode,
                    onTap: () => onOpenEntry(entries[index]),
                    onLongPress: () => onLongPressEntry(entries[index]),
                    onFavorite: () => onFavorite(entries[index]),
                    onShare: () => onShare(entries[index]),
                    onDelete: () => onDelete(entries[index]),
                  ),
                ],
              ],
            ),
          ),
          if (showExpandControl && entries.length > 3) ...[
            Divider(height: 1, color: colors.line),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onToggleExpanded,
                icon: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(expanded ? '收起' : '展开剩余 $hiddenCount 条'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MomentRow extends StatelessWidget {
  const _MomentRow({
    required this.entry,
    required this.selected,
    required this.selectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onFavorite,
    required this.onShare,
    required this.onDelete,
  });

  final DiaryEntry entry;
  final bool selected;
  final bool selectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final content = entry.contentText.trim();
    final autoTitle =
        entry.title.isEmpty ||
        entry.title == '无题' ||
        entry.title == '此刻的照片' ||
        entry.title.endsWith(' 的一个念头') ||
        entry.title.endsWith(' 的照片');
    final primary = !autoTitle
        ? entry.title
        : content.isNotEmpty
        ? content
        : entry.imagePaths.isNotEmpty
        ? '${entry.imagePaths.length} 张照片'
        : entry.title;
    final secondary = !autoTitle && content.isNotEmpty && content != primary
        ? content
        : null;
    final metadata = [
      entry.category,
      if (entry.tags.isNotEmpty) '#${entry.tags.first}',
      if (entry.imagePaths.length > 1 &&
          primary != '${entry.imagePaths.length} 张照片')
        '${entry.imagePaths.length} 张照片',
    ].join(' · ');

    return Semantics(
      key: Key('mobile-entry-row-${entry.id}'),
      container: true,
      selected: selectionMode ? selected : null,
      value: selectionMode ? (selected ? '已选中' : '未选中') : null,
      hint: selectionMode ? '点按切换选择' : '点按打开日记，长按多选',
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          color: selected ? colors.terracottaSoft.withValues(alpha: .55) : null,
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          constraints: const BoxConstraints(minHeight: 64),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    diaryTimeLabel(entry.effectiveOccurredAt.toLocal()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.mutedInk,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 9, right: 11),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? colors.terracotta : colors.mutedInk,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1, bottom: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                      if (secondary != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          secondary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        metadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.mutedInk,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (entry.imagePaths.isNotEmpty) ...[
                const SizedBox(width: 7),
                DiaryImageThumbnail(
                  entryId: entry.id,
                  imagePaths: entry.imagePaths,
                  index: 0,
                  width: 48,
                  height: 48,
                  borderRadius: 7,
                  heroScope: 'timeline',
                ),
              ] else if (entry.hasMedia) ...[
                const SizedBox(width: 6),
                Icon(Icons.attach_file, size: 18, color: colors.mutedInk),
              ],
              if (selectionMode)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    key: selected
                        ? Key('mobile-entry-selected-${entry.id}')
                        : null,
                    size: 20,
                    color: selected ? colors.terracotta : colors.mutedInk,
                  ),
                )
              else
                SizedBox(
                  width: 40,
                  height: 40,
                  child: PopupMenuButton<String>(
                    tooltip: '更多操作：${entry.title}',
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.more_horiz,
                      color: colors.mutedInk,
                      size: 20,
                    ),
                    onSelected: (value) {
                      if (value == 'favorite') onFavorite();
                      if (value == 'share') onShare();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'favorite',
                        child: Text(entry.isFavorite ? '取消收藏' : '收藏'),
                      ),
                      const PopupMenuItem(value: 'share', child: Text('分享')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('移入回收站'),
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
}
