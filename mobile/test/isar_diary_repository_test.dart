import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:diary/data/isar_diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  test('persists diary records and supports the recycle bin flow', () async {
    final tempDirectory = await Directory.systemTemp.createTemp('diary-isar-');
    final repository = await IsarDiaryRepository.open(
      directoryPath: tempDirectory.path,
      initialEntries: [_entry],
    );

    try {
      expect((await repository.load()).single.id, _entry.id);
      expect((await repository.load()).single.moodLabel, '平静');
      expect((await repository.search('数据库')).single.id, _entry.id);

      await repository.moveToTrash(_entry.id);
      expect(await repository.load(), isEmpty);
      expect(
        (await repository.load(includeTrash: true)).single.isInTrash,
        true,
      );

      await repository.restore(_entry.id);
      expect((await repository.load()).single.isInTrash, false);

      await repository.deletePermanently(_entry.id);
      expect(await repository.load(includeTrash: true), isEmpty);
    } finally {
      await repository.close();
      await tempDirectory.delete(recursive: true);
    }
  });
}

final _entry = DiaryEntry(
  id: 'isar-test-entry',
  createdAt: DateTime(2026, 9, 15, 8, 40),
  updatedAt: DateTime(2026, 9, 15, 8, 40),
  title: 'Isar 测试',
  content: '验证本地数据库',
  contentText: '验证本地数据库',
  mood: .7,
  moodLabel: '平静',
  category: '测试',
  tags: const ['本地', '数据库'],
);
