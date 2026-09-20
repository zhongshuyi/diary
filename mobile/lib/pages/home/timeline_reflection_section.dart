import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/timeline_reflection.dart';
import 'package:diary/application/weekly_summary.dart';
import 'package:diary/domain/diary_entry.dart';

class TimelineReflectionSection extends StatelessWidget {
  const TimelineReflectionSection({
    required this.reflection,
    required this.weeklySummary,
    required this.randomRotation,
    required this.onOpenEntry,
    required this.onRotateRandom,
    super.key,
  });

  final TimelineReflection reflection;
  final WeeklySummary? weeklySummary;
  final int randomRotation;
  final ValueChanged<DiaryEntry> onOpenEntry;
  final VoidCallback onRotateRandom;

  @override
  Widget build(BuildContext context) {
    final onThisDay = reflection.featuredOnThisDay;
    final random = reflection.randomEntryAt(randomRotation);
    final summary = weeklySummary;
    if (onThisDay == null && random == null && summary == null) {
      return const SizedBox.shrink();
    }

    final colors = DiaryThemeColors.of(context);
    final hasMultipleOnThisDay = reflection.onThisDayEntries.length > 1;
    return Container(
      key: const Key('timeline-reflection-section'),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        children: [
          if (onThisDay != null)
            _ReflectionRow(
              rowKey: const Key('timeline-on-this-day'),
              icon: Icons.history_rounded,
              label: _onThisDayLabel(onThisDay),
              summary: reflectionSummary(onThisDay),
              semanticLabel:
                  '${_onThisDayLabel(onThisDay)}，${reflectionSummary(onThisDay)}',
              onTap: () {
                if (hasMultipleOnThisDay) {
                  _showAllOnThisDay(context);
                  return;
                }
                onOpenEntry(onThisDay);
              },
              action: hasMultipleOnThisDay
                  ? TextButton(
                      key: const Key('timeline-on-this-day-all'),
                      onPressed: () => _showAllOnThisDay(context),
                      child: Text('查看 ${reflection.onThisDayEntries.length} 条'),
                    )
                  : const Icon(Icons.chevron_right_rounded),
            ),
          if (onThisDay != null && (random != null || summary != null))
            Divider(height: 1, indent: 56, color: colors.line),
          if (random != null)
            _ReflectionRow(
              rowKey: const Key('timeline-random-reread'),
              icon: Icons.auto_awesome_outlined,
              label: '随机重读',
              summary: reflectionSummary(random),
              summaryKey: const Key('timeline-random-reread-summary'),
              semanticLabel: '随机重读，${reflectionSummary(random)}',
              onTap: () => onOpenEntry(random),
              action: IconButton(
                key: const Key('timeline-random-reread-refresh'),
                onPressed: reflection.randomCandidates.length > 1
                    ? onRotateRandom
                    : null,
                tooltip: '换一条',
                icon: const Icon(Icons.refresh_rounded, size: 19),
              ),
            ),
          if (random != null && summary != null)
            Divider(height: 1, indent: 56, color: colors.line),
          if (summary != null)
            _ReflectionRow(
              rowKey: const Key('timeline-weekly-summary'),
              icon: Icons.calendar_view_week_outlined,
              label: '上周小结',
              summary:
                  '写下 ${summary.recordedDayCount} 天 · ${summary.wordCount} 字',
              semanticLabel:
                  '上周小结，写下 ${summary.recordedDayCount} 天，${summary.wordCount} 字',
              onTap: () => _showWeeklySummary(context, summary),
              action: TextButton(
                key: const Key('timeline-weekly-summary-open'),
                onPressed: () => _showWeeklySummary(context, summary),
                child: const Text('查看'),
              ),
            ),
        ],
      ),
    );
  }

  String _onThisDayLabel(DiaryEntry entry) {
    final yearsAgo =
        reflection.today.year - entry.effectiveOccurredAt.toLocal().year;
    return yearsAgo <= 0 ? '那年今日' : '那年今日 · $yearsAgo 年前';
  }

  Future<void> _showAllOnThisDay(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        key: const Key('timeline-on-this-day-sheet'),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: reflection.onThisDayEntries.length + 1,
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox(height: 8) : const Divider(),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Text(
                '那年今日',
                style: Theme.of(context).textTheme.titleLarge,
              );
            }
            final entry = reflection.onThisDayEntries[index - 1];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(reflectionSummary(entry), maxLines: 1),
              subtitle: Text(
                '${reflection.today.year - entry.effectiveOccurredAt.toLocal().year} 年前',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.of(context).pop();
                onOpenEntry(entry);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _showWeeklySummary(BuildContext context, WeeklySummary summary) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .72,
        child: SafeArea(
          key: const Key('timeline-weekly-summary-sheet'),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: summary.entries.length + 2,
            separatorBuilder: (_, index) =>
                index == 1 ? const SizedBox(height: 10) : const Divider(),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _WeeklySummaryHeader(summary: summary);
              }
              if (index == 1) {
                return Text(
                  '这周片段',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                );
              }
              final entry = summary.entries[index - 2];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(reflectionSummary(entry), maxLines: 1),
                subtitle: Text(
                  '${_dateLabel(entry.effectiveOccurredAt)} · ${entry.category}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).pop();
                  onOpenEntry(entry);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WeeklySummaryHeader extends StatelessWidget {
  const _WeeklySummaryHeader({required this.summary});

  final WeeklySummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('上周小结', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          '${_dateLabel(summary.start)} – ${_dateLabel(summary.end)}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _WeeklyMetric(label: '${summary.recordedDayCount} 天记录'),
            _WeeklyMetric(label: '${summary.wordCount} 字'),
            _WeeklyMetric(label: '心情 ${(summary.averageMood * 100).round()}%'),
            _WeeklyMetric(label: '常写 · ${summary.topCategory}'),
          ],
        ),
      ],
    );
  }
}

class _WeeklyMetric extends StatelessWidget {
  const _WeeklyMetric({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.hero.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colors.mutedInk,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.month}月${local.day}日';
}

class _ReflectionRow extends StatelessWidget {
  const _ReflectionRow({
    required this.rowKey,
    required this.icon,
    required this.label,
    required this.summary,
    required this.semanticLabel,
    required this.onTap,
    required this.action,
    this.summaryKey,
  });

  final Key rowKey;
  final IconData icon;
  final String label;
  final String summary;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget action;
  final Key? summaryKey;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: InkWell(
        key: rowKey,
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 60,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.terracotta),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: colors.mutedInk,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        key: summaryKey,
                        summary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                action,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
