import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/domain/diary_entry.dart';

abstract interface class DiaryRepository {
  Future<List<DiaryEntry>> load({bool includeTrash = false});

  Future<List<DiaryEntry>> search(String query, {bool includeTrash = false});

  Future<void> save(DiaryEntry entry);

  Future<void> moveToTrash(String id);

  Future<void> restore(String id);

  Future<void> deletePermanently(String id);

  Future<void> replaceAll(List<DiaryEntry> entries);
}

class MemoryDiaryRepository implements DiaryRepository {
  MemoryDiaryRepository([List<DiaryEntry> initialEntries = const []])
    : _entries = List<DiaryEntry>.of(initialEntries);

  List<DiaryEntry> _entries;

  @override
  Future<List<DiaryEntry>> load({bool includeTrash = false}) async {
    final entries =
        _entries.where((entry) => includeTrash || !entry.isInTrash).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return List<DiaryEntry>.unmodifiable(entries);
  }

  @override
  Future<List<DiaryEntry>> search(
    String query, {
    bool includeTrash = false,
  }) async {
    final entries = await load(includeTrash: includeTrash);
    return entries
        .where((entry) => entry.matches(query))
        .toList(growable: false);
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      _entries.add(entry);
    } else {
      _entries[index] = entry;
    }
  }

  @override
  Future<void> moveToTrash(String id) async {
    await _update(id, (entry) => entry.copyWith(isInTrash: true));
  }

  @override
  Future<void> restore(String id) async {
    await _update(id, (entry) => entry.copyWith(isInTrash: false));
  }

  @override
  Future<void> deletePermanently(String id) async {
    _entries = _entries.where((entry) => entry.id != id).toList();
  }

  @override
  Future<void> replaceAll(List<DiaryEntry> entries) async {
    _entries = List<DiaryEntry>.of(entries);
  }

  Future<void> _update(
    String id,
    DiaryEntry Function(DiaryEntry) update,
  ) async {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index != -1) _entries[index] = update(_entries[index]);
  }
}

class SharedPreferencesDiaryRepository implements DiaryRepository {
  SharedPreferencesDiaryRepository({this.initialEntries = const []});

  static const _storageKey = 'diary.entries.v1';

  final List<DiaryEntry> initialEntries;
  Future<SharedPreferences>? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= SharedPreferences.getInstance();
  }

  @override
  Future<List<DiaryEntry>> load({bool includeTrash = false}) async {
    final preferences = await _prefs;
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      if (initialEntries.isNotEmpty) await replaceAll(initialEntries);
      return List<DiaryEntry>.unmodifiable(
        initialEntries.where((entry) => includeTrash || !entry.isInTrash),
      );
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final entries =
          decoded
              .whereType<Map>()
              .map(
                (item) => DiaryEntry.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((entry) => includeTrash || !entry.isInTrash)
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return List<DiaryEntry>.unmodifiable(entries);
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<List<DiaryEntry>> search(
    String query, {
    bool includeTrash = false,
  }) async {
    final entries = await load(includeTrash: includeTrash);
    return entries
        .where((entry) => entry.matches(query))
        .toList(growable: false);
  }

  @override
  Future<void> save(DiaryEntry entry) async {
    final entries = await load(includeTrash: true);
    final index = entries.indexWhere((item) => item.id == entry.id);
    if (index == -1) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
    await replaceAll(entries);
  }

  @override
  Future<void> moveToTrash(String id) async {
    final entries = await load(includeTrash: true);
    await _replaceMatching(
      entries,
      id,
      (entry) => entry.copyWith(isInTrash: true),
    );
  }

  @override
  Future<void> restore(String id) async {
    final entries = await load(includeTrash: true);
    await _replaceMatching(
      entries,
      id,
      (entry) => entry.copyWith(isInTrash: false),
    );
  }

  @override
  Future<void> deletePermanently(String id) async {
    final entries = await load(includeTrash: true);
    entries.removeWhere((entry) => entry.id == id);
    await replaceAll(entries);
  }

  @override
  Future<void> replaceAll(List<DiaryEntry> entries) async {
    final preferences = await _prefs;
    await preferences.setString(
      _storageKey,
      jsonEncode(entries.map((entry) => entry.toJson()).toList()),
    );
  }

  Future<void> _replaceMatching(
    List<DiaryEntry> entries,
    String id,
    DiaryEntry Function(DiaryEntry entry) update,
  ) async {
    final index = entries.indexWhere((entry) => entry.id == id);
    if (index == -1) return;
    entries[index] = update(entries[index]);
    await replaceAll(entries);
  }
}
