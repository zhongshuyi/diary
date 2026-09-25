import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_mood.dart';

class InsightCount {
  const InsightCount(this.label, this.count);

  final String label;
  final int count;
}

class InsightDay {
  const InsightDay({
    required this.date,
    required this.entryCount,
    this.averageMood,
    this.moodCount = 0,
  });

  final DateTime date;
  final int entryCount;
  final double? averageMood;
  final int moodCount;
}

class InsightsSummary {
  const InsightsSummary({
    required this.entryCount,
    required this.recordedDayCount,
    required this.favoriteCount,
    required this.wordCount,
    required this.averageMood,
    required this.moodCount,
    required this.recentDays,
    required this.moodDays,
    required this.moodLabels,
    required this.categories,
  });

  final int entryCount;
  final int recordedDayCount;
  final int favoriteCount;
  final int wordCount;
  final double? averageMood;
  final int moodCount;
  final List<InsightDay> recentDays;
  final List<InsightDay> moodDays;
  final List<InsightCount> moodLabels;
  final List<InsightCount> categories;
}

InsightsSummary calculateInsights({
  required Iterable<DiaryEntry> entries,
  required DateTime now,
}) {
  final today = _localDay(now);
  final entryCounts = <DateTime, int>{};
  final moodByDay = <DateTime, ({double total, int count})>{};
  final moodLabels = <String, int>{};
  final categories = <String, int>{};
  var entryCount = 0;
  var favoriteCount = 0;
  var wordCount = 0;
  var moodTotal = 0.0;
  var moodCount = 0;

  for (final entry in entries) {
    if (entry.isInTrash || entry.isDeleted || entry.isConflict) continue;
    entryCount++;
    if (entry.isFavorite) favoriteCount++;
    wordCount += entry.wordCount;
    final day = _localDay(entry.effectiveOccurredAt);
    entryCounts.update(day, (count) => count + 1, ifAbsent: () => 1);
    final category = entry.category.trim().isEmpty
        ? '未分类'
        : entry.category.trim();
    categories.update(category, (count) => count + 1, ifAbsent: () => 1);

    if (!entry.hasExplicitMood) continue;
    moodTotal += entry.mood;
    moodCount++;
    final previous = moodByDay[day];
    moodByDay[day] = (
      total: (previous?.total ?? 0) + entry.mood,
      count: (previous?.count ?? 0) + 1,
    );
    final label = entry.moodLabel?.trim();
    final moodLabel = label == null || label.isEmpty
        ? diaryMoodLabel(entry.mood)
        : label;
    moodLabels.update(moodLabel, (count) => count + 1, ifAbsent: () => 1);
  }

  final recentDays = List<InsightDay>.generate(7, (index) {
    final day = DateTime(today.year, today.month, today.day - 6 + index);
    return InsightDay(date: day, entryCount: entryCounts[day] ?? 0);
  }, growable: false);
  final sortedMoodDays = moodByDay.keys.toList()
    ..sort((first, second) => second.compareTo(first));
  final moodDays = [
    for (final day in sortedMoodDays.take(7).toList().reversed)
      InsightDay(
        date: day,
        entryCount: entryCounts[day] ?? 0,
        averageMood: moodByDay[day]!.total / moodByDay[day]!.count,
        moodCount: moodByDay[day]!.count,
      ),
  ];

  return InsightsSummary(
    entryCount: entryCount,
    recordedDayCount: entryCounts.length,
    favoriteCount: favoriteCount,
    wordCount: wordCount,
    averageMood: moodCount == 0 ? null : moodTotal / moodCount,
    moodCount: moodCount,
    recentDays: recentDays,
    moodDays: moodDays,
    moodLabels: _sortedCounts(moodLabels),
    categories: _sortedCounts(categories),
  );
}

DateTime _localDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

List<InsightCount> _sortedCounts(Map<String, int> counts) =>
    counts.entries.map((entry) => InsightCount(entry.key, entry.value)).toList()
      ..sort((first, second) {
        final byCount = second.count.compareTo(first.count);
        return byCount != 0 ? byCount : first.label.compareTo(second.label);
      });
