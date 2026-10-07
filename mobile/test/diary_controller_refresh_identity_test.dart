import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/diary_controller.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';

class _CloningRepository extends MemoryDiaryRepository {
  _CloningRepository(super.entries);

  List<DiaryEntry> lastLoad = const [];

  @override
  Future<List<DiaryEntry>> load({bool includeTrash = false}) async {
    lastLoad = (await super.load(
      includeTrash: includeTrash,
    )).map((entry) => DiaryEntry.fromJson(entry.toJson())).toList();
    return lastLoad;
  }
}

DiaryEntry _entry(String id, {bool inTrash = false}) => DiaryEntry(
  id: id,
  createdAt: DateTime(2026, 10, 7),
  updatedAt: DateTime(2026, 10, 7),
  title: 'synthetic $id',
  content: 'synthetic content',
  contentText: 'synthetic content',
  category: inTrash ? 'ignored' : 'personal',
  isInTrash: inTrash,
);

void main() {
  late _CloningRepository repository;
  late DiaryController controller;

  setUp(() async {
    repository = _CloningRepository([
      _entry('active'),
      _entry('trash', inTrash: true),
    ]);
    controller = DiaryController(repository: repository);
    await controller.initialize();
    addTearDown(controller.dispose);
  });

  test(
    'an unchanged refresh preserves lists even when loaded entities are clones',
    () async {
      final entries = controller.entries;
      final trash = controller.trash;
      final categories = controller.categories;

      await controller.refresh(notifyBeforeLoad: false);

      expect(controller.entries, same(entries));
      expect(controller.trash, same(trash));
      expect(controller.categories, same(categories));
      expect(
        repository.lastLoad.singleWhere((entry) => entry.id == 'active'),
        isNot(same(controller.entries.single)),
      );
    },
  );

  test(
    'a trash-only change preserves the active list and category cache',
    () async {
      final entries = controller.entries;
      final trash = controller.trash;
      final categories = controller.categories;
      await repository.save(
        trash.single.copyWith(
          content: 'changed trash',
          contentText: 'changed trash',
          updatedAt: DateTime(2026, 10, 8),
        ),
      );

      await controller.refresh(notifyBeforeLoad: false);

      expect(controller.entries, same(entries));
      expect(controller.categories, same(categories));
      expect(controller.trash, isNot(same(trash)));
      expect(controller.trash.single.content, 'changed trash');
    },
  );

  test(
    'an active category change updates its list and category cache',
    () async {
      final entries = controller.entries;
      final trash = controller.trash;
      final categories = controller.categories;
      await repository.save(
        entries.single.copyWith(
          category: 'updated',
          updatedAt: DateTime(2026, 10, 8),
        ),
      );

      await controller.refresh(notifyBeforeLoad: false);

      expect(controller.entries, isNot(same(entries)));
      expect(controller.trash, same(trash));
      expect(controller.categories, isNot(same(categories)));
      expect(controller.categories, contains('updated'));
      expect(controller.categories, isNot(contains('personal')));
      expect(controller.entries.single.category, 'updated');
    },
  );
}
