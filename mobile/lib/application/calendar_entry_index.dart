import 'package:diary/domain/diary_entry.dart';

/// Groups entries once so calendar day cells do not scan the full diary.
class CalendarEntryIndex {
  CalendarEntryIndex(Iterable<DiaryEntry> entries) {
    for (final entry in entries) {
      final date = entry.effectiveOccurredAt;
      final day = _dayKey(date);
      final group = _entriesByDay.putIfAbsent(day, () {
        final month = _monthKey(date);
        _daysByMonth[month] = (_daysByMonth[month] ?? 0) + 1;
        return <DiaryEntry>[];
      });
      group.add(entry);
    }
    for (final day in _entriesByDay.keys) {
      final group = _entriesByDay[day]!;
      group.sort(
        (left, right) =>
            right.effectiveOccurredAt.compareTo(left.effectiveOccurredAt),
      );
      _entriesByDay[day] = List.unmodifiable(group);
    }
  }

  final Map<int, List<DiaryEntry>> _entriesByDay = {};
  final Map<int, int> _daysByMonth = {};

  bool hasEntriesOn(DateTime date) => _entriesByDay.containsKey(_dayKey(date));

  List<DiaryEntry> entriesOn(DateTime date) =>
      _entriesByDay[_dayKey(date)] ?? const <DiaryEntry>[];

  int daysWithEntriesInMonth(DateTime date) =>
      _daysByMonth[_monthKey(date)] ?? 0;

  static int _monthKey(DateTime date) => date.year * 100 + date.month;

  static int _dayKey(DateTime date) => _monthKey(date) * 100 + date.day;
}
