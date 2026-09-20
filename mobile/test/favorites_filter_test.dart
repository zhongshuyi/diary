import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/favorites_filter.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry _entry({
  required String id,
  String title = '普通日记',
  String category = '生活',
  List<String> tags = const [],
  bool favorite = false,
  bool inTrash = false,
  bool deleted = false,
  bool conflict = false,
}) {
  final now = DateTime(2026, 9, 20, 9);
  return DiaryEntry(
    id: id,
    createdAt: now,
    updatedAt: now,
    title: title,
    content: title,
    contentText: title,
    category: category,
    tags: tags,
    isFavorite: favorite,
    isInTrash: inTrash,
    isDeleted: deleted,
    isConflict: conflict,
  );
}

void main() {
  test(
    'keeps only visible favorites matching query, category, and every tag',
    () {
      final filter = FavoritesFilter(
        query: '山路',
        category: '旅行',
        tags: const {'照片', '秋天'},
      );

      expect(
        filter.matches(
          _entry(
            id: 'kept',
            title: '山路',
            category: '旅行',
            tags: const ['照片', '秋天'],
            favorite: true,
          ),
        ),
        isTrue,
      );
      expect(
        filter.matches(
          _entry(
            id: 'tag-near-miss',
            title: '山路',
            category: '旅行',
            tags: const ['照片'],
            favorite: true,
          ),
        ),
        isFalse,
      );
      expect(filter.matches(_entry(id: 'ordinary')), isFalse);
      expect(
        filter.matches(_entry(id: 'trash', favorite: true, inTrash: true)),
        isFalse,
      );
      expect(
        filter.matches(_entry(id: 'deleted', favorite: true, deleted: true)),
        isFalse,
      );
      expect(
        filter.matches(_entry(id: 'conflict', favorite: true, conflict: true)),
        isFalse,
      );
    },
  );

  test('clearing conditions preserves the search query', () {
    final cleared = FavoritesFilter(
      query: '旧句子',
      category: '工作',
      tags: const {'项目'},
    ).clearConditions();

    expect(cleared.query, '旧句子');
    expect(cleared.category, '全部');
    expect(cleared.tags, isEmpty);
    expect(cleared.hasActiveConditions, isFalse);
  });
}
