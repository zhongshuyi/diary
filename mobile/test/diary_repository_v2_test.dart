import 'package:flutter_test/flutter_test.dart';

import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_query.dart';

DiaryEntry makeEntry(
  String id,
  DateTime at, {
  String category = '生活',
  List<String> tags = const [],
}) {
  return DiaryEntry(
    id: id,
    createdAt: at,
    updatedAt: at,
    occurredAt: at,
    title: id,
    content: id,
    contentText: id,
    category: category,
    tags: tags,
  );
}

void main() {
  test('filters, pages and sorts taxonomy by frequency then recency', () async {
    final repository = MemoryDiaryRepository([
      makeEntry('old', DateTime(2026, 9, 1), tags: ['工作']),
      makeEntry(
        'new',
        DateTime(2026, 9, 2),
        tags: ['工作', '摘录'],
        category: '灵感',
      ),
      makeEntry('latest', DateTime(2026, 9, 3), tags: ['工作'], category: '灵感'),
    ]);
    final page = await repository.listEntries(
      query: const DiaryQuery(tags: ['工作'], limit: 2),
    );
    expect(page.map((entry) => entry.id), ['latest', 'new']);
    final taxonomy = await repository.taxonomyUsage();
    expect(taxonomy.tags.map((item) => item.value), ['工作', '摘录']);
    expect(taxonomy.categories.map((item) => item.value), ['灵感', '生活']);
  });

  test('batch mutations enqueue one latest mutation per entry', () async {
    final repository = MemoryDiaryRepository([
      makeEntry('a', DateTime(2026, 9, 1)),
      makeEntry('b', DateTime(2026, 9, 1)),
    ]);
    await repository.batchSetFavorite(['a', 'b'], true);
    await repository.batchUpdateOrganization(
      ['a'],
      category: '工作',
      addTags: ['重点'],
    );
    await repository.batchMoveToTrash(['b']);
    expect((await repository.listEntries()).single.id, 'a');
    expect(
      (await repository.load(
        includeTrash: true,
      )).singleWhere((item) => item.id == 'a').category,
      '工作',
    );
    expect((await repository.listPendingMutations()).length, 2);
  });
}
