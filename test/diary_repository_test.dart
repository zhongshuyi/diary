import 'package:flutter_test/flutter_test.dart';

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
