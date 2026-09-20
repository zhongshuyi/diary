import '../domain/conflict.dart';
import '../domain/diary_entry.dart';
import '../domain/outbox_mutation.dart';
import '../domain/sync_state.dart';
import 'diary_repository.dart';

class IsarDiaryRepository extends DiaryRepository {
  IsarDiaryRepository._(this._delegate);

  static Future<IsarDiaryRepository> open({
    Iterable<DiaryEntry>? initialEntries,
    String? directoryPath,
  }) async {
    final delegate = SharedPreferencesDiaryRepository(
      initialEntries: (initialEntries ?? const <DiaryEntry>[]).toList(
        growable: false,
      ),
    );
    await delegate.load();
    return IsarDiaryRepository._(delegate);
  }

  final SharedPreferencesDiaryRepository _delegate;

  @override
  Future<List<DiaryEntry>> load({bool includeTrash = false}) {
    return _delegate.load(includeTrash: includeTrash);
  }

  @override
  Future<List<DiaryEntry>> search(String query, {bool includeTrash = false}) {
    return _delegate.search(query, includeTrash: includeTrash);
  }

  @override
  Future<void> save(DiaryEntry entry, {bool enqueueMutation = true}) =>
      _delegate.save(entry, enqueueMutation: enqueueMutation);

  @override
  Future<void> moveToTrash(String id) => _delegate.moveToTrash(id);

  @override
  Future<void> restore(String id) => _delegate.restore(id);

  @override
  Future<void> deletePermanently(String id) => _delegate.deletePermanently(id);

  @override
  Future<void> clearTrash() => _delegate.clearTrash();

  @override
  Future<void> replaceAll(Iterable<DiaryEntry> entries) =>
      _delegate.replaceAll(entries.toList(growable: false));

  @override
  Future<List<OutboxMutation>> listPendingMutations({int limit = 100}) =>
      _delegate.listPendingMutations(limit: limit);

  @override
  Future<void> applySyncResult(SyncResult result) =>
      _delegate.applySyncResult(result);

  @override
  Future<SyncState> getSyncState() => _delegate.getSyncState();

  @override
  Future<void> setSyncState(SyncState state) => _delegate.setSyncState(state);

  @override
  Future<List<Conflict>> listConflicts({String status = 'pending'}) =>
      _delegate.listConflicts(status: status);

  @override
  Future<void> resolveConflict(String conflictId, DiaryEntry resolution) =>
      _delegate.resolveConflict(conflictId, resolution);

  Future<void> close() async {}
}
