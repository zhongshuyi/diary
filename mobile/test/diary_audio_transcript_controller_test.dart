import 'dart:async';

import 'package:diary/application/diary_controller.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

DiaryEntry _entry(String id, {DateTime? updatedAt}) => DiaryEntry(
  id: id,
  createdAt: DateTime.utc(2026, 10, 7, 10),
  updatedAt: updatedAt ?? DateTime.utc(2026, 10, 7, 10),
  title: '原标题 $id',
  content: '原始正文 $id',
  contentText: '原始正文 $id',
  category: '生活',
  tags: ['原标签'],
  audioPaths: ['recording-$id.m4a'],
);

void main() {
  test(
    'applying recognition is incremental and keeps equal-time entries in place',
    () async {
      final repository = _ObservedRepository([
        _entry('one'),
        _entry('two'),
        _entry('three'),
      ]);
      final controller = DiaryController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      final originalOrder = controller.entries
          .map((entry) => entry.id)
          .toList();
      final selected = controller.entries.first;
      final loads = repository.loads;
      var notifications = 0;
      controller.addListener(() => notifications++);
      final result = await controller.saveAudioTranscript(
        selected.id,
        selected.audioPaths.single,
        '今天去了公园',
      );
      expect(result!.contentText, selected.contentText);
      expect(result.updatedAt, selected.updatedAt);
      expect(result.audioTranscripts, ['今天去了公园']);
      expect(result.tags, selected.tags);
      expect(repository.loads, loads);
      expect(controller.entries.map((entry) => entry.id), originalOrder);
      expect(notifications, 1);
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
    },
  );

  test(
    'missing or deleted recording results neither insert entries nor notify',
    () async {
      final repository = _ObservedRepository([_entry('entry')]);
      final controller = DiaryController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(
        await controller.saveAudioTranscript('missing', 'missing.m4a', '迟到'),
        isNull,
      );
      expect(
        await controller.saveAudioTranscript('entry', 'removed.m4a', '迟到'),
        isNull,
      );
      expect(notifications, 0);
      expect(controller.entries.single.audioTranscripts, isEmpty);
    },
  );

  test(
    'a delayed recognition return cannot resurrect a permanently deleted entry',
    () async {
      final original = _entry('entry');
      final repository = _DelayedTranscriptRepository([original]);
      final controller = DiaryController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      final response = controller.saveAudioTranscript(
        original.id,
        original.audioPaths.single,
        '保存后迟到的UI更新',
      );
      await repository.persisted.future;
      await controller.deletePermanently(controller.entries.single);
      expect(controller.entries, isEmpty);
      repository.returnBarrier.complete();
      await response;
      expect(controller.entries, isEmpty);
      expect(controller.trash, isEmpty);
      expect(await repository.load(includeTrash: true), isEmpty);
    },
  );

  test(
    'a delayed recognition return cannot restore a recording moved to the trash',
    () async {
      final original = _entry('entry');
      final repository = _DelayedTranscriptRepository([original]);
      final controller = DiaryController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      final response = controller.saveAudioTranscript(
        original.id,
        original.audioPaths.single,
        '转写结果',
      );
      await repository.persisted.future;
      await controller.moveToTrash(controller.entries.single);
      repository.returnBarrier.complete();
      await response;
      expect(controller.entries, isEmpty);
      expect(controller.trash.single.id, original.id);
      expect(controller.trash.single.isInTrash, isTrue);
    },
  );

  test(
    'a delayed recognition return does not overwrite a newer editor save',
    () async {
      final original = _entry('entry');
      final repository = _DelayedTranscriptRepository([original]);
      final controller = DiaryController(repository: repository);
      addTearDown(controller.dispose);
      await controller.initialize();
      final response = controller.saveAudioTranscript(
        original.id,
        original.audioPaths.single,
        '编辑期间完成的转写',
      );
      await repository.persisted.future;
      await controller.save(
        original.copyWith(
          title: '新标题',
          content: '识别保存后继续修改的正文',
          contentText: '识别保存后继续修改的正文',
          category: '工作',
          updatedAt: DateTime.utc(2026, 10, 7, 12),
        ),
      );
      final latest = controller.entries.single;
      repository.returnBarrier.complete();
      await response;
      expect(controller.entries.single, latest);
      expect(controller.entries.single.contentText, '识别保存后继续修改的正文');
      expect(controller.entries.single.audioTranscripts, ['编辑期间完成的转写']);
    },
  );

  test(
    'a disposed diary controller does not apply delayed recognition notifications',
    () async {
      final original = _entry('entry');
      final repository = _DelayedTranscriptRepository([original]);
      final controller = DiaryController(repository: repository);
      await controller.initialize();
      final response = controller.saveAudioTranscript(
        original.id,
        original.audioPaths.single,
        '正在保存的转写',
      );
      await repository.persisted.future;
      controller.dispose();
      repository.returnBarrier.complete();
      await expectLater(response, completes);
    },
  );
}

class _ObservedRepository extends MemoryDiaryRepository {
  _ObservedRepository(super.entries);
  int loads = 0;
  @override
  Future<List<DiaryEntry>> load({bool includeTrash = false}) {
    loads++;
    return super.load(includeTrash: includeTrash);
  }
}

class _DelayedTranscriptRepository extends MemoryDiaryRepository {
  _DelayedTranscriptRepository(super.entries);
  final persisted = Completer<void>();
  final returnBarrier = Completer<void>();
  @override
  Future<DiaryEntry?> saveAudioTranscript(
    String entryId,
    String audioPath,
    String text,
  ) async {
    final result = await super.saveAudioTranscript(entryId, audioPath, text);
    persisted.complete();
    await returnBarrier.future;
    return result;
  }
}
