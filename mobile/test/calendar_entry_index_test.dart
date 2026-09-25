import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/calendar_entry_index.dart';
import 'package:diary/domain/diary_entry.dart';

void main() {
  DiaryEntry entry(String id, DateTime createdAt, {DateTime? occurredAt}) =>
      DiaryEntry(
        id: id,
        createdAt: createdAt,
        updatedAt: createdAt,
        occurredAt: occurredAt,
        title: id,
        content: '',
        contentText: '',
        category: '生活',
      );

  test('indexes days across months and orders moments by occurrence', () {
    final index = CalendarEntryIndex([
      entry('morning', DateTime(2026, 9, 25, 9)),
      entry('yesterday', DateTime(2026, 9, 24, 18)),
      entry('evening', DateTime(2026, 9, 25, 20)),
      entry('last-year', DateTime(2025, 9, 25, 12)),
      entry('previous-month', DateTime(2026, 8, 31, 12)),
      entry(
        'moved',
        DateTime(2026, 9, 26, 12),
        occurredAt: DateTime(2026, 9, 25, 15),
      ),
    ]);

    expect(index.entriesOn(DateTime(2026, 9, 25)).map((e) => e.id), [
      'evening',
      'moved',
      'morning',
    ]);
    expect(index.hasEntriesOn(DateTime(2026, 9, 26)), isFalse);
    expect(index.hasEntriesOn(DateTime(2026, 9, 24)), isTrue);
    expect(index.daysWithEntriesInMonth(DateTime(2026, 9, 1)), 2);
    expect(index.daysWithEntriesInMonth(DateTime(2026, 8, 1)), 1);
    expect(index.daysWithEntriesInMonth(DateTime(2025, 9, 1)), 1);
    expect(index.entriesOn(DateTime(2026, 10, 1)), isEmpty);
  });
}
