import 'package:diary/domain/diary_entry.dart';

/// Applies the narrow set of conditions available in the Favorites hub.
class FavoritesFilter {
  FavoritesFilter({
    this.query = '',
    this.category = '全部',
    Set<String> tags = const <String>{},
  }) : tags = Set.unmodifiable(tags);

  final String query;
  final String category;
  final Set<String> tags;

  bool get hasActiveConditions => category != '全部' || tags.isNotEmpty;

  bool matches(DiaryEntry entry) {
    if (!entry.isFavorite ||
        entry.isInTrash ||
        entry.isDeleted ||
        entry.isConflict) {
      return false;
    }
    return entry.matches(query) &&
        (category == '全部' || entry.category == category) &&
        tags.every(entry.tags.contains);
  }

  FavoritesFilter copyWith({
    String? query,
    String? category,
    Set<String>? tags,
  }) {
    return FavoritesFilter(
      query: query ?? this.query,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }

  FavoritesFilter clearConditions() => FavoritesFilter(query: query);
}
