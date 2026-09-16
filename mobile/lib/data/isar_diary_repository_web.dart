import '../domain/demo_data.dart';
import '../domain/diary_entry.dart';
import 'diary_repository.dart';

class IsarDiaryRepository extends DiaryRepository {
  IsarDiaryRepository._(this._delegate);

  static Future<IsarDiaryRepository> open({
    Iterable<DiaryEntry>? initialEntries,
    String? directoryPath,
  }) async {
    final delegate = SharedPreferencesDiaryRepository(
      initialEntries: (initialEntries ?? demoEntries).toList(growable: false),
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
  Future<void> save(DiaryEntry entry) => _delegate.save(entry);

  @override
  Future<void> moveToTrash(String id) => _delegate.moveToTrash(id);

  @override
  Future<void> restore(String id) => _delegate.restore(id);

  @override
  Future<void> deletePermanently(String id) => _delegate.deletePermanently(id);

  @override
  Future<void> replaceAll(Iterable<DiaryEntry> entries) =>
      _delegate.replaceAll(entries.toList(growable: false));

  Future<void> close() async {}
}
