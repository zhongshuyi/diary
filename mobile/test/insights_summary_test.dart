import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/insights_summary.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry _entry(
  String id,
  DateTime date, {
  double mood = .5,
  String? moodLabel,
  String category = '生活',
  bool isFavorite = false,
  bool isInTrash = false,
}) => DiaryEntry(
  id: id,
  createdAt: date,
  updatedAt: date,
  title: id,
  content: id,
  contentText: id,
  category: category,
  mood: mood,
  moodLabel: moodLabel,
  isFavorite: isFavorite,
  isInTrash: isInTrash,
);

void main() {
  test('aggregates unsorted entries by local day and excludes trash', () {
    final summary = calculateInsights(
      now: DateTime(2026, 9, 25, 12),
      entries: [
        _entry('earlier', DateTime(2026, 9, 23), mood: .6, moodLabel: '平静'),
        _entry('second', DateTime(2026, 9, 25, 18), mood: .4),
        _entry('plain', DateTime(2026, 9, 22)),
        _entry(
          'first',
          DateTime(2026, 9, 25, 8),
          mood: .8,
          isFavorite: true,
          category: '工作',
        ),
        _entry('trash', DateTime(2026, 9, 24), mood: .9, isInTrash: true),
      ],
    );

    expect(summary.entryCount, 4);
    expect(summary.recordedDayCount, 3);
    expect(summary.favoriteCount, 1);
    expect(summary.moodCount, 3);
    expect(summary.averageMood, closeTo(.6, .0001));
    expect(summary.moodDays.map((day) => day.date.day), [23, 25]);
    expect(summary.moodDays.last.moodCount, 2);
    expect(summary.moodDays.last.averageMood, closeTo(.6, .0001));
    expect(summary.recentDays.map((day) => day.entryCount), [
      0,
      0,
      0,
      1,
      1,
      0,
      2,
    ]);
    expect(summary.categories.first.label, '生活');
    expect(summary.categories.first.count, 3);
  });
}
