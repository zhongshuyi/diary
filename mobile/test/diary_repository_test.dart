import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';

void main() {
  test(
    'repository can trash, restore and permanently delete an entry',
    () async {
      final repository = MemoryDiaryRepository([
        _entry('one', '第一篇'),
        _entry('two', '第二篇'),
      ]);

      await repository.moveToTrash('one');
      expect((await repository.load(includeTrash: false)).map((e) => e.id), [
        'two',
      ]);
      expect((await repository.load(includeTrash: true)).length, 2);

      await repository.restore('one');
      expect((await repository.load()).map((e) => e.id), contains('one'));

      await repository.deletePermanently('one');
      expect((await repository.load(includeTrash: true)).map((e) => e.id), [
        'two',
      ]);
      final deletion = (await repository.listPendingMutations()).single;
      final tombstone = DiaryEntry.fromJson(
        Map<String, dynamic>.from(deletion.payload['entry'] as Map),
      );
      expect(tombstone.isDeleted, isTrue);
    },
  );

  test(
    'repository keeps entries sorted by updated time and searches them',
    () async {
      final repository = MemoryDiaryRepository([
        _entry('old', '一段旧记录', day: 10),
        _entry('new', '慢下来，生活才会发光', day: 15),
      ]);

      final entries = await repository.search('慢下来');

      expect(entries.single.id, 'new');
      expect((await repository.load()).first.id, 'new');
    },
  );

  test('repository clears only entries in the recycle bin', () async {
    final repository = MemoryDiaryRepository([
      _entry('keep', '保留的日记'),
      _entry('trash-one', '第一篇待清理日记'),
      _entry('trash-two', '第二篇待清理日记'),
    ]);

    await repository.moveToTrash('trash-one');
    await repository.moveToTrash('trash-two');
    await repository.clearTrash();

    expect(
      (await repository.load(includeTrash: true)).map((entry) => entry.id),
      ['keep'],
    );
    expect(await repository.listPendingMutations(), hasLength(2));
  });

  test(
    'a synchronized tombstone removes a local record without entering trash',
    () async {
      final local = _entry('one', '第一篇');
      final repository = MemoryDiaryRepository([local]);

      await repository.applySyncResult(
        SyncResult(changes: [DiaryEntry.tombstone(local)]),
      );

      expect(await repository.load(includeTrash: true), isEmpty);
    },
  );

  test(
    'fallback repository can edit its read-only load results safely',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SharedPreferencesDiaryRepository(
        initialEntries: [_entry('one', '第一篇')],
      );
      await repository.load();

      await repository.save(_entry('two', '第二篇'));
      await repository.save(_entry('one', '修改后'));
      await repository.moveToTrash('one');
      expect((await repository.load()).map((entry) => entry.id), ['two']);

      await repository.restore('one');
      expect((await repository.load()).length, 2);
      await repository.deletePermanently('one');
      expect((await repository.load()).map((entry) => entry.id), ['two']);
    },
  );

  test('fallback save returns the same entry a later load sees', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SharedPreferencesDiaryRepository();
    final stored = await repository.saveAndGet(
      _entry('trash', '留在回收站').copyWith(isInTrash: true),
    );

    expect(stored, (await repository.load(includeTrash: true)).single);
    expect(stored.deletedAt, isNotNull);
  });
}

DiaryEntry _entry(String id, String title, {int day = 15}) {
  return DiaryEntry(
    id: id,
    createdAt: DateTime(2026, 9, day),
    updatedAt: DateTime(2026, 9, day),
    title: title,
    content: title,
    contentText: title,
    category: '生活',
  );
}
