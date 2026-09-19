import 'dart:async';

import '../data/diary_repository.dart';
import '../domain/conflict.dart';
import '../domain/sync_state.dart';
import 'attachment_transfer.dart';
import 'sync_client.dart';
import 'sync_models.dart';

class SyncRunResult {
  const SyncRunResult({
    required this.status,
    required this.pendingCount,
    this.error,
  });

  final SyncStatus status;
  final int pendingCount;
  final Object? error;
}

class SyncEngine {
  SyncEngine({
    required this.repository,
    required this.client,
    this.interval = const Duration(seconds: 45),
    this.onStateChanged,
    AttachmentTransfer? attachmentTransfer,
  }) : attachmentTransfer =
           attachmentTransfer ?? AttachmentTransfer(client: client);

  final DiaryRepository repository;
  final SyncClient client;
  final Duration interval;
  final void Function(SyncState state)? onStateChanged;
  final AttachmentTransfer attachmentTransfer;
  Timer? _timer;
  bool _running = false;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => syncNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<SyncRunResult> syncNow() async {
    if (_running)
      return SyncRunResult(
        status: SyncStatus.syncing,
        pendingCount: (await repository.listPendingMutations()).length,
      );
    _running = true;
    final before = await repository.getSyncState();
    onStateChanged?.call(
      SyncState(
        deviceId: before.deviceId,
        cursor: before.cursor,
        status: SyncStatus.syncing,
      ),
    );
    try {
      await attachmentTransfer.backfillEntries(
        await repository.load(includeTrash: true),
        (entry) => repository.save(entry),
      );
      final pending = await repository.listPendingMutations(limit: 100);
      final request = SyncRequest(
        deviceId: before.deviceId.isEmpty ? 'mobile' : before.deviceId,
        cursor: before.cursor,
        changes: await attachmentTransfer.prepareChanges(pending),
      );
      final response = await client.sync(request);
      final changes = await Future.wait(
        response.changes.map(attachmentTransfer.hydrateEntry),
      );
      final conflicts = await Future.wait(
        response.conflicts.map(
          (conflict) async => Conflict(
            conflictId: conflict.conflictId,
            entryId: conflict.entryId,
            entry: await attachmentTransfer.hydrateEntry(conflict.entry),
            serverEntry: await attachmentTransfer.hydrateEntry(
              conflict.serverEntry,
            ),
            sourceDeviceId: conflict.sourceDeviceId,
            sourceMutationId: conflict.sourceMutationId,
            createdAt: conflict.createdAt,
            status: conflict.status,
          ),
        ),
      );
      await repository.applySyncResult(
        SyncResult(
          changes: changes,
          conflicts: conflicts,
          acknowledgedMutationIds: response.acknowledgedMutationIds,
          nextCursor: response.nextCursor,
        ),
      );
      final left = (await repository.listPendingMutations()).length;
      final status = conflicts.isEmpty
          ? (left == 0 ? SyncStatus.synced : SyncStatus.pending)
          : SyncStatus.conflict;
      final state = SyncState(
        deviceId: request.deviceId,
        cursor: response.nextCursor,
        lastSuccessAt: DateTime.now(),
        status: status,
      );
      await repository.setSyncState(state);
      onStateChanged?.call(state);
      return SyncRunResult(status: status, pendingCount: left);
    } catch (error) {
      final state = SyncState(
        deviceId: before.deviceId,
        cursor: before.cursor,
        lastError: '$error',
        status: SyncStatus.failed,
      );
      await repository.setSyncState(state);
      onStateChanged?.call(state);
      return SyncRunResult(
        status: SyncStatus.failed,
        pendingCount: (await repository.listPendingMutations()).length,
        error: error,
      );
    } finally {
      _running = false;
    }
  }
}
