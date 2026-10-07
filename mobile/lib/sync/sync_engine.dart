import 'dart:async';

import '../data/diary_repository.dart';
import '../domain/conflict.dart';
import '../domain/diary_entry.dart';
import '../domain/sync_state.dart';
import 'attachment_transfer.dart';
import 'sync_client.dart';
import 'sync_models.dart';

class SyncRunResult {
  const SyncRunResult({
    required this.status,
    required this.pendingCount,
    this.hasMoreWork = false,
    this.localDataChanged = false,
    this.error,
  });

  final SyncStatus status;
  final int pendingCount;
  final bool hasMoreWork;
  final bool localDataChanged;
  final Object? error;
}

class SyncEngine {
  SyncEngine({
    required this.repository,
    required this.client,
    this.interval = const Duration(seconds: 45),
    this.onStateChanged,
    this.onAutoSyncRequested,
    this.mutationBatchSize = 100,
    this.attachmentBackfillBatchSize = 10,
    AttachmentTransfer? attachmentTransfer,
  }) : assert(mutationBatchSize > 0),
       assert(attachmentBackfillBatchSize > 0),
       attachmentTransfer =
           attachmentTransfer ?? AttachmentTransfer(client: client);

  final DiaryRepository repository;
  final SyncClient client;
  final Duration interval;
  final void Function(SyncState state)? onStateChanged;
  final void Function()? onAutoSyncRequested;
  final int mutationBatchSize;
  final int attachmentBackfillBatchSize;
  final AttachmentTransfer attachmentTransfer;
  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  String? _backfillAfterId;
  bool _backfillComplete = false;

  void start() {
    if (_disposed) return;
    _timer ??= Timer.periodic(interval, (_) {
      final request = onAutoSyncRequested;
      if (request == null) {
        unawaited(syncNow());
      } else {
        request();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    stop();
    client.close();
  }

  Future<SyncRunResult> _cancelledResult() async => SyncRunResult(
    status: SyncStatus.pending,
    pendingCount: await repository.countPendingMutations(),
  );

  Future<SyncRunResult> syncNow() async {
    if (_disposed) return _cancelledResult();
    if (_running) {
      return SyncRunResult(
        status: SyncStatus.syncing,
        pendingCount: await repository.countPendingMutations(),
      );
    }
    _running = true;
    var before = const SyncState();
    var localDataChanged = false;
    try {
      before = await repository.getSyncState();
      if (_disposed) return _cancelledResult();
      onStateChanged?.call(
        SyncState(
          deviceId: before.deviceId,
          cursor: before.cursor,
          status: SyncStatus.syncing,
        ),
      );
      final pending = await repository.listPendingMutations(
        limit: mutationBatchSize,
      );
      final request = SyncRequest(
        deviceId: before.deviceId.isEmpty ? 'mobile' : before.deviceId,
        cursor: before.cursor,
        limit: mutationBatchSize.clamp(1, 200),
        changes: await attachmentTransfer.prepareChanges(pending),
      );
      if (_disposed) return _cancelledResult();
      final response = await client.sync(request);
      if (_disposed) return _cancelledResult();
      if (pending.isNotEmpty &&
          !pending.any(
            (mutation) =>
                response.acknowledgedMutationIds.contains(mutation.mutationId),
          )) {
        throw const SyncFailure('sync_no_progress', '同步服务未确认待同步记录，请稍后重试');
      }
      final hasMoreRemoteChanges = response.changes.length >= request.limit;
      if (hasMoreRemoteChanges && response.nextCursor == request.cursor) {
        throw const SyncFailure(
          'sync_cursor_not_advanced',
          '同步服务未推进记录位置，请稍后重试',
        );
      }
      // Hydrate one entry at a time so a large incoming batch does not start
      // every attachment download and validation at once.
      final changes = <DiaryEntry>[];
      for (final entry in response.changes) {
        if (_disposed) return _cancelledResult();
        changes.add(await attachmentTransfer.hydrateEntry(entry));
      }
      final conflicts = <Conflict>[];
      for (final conflict in response.conflicts) {
        if (_disposed) return _cancelledResult();
        conflicts.add(
          Conflict(
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
        );
      }
      if (_disposed) return _cancelledResult();
      await repository.applySyncResult(
        SyncResult(
          changes: changes,
          conflicts: conflicts,
          acknowledgedMutationIds: response.acknowledgedMutationIds,
          nextCursor: response.nextCursor,
        ),
      );
      localDataChanged = changes.isNotEmpty || conflicts.isNotEmpty;
      if (_disposed) return _cancelledResult();
      // Attachment repair happens after the remote transaction. Keep its
      // committed cursor if a later historical file cannot be read.
      before = await repository.getSyncState();
      if (_disposed) return _cancelledResult();
      var left = await repository.countPendingMutations();
      if (_disposed) return _cancelledResult();
      // New mutations have priority. Repair historical attachment metadata in
      // bounded pages only when the outbox has drained, never by loading all
      // journal entries for each message batch.
      if (left == 0 && !hasMoreRemoteChanges && !_backfillComplete) {
        final page = await repository.listAttachmentBackfillEntries(
          afterId: _backfillAfterId,
          limit: attachmentBackfillBatchSize,
        );
        if (_disposed) return _cancelledResult();
        final sources = {for (final entry in page) entry.id: entry};
        await attachmentTransfer.backfillEntries(
          page.where((entry) => !entry.isDeleted),
          (entry) async {
            if (!_disposed) {
              final merged = await repository.mergeAttachmentIds(
                sources[entry.id]!,
                entry.attachmentIds,
              );
              localDataChanged = localDataChanged || merged;
            }
          },
        );
        if (_disposed) return _cancelledResult();
        if (page.isNotEmpty) _backfillAfterId = page.last.id;
        _backfillComplete = page.length < attachmentBackfillBatchSize;
        left = await repository.countPendingMutations();
        if (_disposed) return _cancelledResult();
      }
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
      if (_disposed) return _cancelledResult();
      onStateChanged?.call(state);
      return SyncRunResult(
        status: status,
        pendingCount: left,
        hasMoreWork: hasMoreRemoteChanges || !_backfillComplete,
        localDataChanged: localDataChanged,
      );
    } catch (error) {
      if (_disposed) return _cancelledResult();
      final state = SyncState(
        deviceId: before.deviceId,
        cursor: before.cursor,
        lastSuccessAt: before.lastSuccessAt,
        lastError: '$error',
        status: SyncStatus.failed,
      );
      await repository.setSyncState(state);
      if (_disposed) return _cancelledResult();
      onStateChanged?.call(state);
      return SyncRunResult(
        status: SyncStatus.failed,
        pendingCount: await repository.countPendingMutations(),
        localDataChanged: localDataChanged,
        error: error,
      );
    } finally {
      _running = false;
    }
  }
}
