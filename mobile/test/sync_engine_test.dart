import 'package:flutter_test/flutter_test.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/sync/sync_client.dart';
import 'package:diary/sync/sync_engine.dart';

import 'sync_client_test.dart' show FakeClient;

DiaryEntry _entry() => DiaryEntry(
  id: 'local-1',
  createdAt: DateTime(2026, 9, 16),
  updatedAt: DateTime(2026, 9, 16),
  title: '本地',
  content: '内容',
  contentText: '内容',
  category: '工作',
);

void main() {
  test('flushes outbox and advances cursor', () async {
    final repository = MemoryDiaryRepository();
    await repository.save(_entry());
    final states = <String>[];
    final engine = SyncEngine(
      repository: repository,
      client: SyncClient(
        baseUrl: 'http://localhost:8787',
        client: FakeClient(),
      ),
      onStateChanged: (state) => states.add(state.status.name),
    );

    final result = await engine.syncNow();

    expect(result.status.name, 'synced');
    expect(result.pendingCount, 0);
    expect((await repository.getSyncState()).cursor, '4');
    expect(
      (await repository.load()).any((entry) => entry.id == 'remote-1'),
      isTrue,
    );
    expect(states, containsAllInOrder(<String>['syncing', 'synced']));
    engine.stop();
  });

  test('does not overlap concurrent sync runs', () async {
    final repository = MemoryDiaryRepository();
    final engine = SyncEngine(
      repository: repository,
      client: SyncClient(
        baseUrl: 'http://localhost:8787',
        client: FakeClient(),
      ),
    );
    final first = engine.syncNow();
    final second = await engine.syncNow();
    await first;
    expect(second.status.name, 'syncing');
  });
}
