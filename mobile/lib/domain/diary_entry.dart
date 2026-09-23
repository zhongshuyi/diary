enum DiaryEditorType { plainText, markdown, richText }

extension DiaryEditorTypeCodec on DiaryEditorType {
  String get wireValue {
    switch (this) {
      case DiaryEditorType.plainText:
        return 'plain_text';
      case DiaryEditorType.markdown:
        return 'markdown';
      case DiaryEditorType.richText:
        return 'rich_text';
    }
  }

  String get label {
    switch (this) {
      case DiaryEditorType.plainText:
        return '纯文本';
      case DiaryEditorType.markdown:
        return 'Markdown';
      case DiaryEditorType.richText:
        return '富文本';
    }
  }

  static DiaryEditorType fromWireValue(String? value) {
    return DiaryEditorType.values.firstWhere(
      (type) => type.wireValue == value,
      orElse: () => DiaryEditorType.plainText,
    );
  }

  static DiaryEditorType fromIndex(int? index) {
    if (index == null || index < 0 || index >= DiaryEditorType.values.length) {
      return DiaryEditorType.plainText;
    }
    return DiaryEditorType.values[index];
  }
}

class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.occurredAt,
    this.deletedAt,
    this.revision = 1,
    this.deviceId = '',
    this.isConflict = false,
    this.conflictOf,
    this.conflictStatus = 'pending',
    required this.title,
    required this.content,
    required this.contentText,
    required this.category,
    this.editorType = DiaryEditorType.plainText,
    this.mood = 0.5,
    this.moodLabel,
    this.tags = const [],
    this.attachmentIds = const [],
    this.imagePaths = const [],
    this.audioPaths = const [],
    this.videoPaths = const [],
    this.weather = const [],
    this.positions = const [],
    this.latitude,
    this.longitude,
    this.colorValue = 0xFFE4E0ED,
    this.isFavorite = false,
    this.isInTrash = false,
    this.isDeleted = false,
  });

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? occurredAt;
  final DateTime? deletedAt;
  final int revision;
  final String deviceId;
  final bool isConflict;
  final String? conflictOf;
  final String conflictStatus;
  final String title;
  final String content;
  final String contentText;
  final DiaryEditorType editorType;
  final double mood;
  final String? moodLabel;

  // Older entries saved a chosen non-neutral mood without a label. A value of
  // .5 is ambiguous because it was also the default for an unmarked entry.
  bool get hasExplicitMood =>
      (moodLabel?.trim().isNotEmpty ?? false) || mood != .5;
  final String category;
  final List<String> tags;
  final List<String> attachmentIds;
  final List<String> imagePaths;
  final List<String> audioPaths;
  final List<String> videoPaths;
  final List<String> weather;
  final List<String> positions;
  final double? latitude;
  final double? longitude;
  final int colorValue;
  final bool isFavorite;
  final bool isInTrash;

  /// A synchronized tombstone for a record that was permanently deleted.
  ///
  /// Tombstones are never rendered in the recycle bin. They exist only long
  /// enough to prevent an older device from restoring the record during sync.
  final bool isDeleted;

  factory DiaryEntry.tombstone(DiaryEntry entry, {DateTime? deletedAt}) {
    final deletedOn = deletedAt ?? DateTime.now();
    return DiaryEntry(
      id: entry.id,
      createdAt: entry.createdAt,
      updatedAt: deletedOn,
      occurredAt: entry.occurredAt,
      deletedAt: deletedOn,
      revision: entry.revision + 1,
      deviceId: entry.deviceId,
      title: '',
      content: '',
      contentText: '',
      category: entry.category,
      isInTrash: true,
      isDeleted: true,
    );
  }

  DateTime get effectiveOccurredAt => occurredAt ?? createdAt;

  String get yearMonth =>
      '${effectiveOccurredAt.year}/${effectiveOccurredAt.month}';

  String get yearMonthDay =>
      '${effectiveOccurredAt.year}/${effectiveOccurredAt.month}/${effectiveOccurredAt.day}';

  bool get hasMedia =>
      imagePaths.isNotEmpty || audioPaths.isNotEmpty || videoPaths.isNotEmpty;

  int get wordCount => contentText.trim().runes.length;

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final searchable = [
      title,
      contentText,
      category,
      ...tags,
    ].join(' ').toLowerCase();
    return searchable.contains(normalized);
  }

  DiaryEntry copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? occurredAt,
    DateTime? deletedAt,
    int? revision,
    String? deviceId,
    bool? isConflict,
    String? conflictOf,
    String? conflictStatus,
    String? title,
    String? content,
    String? contentText,
    DiaryEditorType? editorType,
    double? mood,
    String? moodLabel,
    String? category,
    List<String>? tags,
    List<String>? attachmentIds,
    List<String>? imagePaths,
    List<String>? audioPaths,
    List<String>? videoPaths,
    List<String>? weather,
    List<String>? positions,
    double? latitude,
    double? longitude,
    int? colorValue,
    bool? isFavorite,
    bool? isInTrash,
    bool? isDeleted,
  }) {
    final nextDeletedAt =
        deletedAt ??
        (isInTrash == null
            ? this.deletedAt
            : isInTrash
            ? (updatedAt ?? DateTime.now())
            : null);
    return DiaryEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      occurredAt: occurredAt ?? this.occurredAt,
      deletedAt: nextDeletedAt,
      revision: revision ?? this.revision,
      deviceId: deviceId ?? this.deviceId,
      isConflict: isConflict ?? this.isConflict,
      conflictOf: conflictOf ?? this.conflictOf,
      conflictStatus: conflictStatus ?? this.conflictStatus,
      title: title ?? this.title,
      content: content ?? this.content,
      contentText: contentText ?? this.contentText,
      editorType: editorType ?? this.editorType,
      mood: mood ?? this.mood,
      moodLabel: moodLabel ?? this.moodLabel,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      attachmentIds: attachmentIds ?? this.attachmentIds,
      imagePaths: imagePaths ?? this.imagePaths,
      audioPaths: audioPaths ?? this.audioPaths,
      videoPaths: videoPaths ?? this.videoPaths,
      weather: weather ?? this.weather,
      positions: positions ?? this.positions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      colorValue: colorValue ?? this.colorValue,
      isFavorite: isFavorite ?? this.isFavorite,
      isInTrash: isInTrash ?? this.isInTrash,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': 2,
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'occurredAt': effectiveOccurredAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'revision': revision,
      'deviceId': deviceId,
      'isConflict': isConflict,
      'conflictOf': conflictOf,
      'conflictStatus': conflictStatus,
      'title': title,
      'content': content,
      'contentText': contentText,
      'editorType': editorType.wireValue,
      'mood': mood,
      'moodLabel': moodLabel,
      'category': category,
      'tags': tags,
      'attachmentIds': attachmentIds,
      'imagePaths': imagePaths,
      'audioPaths': audioPaths,
      'videoPaths': videoPaths,
      'weather': weather,
      'positions': positions,
      'latitude': latitude,
      'longitude': longitude,
      'colorValue': colorValue,
      'isFavorite': isFavorite,
      'isInTrash': isInTrash,
      'isDeleted': isDeleted,
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final deletedAt = _readNullableDate(json['deletedAt']);
    final isDeleted = json['isDeleted'] == true;
    final inTrash =
        isDeleted ||
        json['isInTrash'] == true ||
        json['show'] == false ||
        deletedAt != null;
    return DiaryEntry(
      id: _readString(
        json['id'],
        fallback: now.microsecondsSinceEpoch.toString(),
      ),
      createdAt: _readDate(json['createdAt'] ?? json['time'], fallback: now),
      updatedAt: _readDate(
        json['updatedAt'] ?? json['lastModified'],
        fallback: now,
      ),
      occurredAt: _readDate(
        json['occurredAt'],
        fallback: _readDate(json['createdAt'] ?? json['time'], fallback: now),
      ),
      deletedAt:
          deletedAt ??
          (inTrash
              ? _readDate(
                  json['updatedAt'] ?? json['lastModified'],
                  fallback: now,
                )
              : null),
      revision: _readInt(json['revision'], fallback: 1),
      deviceId: _readString(json['deviceId']),
      isConflict: json['isConflict'] == true,
      conflictOf: json['conflictOf'] is String
          ? json['conflictOf'] as String
          : null,
      conflictStatus: json['conflictStatus'] == 'resolved'
          ? 'resolved'
          : 'pending',
      title: _readString(json['title']),
      content: _readString(json['content']),
      contentText: _readString(
        json['contentText'],
        fallback: _readString(json['content']),
      ),
      editorType: DiaryEditorTypeCodec.fromWireValue(
        json['editorType'] as String?,
      ),
      mood: _readDouble(json['mood'], fallback: 0.5).clamp(0, 1),
      moodLabel: _readNullableString(json['moodLabel']),
      category: _readString(json['category'], fallback: '生活'),
      tags: _readStringList(json['tags']),
      attachmentIds: _readStringList(json['attachmentIds']),
      imagePaths: _readStringList(json['imagePaths'] ?? json['imageName']),
      audioPaths: _readStringList(json['audioPaths'] ?? json['audioName']),
      videoPaths: _readStringList(json['videoPaths'] ?? json['videoName']),
      weather: _readStringList(json['weather']),
      positions: _readStringList(json['positions'] ?? json['position']),
      latitude: _readNullableDouble(json['latitude']),
      longitude: _readNullableDouble(json['longitude']),
      colorValue: _readInt(json['colorValue'], fallback: 0xFFE4E0ED),
      isFavorite: json['isFavorite'] == true,
      isInTrash: inTrash,
      isDeleted: isDeleted,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DiaryEntry &&
        id == other.id &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        effectiveOccurredAt == other.effectiveOccurredAt &&
        deletedAt == other.deletedAt &&
        revision == other.revision &&
        deviceId == other.deviceId &&
        isConflict == other.isConflict &&
        conflictOf == other.conflictOf &&
        conflictStatus == other.conflictStatus &&
        title == other.title &&
        content == other.content &&
        contentText == other.contentText &&
        editorType == other.editorType &&
        mood == other.mood &&
        moodLabel == other.moodLabel &&
        category == other.category &&
        _listEquals(tags, other.tags) &&
        _listEquals(attachmentIds, other.attachmentIds) &&
        _listEquals(imagePaths, other.imagePaths) &&
        _listEquals(audioPaths, other.audioPaths) &&
        _listEquals(videoPaths, other.videoPaths) &&
        _listEquals(weather, other.weather) &&
        _listEquals(positions, other.positions) &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        colorValue == other.colorValue &&
        isFavorite == other.isFavorite &&
        isInTrash == other.isInTrash &&
        isDeleted == other.isDeleted;
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    effectiveOccurredAt,
    deletedAt,
    revision,
    deviceId,
    isConflict,
    conflictOf,
    conflictStatus,
    title,
    content,
    contentText,
    editorType,
    mood,
    moodLabel,
    category,
    Object.hashAll(tags),
    Object.hashAll(attachmentIds),
    Object.hashAll(imagePaths),
    Object.hashAll(audioPaths),
    Object.hashAll(videoPaths),
    Object.hashAll(weather),
    Object.hashAll(positions),
    latitude,
    longitude,
    colorValue,
    isFavorite,
    isInTrash,
    isDeleted,
  ]);
}

String _readString(Object? value, {String fallback = ''}) {
  return value is String ? value : fallback;
}

String? _readNullableString(Object? value) {
  final result = value is String ? value.trim() : '';
  return result.isEmpty ? null : result;
}

DateTime _readDate(Object? value, {required DateTime fallback}) {
  return value is String ? DateTime.tryParse(value) ?? fallback : fallback;
}

DateTime? _readNullableDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

double _readDouble(Object? value, {required double fallback}) {
  return value is num ? value.toDouble() : fallback;
}

double? _readNullableDouble(Object? value) {
  return value is num ? value.toDouble() : null;
}

int _readInt(Object? value, {required int fallback}) {
  return value is num ? value.toInt() : fallback;
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList(growable: false);
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
