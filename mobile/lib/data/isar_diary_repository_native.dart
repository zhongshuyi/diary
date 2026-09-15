import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/demo_data.dart';
import '../domain/diary_entry.dart';
import 'diary_repository.dart';
import 'isar_diary_record.dart';

class IsarDiaryRepository implements DiaryRepository {
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
    final isar = await Isar.open(
      [DiaryRecordSchema],
      directory: databasePath,
      name: 'diary',
    );
    final repository = IsarDiaryRepository._(isar);

    if (await isar.diaryRecords.count() == 0) {
      final seeds = (initialEntries ?? demoEntries).toList(growable: false);
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
  Future<void> save(DiaryEntry entry) async {
    final existing = await _isar.diaryRecords
        .filter()
        .uuidEqualTo(entry.id)
        .findFirst();
    final record = DiaryRecord.fromEntity(entry)
      ..id = existing?.id ?? Isar.autoIncrement;
    await _isar.writeTxn(() async {
      await _isar.diaryRecords.put(record);
    });
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
    await _isar.writeTxn(() async {
      await _isar.diaryRecords.delete(record.id);
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

  Future<DiaryEntry?> _find(String id) async {
    final record = await _isar.diaryRecords
        .filter()
        .uuidEqualTo(id)
        .findFirst();
    return record?.toEntity();
  }

  Future<void> close() => _isar.close(deleteFromDisk: false);
}
