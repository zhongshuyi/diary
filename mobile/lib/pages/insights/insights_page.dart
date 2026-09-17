import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:diary/app/app_theme.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/widgets/page_intro.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({required this.entries, super.key});

  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = DiaryThemeColors.of(context);
    final recent = entries
        .take(7)
        .toList(growable: false)
        .reversed
        .toList(growable: false);
    final averageMood = entries.isEmpty
        ? 0.0
        : entries.map((entry) => entry.mood).reduce((a, b) => a + b) /
              entries.length;
    final moodCounts = <String, int>{};
    for (final entry in entries) {
      final label = diaryMoodLabel(entry.mood);
      moodCounts[label] = (moodCounts[label] ?? 0) + 1;
    }
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
                description: '不分析你，只陪你看见自己的轨迹。',
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 580 ? 4 : 2;
                  return GridView.count(
                    crossAxisCount: columns,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: columns == 4 ? 1.35 : 1.75,
                    children: [
                      _Metric(
                        number: '${entries.length}',
                        label: '累计记录',
                        tint: colors.sage,
                      ),
                      _Metric(
                        number: '${(averageMood * 100).round()}%',
                        label: '平均心情',
                        tint: colors.butter,
                      ),
                      _Metric(
                        number:
                            '${entries.where((entry) => entry.isFavorite).length}',
                        label: '收藏片段',
                        tint: colors.terracottaSoft,
                      ),
                      _Metric(
                        number:
                            '${entries.fold<int>(0, (sum, entry) => sum + entry.wordCount)}',
                        label: '写下字数',
                        tint: colors.lavender,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '最近的情绪天气',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            '按日记录',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 210,
                        child: recent.isEmpty
                            ? Center(
                                child: Text(
                                  '写下第一篇日记后，这里会出现你的情绪轨迹。',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              )
                            : BarChart(
                                BarChartData(
                                  maxY: 1,
                                  minY: 0,
                                  alignment: BarChartAlignment.spaceAround,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      fitInsideHorizontally: true,
                                      fitInsideVertically: true,
                                      getTooltipItem:
                                          (
                                            group,
                                            groupIndex,
                                            rod,
                                            rodIndex,
                                          ) => BarTooltipItem(
                                            '心情 ${(rod.toY * 100).round()}%',
                                            TextStyle(
                                              color: colors.onHero,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
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
                                        reservedSize: 28,
                                        getTitlesWidget: (value, meta) =>
                                            SideTitleWidget(
                                              meta: meta,
                                              child: Text(
                                                '${recent[value.toInt()].effectiveOccurredAt.day}日',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: colors.mutedInk,
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  barGroups: recent.asMap().entries.map((item) {
                                    return BarChartGroupData(
                                      x: item.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: item.value.mood.clamp(.08, 1),
                                          width: 22,
                                          color: item.key == recent.length - 1
                                              ? colors.terracotta
                                              : colors.sage,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '出现得最多的心情',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 17),
                      if (moodCounts.isEmpty)
                        Text(
                          '写下第一篇日记之后，这里会慢慢长出你的情绪天气。',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        ...moodCounts.entries.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    item.key,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: item.value / entries.length,
                                      minHeight: 8,
                                      backgroundColor: colors.paper,
                                      color: colors.terracotta,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${item.value}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.hero,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'A NOTE TO YOUR FUTURE SELF',
                      style: TextStyle(
                        color: colors.butter,
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '“普通的日子，也值得被好好记住。”',
                      style: TextStyle(
                        color: colors.onHero,
                        fontFamily: 'Georgia',
                        fontSize: 20,
                        height: 1.35,
                      ),
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

class _Metric extends StatelessWidget {
  const _Metric({
    required this.number,
    required this.label,
    required this.tint,
  });

  final String number;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 15, 12, 14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(number, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(letterSpacing: 0),
          ),
        ],
      ),
    );
  }
}
