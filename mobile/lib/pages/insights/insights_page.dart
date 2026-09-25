import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/application/insights_summary.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/page_intro.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({required this.entries, super.key});

  final List<DiaryEntry> entries;

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  List<DiaryEntry>? _summarySource;
  DateTime? _summaryDay;
  InsightsSummary? _summary;

  InsightsSummary _summaryFor(DateTime now) {
    final day = DateTime(now.year, now.month, now.day);
    if (!identical(_summarySource, widget.entries) || _summaryDay != day) {
      _summarySource = widget.entries;
      _summaryDay = day;
      _summary = calculateInsights(entries: widget.entries, now: now);
    }
    return _summary!;
  }

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final summary = _summaryFor(DateTime.now());
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DiaryPageIntro(
                eyebrow: 'A LITTLE LOOK BACK',
                title: '洞察',
                description: '从记录时间、心情和主题里，看见生活的轨迹。',
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) => GridView.count(
                  crossAxisCount: constraints.maxWidth > 580 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: constraints.maxWidth > 580 ? 1.4 : 1.55,
                  children: [
                    _Metric(
                      icon: Icons.auto_stories_outlined,
                      number: '${summary.entryCount}',
                      label: '累计记录',
                      tint: colors.sage,
                    ),
                    _Metric(
                      icon: Icons.event_available_outlined,
                      number: '${summary.recordedDayCount}',
                      label: '有记录的日子',
                      tint: colors.butter,
                    ),
                    _Metric(
                      icon: Icons.bookmark_outline_rounded,
                      number: '${summary.favoriteCount}',
                      label: '收藏片段',
                      tint: colors.terracottaSoft,
                    ),
                    _Metric(
                      icon: Icons.edit_note_rounded,
                      number: '${summary.wordCount}',
                      label: '写下字数',
                      tint: colors.lavender,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _ActivityCard(days: summary.recentDays),
              const SizedBox(height: 14),
              _MoodCard(summary: summary),
              const SizedBox(height: 14),
              _DistributionCard(
                title: '常出现的心情',
                description: '仅统计你主动标记的心情',
                emptyMessage: '主动标记心情后，这里会慢慢长出你的情绪天气。',
                counts: summary.moodLabels,
                total: summary.moodCount,
                barColor: colors.terracotta,
              ),
              const SizedBox(height: 14),
              _DistributionCard(
                title: '常写的主题',
                description: '看看文字都留给了哪些生活片段',
                emptyMessage: '写下日记后，这里会出现常写的分类。',
                counts: summary.categories,
                total: summary.entryCount,
                barColor: colors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.number,
    required this.label,
    required this.tint,
  });

  final IconData icon;
  final String number;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 21, color: colors.ink),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  number,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 3),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.days});

  final List<InsightDay> days;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final maxCount = days.fold<int>(
      0,
      (value, day) => math.max(value, day.entryCount),
    );
    final total = days.fold<int>(0, (value, day) => value + day.entryCount);
    final activeDays = days.where((day) => day.entryCount > 0).length;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 19, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('最近 7 天', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              '$total 篇记录 · $activeDays 天有记录',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 105,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: Tooltip(
                        message:
                            '${day.date.month}月${day.date.day}日 · ${day.entryCount} 篇',
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              day.entryCount == 0 ? '' : '${day.entryCount}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 5),
                            Container(
                              width: 19,
                              height: day.entryCount == 0
                                  ? 5
                                  : 12 + 48 * day.entryCount / maxCount,
                              decoration: BoxDecoration(
                                color: day.entryCount == 0
                                    ? colors.line
                                    : colors.terracotta,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '周${'一二三四五六日'[day.date.weekday - 1]}',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colors.mutedInk),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.summary});

  final InsightsSummary summary;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final days = summary.moodDays;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 19, 18, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '最近的情绪天气',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  summary.averageMood == null
                      ? '—'
                      : '${(summary.averageMood! * 100).round()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: colors.terracotta),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '近 7 个有心情的日子 · 同日取平均',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 208,
              child: days.isEmpty
                  ? Center(
                      child: Text(
                        '主动标记心情后，这里会出现你的情绪轨迹。',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        maxY: 1,
                        minY: 0,
                        alignment: BarChartAlignment.spaceAround,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              if (group.x < 0 || group.x >= days.length) {
                                return null;
                              }
                              final day = days[group.x];
                              return BarTooltipItem(
                                '${day.date.month}月${day.date.day}日 · '
                                '${day.moodCount} 条心情\n平均 ${(day.averageMood! * 100).round()}%',
                                TextStyle(color: colors.onHero),
                              );
                            },
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 27,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (value != index ||
                                    index < 0 ||
                                    index >= days.length) {
                                  return const SizedBox.shrink();
                                }
                                final date = days[index].date;
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    '${date.month}/${date.day}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: colors.mutedInk,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [
                          for (var index = 0; index < days.length; index++)
                            BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: days[index].averageMood!.clamp(.08, 1),
                                  width: 22,
                                  color: index == days.length - 1
                                      ? colors.terracotta
                                      : colors.sage,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionCard extends StatelessWidget {
  const _DistributionCard({
    required this.title,
    required this.description,
    required this.emptyMessage,
    required this.counts,
    required this.total,
    required this.barColor,
  });

  final String title;
  final String description;
  final String emptyMessage;
  final List<InsightCount> counts;
  final int total;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.mutedInk),
            ),
            const SizedBox(height: 18),
            if (counts.isEmpty)
              Text(emptyMessage, style: Theme.of(context).textTheme.bodyMedium)
            else
              for (final item in counts.take(5)) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 78,
                      child: Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.count / total,
                          minHeight: 8,
                          backgroundColor: colors.paper,
                          color: barColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${item.count}',
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}
