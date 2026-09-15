import 'package:isar_community/isar.dart';

import '../domain/diary_entry.dart';

part 'isar_diary_record.g.dart';

@collection
class DiaryRecord {
  DiaryRecord();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uuid;

  @Index()
  late DateTime createdAt;

  @Index()
  late DateTime updatedAt;

  @Index(type: IndexType.value)
  late String title;
  late String content;
  @Index(type: IndexType.value)
  late String contentText;

  @Index()
  late int editorType;

  late double mood;

  @Index()
  late String category;

  late List<String> tags;
  late List<String> imagePaths;
  late List<String> audioPaths;
  late List<String> videoPaths;
  late List<String> weather;
  late List<String> positions;
  late double? latitude;
  late double? longitude;
  late int colorValue;
  late bool isFavorite;

  @Index()
  late bool isInTrash;

  factory DiaryRecord.fromEntity(DiaryEntry entry) {
    return DiaryRecord()
      ..uuid = entry.id
      ..createdAt = entry.createdAt
      ..updatedAt = entry.updatedAt
      ..title = entry.title
      ..content = entry.content
      ..contentText = entry.contentText
      ..editorType = entry.editorType.index
      ..mood = entry.mood
      ..category = entry.category
      ..tags = List<String>.from(entry.tags)
      ..imagePaths = List<String>.from(entry.imagePaths)
      ..audioPaths = List<String>.from(entry.audioPaths)
      ..videoPaths = List<String>.from(entry.videoPaths)
      ..weather = List<String>.from(entry.weather)
      ..positions = List<String>.from(entry.positions)
      ..latitude = entry.latitude
      ..longitude = entry.longitude
      ..colorValue = entry.colorValue
      ..isFavorite = entry.isFavorite
      ..isInTrash = entry.isInTrash;
  }

  DiaryEntry toEntity() {
    return DiaryEntry(
      id: uuid,
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: title,
      content: content,
      contentText: contentText,
      editorType: DiaryEditorTypeCodec.fromIndex(editorType),
      mood: mood,
      category: category,
      tags: tags,
      imagePaths: imagePaths,
      audioPaths: audioPaths,
      videoPaths: videoPaths,
      weather: weather,
      positions: positions,
      latitude: latitude,
      longitude: longitude,
      colorValue: colorValue,
      isFavorite: isFavorite,
      isInTrash: isInTrash,
    );
  }
}
