import 'dart:convert';
import 'dart:io';

import 'package:diary/data/diary_backup_service.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/isar_diary_record.dart';
import 'package:diary/data/isar_diary_repository.dart';
import 'package:diary/data/mobile_attachment_store.dart';
import 'package:diary/data/portable_backup_exporter.dart';
import 'package:diary/data/portable_backup_importer.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_query.dart';
import 'package:diary/domain/conflict.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

DiaryEntry _entry({
  String id = 'recording-entry',
  List<String> audioPaths = const ['first.m4a', 'second.m4a'],
  List<String> audioTranscripts = const [],
}) => DiaryEntry(
  id: id,
  createdAt: DateTime.utc(2026, 10, 7),
  updatedAt: DateTime.utc(2026, 10, 7),
  title: '随手记录',
  content: '原始记录不能被自动替换',
  contentText: '原始记录不能被自动替换',
  category: '生活',
  audioPaths: audioPaths,
  audioTranscripts: audioTranscripts,
);

void main() {
  group('audio transcript entity', () {
    test(
      'legacy entries default to no transcript without changing original text',
      () {
        final payload = _entry().toJson()..remove('audioTranscripts');
        final restored = DiaryEntry.fromJson(payload);
        expect(restored.audioTranscripts, isEmpty);
        expect(restored.transcriptForAudioPath('first.m4a'), isNull);
        expect(restored.contentText, '原始记录不能被自动替换');
        expect(restored, _entry());
      },
    );

    test(
      'JSON and copyWith retain aligned transcript results and searchable text',
      () {
        final original = _entry();
        final updated = original.withAudioTranscript(
          'second.m4a',
          '  去公园散步了  ',
        );
        expect(updated.audioTranscripts, ['', '去公园散步了']);
        expect(updated.transcriptForAudioPath('first.m4a'), isNull);
        expect(updated.transcriptForAudioPath('second.m4a'), '去公园散步了');
        expect(updated.content, original.content);
        expect(updated.contentText, original.contentText);
        expect(updated.wordCount, original.wordCount);
        expect(updated.matches('公园'), isTrue);
        expect(DiaryEntry.fromJson(updated.toJson()), updated);
        expect(
          updated.copyWith(isFavorite: true).audioTranscripts,
          updated.audioTranscripts,
        );
        expect(updated.toJson()['schemaVersion'], 2);
      },
    );

    test(
      'deleting, replacing and reordering attachments follows their paths',
      () {
        final entry = _entry(audioTranscripts: ['第一段声音', '第二段声音']);
        final reordered = entry.copyWith(
          audioPaths: ['second.m4a', 'first.m4a'],
        );
        expect(reordered.audioTranscripts, ['第二段声音', '第一段声音']);
        final removed = entry.copyWith(audioPaths: ['second.m4a']);
        expect(removed.audioTranscripts, ['第二段声音']);
        expect(removed.matches('第一段声音'), isFalse);
        final replaced = entry.copyWith(audioPaths: ['new-recording.m4a']);
        expect(replaced.audioTranscripts, isEmpty);
        expect(entry.copyWith(audioPaths: []).audioTranscripts, isEmpty);
        expect(entry.withAudioTranscript('removed.m4a', '迟到的结果'), same(entry));
      },
    );

    test(
      'explicit transcript lists preserve association through portable path rewrites',
      () {
        final original = _entry(audioTranscripts: ['早晨散步', '傍晚回家']);
        final portable = original.copyWith(
          audioPaths: ['attachments/hash-first', 'attachments/hash-second'],
          audioTranscripts: original.audioTranscripts,
        );
        final materialized = DiaryEntry.fromJson(portable.toJson()).copyWith(
          audioPaths: ['/new/device/first.m4a', '/new/device/second.m4a'],
          audioTranscripts: portable.audioTranscripts,
        );
        expect(
          materialized.transcriptForAudioPath('/new/device/first.m4a'),
          '早晨散步',
        );
        expect(
          materialized.transcriptForAudioPath('/new/device/second.m4a'),
          '傍晚回家',
        );
        expect(materialized.contentText, original.contentText);
      },
    );

    test(
      'malformed values keep empty positions and invalid paths do not shift results',
      () {
        final payload = _entry().toJson()
          ..['audioPaths'] = ['first.m4a', 42, 'second.m4a', 'third.m4a']
          ..['audioTranscripts'] = ['第一段', '无效附件的结果', false, '第三段', '多余'];
        final entry = DiaryEntry.fromJson(payload);
        expect(entry.audioPaths, ['first.m4a', 'second.m4a', 'third.m4a']);
        expect(entry.audioTranscripts, ['第一段', '', '第三段']);
        expect(entry.transcriptForAudioPath('second.m4a'), isNull);
        expect(entry.transcriptForAudioPath('third.m4a'), '第三段');
        expect(entry.matches('无效附件'), isFalse);
        expect(entry.matches('多余'), isFalse);
      },
    );

    test(
      'limits imported list sizes and transcript length without splitting Unicode',
      () {
        final paths = List.generate(60, (index) => 'recording-$index.m4a');
        final payload = _entry(audioPaths: paths).toJson()
          ..['audioTranscripts'] = List.filled(60, '${'字' * 15999}🙂尾巴');
        final entry = DiaryEntry.fromJson(payload);
        expect(entry.audioPaths, hasLength(60));
        expect(
          entry.audioTranscripts,
          hasLength(DiaryEntry.maxAudioTranscripts),
        );
        expect(entry.audioTranscripts.first, '字' * 15999);
        expect(entry.toJson()['audioTranscripts'], hasLength(32));
        expect(
          () => entry.withAudioTranscript(paths.last, '超出条数的结果'),
          throwsFormatException,
        );
        expect(
          () => entry.withAudioTranscript(paths.first, '字' * 16001),
          throwsFormatException,
        );
      },
    );

    test(
      'equality and hash include transcripts while empty slots have one representation',
      () {
        final empty = _entry();
        final noResults = _entry(audioTranscripts: ['', ' ']);
        final first = _entry(audioTranscripts: ['识别到了声音']);
        final sameResult = _entry(audioTranscripts: ['识别到了声音', '']);
        final different = _entry(audioTranscripts: ['不同的声音']);
        expect(empty, noResults);
        expect(empty.hashCode, noResults.hashCode);
        expect(first, sameResult);
        expect(first.hashCode, sameResult.hashCode);
        expect(first, isNot(different));
        expect({first, sameResult, different}, hasLength(2));
        expect(
          () => first.audioTranscripts.add('mutable'),
          throwsUnsupportedError,
        );
      },
    );

    test('a permanent deletion tombstone drops derived recording text', () {
      final tombstone = DiaryEntry.tombstone(
        _entry(audioTranscripts: ['隐私录音内容']),
      );
      expect(tombstone.audioPaths, isEmpty);
      expect(tombstone.audioTranscripts, isEmpty);
      expect(jsonEncode(tombstone.toJson()), isNot(contains('隐私录音内容')));
    });

    test('Isar entity mapping keeps a separate native search field', () {
      final entry = _entry(audioTranscripts: ['第一段', 'The evening walk']);
      final record = DiaryRecord.fromEntity(entry);
      expect(record.audioTranscripts, entry.audioTranscripts);
      expect(record.audioTranscriptText, '第一段\nThe evening walk');
      expect(record.contentText, entry.contentText);
      expect(record.toEntity(), entry);
    });
  });

  group('repository search and persistence', () {
    test(
      'memory search and filtered lists match transcription without matching deleted audio',
      () async {
        final entry = _entry(audioTranscripts: ['', '秋天的公园散步']);
        final repository = MemoryDiaryRepository([entry]);
        expect((await repository.search('公园')).single.id, entry.id);
        expect(
          (await repository.listEntries(
            query: const DiaryQuery(query: '秋天'),
          )).single.id,
          entry.id,
        );
        await repository.save(entry.copyWith(audioPaths: ['first.m4a']));
        expect(await repository.search('公园'), isEmpty);
        expect((await repository.load()).single.contentText, entry.contentText);
      },
    );

    test(
      'shared preferences persist searchable transcripts and sync mutation JSON',
      () async {
        SharedPreferences.setMockInitialValues({});
        final entry = _entry(audioTranscripts: ['Quiet afternoon', '']);
        final repository = SharedPreferencesDiaryRepository();
        await repository.save(entry);
        final restarted = SharedPreferencesDiaryRepository();
        final loaded = (await restarted.load()).single;
        expect(loaded.audioTranscripts, entry.audioTranscripts);
        expect((await restarted.search('AFTERNOON')).single.id, entry.id);
        expect(loaded.contentText, entry.contentText);
        final mutation = (await restarted.listPendingMutations()).single;
        final sent = DiaryEntry.fromJson(
          Map<String, dynamic>.from(mutation.payload['entry'] as Map),
        );
        expect(sent.audioTranscripts, entry.audioTranscripts);
        expect(sent.contentText, entry.contentText);
      },
    );
  });

  for (final adapter in ['memory', 'preferences', 'native']) {
    group('$adapter atomic transcript merge', () {
      Future<DiaryRepository> open(DiaryEntry entry) async {
        if (adapter == 'memory') return MemoryDiaryRepository([entry]);
        if (adapter == 'preferences') {
          SharedPreferences.setMockInitialValues({});
          final repository = SharedPreferencesDiaryRepository();
          await repository.replaceAll([entry]);
          return repository;
        }
        await Isar.initializeIsarCore(download: true);
        final directory = await Directory.systemTemp.createTemp(
          'diary-atomic-asr-',
        );
        final repository = await IsarDiaryRepository.open(
          directoryPath: directory.path,
          initialEntries: [entry],
        );
        addTearDown(() async {
          await repository.close();
          await directory.delete(recursive: true);
        });
        return repository;
      }

      test(
        'old sync echoes preserve transcripts while applying remote body and metadata',
        () async {
          final original = _entry();
          final repository = await open(original);
          await repository.saveAudioTranscript(
            original.id,
            'first.m4a',
            '本地录音文字',
          );
          final acknowledged = (await repository.listPendingMutations())
              .map((item) => item.mutationId)
              .toList();
          final remote = original.copyWith(
            title: '同步来的标题',
            content: '同步来的正文',
            contentText: '同步来的正文',
            tags: ['同步标签'],
            isFavorite: true,
            revision: 100,
            updatedAt: DateTime.utc(2026, 10, 8),
          );
          final legacy = remote.toJson()..remove('audioTranscripts');
          await repository.applySyncResult(
            SyncResult(
              changes: [DiaryEntry.fromJson(legacy)],
              acknowledgedMutationIds: acknowledged,
            ),
          );
          var current = (await repository.load()).single;
          expect(current.title, remote.title);
          expect(current.content, remote.content);
          expect(current.contentText, remote.contentText);
          expect(current.tags, remote.tags);
          expect(current.isFavorite, remote.isFavorite);
          expect(current.revision, remote.revision);
          expect(current.updatedAt.isAtSameMomentAs(remote.updatedAt), isTrue);
          expect(current.transcriptForAudioPath('first.m4a'), '本地录音文字');
          expect((await repository.search('本地录音文字')).single.id, original.id);
          expect(await repository.countPendingMutations(), 0);

          await repository.applySyncResult(
            SyncResult(
              changes: [
                remote.copyWith(audioTranscripts: ['', '']),
              ],
            ),
          );
          current = (await repository.load()).single;
          expect(current.transcriptForAudioPath('first.m4a'), '本地录音文字');
          expect(current.contentText, remote.contentText);
          expect(current.revision, remote.revision);
        },
      );

      test(
        'sync keeps incoming nonempty text and drops removed recording transcripts',
        () async {
          final original = _entry(audioTranscripts: ['本地第一段', '本地第二段']);
          final repository = await open(original);
          final remote = original.copyWith(
            audioTranscripts: ['远端修正的第一段', ''],
            revision: 100,
          );
          await repository.applySyncResult(SyncResult(changes: [remote]));
          var current = (await repository.load()).single;
          expect(current.audioTranscripts, ['远端修正的第一段', '本地第二段']);
          final removed = remote.copyWith(
            audioPaths: ['first.m4a'],
            audioTranscripts: [],
            revision: 101,
          );
          await repository.applySyncResult(SyncResult(changes: [removed]));
          current = (await repository.load()).single;
          expect(current.audioPaths, ['first.m4a']);
          expect(current.audioTranscripts, ['远端修正的第一段']);
          expect(await repository.search('本地第二段'), isEmpty);
        },
      );

      test(
        'legacy conflict records inherit retained recording text without changing remote content',
        () async {
          final original = _entry(audioTranscripts: ['本地识别结果', '第二段结果']);
          final repository = await open(original);
          final conflicted = original.copyWith(
            id: '${original.id}-conflict',
            content: '远端冲突正文',
            contentText: '远端冲突正文',
            audioTranscripts: [],
            revision: 100,
          );
          final server = original.copyWith(
            audioTranscripts: ['远端非空结果', ''],
            revision: 100,
          );
          final conflict = Conflict(
            conflictId: 'recording-conflict',
            entryId: original.id,
            entry: conflicted,
            serverEntry: server,
            sourceDeviceId: 'old-client',
            sourceMutationId: 'old-mutation',
            createdAt: DateTime.utc(2026, 10, 8),
          );
          await repository.applySyncResult(SyncResult(conflicts: [conflict]));
          final stored = (await repository.load()).singleWhere(
            (entry) => entry.id == conflicted.id,
          );
          expect(stored.contentText, conflicted.contentText);
          expect(stored.audioTranscripts, ['本地识别结果', '第二段结果']);
          final savedConflict = (await repository.listConflicts()).single;
          expect(savedConflict.entry.audioTranscripts, stored.audioTranscripts);
          expect(savedConflict.entry.contentText, conflicted.contentText);
          expect(savedConflict.serverEntry.audioTranscripts, [
            '远端非空结果',
            '第二段结果',
          ]);
          expect(savedConflict.sourceMutationId, conflict.sourceMutationId);
          expect(await repository.countPendingMutations(), 0);
        },
      );

      test(
        'recognition completion merges into current edited body and metadata',
        () async {
          final original = _entry();
          final repository = await open(original);
          await repository.save(
            original.copyWith(
              title: '识别期间改了标题',
              content: '识别期间改了正文',
              contentText: '识别期间改了正文',
              category: '工作',
              tags: ['后来添加的标签'],
              mood: .8,
              moodLabel: '开心',
              isFavorite: true,
              updatedAt: DateTime.utc(2026, 10, 7, 20),
            ),
          );
          final current = (await repository.load()).single;
          final result = await repository.saveAudioTranscript(
            original.id,
            'second.m4a',
            '刚刚的录音转写',
          );
          expect(
            result,
            current
                .withAudioTranscript('second.m4a', '刚刚的录音转写')
                .copyWith(revision: current.revision + 1),
          );
          expect(result!.updatedAt, current.updatedAt);
          expect((await repository.search('录音转写')).single, result);
          final pending = (await repository.listPendingMutations()).single;
          final sent = DiaryEntry.fromJson(
            Map<String, dynamic>.from(pending.payload['entry'] as Map),
          );
          expect(sent, result);
          final repeated = await repository.saveAudioTranscript(
            original.id,
            'second.m4a',
            '刚刚的录音转写',
          );
          expect(repeated!.revision, result.revision);
        },
      );

      test(
        'simultaneous recording results both survive without reordering the entry',
        () async {
          final original = _entry();
          final repository = await open(original);
          await Future.wait([
            repository.saveAudioTranscript(original.id, 'first.m4a', '第一段识别结果'),
            repository.saveAudioTranscript(
              original.id,
              'second.m4a',
              '第二段识别结果',
            ),
          ]);
          final result = (await repository.load()).single;
          expect(result.audioTranscripts, ['第一段识别结果', '第二段识别结果']);
          expect(result.revision, original.revision + 2);
          expect(result.updatedAt.isAtSameMomentAs(original.updatedAt), isTrue);
          expect(result.contentText, original.contentText);
          final pending = (await repository.listPendingMutations()).single;
          expect((pending.payload['entry'] as Map)['audioTranscripts'], [
            '第一段识别结果',
            '第二段识别结果',
          ]);
        },
      );

      test(
        'a stale editor snapshot cannot clear a newer recording transcript',
        () async {
          final original = _entry();
          final repository = await open(original);
          final editorSnapshot = (await repository.load()).single;
          await repository.saveAudioTranscript(
            original.id,
            'first.m4a',
            '编辑期间识别完成',
          );
          await repository.save(
            editorSnapshot.copyWith(content: '后来保存的编辑', contentText: '后来保存的编辑'),
          );
          final current = (await repository.load()).single;
          expect(current.contentText, '后来保存的编辑');
          expect(current.transcriptForAudioPath('first.m4a'), '编辑期间识别完成');
          await repository.save(
            current.copyWith(audioTranscripts: ['明确传入的新结果']),
          );
          expect(
            (await repository.load()).single.transcriptForAudioPath(
              'first.m4a',
            ),
            '明确传入的新结果',
          );
        },
      );

      test(
        'concurrent editor save and recognition retain the edited body and transcript',
        () async {
          final original = _entry();
          final repository = await open(original);
          final snapshot = (await repository.load()).single;
          final edit = repository.save(
            snapshot.copyWith(
              title: '修改的标题',
              content: '同时修改的正文',
              contentText: '同时修改的正文',
            ),
          );
          final transcript = repository.saveAudioTranscript(
            original.id,
            'second.m4a',
            '同时完成的识别结果',
          );
          await Future.wait([edit, transcript]);
          final current = (await repository.load()).single;
          expect(current.title, '修改的标题');
          expect(current.contentText, '同时修改的正文');
          expect(current.transcriptForAudioPath('second.m4a'), '同时完成的识别结果');
          expect(current.updatedAt, snapshot.updatedAt);
        },
      );

      test(
        'removed recordings and deleted entries reject late recognition results',
        () async {
          final original = _entry();
          final repository = await open(original);
          await repository.save(original.copyWith(audioPaths: ['first.m4a']));
          expect(
            await repository.saveAudioTranscript(
              original.id,
              'second.m4a',
              '已删除附件的迟到结果',
            ),
            isNull,
          );
          expect((await repository.load()).single.audioTranscripts, isEmpty);
          await repository.moveToTrash(original.id);
          expect(
            await repository.saveAudioTranscript(
              original.id,
              'first.m4a',
              '回收站不应被改写',
            ),
            isNull,
          );
          await repository.deletePermanently(original.id);
          expect(
            await repository.saveAudioTranscript(
              original.id,
              'first.m4a',
              '永久删除不能复活',
            ),
            isNull,
          );
          expect(await repository.load(includeTrash: true), isEmpty);
          final pending = (await repository.listPendingMutations()).single;
          final deleted = DiaryEntry.fromJson(
            Map<String, dynamic>.from(pending.payload['entry'] as Map),
          );
          expect(deleted.isDeleted, isTrue);
          expect(deleted.audioTranscripts, isEmpty);
        },
      );
    });
  }

  test(
    'portable backup relocates recordings and retains their searchable transcripts',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'diary-audio-backup-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File(p.join(directory.path, 'source.m4a'));
      await source.writeAsBytes(utf8.encode('small audio backup fixture'));
      final sourceStore = MobileAttachmentStore(
        rootDirectory: Directory(p.join(directory.path, 'source-store')),
      );
      final original = _entry(
        audioPaths: [source.path],
        audioTranscripts: ['录下了今天在公园的想法'],
      );
      final zip = await PortableBackupExporter(
        attachmentStore: sourceStore,
      ).export([original]);
      final package = const DiaryBackupService().importZip(zip);
      final portable = package.entries.single;
      expect(portable.audioPaths.single, startsWith('attachments/'));
      expect(portable.audioTranscripts, original.audioTranscripts);
      final relocated = (await PortableBackupImporter(
        attachmentStore: MobileAttachmentStore(
          rootDirectory: Directory(p.join(directory.path, 'restored-store')),
        ),
      ).materialize(package)).single;
      expect(relocated.audioPaths.single, isNot(source.path));
      expect(await File(relocated.audioPaths.single).exists(), isTrue);
      expect(
        relocated.transcriptForAudioPath(relocated.audioPaths.single),
        '录下了今天在公园的想法',
      );
      expect(relocated.matches('公园'), isTrue);
      expect(relocated.contentText, original.contentText);
    },
  );

  group('native transcript search', () {
    setUpAll(() => Isar.initializeIsarCore(download: true));
    test(
      'native database persists and searches transcription after reopening',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'diary-audio-isar-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final entry = _entry(audioTranscripts: ['今天在公园散步', 'An evening WALK']);
        var repository = await IsarDiaryRepository.open(
          directoryPath: directory.path,
        );
        await repository.save(entry);
        await repository.close();
        repository = await IsarDiaryRepository.open(
          directoryPath: directory.path,
        );
        try {
          expect(
            (await repository.load()).single.audioTranscripts,
            entry.audioTranscripts,
          );
          expect((await repository.search('公园')).single.id, entry.id);
          expect((await repository.search('walk')).single.id, entry.id);
          expect(
            (await repository.load()).single.contentText,
            entry.contentText,
          );
          await repository.moveToTrash(entry.id);
          expect(await repository.search('公园'), isEmpty);
          expect(
            (await repository.search('公园', includeTrash: true)).single.id,
            entry.id,
          );
        } finally {
          await repository.close();
        }
      },
    );
  });
}
