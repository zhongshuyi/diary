import 'package:flutter/foundation.dart';

import 'package:diary/data/diary_repository.dart';
import 'package:diary/domain/diary_entry.dart';

/// Application-layer state and use cases for the diary feature.
///
/// Pages depend on this controller through callbacks exposed by the shell;
/// persistence stays behind [DiaryRepository]. This keeps widgets free from
/// storage details and makes the same flows usable with Isar or an in-memory
/// repository in tests.
class DiaryController extends ChangeNotifier {
  DiaryController({required DiaryRepository repository})
    : _repository = repository;

  final DiaryRepository _repository;

  List<DiaryEntry> _entries = const [];
  List<DiaryEntry> _trash = const [];
  List<String> _categories = const ['生活', '灵感', '心绪'];
  bool _isLoading = true;
  Object? _error;
  // Rejects a load that began before a newer load or local save.
  int _entryVersion = 0;

  List<DiaryEntry> get entries => _entries;
  List<DiaryEntry> get trash => _trash;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  List<String> get categories => _categories;

  Future<void> initialize() => refresh();

  Future<void> refresh({bool notifyBeforeLoad = true}) async {
    final entryVersion = ++_entryVersion;
    _isLoading = true;
    _error = null;
    if (notifyBeforeLoad) notifyListeners();
    try {
      final all = await _repository.load(includeTrash: true);
      if (entryVersion != _entryVersion) return;
      _entries = List.unmodifiable(all.where((entry) => !entry.isInTrash));
      _trash = List.unmodifiable(all.where((entry) => entry.isInTrash));
      _categories = _collectCategories(_entries);
    } catch (error) {
      if (entryVersion == _entryVersion) _error = error;
    } finally {
      if (entryVersion == _entryVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> save(DiaryEntry entry) async {
    final stored = await _repository.saveAndGet(entry);
    _entryVersion++;
    _isLoading = false;
    _error = null;
    _entries = _replaceEntry(_entries, stored, include: !stored.isInTrash);
    _trash = _replaceEntry(_trash, stored, include: stored.isInTrash);
    _categories = _collectCategories(_entries);
    notifyListeners();
  }

  /// Chat sends share the same incremental path as regular saves.
  Future<void> saveNewChatEntry(DiaryEntry entry) => save(entry);

  List<DiaryEntry> _replaceEntry(
    List<DiaryEntry> source,
    DiaryEntry stored, {
    required bool include,
  }) {
    if (!include && !source.any((entry) => entry.id == stored.id)) {
      return source;
    }
    final next = List<DiaryEntry>.of(source)
      ..removeWhere((entry) => entry.id == stored.id);
    if (include) {
      final index = next.indexWhere(
        (entry) => entry.updatedAt.isBefore(stored.updatedAt),
      );
      next.insert(index < 0 ? next.length : index, stored);
    }
    return List.unmodifiable(next);
  }

  List<String> _collectCategories(List<DiaryEntry> entries) =>
      List.unmodifiable({
        '生活',
        '灵感',
        '心绪',
        ...entries.map((entry) => entry.category),
      });

  Future<void> toggleFavorite(DiaryEntry entry) async {
    await save(
      entry.copyWith(isFavorite: !entry.isFavorite, updatedAt: DateTime.now()),
    );
  }

  Future<void> moveToTrash(DiaryEntry entry) async {
    await _repository.moveToTrash(entry.id);
    await refresh();
  }

  Future<void> restore(DiaryEntry entry) async {
    await _repository.restore(entry.id);
    await refresh();
  }

  Future<void> deletePermanently(DiaryEntry entry) async {
    await _repository.deletePermanently(entry.id);
    await refresh();
  }

  Future<void> clearTrash() async {
    await _repository.clearTrash();
    await refresh();
  }

  Future<void> replaceAll(List<DiaryEntry> entries) async {
    await _repository.replaceAll(entries);
    await refresh();
  }

  /// Keeps existing records, including trash, when importing another app's data.
  Future<int> addMissingEntries(
    List<DiaryEntry> entries, {
    bool resyncMatching = false,
  }) async {
    final existing = await _repository.load(includeTrash: true);
    final byId = {for (final entry in existing) entry.id: entry};
    var imported = 0;
    for (final entry in entries) {
      final current = byId[entry.id];
      if (current != null) {
        if (resyncMatching &&
            current.createdAt.isAtSameMomentAs(entry.createdAt) &&
            current.title == entry.title &&
            current.contentText == entry.contentText &&
            current.editorType == entry.editorType &&
            current.isInTrash == entry.isInTrash &&
            listEquals(current.imagePaths, entry.imagePaths)) {
          await _repository.save(current.copyWith(updatedAt: DateTime.now()));
        }
        continue;
      }
      await _repository.save(entry);
      byId[entry.id] = entry;
      imported++;
    }
    await refresh(notifyBeforeLoad: false);
    return imported;
  }

  Future<void> batchSetFavorite(Iterable<String> ids, bool value) async {
    await _repository.batchSetFavorite(ids, value);
    await refresh();
  }

  Future<void> batchMoveToTrash(Iterable<String> ids) async {
    await _repository.batchMoveToTrash(ids);
    await refresh();
  }

  Future<void> batchRestore(Iterable<String> ids) async {
    await _repository.batchRestore(ids);
    await refresh();
  }
}
