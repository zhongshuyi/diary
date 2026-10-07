import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/isar_diary_repository.dart';
import 'package:diary/data/isar_diary_record.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry _entry(String id, {bool inTrash = false}) => DiaryEntry(
  id: id,
  createdAt: DateTime(2026, 10, 7),
  updatedAt: DateTime(2026, 10, 7),
  title: 'synthetic $id',
  content: 'synthetic content $id',
  contentText: 'synthetic content $id',
  category: 'test',
  imagePaths: ['synthetic-$id.png'],
  attachmentIds: const ['existing-asset'],
  tags: const ['preserved-tag'],
  mood: .8,
  isFavorite: true,
  isInTrash: inTrash,
);

void main() {
  setUpAll(() async => Isar.initializeIsarCore(download: true));

  final factories =
      <String, Future<DiaryRepository> Function(List<DiaryEntry>)>{
        'Memory': (entries) async => MemoryDiaryRepository(entries),
        'SharedPreferences': (entries) async {
          SharedPreferences.setMockInitialValues({});
          final repository = SharedPreferencesDiaryRepository(
            initialEntries: entries,
          );
          await repository.load(includeTrash: true);
          return repository;
        },
        'Isar': (entries) async {
          final directory = await Directory.systemTemp.createTemp(
            'diary-backfill-db-',
          );
          final repository = await IsarDiaryRepository.open(
            initialEntries: entries,
            directoryPath: directory.path,
          );
          addTearDown(() async {
            await repository.close();
            await directory.delete(recursive: true);
          });
          return repository;
        },
      };

  for (final scenario in factories.entries) {
    group(scenario.key, () {
      test(
        'counts pending work without the page limit and reflects acknowledgements',
        () async {
          final repository = await scenario.value([]);
          expect(await repository.countPendingMutations(), 0);
          await Future.wait([
            for (var index = 0; index < 105; index++)
              repository.save(_entry('count-$index')),
          ]);
          expect(await repository.listPendingMutations(), hasLength(100));
          expect(await repository.countPendingMutations(), 105);
          final acknowledged = (await repository.listPendingMutations(
            limit: 1,
          )).single;
          await repository.applySyncResult(
            SyncResult(acknowledgedMutationIds: [acknowledged.mutationId]),
          );
          expect(await repository.countPendingMutations(), 104);
        },
      );

      test(
        'pages by ID without being reordered by edits and includes trash',
        () async {
          final repository = await scenario.value([
            _entry('d'),
            _entry('a'),
            _entry('c'),
            _entry('b', inTrash: true),
            _entry('e'),
          ]);
          final first = await repository.listAttachmentBackfillEntries(
            limit: 2,
          );
          expect(first.map((entry) => entry.id), ['a', 'b']);
          expect(first.last.isInTrash, isTrue);
          await repository.save(
            first.first.copyWith(updatedAt: DateTime(2030)),
          );
          final second = await repository.listAttachmentBackfillEntries(
            afterId: first.last.id,
            limit: 2,
          );
          expect(second.map((entry) => entry.id), ['c', 'd']);
          expect(
            (await repository.listAttachmentBackfillEntries(
              afterId: second.last.id,
              limit: 2,
            )).map((entry) => entry.id),
            ['e'],
          );
          expect(
            await repository.listAttachmentBackfillEntries(afterId: 'e'),
            isEmpty,
          );
          expect(
            (await repository.listAttachmentBackfillEntries(
              afterId: 'bb',
              limit: 1,
            )).single.id,
            'c',
          );
          expect(
            await repository.listAttachmentBackfillEntries(limit: 0),
            isEmpty,
          );
        },
      );

      test(
        'merges only attachment IDs and enqueues the new revision once',
        () async {
          final repository = await scenario.value([_entry('a', inTrash: true)]);
          final source = (await repository.load(includeTrash: true)).single;
          expect(
            await repository.mergeAttachmentIds(source, [
              'new-asset',
              'new-asset',
            ]),
            isTrue,
          );
          final stored = (await repository.load(includeTrash: true)).single;
          expect(stored.attachmentIds, ['existing-asset', 'new-asset']);
          expect(stored.revision, source.revision + 1);
          expect(stored.updatedAt, isNot(source.updatedAt));
          final beforeFields = source.toJson()
            ..remove('attachmentIds')
            ..remove('revision')
            ..remove('updatedAt');
          final afterFields = stored.toJson()
            ..remove('attachmentIds')
            ..remove('revision')
            ..remove('updatedAt');
          expect(afterFields, beforeFields);
          final mutation = (await repository.listPendingMutations()).single;
          final queued = DiaryEntry.fromJson(
            Map<String, dynamic>.from(mutation.payload['entry'] as Map),
          );
          expect(queued.attachmentIds, stored.attachmentIds);
          expect(queued.revision, stored.revision);
          expect(
            await repository.mergeAttachmentIds(stored, ['new-asset']),
            isFalse,
          );
          expect(
            (await repository.load(includeTrash: true)).single.revision,
            stored.revision,
          );
          expect(await repository.listPendingMutations(), hasLength(1));
        },
      );

      test(
        'stale repair cannot overwrite a newer edit or its outbox',
        () async {
          final repository = await scenario.value([_entry('a')]);
          final source = (await repository.load(includeTrash: true)).single;
          await repository.save(
            source.copyWith(
              content: 'newer edit',
              contentText: 'newer edit',
              updatedAt: source.updatedAt.add(const Duration(seconds: 1)),
              imagePaths: const ['newer-photo.png'],
            ),
          );
          final mutationIds = (await repository.listPendingMutations())
              .map((mutation) => mutation.mutationId)
              .toList();

          expect(
            await repository.mergeAttachmentIds(source, ['stale-asset']),
            isFalse,
          );

          final stored = (await repository.load(includeTrash: true)).single;
          expect(stored.content, 'newer edit');
          expect(stored.imagePaths, ['newer-photo.png']);
          expect(stored.attachmentIds, ['existing-asset']);
          expect(
            (await repository.listPendingMutations()).map(
              (mutation) => mutation.mutationId,
            ),
            mutationIds,
          );
        },
      );

      test(
        'deleted records are not recreated by an attachment repair',
        () async {
          final repository = await scenario.value([_entry('a')]);
          final source = (await repository.load(includeTrash: true)).single;
          await repository.deletePermanently(source.id);
          final mutations = await repository.listPendingMutations();

          expect(
            await repository.mergeAttachmentIds(source, ['stale-asset']),
            isFalse,
          );

          expect(await repository.load(includeTrash: true), isEmpty);
          expect(
            (await repository.listPendingMutations()).map(
              (item) => item.mutationId,
            ),
            mutations.map((item) => item.mutationId),
          );
        },
      );

      test(
        'same-version snapshots must still match content and media paths',
        () async {
          final original = _entry('a');
          final repository = await scenario.value([original]);
          final source = (await repository.load(includeTrash: true)).single;
          await repository.replaceAll([
            source.copyWith(imagePaths: const ['replaced.png']),
          ]);

          expect(
            await repository.mergeAttachmentIds(source, ['wrong-asset']),
            isFalse,
          );

          final current = (await repository.load(includeTrash: true)).single;
          expect(current.imagePaths, ['replaced.png']);
          expect(await repository.listPendingMutations(), isEmpty);
          await repository.replaceAll([
            source.copyWith(content: 'same-version replacement'),
          ]);
          expect(
            await repository.mergeAttachmentIds(source, ['wrong-asset']),
            isFalse,
          );
        },
      );

      test(
        'an edit queued before the merge wins without awaiting its completion',
        () async {
          final repository = await scenario.value([_entry('a')]);
          final source = (await repository.load(includeTrash: true)).single;
          final editing = repository.save(
            source.copyWith(
              content: 'concurrent edit',
              contentText: 'concurrent edit',
              updatedAt: source.updatedAt.add(const Duration(seconds: 1)),
            ),
          );
          final repairing = repository.mergeAttachmentIds(source, [
            'stale-asset',
          ]);
          await editing;

          if (scenario.key == 'Isar') {
            // The save reads before entering its write transaction, so the merge
            // may legitimately commit first. The user's final edit must still win.
            await repairing;
          } else {
            expect(await repairing, isFalse);
          }
          expect(
            (await repository.load(includeTrash: true)).single.content,
            'concurrent edit',
          );
        },
      );
    });
  }

  test('Isar count does not deserialize pending payloads', () async {
    final repository = await factories['Isar']!([]);
    final isar = Isar.getInstance('diary')!;
    final row = OutboxRecord()
      ..mutationId = 'synthetic-invalid-payload'
      ..entityType = 'entry'
      ..entityId = 'synthetic-entry'
      ..payloadJson = 'not JSON'
      ..retryCount = 0
      ..createdAt = DateTime(2026, 10, 7);
    await isar.writeTxn(() async => isar.outboxRecords.put(row));

    expect(await repository.countPendingMutations(), 1);
    await expectLater(repository.listPendingMutations(), throwsFormatException);
  });
}
