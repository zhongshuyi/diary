import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/diary_controller.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';

void main() {
  DiaryEntry entry({String id = 'entry-1', bool favorite = false}) {
    final now = DateTime(2026, 9, 15, 9);
    return DiaryEntry(
      id: id,
      createdAt: now,
      updatedAt: now,
      title: '一段记录',
      content: '把今天留给自己。',
      contentText: '把今天留给自己。',
      category: '生活',
      isFavorite: favorite,
    );
  }

  test('coordinates repository use cases and exposes derived state', () async {
    final controller = DiaryController(
      repository: MemoryDiaryRepository([entry()]),
    );

    await controller.initialize();
    expect(controller.entries, hasLength(1));
    expect(controller.categories, contains('生活'));

    await controller.toggleFavorite(controller.entries.single);
    expect(controller.entries.single.isFavorite, isTrue);

    await controller.moveToTrash(controller.entries.single);
    expect(controller.entries, isEmpty);
    expect(controller.trash, hasLength(1));

    await controller.restore(controller.trash.single);
    expect(controller.entries, hasLength(1));
    expect(controller.trash, isEmpty);

    controller.dispose();
  });

  test('saving an entry publishes one completed update', () async {
    final controller = DiaryController(repository: MemoryDiaryRepository());
    await controller.initialize();
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.save(entry());

    expect(notifications, 1);
    expect(controller.entries.single.id, 'entry-1');
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });

  test(
    'ordinary saves avoid a full reload and retain stored revisions',
    () async {
      final repository = _CountingRepository([
        entry(id: 'older').copyWith(updatedAt: DateTime(2026, 9, 15, 10)),
        entry(id: 'newer').copyWith(updatedAt: DateTime(2026, 9, 15, 11)),
      ]);
      final controller = DiaryController(repository: repository);
      await controller.initialize();
      expect(repository.loadCount, 1);

      await controller.save(
        controller.entries.last.copyWith(updatedAt: DateTime(2026, 9, 15, 12)),
      );

      expect(repository.loadCount, 1);
      expect(controller.entries.map((item) => item.id), ['older', 'newer']);
      expect(controller.entries.first.revision, 2);
      controller.dispose();
    },
  );

  test(
    'incremental saves move entries between active and trash lists',
    () async {
      final controller = DiaryController(repository: MemoryDiaryRepository());
      await controller.initialize();

      await controller.save(entry().copyWith(category: '工作'));
      expect(controller.categories, contains('工作'));
      await controller.save(
        controller.entries.single.copyWith(isInTrash: true),
      );
      expect(controller.entries, isEmpty);
      expect(controller.trash.single.id, 'entry-1');
      expect(controller.categories, isNot(contains('工作')));

      await controller.save(controller.trash.single.copyWith(isInTrash: false));
      expect(controller.entries.single.id, 'entry-1');
      expect(controller.trash, isEmpty);
      expect(controller.categories, contains('工作'));
      controller.dispose();
    },
  );

  test('new chat entry appears without reloading the whole diary', () async {
    final repository = _CountingRepository();
    final controller = DiaryController(repository: repository);
    await controller.initialize();
    expect(repository.loadCount, 1);

    await controller.saveNewChatEntry(entry());

    expect(repository.loadCount, 1);
    expect(controller.entries.single.id, 'entry-1');
    controller.dispose();
  });

  test('an older refresh cannot hide a newly saved chat entry', () async {
    final repository = _CountingRepository();
    final controller = DiaryController(repository: repository);
    await controller.initialize();
    repository.loadStarted = Completer<void>();
    repository.releaseLoad = Completer<void>();

    final refresh = controller.refresh(notifyBeforeLoad: false);
    await repository.loadStarted!.future;
    await controller.saveNewChatEntry(entry());
    repository.releaseLoad!.complete();
    await refresh;

    expect(controller.entries.single.id, 'entry-1');
    controller.dispose();
  });

  test('an older refresh cannot hide an ordinary save', () async {
    final repository = _CountingRepository();
    final controller = DiaryController(repository: repository);
    await controller.initialize();
    repository.loadStarted = Completer<void>();
    repository.releaseLoad = Completer<void>();

    final refresh = controller.refresh(notifyBeforeLoad: false);
    await repository.loadStarted!.future;
    await controller.save(entry());
    repository.releaseLoad!.complete();
    await refresh;

    expect(controller.entries.single.id, 'entry-1');
    expect(controller.isLoading, isFalse);
    controller.dispose();
  });
}

class _CountingRepository extends MemoryDiaryRepository {
  _CountingRepository([super.initialEntries]);

  int loadCount = 0;
  Completer<void>? loadStarted;
  Completer<void>? releaseLoad;

  @override
  Future<List<DiaryEntry>> load({bool includeTrash = false}) async {
    loadCount++;
    final entries = await super.load(includeTrash: includeTrash);
    loadStarted?.complete();
    await releaseLoad?.future;
    return entries;
  }
}
