import 'package:flutter_test/flutter_test.dart';

import 'package:diary/domain/diary_entry.dart';

void main() {
  test('round trips diary metadata through JSON', () {
    final entry = DiaryEntry(
      id: 'entry-1',
      createdAt: DateTime(2026, 9, 15, 8, 40),
      updatedAt: DateTime(2026, 9, 15, 9, 10),
      title: '一段值得留下的话',
      content: '[{"insert":"今天很好。\\n"}]',
      contentText: '今天很好。',
      editorType: DiaryEditorType.richText,
      mood: 0.82,
      moodLabel: '明亮',
      category: '生活',
      tags: const ['散步', '慢生活'],
      imagePaths: const ['photo://one'],
      weather: const ['晴', '24°'],
      latitude: 31.23,
      longitude: 121.47,
      isFavorite: true,
    );

    final restored = DiaryEntry.fromJson(entry.toJson());

    expect(restored, entry);
    expect(restored.editorType, DiaryEditorType.richText);
    expect(restored.moodLabel, '明亮');
    expect(restored.tags, contains('慢生活'));
    expect(restored.imagePaths, contains('photo://one'));
  });

  test('matches a query across title, text, tags and category', () {
    final entry = DiaryEntry(
      id: 'entry-2',
      createdAt: DateTime(2026, 9, 15),
      updatedAt: DateTime(2026, 9, 15),
      title: '把周末留给自己',
      content: '读完几页书，煮了一锅番茄汤。',
      contentText: '读完几页书，煮了一锅番茄汤。',
      category: '生活',
      tags: const ['周末', '小确幸'],
    );

    expect(entry.matches('番茄'), isTrue);
    expect(entry.matches('小确幸'), isTrue);
    expect(entry.matches('生活'), isTrue);
    expect(entry.matches('不存在'), isFalse);
  });

  test('reads backups from before optional mood labels existed', () {
    final entry = DiaryEntry(
      id: 'entry-legacy',
      createdAt: DateTime(2026, 9, 15),
      updatedAt: DateTime(2026, 9, 15),
      title: '旧日记',
      content: '内容',
      contentText: '内容',
      category: '生活',
    );
    final legacyPayload = entry.toJson()..remove('moodLabel');

    expect(DiaryEntry.fromJson(legacyPayload).moodLabel, isNull);
  });
}
