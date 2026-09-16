enum SyncStatus { idle, syncing, pending, synced, failed, conflict }

class SyncState {
  const SyncState({
    this.deviceId = '',
    this.cursor = '0',
    this.lastSuccessAt,
    this.lastError,
    this.status = SyncStatus.idle,
  });

  final String deviceId;
  final String cursor;
  final DateTime? lastSuccessAt;
  final String? lastError;
  final SyncStatus status;
}
