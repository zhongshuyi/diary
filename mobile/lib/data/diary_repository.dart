import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/domain/attachment.dart';
import 'package:diary/domain/conflict.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_query.dart';
import 'package:diary/domain/outbox_mutation.dart';
import 'package:diary/domain/sync_state.dart';

class TaxonomyItem {
  const TaxonomyItem({required this.value, required this.count, required this.latestUsedAt});

  final String value;
  final int count;
  final DateTime? latestUsedAt;
}

class TaxonomyUsage {
  const TaxonomyUsage({this.categories = const [], this.tags = const []});

  final List<TaxonomyItem> categories;
  final List<TaxonomyItem> tags;
}

class DraftPayload {
  const DraftPayload({required this.id, this.entryId, required this.payload, required this.updatedAt});

  final String id;
  final String? entryId;
  final Map<String, dynamic> payload;
  final DateTime updatedAt;
}

enum ImportPolicy { merge, skipLocalNewer, replaceLocal }

class ImportPackage {
  const ImportPackage({this.entries = const [], this.attachments = const [], this.settings = const {}});

  final List<DiaryEntry> entries;
  final List<Attachment> attachments;
  final Map<String, dynamic> settings;
}

class ImportResult {
  const ImportResult({this.importedEntries = 0, this.skippedEntries = 0, this.conflicts = 0});

  final int importedEntries;
  final int skippedEntries;
  final int conflicts;
}

class DeletePreview {
  const DeletePreview({this.entryCount = 1, this.exclusiveAttachmentCount = 0, this.sharedAttachmentCount = 0});

  final int entryCount;
  final int exclusiveAttachmentCount;
  final int sharedAttachmentCount;
}

class SyncResult {
  const SyncResult({this.changes = const [], this.conflicts = const [], this.acknowledgedMutationIds = const [], this.nextCursor});

  final List<DiaryEntry> changes;
  final List<Conflict> conflicts;
  final List<String> acknowledgedMutationIds;
  final String? nextCursor;
}

abstract class DiaryRepository {
  Future<List<DiaryEntry>> load({bool includeTrash = false});

  Future<List<DiaryEntry>> listEntries({DiaryQuery query = const DiaryQuery()}) async {
    final all = await load(includeTrash: query.includeTrash);
    final normalized = query.query.trim().toLowerCase();
    final filtered = all.where((entry) {
      if (!query.includeConflicts && entry.isConflict) return false;
      if (query.category != null && entry.category != query.category) return false;
      if (query.favoriteOnly && !entry.isFavorite) return false;
      if (query.tags.isNotEmpty && !query.tags.every(entry.tags.contains)) return false;
      if (normalized.isNotEmpty && !entry.matches(normalized)) return false;
      if (query.dateFrom != null && entry.effectiveOccurredAt.isBefore(query.dateFrom!)) return false;
      if (query.dateTo != null && entry.effectiveOccurredAt.isAfter(query.dateTo!)) return false;
      return true;
    }).toList()..sort((a, b) => b.effectiveOccurredAt.compareTo(a.effectiveOccurredAt));
    final start = query.offset.clamp(0, filtered.length);
    final end = (start + query.limit).clamp(start, filtered.length);
    return List.unmodifiable(filtered.sublist(start, end));
  }

  Future<List<DiaryEntry>> search(String query, {bool includeTrash = false});

  Future<void> save(DiaryEntry entry, {bool enqueueMutation = true});

  Future<void> moveToTrash(String id);

  Future<void> restore(String id);

  Future<void> deletePermanently(String id);

  Future<void> replaceAll(List<DiaryEntry> entries);

  Future<void> batchSetFavorite(Iterable<String> ids, bool value) async {
    final selected = ids.toSet();
    for (final entry in await load(includeTrash: true)) {
      if (selected.contains(entry.id)) await save(entry.copyWith(isFavorite: value, updatedAt: DateTime.now()));
    }
  }
  Future<void> batchMoveToTrash(Iterable<String> ids) async {
    for (final id in ids.toSet()) await moveToTrash(id);
  }
  Future<void> batchRestore(Iterable<String> ids) async {
    for (final id in ids.toSet()) await restore(id);
  }
  Future<void> batchUpdateOrganization(
    Iterable<String> ids, {
    String? category,
    Iterable<String> addTags = const [],
    Iterable<String> removeTags = const [],
  }) async {
    final selected = ids.toSet();
    final add = addTags.toSet();
    final remove = removeTags.toSet();
    for (final entry in await load(includeTrash: true)) {
      if (!selected.contains(entry.id)) continue;
      await save(entry.copyWith(
        category: category ?? entry.category,
        tags: {...entry.tags, ...add}.difference(remove).toList(),
        updatedAt: DateTime.now(),
      ));
    }
  }
  Future<TaxonomyUsage> taxonomyUsage() async {
    final categories = <String, TaxonomyItem>{};
    final tags = <String, TaxonomyItem>{};
    for (final entry in (await load()).where((item) => !item.isConflict)) {
      final when = entry.effectiveOccurredAt;
      final category = categories[entry.category];
      categories[entry.category] = TaxonomyItem(value: entry.category, count: (category?.count ?? 0) + 1, latestUsedAt: _latest(category?.latestUsedAt, when));
      for (final tagValue in entry.tags) {
        final tag = tags[tagValue];
        tags[tagValue] = TaxonomyItem(value: tagValue, count: (tag?.count ?? 0) + 1, latestUsedAt: _latest(tag?.latestUsedAt, when));
      }
    }
    return TaxonomyUsage(categories: categories.values.toList(), tags: tags.values.toList());
  }
  Future<void> saveDraft(DraftPayload draft) async {}
  Future<DraftPayload?> loadDraft(String id) async => null;
  Future<void> clearDraft(String id) async {}
  Future<List<OutboxMutation>> listPendingMutations({int limit = 100}) async => const [];
  Future<void> applySyncResult(SyncResult result) async {
    for (final entry in result.changes) await save(entry, enqueueMutation: false);
  }
  Future<SyncState> getSyncState() async => const SyncState();
  Future<void> setSyncState(SyncState state) async {}
  Future<List<Conflict>> listConflicts({String status = 'pending'}) async => const [];
  Future<void> resolveConflict(String conflictId, DiaryEntry resolution) async => save(resolution);
  Future<ImportResult> mergeImport(ImportPackage package, {ImportPolicy policy = ImportPolicy.merge}) async {
    var imported = 0;
    for (final entry in package.entries) { await save(entry); imported++; }
    return ImportResult(importedEntries: imported);
  }
  Future<DeletePreview> previewDelete(String id) async => const DeletePreview();
}

class MemoryDiaryRepository extends DiaryRepository {
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
  Future<List<DiaryEntry>> listEntries({DiaryQuery query = const DiaryQuery()}) async {
    final normalized = query.query.trim().toLowerCase();
    final entries = _entries.where((entry) {
      if (!query.includeTrash && entry.isInTrash) return false;
      if (!query.includeConflicts && entry.isConflict) return false;
      if (query.category != null && query.category!.isNotEmpty && entry.category != query.category) return false;
      if (query.favoriteOnly && !entry.isFavorite) return false;
      if (query.dateFrom != null && entry.effectiveOccurredAt.isBefore(query.dateFrom!)) return false;
      if (query.dateTo != null && entry.effectiveOccurredAt.isAfter(query.dateTo!)) return false;
      if (query.mood != null && !query.mood!.contains(entry.mood)) return false;
      if (query.tags.isNotEmpty && !query.tags.every(entry.tags.contains)) return false;
      if (normalized.isNotEmpty && !entry.matches(normalized)) return false;
      if (query.attachmentKind != null && !_hasAttachmentKind(entry, query.attachmentKind!)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.effectiveOccurredAt.compareTo(a.effectiveOccurredAt));
    final start = query.offset.clamp(0, entries.length);
    final end = (start + query.limit).clamp(start, entries.length);
    return List.unmodifiable(entries.sublist(start, end));
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
  Future<void> save(DiaryEntry entry, {bool enqueueMutation = true}) async {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    final previous = index == -1 ? null : _entries[index];
    final next = entry.copyWith(
      occurredAt: entry.occurredAt ?? entry.createdAt,
      revision: previous != null && entry.revision <= previous.revision ? previous.revision + 1 : entry.revision,
    );
    if (index == -1) {
      _entries.add(next);
    } else {
      _entries[index] = next;
    }
    if (enqueueMutation) _enqueue(next);
  }

  @override
  Future<void> moveToTrash(String id) async {
    final entry = _findEntry(id);
    if (entry != null) await save(entry.copyWith(isInTrash: true, updatedAt: DateTime.now()));
  }

  @override
  Future<void> restore(String id) async {
    final entry = _findEntry(id);
    if (entry != null) await save(entry.copyWith(isInTrash: false, updatedAt: DateTime.now()));
  }

  @override
  Future<void> deletePermanently(String id) async {
    _entries = _entries.where((entry) => entry.id != id).toList();
  }

  @override
  Future<void> replaceAll(List<DiaryEntry> entries) async {
    _entries = List<DiaryEntry>.of(entries);
  }

  @override
  Future<void> batchSetFavorite(Iterable<String> ids, bool value) async {
    final selected = ids.toSet();
    for (final entry in List<DiaryEntry>.of(_entries)) {
      if (selected.contains(entry.id)) await save(entry.copyWith(isFavorite: value, updatedAt: DateTime.now()));
    }
  }

  @override
  Future<void> batchMoveToTrash(Iterable<String> ids) async {
    for (final id in ids.toSet()) await moveToTrash(id);
  }

  @override
  Future<void> batchRestore(Iterable<String> ids) async {
    for (final id in ids.toSet()) await restore(id);
  }

  @override
  Future<void> batchUpdateOrganization(
    Iterable<String> ids, {
    String? category,
    Iterable<String> addTags = const [],
    Iterable<String> removeTags = const [],
  }) async {
    final selected = ids.toSet();
    final add = addTags.toSet();
    final remove = removeTags.toSet();
    for (final entry in List<DiaryEntry>.of(_entries)) {
      if (!selected.contains(entry.id)) continue;
      await save(entry.copyWith(
        category: category ?? entry.category,
        tags: {...entry.tags, ...add}.difference(remove).toList(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  @override
  Future<TaxonomyUsage> taxonomyUsage() async {
    final categories = <String, TaxonomyItem>{};
    final tags = <String, TaxonomyItem>{};
    for (final entry in _entries.where((item) => !item.isInTrash && !item.isConflict)) {
      final when = entry.effectiveOccurredAt;
      final category = categories[entry.category];
      categories[entry.category] = TaxonomyItem(value: entry.category, count: (category?.count ?? 0) + 1, latestUsedAt: _latest(category?.latestUsedAt, when));
      for (final tagValue in entry.tags) {
        final tag = tags[tagValue];
        tags[tagValue] = TaxonomyItem(value: tagValue, count: (tag?.count ?? 0) + 1, latestUsedAt: _latest(tag?.latestUsedAt, when));
      }
    }
    int compare(TaxonomyItem a, TaxonomyItem b) => b.count.compareTo(a.count) != 0 ? b.count.compareTo(a.count) : (b.latestUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.latestUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0)) != 0 ? (b.latestUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(a.latestUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0)) : a.value.compareTo(b.value);
    return TaxonomyUsage(categories: (categories.values.toList()..sort(compare)), tags: (tags.values.toList()..sort(compare)));
  }

  @override
  Future<void> saveDraft(DraftPayload draft) async => _drafts[draft.id] = draft;

  @override
  Future<DraftPayload?> loadDraft(String id) async => _drafts[id];

  @override
  Future<void> clearDraft(String id) async => _drafts.remove(id);

  @override
  Future<List<OutboxMutation>> listPendingMutations({int limit = 100}) async => List.unmodifiable(_outbox.take(limit));

  @override
  Future<void> applySyncResult(SyncResult result) async {
    for (final entry in result.changes) await save(entry, enqueueMutation: false);
    _outbox.removeWhere((item) => result.acknowledgedMutationIds.contains(item.mutationId));
    for (final conflict in result.conflicts) {
      _conflicts[conflict.conflictId] = conflict;
      await save(conflict.entry, enqueueMutation: false);
    }
    final current = await getSyncState();
    await setSyncState(SyncState(deviceId: current.deviceId, cursor: result.nextCursor ?? current.cursor, lastSuccessAt: DateTime.now(), status: result.conflicts.isEmpty ? SyncStatus.synced : SyncStatus.conflict));
  }

  @override
  Future<SyncState> getSyncState() async => _syncState;

  @override
  Future<void> setSyncState(SyncState state) async => _syncState = state;

  @override
  Future<List<Conflict>> listConflicts({String status = 'pending'}) async => List.unmodifiable(_conflicts.values.where((item) => item.status == status));

  @override
  Future<void> resolveConflict(String conflictId, DiaryEntry resolution) async {
    await save(resolution.copyWith(isConflict: false, conflictStatus: 'resolved'), enqueueMutation: true);
    _conflicts.remove(conflictId);
  }

  @override
  Future<ImportResult> mergeImport(ImportPackage package, {ImportPolicy policy = ImportPolicy.merge}) async {
    var imported = 0;
    var skipped = 0;
    var conflicts = 0;
    if (policy == ImportPolicy.replaceLocal) _entries = [];
    for (final entry in package.entries) {
      final existing = _findEntry(entry.id);
      if (existing != null && existing.updatedAt.isAfter(entry.updatedAt)) {
        skipped++;
        if (policy == ImportPolicy.merge) conflicts++;
        continue;
      }
      await save(entry);
      imported++;
    }
    return ImportResult(importedEntries: imported, skippedEntries: skipped, conflicts: conflicts);
  }

  @override
  Future<DeletePreview> previewDelete(String id) async => const DeletePreview();

  final Map<String, DraftPayload> _drafts = {};
  final List<OutboxMutation> _outbox = [];
  final Map<String, Conflict> _conflicts = {};
  SyncState _syncState = const SyncState();

  void _enqueue(DiaryEntry entry) {
    final mutationId = '${entry.deviceId.isEmpty ? 'mobile' : entry.deviceId}:${entry.id}:${entry.revision}';
    _outbox.removeWhere((item) => item.entityId == entry.id);
    _outbox.add(OutboxMutation(mutationId: mutationId, entityType: 'entry', entityId: entry.id, payload: {'mutationId': mutationId, 'entry': entry.toJson()}, createdAt: DateTime.now()));
  }

  DiaryEntry? _findEntry(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Future<void> _update(
    String id,
    DiaryEntry Function(DiaryEntry) update,
  ) async {
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index != -1) _entries[index] = update(_entries[index]);
  }
}

DateTime _latest(DateTime? left, DateTime right) => left == null || right.isAfter(left) ? right : left;

bool _hasAttachmentKind(DiaryEntry entry, AttachmentKind kind) {
  switch (kind) {
    case AttachmentKind.image:
      return entry.imagePaths.isNotEmpty;
    case AttachmentKind.video:
      return entry.videoPaths.isNotEmpty;
    case AttachmentKind.audio:
      return entry.audioPaths.isNotEmpty;
    case AttachmentKind.file:
      return entry.attachmentIds.isNotEmpty;
  }
}

class SharedPreferencesDiaryRepository extends DiaryRepository {
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
  Future<void> save(DiaryEntry entry, {bool enqueueMutation = true}) async {
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
