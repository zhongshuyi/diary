import 'diary_entry.dart';

class Conflict {
  const Conflict({
    required this.conflictId,
    required this.entryId,
    required this.entry,
    required this.serverEntry,
    required this.sourceDeviceId,
    required this.sourceMutationId,
    required this.createdAt,
    this.status = 'pending',
  });

  final String conflictId;
  final String entryId;
  final DiaryEntry entry;
  final DiaryEntry serverEntry;
  final String sourceDeviceId;
  final String sourceMutationId;
  final DateTime createdAt;
  final String status;
}
