import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/conflict.dart';
import '../domain/diary_entry.dart';
import '../domain/diary_query.dart';
import '../domain/outbox_mutation.dart';
import '../domain/sync_state.dart';
import 'diary_repository.dart';
import 'isar_diary_record.dart';

class IsarDiaryRepository extends DiaryRepository {
  IsarDiaryRepository._(this._isar);

  static Future<IsarDiaryRepository> open({
    Iterable<DiaryEntry>? initialEntries,
    String? directoryPath,
  }) async {
    final databasePath =
        directoryPath ??
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          'diary_database',
        );
    await Directory(databasePath).create(recursive: true);
    final isar = await Isar.open(
      [
        DiaryRecordSchema,
        AttachmentRecordSchema,
        OutboxRecordSchema,
        DraftRecordSchema,
        SyncStateRecordSchema,
        ConflictRecordSchema,
      ],
      directory: databasePath,
      name: 'diary',
    );
    final repository = IsarDiaryRepository._(isar);

    if (await isar.diaryRecords.count() == 0) {
      final seeds = (initialEntries ?? const <DiaryEntry>[]).toList(
        growable: false,
      );
      if (seeds.isNotEmpty) {
        await repository.replaceAll(seeds);
      }
    }

    return repository;
  }

  final Isar _isar;

  @override
  Future<List<DiaryEntry>> load({bool includeTrash = false}) async {
    final records = includeTrash
        ? await _isar.diaryRecords.where().findAll()
        : await _isar.diaryRecords.filter().isInTrashEqualTo(false).findAll();
    records.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return records.map((record) => record.toEntity()).toList(growable: false);
  }

  @override
  Future<List<DiaryEntry>> search(
    String query, {
    bool includeTrash = false,
  }) async {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return load(includeTrash: includeTrash);
    }

    final records = await _isar.diaryRecords
        .filter()
        .titleContains(normalized, caseSensitive: false)
        .or()
        .contentTextContains(normalized, caseSensitive: false)
        .or()
        .categoryContains(normalized, caseSensitive: false)
        .or()
        .tagsElementContains(normalized, caseSensitive: false)
        .findAll();
    final entries =
        records
            .map((record) => record.toEntity())
            .where(
              (entry) =>
                  (includeTrash || !entry.isInTrash) &&
                  entry.matches(normalized),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<DiaryEntry>.unmodifiable(entries);
  }

  @override
  Future<void> save(DiaryEntry entry, {bool enqueueMutation = true}) async {
    await _saveStored(entry, enqueueMutation: enqueueMutation);
  }

  @override
  Future<DiaryEntry> saveAndGet(
    DiaryEntry entry, {
    bool enqueueMutation = true,
  }) async {
    final record = await _saveStored(entry, enqueueMutation: enqueueMutation);
    return record.toEntity();
  }

  Future<DiaryRecord> _saveStored(
    DiaryEntry entry, {
    required bool enqueueMutation,
  }) async {
    final existing = await _isar.diaryRecords
        .filter()
        .uuidEqualTo(entry.id)
        .findFirst();
    final current = existing?.toEntity();
    final now = DateTime.now();
    final next = entry.copyWith(
      occurredAt: entry.occurredAt ?? entry.createdAt,
      revision: current != null && entry.revision <= current.revision
          ? current.revision + 1
          : entry.revision,
      deviceId: entry.deviceId.isEmpty ? 'mobile' : entry.deviceId,
      updatedAt: entry.updatedAt,
    );
    final record = DiaryRecord.fromEntity(next)
      ..id = existing?.id ?? Isar.autoIncrement;
    await _isar.writeTxn(() async {
      await _isar.diaryRecords.put(record);
      if (enqueueMutation) {
        final mutationId = '${next.deviceId}:${next.id}:${next.revision}';
        final existingOutbox = await _isar.outboxRecords
            .filter()
            .entityIdEqualTo(next.id)
            .findAll();
        for (final item in existingOutbox)
          await _isar.outboxRecords.delete(item.id);
        await _isar.outboxRecords.put(
          OutboxRecord.fromEntity(
            OutboxMutation(
              mutationId: mutationId,
              entityType: 'entry',
              entityId: next.id,
              payload: {'mutationId': mutationId, 'entry': next.toJson()},
              createdAt: now,
            ),
          ),
        );
      }
    });
    return record;
  }

  @override
  Future<void> moveToTrash(String id) async {
    final entry = await _find(id);
    if (entry != null) {
      await save(entry.copyWith(isInTrash: true, updatedAt: DateTime.now()));
    }
  }

  @override
  Future<void> restore(String id) async {
    final entry = await _find(id);
    if (entry != null) {
      await save(entry.copyWith(isInTrash: false, updatedAt: DateTime.now()));
    }
  }

  @override
  Future<void> deletePermanently(String id) async {
    final record = await _isar.diaryRecords
        .filter()
        .uuidEqualTo(id)
        .findFirst();
    if (record == null) {
      return;
    }
    final tombstone = DiaryEntry.tombstone(record.toEntity());
    await _isar.writeTxn(() async {
      await _isar.diaryRecords.delete(record.id);
      await _replaceOutboxEntry(tombstone);
    });
  }

  @override
  Future<void> clearTrash() async {
    final records = await _isar.diaryRecords
        .filter()
        .isInTrashEqualTo(true)
        .findAll();
    if (records.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.diaryRecords.deleteAll(
        records.map((record) => record.id).toList(growable: false),
      );
      for (final record in records) {
        await _replaceOutboxEntry(DiaryEntry.tombstone(record.toEntity()));
      }
    });
  }

  @override
  Future<void> replaceAll(Iterable<DiaryEntry> entries) async {
    final records = entries.map(DiaryRecord.fromEntity).toList(growable: false);
    await _isar.writeTxn(() async {
      await _isar.diaryRecords.clear();
      await _isar.diaryRecords.putAll(records);
    });
  }

  @override
  Future<List<DiaryEntry>> listEntries({
    DiaryQuery query = const DiaryQuery(),
  }) async {
    final all = await load(includeTrash: query.includeTrash);
    final filtered =
        all.where((entry) {
          if (!query.includeConflicts && entry.isConflict) return false;
          if (query.category != null && entry.category != query.category)
            return false;
          if (query.favoriteOnly && !entry.isFavorite) return false;
          if (query.tags.isNotEmpty && !query.tags.every(entry.tags.contains))
            return false;
          if (query.query.trim().isNotEmpty && !entry.matches(query.query))
            return false;
          if (query.dateFrom != null &&
              entry.effectiveOccurredAt.isBefore(query.dateFrom!))
            return false;
          if (query.dateTo != null &&
              entry.effectiveOccurredAt.isAfter(query.dateTo!))
            return false;
          return true;
        }).toList()..sort(
          (a, b) => b.effectiveOccurredAt.compareTo(a.effectiveOccurredAt),
        );
    final start = query.offset.clamp(0, filtered.length);
    final end = (start + query.limit).clamp(start, filtered.length);
    return List.unmodifiable(filtered.sublist(start, end));
  }

  @override
  Future<void> saveDraft(DraftPayload draft) async {
    await _isar.writeTxn(
      () async => _isar.draftRecords.put(DraftRecord.fromEntity(draft)),
    );
  }

  @override
  Future<DraftPayload?> loadDraft(String id) async {
    final record = await _isar.draftRecords
        .filter()
        .draftIdEqualTo(id)
        .findFirst();
    return record?.toEntity();
  }

  @override
  Future<void> clearDraft(String id) async {
    final record = await _isar.draftRecords
        .filter()
        .draftIdEqualTo(id)
        .findFirst();
    if (record != null)
      await _isar.writeTxn(() async => _isar.draftRecords.delete(record.id));
  }

  @override
  Future<List<OutboxMutation>> listPendingMutations({int limit = 100}) async {
    final rows = await _isar.outboxRecords
        .where()
        .sortByCreatedAt()
        .limit(limit)
        .findAll();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  @override
  Future<void> applySyncResult(SyncResult result) async {
    await _isar.writeTxn(() async {
      for (final change in result.changes) {
        final current = await _isar.diaryRecords
            .filter()
            .uuidEqualTo(change.id)
            .findFirst();
        if (change.isDeleted) {
          if (current != null) await _isar.diaryRecords.delete(current.id);
          continue;
        }
        await _isar.diaryRecords.put(
          DiaryRecord.fromEntity(change)
            ..id = current?.id ?? Isar.autoIncrement,
        );
      }
      for (final conflict in result.conflicts) {
        final current = await _isar.diaryRecords
            .filter()
            .uuidEqualTo(conflict.entry.id)
            .findFirst();
        await _isar.diaryRecords.put(
          DiaryRecord.fromEntity(conflict.entry)
            ..id = current?.id ?? Isar.autoIncrement,
        );
        await _isar.conflictRecords.put(ConflictRecord.fromEntity(conflict));
      }
      for (final mutationId in result.acknowledgedMutationIds) {
        final row = await _isar.outboxRecords
            .filter()
            .mutationIdEqualTo(mutationId)
            .findFirst();
        if (row != null) await _isar.outboxRecords.delete(row.id);
      }
      final current = await getSyncState();
      final next = SyncState(
        deviceId: current.deviceId,
        cursor: result.nextCursor ?? current.cursor,
        lastSuccessAt: DateTime.now(),
        status: result.conflicts.isEmpty
            ? SyncStatus.synced
            : SyncStatus.conflict,
      );
      final state = SyncStateRecord()
        ..key = 'default'
        ..deviceId = next.deviceId
        ..cursor = next.cursor
        ..lastSuccessAt = next.lastSuccessAt
        ..lastError = next.lastError
        ..status = next.status.index;
      final existing = await _isar.syncStateRecords
          .filter()
          .keyEqualTo('default')
          .findFirst();
      state.id = existing?.id ?? Isar.autoIncrement;
      await _isar.syncStateRecords.put(state);
    });
  }

  @override
  Future<SyncState> getSyncState() async {
    final row = await _isar.syncStateRecords
        .filter()
        .keyEqualTo('default')
        .findFirst();
    return row?.toEntity() ?? const SyncState(deviceId: 'mobile', cursor: '0');
  }

  @override
  Future<void> setSyncState(SyncState state) async {
    final existing = await _isar.syncStateRecords
        .filter()
        .keyEqualTo('default')
        .findFirst();
    final row = SyncStateRecord()
      ..id = existing?.id ?? Isar.autoIncrement
      ..key = 'default'
      ..deviceId = state.deviceId
      ..cursor = state.cursor
      ..lastSuccessAt = state.lastSuccessAt
      ..lastError = state.lastError
      ..status = state.status.index;
    await _isar.writeTxn(() async => _isar.syncStateRecords.put(row));
  }

  @override
  Future<List<Conflict>> listConflicts({String status = 'pending'}) async {
    final rows = await _isar.conflictRecords
        .filter()
        .statusEqualTo(status)
        .sortByCreatedAtDesc()
        .findAll();
    return rows.map((row) => row.toEntity()).toList(growable: false);
  }

  @override
  Future<void> resolveConflict(String conflictId, DiaryEntry resolution) async {
    await save(
      resolution.copyWith(isConflict: false, conflictStatus: 'resolved'),
    );
    final row = await _isar.conflictRecords
        .filter()
        .conflictIdEqualTo(conflictId)
        .findFirst();
    if (row != null) {
      row.status = 'resolved';
      await _isar.writeTxn(() async => _isar.conflictRecords.put(row));
    }
  }

  Future<DiaryEntry?> _find(String id) async {
    final record = await _isar.diaryRecords
        .filter()
        .uuidEqualTo(id)
        .findFirst();
    return record?.toEntity();
  }

  Future<void> _replaceOutboxEntry(DiaryEntry entry) async {
    final existingOutbox = await _isar.outboxRecords
        .filter()
        .entityIdEqualTo(entry.id)
        .findAll();
    for (final item in existingOutbox) {
      await _isar.outboxRecords.delete(item.id);
    }
    final mutationId = '${entry.deviceId}:${entry.id}:${entry.revision}';
    await _isar.outboxRecords.put(
      OutboxRecord.fromEntity(
        OutboxMutation(
          mutationId: mutationId,
          entityType: 'entry',
          entityId: entry.id,
          payload: {'mutationId': mutationId, 'entry': entry.toJson()},
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> close() => _isar.close(deleteFromDisk: false);
}
