import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/timeline_reflection.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry entry(
  String id, {
  DateTime? createdAt,
  DateTime? occurredAt,
  String? title,
  String? contentText,
  bool isInTrash = false,
  bool isDeleted = false,
  bool isConflict = false,
}) {
  final created = createdAt ?? occurredAt ?? DateTime(2020, 1, 1, 9);
  final text = contentText ?? '$id 正文';
  return DiaryEntry(
    id: id,
    createdAt: created,
    updatedAt: created,
    occurredAt: occurredAt,
    title: title ?? id,
    content: text,
    contentText: text,
    category: '生活',
    isInTrash: isInTrash,
    isDeleted: isDeleted,
    isConflict: isConflict,
  );
}

void main() {
  test('sorts prior same-day entries and excludes ineligible records', () {
    final reflection = calculateTimelineReflection(
      entries: [
        entry('older', occurredAt: DateTime(2023, 9, 20)),
        entry('recent', occurredAt: DateTime(2025, 9, 20)),
        entry('today', occurredAt: DateTime(2026, 9, 20, 8)),
        entry(
          'trash',
          occurredAt: DateTime(2024, 9, 20),
          isInTrash: true,
        ),
        entry(
          'conflict',
          occurredAt: DateTime(2024, 9, 20),
          isConflict: true,
        ),
        entry(
          'tombstone',
          occurredAt: DateTime(2024, 9, 20),
          isDeleted: true,
        ),
      ],
      now: DateTime(2026, 9, 20, 12),
    );

    expect(
      reflection.onThisDayEntries.map((value) => value.id),
      ['recent', 'older'],
    );
    expect(
      reflection.randomCandidates.map((value) => value.id),
      containsAll(['older', 'recent']),
    );
    expect(
      reflection.randomCandidates.map((value) => value.id),
      isNot(contains('today')),
    );
  });

  test('keeps the daily random entry stable and rotates a multi-entry set', () {
    final reflection = calculateTimelineReflection(
      entries: [entry('a'), entry('b'), entry('c')],
      now: DateTime(2026, 9, 20),
    );

    expect(reflection.randomEntryAt(0)?.id, reflection.randomEntryAt(0)?.id);
    expect(
      reflection.randomEntryAt(1)?.id,
      isNot(reflection.randomEntryAt(0)?.id),
    );
  });

  test('uses effective occurrence date and a content fallback for untitled records', () {
    final value = entry(
      'legacy',
      createdAt: DateTime(2024, 9, 20),
      title: '   ',
      contentText: '  旧日记   正文  ',
    );
    final reflection = calculateTimelineReflection(
      entries: [value],
      now: DateTime(2026, 9, 20),
    );

    expect(reflection.onThisDayEntries.single.id, 'legacy');
    expect(reflectionSummary(value), '旧日记 正文');
  });

  test('breaks same-time on-this-day ties by ID and rotates a single candidate safely', () {
    final reflection = calculateTimelineReflection(
      entries: [
        entry('zeta', occurredAt: DateTime(2024, 9, 20, 9)),
        entry('alpha', occurredAt: DateTime(2024, 9, 20, 9)),
      ],
      now: DateTime(2026, 9, 20),
    );
    final single = calculateTimelineReflection(
      entries: [entry('only', occurredAt: DateTime(2025, 9, 1))],
      now: DateTime(2026, 9, 20),
    );

    expect(
      reflection.onThisDayEntries.map((value) => value.id),
      ['alpha', 'zeta'],
    );
    expect(single.randomEntryAt(0)?.id, 'only');
    expect(single.randomEntryAt(7)?.id, 'only');
  });
}
