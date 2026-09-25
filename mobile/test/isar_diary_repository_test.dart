import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/isar_diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';

void main() {
  setUpAll(() async {
    await Isar.initializeIsarCore(download: true);
  });

  test('opens a new diary database without sample entries', () async {
    final tempDirectory = await Directory.systemTemp.createTemp('diary-isar-');
    final repository = await IsarDiaryRepository.open(
      directoryPath: tempDirectory.path,
    );

    try {
      expect(await repository.load(), isEmpty);
    } finally {
      await repository.close();
      await tempDirectory.delete(recursive: true);
    }
  });

  test('creates a missing database directory before opening Isar', () async {
    final tempDirectory = await Directory.systemTemp.createTemp('diary-isar-');
    final databaseDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}new${Platform.pathSeparator}diary_database',
    );

    expect(await databaseDirectory.exists(), isFalse);

    final repository = await IsarDiaryRepository.open(
      directoryPath: databaseDirectory.path,
    );

    try {
      expect(await databaseDirectory.exists(), isTrue);
      expect(await repository.load(), isEmpty);
    } finally {
      await repository.close();
      await tempDirectory.delete(recursive: true);
    }
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
      final stored = await repository.saveAndGet(
        _entry.copyWith(updatedAt: DateTime(2026, 9, 15, 9)),
      );
      expect(stored.revision, 2);
      expect(stored.deviceId, 'mobile');

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
      final deletion = (await repository.listPendingMutations()).single;
      final tombstone = DiaryEntry.fromJson(
        Map<String, dynamic>.from(deletion.payload['entry'] as Map),
      );
      expect(tombstone.isDeleted, isTrue);
    } finally {
      await repository.close();
      await tempDirectory.delete(recursive: true);
    }
  });

  test('limits pending mutations in the database query', () async {
    final tempDirectory = await Directory.systemTemp.createTemp('diary-isar-');
    final repository = await IsarDiaryRepository.open(
      directoryPath: tempDirectory.path,
    );

    try {
      for (var index = 0; index < 3; index++) {
        await repository.save(_entry.copyWith(id: 'pending-$index'));
      }
      expect(await repository.listPendingMutations(limit: 0), isEmpty);
      expect(await repository.listPendingMutations(limit: 1), hasLength(1));
      expect(await repository.listPendingMutations(limit: 2), hasLength(2));
      expect(await repository.listPendingMutations(), hasLength(3));
    } finally {
      await repository.close();
      await tempDirectory.delete(recursive: true);
    }
  });

  test(
    'removes an entry when the desktop repository receives a tombstone',
    () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'diary-isar-',
      );
      final repository = await IsarDiaryRepository.open(
        directoryPath: tempDirectory.path,
        initialEntries: [_entry],
      );

      try {
        await repository.applySyncResult(
          SyncResult(changes: [DiaryEntry.tombstone(_entry)]),
        );
        expect(await repository.load(includeTrash: true), isEmpty);
      } finally {
        await repository.close();
        await tempDirectory.delete(recursive: true);
      }
    },
  );
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
