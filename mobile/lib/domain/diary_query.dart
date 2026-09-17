import 'attachment.dart';

class DiaryQuery {
  const DiaryQuery({
    this.query = '',
    this.dateFrom,
    this.dateTo,
    this.category,
    this.tags = const [],
    this.mood,
    this.favoriteOnly = false,
    this.attachmentKind,
    this.includeTrash = false,
    this.includeConflicts = false,
    this.limit = 50,
    this.offset = 0,
  });

  final String query;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? category;
  final List<String> tags;
  final MoodRange? mood;
  final bool favoriteOnly;
  final AttachmentKind? attachmentKind;
  final bool includeTrash;
  final bool includeConflicts;
  final int limit;
  final int offset;

  DiaryQuery copyWith({
    String? query,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? category,
    List<String>? tags,
    MoodRange? mood,
    bool? favoriteOnly,
    AttachmentKind? attachmentKind,
    bool? includeTrash,
    bool? includeConflicts,
    int? limit,
    int? offset,
  }) {
    return DiaryQuery(
      query: query ?? this.query,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      mood: mood ?? this.mood,
      favoriteOnly: favoriteOnly ?? this.favoriteOnly,
      attachmentKind: attachmentKind ?? this.attachmentKind,
      includeTrash: includeTrash ?? this.includeTrash,
      includeConflicts: includeConflicts ?? this.includeConflicts,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

class MoodRange {
  const MoodRange(this.min, this.max);

  final double min;
  final double max;

  bool contains(double value) => value >= min && value <= max;
}
