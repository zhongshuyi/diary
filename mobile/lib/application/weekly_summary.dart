import 'package:diary/domain/diary_entry.dart';

/// A local-only reflection over the most recently completed natural week.
class WeeklySummary {
  const WeeklySummary({
    required this.start,
    required this.end,
    required this.entries,
    required this.recordedDayCount,
    required this.wordCount,
    required this.averageMood,
    required this.topCategory,
  });

  /// Monday at 00:00 in the device's local time zone.
  final DateTime start;

  /// Sunday at 00:00 in the device's local time zone.
  final DateTime end;
  final List<DiaryEntry> entries;
  final int recordedDayCount;
  final int wordCount;
  final double averageMood;
  final String topCategory;

  int get entryCount => entries.length;
}

/// Returns the previous fully completed Monday-to-Sunday week when it has at
/// least two eligible entries. The current partial week is intentionally not
/// included so this stays a calm reflection rather than a progress target.
WeeklySummary? calculateWeeklySummary({
  required Iterable<DiaryEntry> entries,
  required DateTime now,
}) {
  final currentWeekStart = _startOfCurrentWeek(now);
  final priorWeekStart = currentWeekStart.subtract(const Duration(days: 7));
  final priorWeekEnd = currentWeekStart.subtract(const Duration(days: 1));

  final weeklyEntries =
      entries
          .where(
            (entry) =>
                _isEligible(entry) &&
                _isInWeek(
                  entry.effectiveOccurredAt.toLocal(),
                  priorWeekStart,
                  currentWeekStart,
                ),
          )
          .toList()
        ..sort((left, right) {
          final byDate = right.effectiveOccurredAt.compareTo(
            left.effectiveOccurredAt,
          );
          return byDate != 0 ? byDate : left.id.compareTo(right.id);
        });

  if (weeklyEntries.length < 2) return null;

  final recordedDays = <DateTime>{
    for (final entry in weeklyEntries)
      _startOfLocalDay(entry.effectiveOccurredAt),
  };
  final categoryCounts = <String, int>{};
  for (final entry in weeklyEntries) {
    final category = _categoryLabel(entry);
    categoryCounts.update(category, (count) => count + 1, ifAbsent: () => 1);
  }
  final topCategory = categoryCounts.entries.toList()
    ..sort((left, right) {
      final byCount = right.value.compareTo(left.value);
      return byCount != 0 ? byCount : left.key.compareTo(right.key);
    });

  return WeeklySummary(
    start: priorWeekStart,
    end: priorWeekEnd,
    entries: List.unmodifiable(weeklyEntries),
    recordedDayCount: recordedDays.length,
    wordCount: weeklyEntries.fold(0, (sum, entry) => sum + entry.wordCount),
    averageMood:
        weeklyEntries.fold<double>(0, (sum, entry) => sum + entry.mood) /
        weeklyEntries.length,
    topCategory: topCategory.first.key,
  );
}

bool _isEligible(DiaryEntry entry) =>
    !entry.isInTrash && !entry.isDeleted && !entry.isConflict;

bool _isInWeek(DateTime value, DateTime start, DateTime endExclusive) =>
    !value.isBefore(start) && value.isBefore(endExclusive);

DateTime _startOfCurrentWeek(DateTime value) {
  final localDay = _startOfLocalDay(value);
  return localDay.subtract(Duration(days: localDay.weekday - DateTime.monday));
}

DateTime _startOfLocalDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}

String _categoryLabel(DiaryEntry entry) {
  final category = entry.category.trim();
  return category.isEmpty ? '未分类' : category;
}
