import '../domain/conflict.dart';
import '../domain/diary_entry.dart';

class SyncRequest {
  const SyncRequest({
    required this.deviceId,
    required this.cursor,
    required this.changes,
    this.limit = 100,
  });

  final String deviceId;
  final String cursor;
  final List<Map<String, dynamic>> changes;
  final int limit;

  Map<String, dynamic> toJson() => {
    'protocolVersion': 2,
    'deviceId': deviceId,
    'cursor': cursor,
    'limit': limit,
    'client': {'platform': 'mobile', 'appVersion': '0.2.0'},
    'changes': changes,
  };
}

class SyncResponse {
  const SyncResponse({
    required this.nextCursor,
    required this.changes,
    required this.conflicts,
    required this.acknowledgedMutationIds,
  });

  final String nextCursor;
  final List<DiaryEntry> changes;
  final List<Conflict> conflicts;
  final List<String> acknowledgedMutationIds;
}

class SyncFailure implements Exception {
  const SyncFailure(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'SyncFailure($code): $message';
}
