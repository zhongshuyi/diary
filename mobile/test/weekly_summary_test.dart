import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/weekly_summary.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry entry(
  String id, {
  required DateTime occurredAt,
  required String category,
  required String contentText,
  double mood = .5,
  String? moodLabel,
  bool isInTrash = false,
  bool isDeleted = false,
  bool isConflict = false,
}) {
  return DiaryEntry(
    id: id,
    createdAt: occurredAt,
    updatedAt: occurredAt,
    occurredAt: occurredAt,
    title: id,
    content: contentText,
    contentText: contentText,
    category: category,
    mood: mood,
    moodLabel: moodLabel,
    isInTrash: isInTrash,
    isDeleted: isDeleted,
    isConflict: isConflict,
  );
}

void main() {
  test('summarizes the preceding completed Monday-to-Sunday week', () {
    final summary = calculateWeeklySummary(
      now: DateTime(2026, 9, 20, 12),
      entries: [
        entry(
          'early',
          occurredAt: DateTime(2026, 9, 8, 8),
          category: '工作',
          contentText: 'xy',
          mood: .2,
          moodLabel: '阴天',
        ),
        entry(
          'middle',
          occurredAt: DateTime(2026, 9, 8, 20),
          category: '工作',
          contentText: 'abc',
          mood: .7,
          moodLabel: '平静',
        ),
        entry(
          'late',
          occurredAt: DateTime(2026, 9, 13, 18),
          category: '生活',
          contentText: '三个字',
          mood: .9,
          moodLabel: '明亮',
        ),
        entry(
          'current-week',
          occurredAt: DateTime(2026, 9, 14),
          category: '工作',
          contentText: '不会计入',
        ),
        entry(
          'trash',
          occurredAt: DateTime(2026, 9, 9),
          category: '工作',
          contentText: '不会计入',
          isInTrash: true,
        ),
        entry(
          'conflict',
          occurredAt: DateTime(2026, 9, 10),
          category: '工作',
          contentText: '不会计入',
          isConflict: true,
        ),
        entry(
          'deleted',
          occurredAt: DateTime(2026, 9, 11),
          category: '工作',
          contentText: '不会计入',
          isDeleted: true,
        ),
      ],
    );

    expect(summary, isNotNull);
    expect(summary!.start, DateTime(2026, 9, 7));
    expect(summary.end, DateTime(2026, 9, 13));
    expect(summary.entries.map((entry) => entry.id), [
      'late',
      'middle',
      'early',
    ]);
    expect(summary.recordedDayCount, 2);
    expect(summary.wordCount, 8);
    expect(summary.averageMood, closeTo(.6, .0001));
    expect(summary.topCategory, '工作');
  });

  test('stays hidden until a completed week has at least two entries', () {
    final summary = calculateWeeklySummary(
      now: DateTime(2026, 9, 20),
      entries: [
        entry(
          'only',
          occurredAt: DateTime(2026, 9, 9),
          category: '生活',
          contentText: '一条记录',
        ),
      ],
    );

    expect(summary, isNull);
  });

  test('does not invent a weekly mood when entries have no selected mood', () {
    final summary = calculateWeeklySummary(
      now: DateTime(2026, 9, 20),
      entries: [
        entry(
          'first',
          occurredAt: DateTime(2026, 9, 8),
          category: '生活',
          contentText: '一',
        ),
        entry(
          'second',
          occurredAt: DateTime(2026, 9, 9),
          category: '生活',
          contentText: '二',
        ),
      ],
    );

    expect(summary, isNotNull);
    expect(summary!.averageMood, isNull);
  });

  test('retains a non-neutral mood from older entries without labels', () {
    final summary = calculateWeeklySummary(
      now: DateTime(2026, 9, 20),
      entries: [
        entry(
          'unmarked',
          occurredAt: DateTime(2026, 9, 8),
          category: '生活',
          contentText: '一',
        ),
        entry(
          'legacy',
          occurredAt: DateTime(2026, 9, 9),
          category: '生活',
          contentText: '二',
          mood: .9,
        ),
      ],
    );

    expect(summary?.averageMood, closeTo(.9, .0001));
  });
}
