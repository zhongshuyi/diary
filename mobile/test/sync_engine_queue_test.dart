import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/outbox_mutation.dart';
import 'package:diary/domain/sync_state.dart';
import 'package:diary/sync/attachment_transfer.dart';
import 'package:diary/sync/sync_client.dart';
import 'package:diary/sync/sync_engine.dart';
import 'package:diary/sync/sync_models.dart';

void main() {
  testWidgets('periodic sync requests the queue without running the network', (
    tester,
  ) async {
    final repository = MemoryDiaryRepository();
    await repository.save(_entry(0));
    final client = _RecordingSyncClient();
    var queuedRequests = 0;
    final engine = SyncEngine(
      repository: repository,
      client: client,
      interval: const Duration(seconds: 5),
      onAutoSyncRequested: () => queuedRequests++,
    );
    addTearDown(engine.dispose);

    engine.start();
    await tester.pump(const Duration(milliseconds: 4999));
    expect(queuedRequests, 0);
    expect(client.requests, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(queuedRequests, 1);
    expect(client.requests, isEmpty);
    await tester.pump(const Duration(seconds: 5));
    expect(queuedRequests, 2);
    expect(client.requests, isEmpty);
    expect(await repository.listPendingMutations(), hasLength(1));

    engine.stop();
    await tester.pump(const Duration(seconds: 5));
    expect(queuedRequests, 2);
    expect(client.requests, isEmpty);
  });

  test(
    'a configured batch sends 20 mutations then drains the final five',
    () async {
      final repository = MemoryDiaryRepository();
      for (var index = 0; index < 25; index++) {
        await repository.save(_entry(index));
      }
      final originalIds = (await repository.listPendingMutations())
          .map((mutation) => mutation.mutationId)
          .toSet();
      final client = _RecordingSyncClient();
      final engine = SyncEngine(
        repository: repository,
        client: client,
        mutationBatchSize: 20,
      );
      addTearDown(engine.dispose);

      final first = await engine.syncNow();
      expect(first.localDataChanged, isFalse);
      expect(client.requests, hasLength(1));
      expect(client.requests.single.changes, hasLength(20));
      expect(first.status, SyncStatus.pending);
      expect(first.pendingCount, 5);
      expect(await repository.listPendingMutations(), hasLength(5));

      final second = await engine.syncNow();
      expect(client.requests, hasLength(2));
      expect(client.requests.last.changes, hasLength(5));
      expect(second.status, SyncStatus.synced);
      expect(second.pendingCount, 0);
      expect(await repository.listPendingMutations(), isEmpty);
      final sentIds = client.requests
          .expand((request) => request.changes)
          .map((change) => change['mutationId'] as String)
          .toList();
      expect(sentIds, hasLength(25));
      expect(sentIds.toSet(), originalIds);
    },
  );

  test('the default engine still sends batches of 100 mutations', () async {
    final repository = MemoryDiaryRepository();
    for (var index = 0; index < 105; index++) {
      await repository.save(_entry(index));
    }
    final client = _RecordingSyncClient();
    final engine = SyncEngine(repository: repository, client: client);
    addTearDown(engine.dispose);

    final first = await engine.syncNow();
    expect(client.requests.single.changes, hasLength(100));
    expect(first.status, SyncStatus.pending);
    expect(first.pendingCount, 5);

    final second = await engine.syncNow();
    expect(client.requests.last.changes, hasLength(5));
    expect(second.status, SyncStatus.synced);
    expect(second.pendingCount, 0);
    expect(await repository.listPendingMutations(), isEmpty);
  });

  test(
    'a disposed engine ignores a late response and preserves its outbox',
    () async {
      final repository = MemoryDiaryRepository();
      await repository.save(_entry(0));
      const originalState = SyncState(
        deviceId: 'original-device',
        cursor: '7',
        status: SyncStatus.pending,
      );
      await repository.setSyncState(originalState);
      final originalMutationIds = (await repository.listPendingMutations())
          .map((mutation) => mutation.mutationId)
          .toList();
      final client = _DelayedSyncClient();
      final emittedStates = <SyncState>[];
      final engine = SyncEngine(
        repository: repository,
        client: client,
        onStateChanged: emittedStates.add,
      );

      final synchronization = engine.syncNow();
      await client.requestStarted.future;
      expect(emittedStates.map((state) => state.status), [SyncStatus.syncing]);
      engine.dispose();
      expect(client.closed, isTrue);
      client.response.complete(
        SyncResponse(
          nextCursor: 'stale-server-cursor',
          changes: [_entry(1)],
          conflicts: const [],
          acknowledgedMutationIds: originalMutationIds,
        ),
      );

      final result = await synchronization;
      expect(result.status, SyncStatus.pending);
      expect(result.pendingCount, 1);
      expect((await repository.load()).map((entry) => entry.id), [
        'queued-entry-0',
      ]);
      expect(
        (await repository.listPendingMutations()).map(
          (mutation) => mutation.mutationId,
        ),
        originalMutationIds,
      );
      expect(await repository.getSyncState(), same(originalState));
      expect(emittedStates.map((state) => state.status), [SyncStatus.syncing]);

      final afterDisposal = await engine.syncNow();
      expect(afterDisposal.pendingCount, 1);
      expect(client.requests, hasLength(1));
      expect(emittedStates.map((state) => state.status), [SyncStatus.syncing]);
    },
  );

  test(
    'historical attachment backfill runs in bounded pages without full loads',
    () async {
      final history = [
        for (var index = 0; index < 25; index++)
          _entry(
            index,
          ).copyWith(id: 'history-${index.toString().padLeft(2, '0')}'),
      ];
      final repository = _BackfillTrackingRepository(history);
      final client = _RecordingSyncClient();
      final transfer = _RecordingAttachmentTransfer(client);
      final engine = SyncEngine(
        repository: repository,
        client: client,
        mutationBatchSize: 20,
        attachmentBackfillBatchSize: 10,
        attachmentTransfer: transfer,
      );
      addTearDown(engine.dispose);

      final first = await engine.syncNow();
      expect(first.status, SyncStatus.synced);
      expect(first.pendingCount, 0);
      expect(first.hasMoreWork, isTrue);
      expect(transfer.pages.map((page) => page.length), [10]);

      final second = await engine.syncNow();
      expect(second.hasMoreWork, isTrue);
      expect(transfer.pages.map((page) => page.length), [10, 10]);

      final third = await engine.syncNow();
      expect(third.status, SyncStatus.synced);
      expect(third.pendingCount, 0);
      expect(third.hasMoreWork, isFalse);
      expect(transfer.pages.map((page) => page.length), [10, 10, 5]);
      expect(repository.pageAfterIds, [null, 'history-09', 'history-19']);
      expect(repository.pageLimits, [10, 10, 10]);
      expect(repository.loadCalls, 0);
      expect(
        transfer.pages.expand((page) => page).map((entry) => entry.id),
        history.map((entry) => entry.id),
      );
      expect(
        client.requests.every((request) => request.changes.isEmpty),
        isTrue,
      );

      final subsequent = await engine.syncNow();
      expect(subsequent.hasMoreWork, isFalse);
      expect(transfer.pages, hasLength(3));
      expect(repository.pageAfterIds, hasLength(3));
      expect(repository.loadCalls, 0);
    },
  );

  test(
    'an HTTP 200 response without acknowledgments fails without losing mutations',
    () async {
      final repository = _BackfillTrackingRepository(const []);
      await repository.save(_entry(0));
      final mutationIds = (await repository.listPendingMutations())
          .map((mutation) => mutation.mutationId)
          .toList();
      var requests = 0;
      final client = SyncClient(
        baseUrl: 'http://unused.invalid',
        client: MockClient((request) async {
          requests++;
          expect(request.url.path, '/api/v2/sync');
          expect((jsonDecode(request.body) as Map)['changes'], hasLength(1));
          return http.Response(
            jsonEncode({
              'data': {
                'nextCursor': 'unconfirmed-cursor',
                'changes': const [],
                'conflicts': const [],
                'appliedMutationIds': const [],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final transfer = _RecordingAttachmentTransfer(client);
      final engine = SyncEngine(
        repository: repository,
        client: client,
        mutationBatchSize: 20,
        attachmentTransfer: transfer,
      );
      addTearDown(engine.dispose);

      final result = await engine.syncNow();
      expect(result.status, SyncStatus.failed);
      expect(
        result.error,
        isA<SyncFailure>().having(
          (failure) => failure.code,
          'code',
          'sync_no_progress',
        ),
      );
      expect(result.pendingCount, 1);
      expect(requests, 1);
      expect(
        (await repository.listPendingMutations()).map(
          (mutation) => mutation.mutationId,
        ),
        mutationIds,
      );
      expect((await repository.getSyncState()).cursor, '0');
      expect(repository.pageAfterIds, isEmpty);
      expect(transfer.pages, isEmpty);
      expect(repository.loadCalls, 0);
    },
  );

  test(
    'pending message batches take priority over historical attachment backfill',
    () async {
      final repository = _BackfillTrackingRepository(const []);
      for (var index = 0; index < 25; index++) {
        await repository.save(_entry(index));
      }
      final client = _RecordingSyncClient();
      final transfer = _RecordingAttachmentTransfer(client);
      final engine = SyncEngine(
        repository: repository,
        client: client,
        mutationBatchSize: 20,
        attachmentTransfer: transfer,
      );
      addTearDown(engine.dispose);

      final result = await engine.syncNow();
      expect(result.status, SyncStatus.pending);
      expect(result.pendingCount, 5);
      expect(client.requests.single.changes, hasLength(20));
      expect(repository.pageAfterIds, isEmpty);
      expect(transfer.pages, isEmpty);
      expect(repository.loadCalls, 0);
    },
  );

  test(
    'attachment backfill failure keeps an already applied response cursor',
    () async {
      final repository = _BackfillTrackingRepository([_entry(0)]);
      final client = _RecordingSyncClient();
      final engine = SyncEngine(
        repository: repository,
        client: client,
        attachmentTransfer: _FailingBackfillTransfer(client),
      );
      addTearDown(engine.dispose);

      final result = await engine.syncNow();
      expect(result.status, SyncStatus.failed);
      expect(result.pendingCount, 0);
      expect(result.error, isA<StateError>());
      expect((await repository.getSyncState()).cursor, '1');
      expect(repository.pageAfterIds, [null]);
      expect(repository.loadCalls, 0);
    },
  );

  test('only committed local data changes request a diary refresh', () async {
    final repository = MemoryDiaryRepository([_entry(0)]);
    final client = _RecordingSyncClient();
    final engine = SyncEngine(
      repository: repository,
      client: client,
      attachmentTransfer: _SavingBackfillTransfer(client),
    );
    addTearDown(engine.dispose);

    final repaired = await engine.syncNow();
    expect(repaired.localDataChanged, isTrue);
    expect(repaired.pendingCount, 1);
    expect((await repository.load()).single.attachmentIds, ['asset-test']);

    final acknowledged = await engine.syncNow();
    expect(acknowledged.localDataChanged, isFalse);
    expect(acknowledged.pendingCount, 0);
  });

  test(
    'remote records arrive in pages of 20 then five before backfill',
    () async {
      final remoteEntries = [
        for (var index = 0; index < 25; index++)
          _entry(index).copyWith(id: 'remote-$index'),
      ];
      final repository = _BackfillTrackingRepository(const []);
      final client = _PagedRemoteSyncClient(remoteEntries);
      final transfer = _RecordingAttachmentTransfer(client);
      final engine = SyncEngine(
        repository: repository,
        client: client,
        mutationBatchSize: 20,
        attachmentTransfer: transfer,
      );
      addTearDown(engine.dispose);

      final first = await engine.syncNow();
      expect(first.error, isNull);
      expect(first.pendingCount, 0);
      expect(first.hasMoreWork, isTrue);
      expect(first.localDataChanged, isTrue);
      expect(client.requests.single.limit, 20);
      expect(client.requests.single.cursor, '0');
      expect((await repository.getSyncState()).cursor, '20');
      expect(await repository.committedEntries(), hasLength(20));
      expect(repository.pageAfterIds, isEmpty);
      expect(transfer.pages, isEmpty);

      final second = await engine.syncNow();
      expect(second.error, isNull);
      expect(second.status, SyncStatus.synced);
      expect(second.pendingCount, 0);
      expect(second.hasMoreWork, isFalse);
      expect(second.localDataChanged, isTrue);
      expect(client.requests.map((request) => request.limit), [20, 20]);
      expect(client.requests.map((request) => request.cursor), ['0', '20']);
      expect((await repository.getSyncState()).cursor, '25');
      final committedIds = (await repository.committedEntries())
          .map((entry) => entry.id)
          .toList();
      expect(committedIds, hasLength(25));
      expect(
        committedIds.toSet(),
        remoteEntries.map((entry) => entry.id).toSet(),
      );
      expect(repository.pageAfterIds, [null]);
      expect(transfer.pages.single, isEmpty);
      expect(repository.loadCalls, 0);
    },
  );

  test(
    'a full remote page without cursor progress fails before applying',
    () async {
      final repository = _BackfillTrackingRepository(const []);
      final client = _PagedRemoteSyncClient([
        for (var index = 0; index < 20; index++) _entry(index),
      ], keepCursor: true);
      final transfer = _RecordingAttachmentTransfer(client);
      final engine = SyncEngine(
        repository: repository,
        client: client,
        mutationBatchSize: 20,
        attachmentTransfer: transfer,
      );
      addTearDown(engine.dispose);

      final result = await engine.syncNow();
      expect(result.status, SyncStatus.failed);
      expect(
        result.error,
        isA<SyncFailure>().having(
          (failure) => failure.code,
          'code',
          'sync_cursor_not_advanced',
        ),
      );
      expect(result.pendingCount, 0);
      expect(result.localDataChanged, isFalse);
      expect(client.requests, hasLength(1));
      expect(client.requests.single.limit, 20);
      expect((await repository.getSyncState()).cursor, '0');
      expect(await repository.committedEntries(), isEmpty);
      expect(repository.pageAfterIds, isEmpty);
      expect(transfer.pages, isEmpty);
      expect(repository.loadCalls, 0);
    },
  );
}

DiaryEntry _entry(int index) {
  final timestamp = DateTime(2026, 10, 7, 12).add(Duration(seconds: index));
  return DiaryEntry(
    id: 'queued-entry-$index',
    createdAt: timestamp,
    updatedAt: timestamp,
    title: '队列消息 $index',
    content: '内容 $index',
    contentText: '内容 $index',
    category: '生活',
  );
}

class _RecordingSyncClient extends SyncClient {
  _RecordingSyncClient() : super(baseUrl: 'http://unused.invalid');

  final requests = <SyncRequest>[];

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    requests.add(request);
    return SyncResponse(
      nextCursor: '${requests.length}',
      changes: const [],
      conflicts: const [],
      acknowledgedMutationIds: request.changes
          .map((change) => change['mutationId'] as String)
          .toList(),
    );
  }
}

class _DelayedSyncClient extends SyncClient {
  _DelayedSyncClient() : super(baseUrl: 'http://unused.invalid');

  final requests = <SyncRequest>[];
  final requestStarted = Completer<void>();
  final response = Completer<SyncResponse>();
  var closed = false;

  @override
  Future<SyncResponse> sync(SyncRequest request) {
    requests.add(request);
    requestStarted.complete();
    return response.future;
  }

  @override
  void close() {
    closed = true;
    super.close();
  }
}

class _BackfillTrackingRepository extends MemoryDiaryRepository {
  _BackfillTrackingRepository(List<DiaryEntry> history)
    : history = List<DiaryEntry>.of(history)
        ..sort((a, b) => a.id.compareTo(b.id)),
      super(List<DiaryEntry>.of(history));

  final List<DiaryEntry> history;
  final pageAfterIds = <String?>[];
  final pageLimits = <int>[];
  var loadCalls = 0;

  @override
  Future<List<DiaryEntry>> load({bool includeTrash = false}) async {
    loadCalls++;
    throw StateError('sync must not load all historical entries');
  }

  Future<List<DiaryEntry>> committedEntries() => super.load(includeTrash: true);

  @override
  Future<List<DiaryEntry>> listAttachmentBackfillEntries({
    String? afterId,
    int limit = 10,
  }) async {
    pageAfterIds.add(afterId);
    pageLimits.add(limit);
    return history
        .where((entry) => afterId == null || entry.id.compareTo(afterId) > 0)
        .take(limit)
        .toList();
  }
}

class _RecordingAttachmentTransfer extends AttachmentTransfer {
  _RecordingAttachmentTransfer(SyncClient client) : super(client: client);

  final pages = <List<DiaryEntry>>[];

  @override
  Future<List<Map<String, dynamic>>> prepareChanges(
    Iterable<OutboxMutation> mutations,
  ) async => [
    for (final mutation in mutations)
      Map<String, dynamic>.from(mutation.payload),
  ];

  @override
  Future<void> backfillEntries(
    Iterable<DiaryEntry> entries,
    Future<void> Function(DiaryEntry entry) save,
  ) async {
    pages.add(entries.toList());
  }

  @override
  Future<DiaryEntry> hydrateEntry(DiaryEntry entry) async => entry;
}

class _FailingBackfillTransfer extends _RecordingAttachmentTransfer {
  _FailingBackfillTransfer(super.client);

  @override
  Future<void> backfillEntries(
    Iterable<DiaryEntry> entries,
    Future<void> Function(DiaryEntry entry) save,
  ) async {
    throw StateError('attachment backfill failure');
  }
}

class _SavingBackfillTransfer extends _RecordingAttachmentTransfer {
  _SavingBackfillTransfer(super.client);

  @override
  Future<void> backfillEntries(
    Iterable<DiaryEntry> entries,
    Future<void> Function(DiaryEntry entry) save,
  ) async {
    for (final entry in entries) {
      await save(entry.copyWith(attachmentIds: ['asset-test']));
    }
  }
}

class _PagedRemoteSyncClient extends SyncClient {
  _PagedRemoteSyncClient(this.entries, {this.keepCursor = false})
    : super(baseUrl: 'http://unused.invalid');

  final List<DiaryEntry> entries;
  final bool keepCursor;
  final requests = <SyncRequest>[];

  @override
  Future<SyncResponse> sync(SyncRequest request) async {
    requests.add(request);
    final offset = int.parse(request.cursor);
    final changes = entries.skip(offset).take(request.limit).toList();
    return SyncResponse(
      nextCursor: keepCursor ? request.cursor : '${offset + changes.length}',
      changes: changes,
      conflicts: const [],
      acknowledgedMutationIds: request.changes
          .map((change) => change['mutationId'] as String)
          .toList(),
    );
  }
}
