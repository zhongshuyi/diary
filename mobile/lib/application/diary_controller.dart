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
  bool _isLoading = true;
  Object? _error;
  int _entryVersion = 0;

  List<DiaryEntry> get entries => _entries;
  List<DiaryEntry> get trash => _trash;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  List<String> get categories {
    final result = <String>{
      '生活',
      '灵感',
      '心绪',
      ..._entries.map((entry) => entry.category),
    };
    return result.toList(growable: false);
  }

  Future<void> initialize() => refresh();

  Future<void> refresh({bool notifyBeforeLoad = true}) async {
    final entryVersion = _entryVersion;
    _isLoading = true;
    _error = null;
    if (notifyBeforeLoad) notifyListeners();
    try {
      final all = await _repository.load(includeTrash: true);
      if (entryVersion != _entryVersion) return;
      _entries = List.unmodifiable(all.where((entry) => !entry.isInTrash));
      _trash = List.unmodifiable(all.where((entry) => entry.isInTrash));
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
    await _repository.save(entry);
    await refresh(notifyBeforeLoad: false);
  }

  /// New chat entries already have all fields needed by the visible list.
  /// Avoid reloading and decoding every diary entry on the send path.
  Future<void> saveNewChatEntry(DiaryEntry entry) async {
    await _repository.save(entry);
    _entryVersion++;
    _isLoading = false;
    _entries = List.unmodifiable([
      entry,
      ..._entries.where((existing) => existing.id != entry.id),
    ]);
    notifyListeners();
  }

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
