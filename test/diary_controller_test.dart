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
}
