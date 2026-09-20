import 'package:diary/domain/diary_entry.dart';

/// A local-only selection of moments that can be resurfaced in the timeline.
class TimelineReflection {
  const TimelineReflection({
    required this.today,
    required this.onThisDayEntries,
    required this.randomCandidates,
  });

  final DateTime today;
  final List<DiaryEntry> onThisDayEntries;
  final List<DiaryEntry> randomCandidates;

  DiaryEntry? get featuredOnThisDay =>
      onThisDayEntries.isEmpty ? null : onThisDayEntries.first;

  DiaryEntry? randomEntryAt(int rotationOffset) {
    if (randomCandidates.isEmpty) return null;
    final seed = today.year * 10000 + today.month * 100 + today.day;
    var index = (seed + rotationOffset) % randomCandidates.length;
    if (index < 0) index += randomCandidates.length;
    return randomCandidates[index];
  }
}

TimelineReflection calculateTimelineReflection({
  required Iterable<DiaryEntry> entries,
  required DateTime now,
}) {
  final today = _startOfLocalDay(now);
  final eligible = entries.where(_isEligible).toList(growable: false);

  final onThisDay = eligible.where((entry) {
    final occurredAt = entry.effectiveOccurredAt.toLocal();
    return occurredAt.month == today.month &&
        occurredAt.day == today.day &&
        occurredAt.year < today.year;
  }).toList()
    ..sort((left, right) {
      final byDate = right.effectiveOccurredAt.compareTo(
        left.effectiveOccurredAt,
      );
      return byDate != 0 ? byDate : left.id.compareTo(right.id);
    });

  final randomCandidates = eligible
      .where((entry) => entry.effectiveOccurredAt.toLocal().isBefore(today))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));

  return TimelineReflection(
    today: today,
    onThisDayEntries: List.unmodifiable(onThisDay),
    randomCandidates: List.unmodifiable(randomCandidates),
  );
}

String reflectionSummary(DiaryEntry entry) {
  final title = entry.title.trim();
  if (title.isNotEmpty) return title;

  final content = entry.contentText.trim().replaceAll(RegExp(r'\s+'), ' ');
  return content.isEmpty ? '未命名日记' : content;
}

bool _isEligible(DiaryEntry entry) =>
    !entry.isInTrash && !entry.isDeleted && !entry.isConflict;

DateTime _startOfLocalDay(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
