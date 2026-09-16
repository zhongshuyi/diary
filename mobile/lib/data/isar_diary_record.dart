import 'dart:convert';

import 'package:isar_community/isar.dart';

import '../domain/diary_entry.dart';
import '../domain/attachment.dart';
import '../domain/conflict.dart';
import '../domain/outbox_mutation.dart';
import '../domain/sync_state.dart';
import 'diary_repository.dart';

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

  @Index()
  DateTime? occurredAt;

  @Index()
  DateTime? deletedAt;

  late int revision;
  late String deviceId;
  late bool isConflict;
  String? conflictOf;
  late String conflictStatus;

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
  late List<String> attachmentIds;
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
      ..occurredAt = entry.occurredAt ?? entry.createdAt
      ..deletedAt = entry.deletedAt
      ..revision = entry.revision
      ..deviceId = entry.deviceId
      ..isConflict = entry.isConflict
      ..conflictOf = entry.conflictOf
      ..conflictStatus = entry.conflictStatus
      ..title = entry.title
      ..content = entry.content
      ..contentText = entry.contentText
      ..editorType = entry.editorType.index
      ..mood = entry.mood
      ..category = entry.category
      ..tags = List<String>.from(entry.tags)
      ..attachmentIds = List<String>.from(entry.attachmentIds)
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
      occurredAt: occurredAt,
      deletedAt: deletedAt,
      revision: revision,
      deviceId: deviceId,
      isConflict: isConflict,
      conflictOf: conflictOf,
      conflictStatus: conflictStatus,
      title: title,
      content: content,
      contentText: contentText,
      editorType: DiaryEditorTypeCodec.fromIndex(editorType),
      mood: mood,
      category: category,
      tags: tags,
      attachmentIds: attachmentIds,
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

@collection
class AttachmentRecord {
  AttachmentRecord();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String assetId;

  @Index(unique: true, replace: true)
  late String sha256;

  late int kind;
  late String mimeType;
  late int byteSize;
  late String originalName;
  String? localPath;
  late int remoteState;
  String? lastError;
  late DateTime createdAt;

  factory AttachmentRecord.fromEntity(Attachment value) {
    return AttachmentRecord()
      ..assetId = value.assetId
      ..sha256 = value.sha256
      ..kind = value.kind.index
      ..mimeType = value.mimeType
      ..byteSize = value.byteSize
      ..originalName = value.originalName
      ..localPath = value.localPath
      ..remoteState = value.remoteState.index
      ..lastError = value.lastError
      ..createdAt = value.createdAt;
  }

  Attachment toEntity() {
    return Attachment(
      assetId: assetId,
      sha256: sha256,
      kind: AttachmentKind.values[_safeIndex(kind, AttachmentKind.values.length)],
      mimeType: mimeType,
      byteSize: byteSize,
      originalName: originalName,
      localPath: localPath,
      remoteState: AttachmentRemoteState.values[_safeIndex(remoteState, AttachmentRemoteState.values.length)],
      lastError: lastError,
      createdAt: createdAt,
    );
  }
}

@collection
class OutboxRecord {
  OutboxRecord();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String mutationId;
  late String entityType;
  @Index()
  late String entityId;
  late String payloadJson;
  late int retryCount;
  DateTime? nextRetryAt;
  @Index()
  late DateTime createdAt;

  factory OutboxRecord.fromEntity(OutboxMutation value) {
    return OutboxRecord()
      ..mutationId = value.mutationId
      ..entityType = value.entityType
      ..entityId = value.entityId
      ..payloadJson = jsonEncode(value.payload)
      ..retryCount = value.retryCount
      ..nextRetryAt = value.nextRetryAt
      ..createdAt = value.createdAt;
  }

  OutboxMutation toEntity() {
    final decoded = jsonDecode(payloadJson);
    return OutboxMutation(
      mutationId: mutationId,
      entityType: entityType,
      entityId: entityId,
      payload: decoded is Map ? Map<String, dynamic>.from(decoded) : const {},
      retryCount: retryCount,
      nextRetryAt: nextRetryAt,
      createdAt: createdAt,
    );
  }
}

@collection
class DraftRecord {
  DraftRecord();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String draftId;
  String? entryId;
  late String payloadJson;
  late DateTime updatedAt;

  factory DraftRecord.fromEntity(DraftPayload value) {
    return DraftRecord()
      ..draftId = value.id
      ..entryId = value.entryId
      ..payloadJson = jsonEncode(value.payload)
      ..updatedAt = value.updatedAt;
  }

  DraftPayload toEntity() {
    final decoded = jsonDecode(payloadJson);
    return DraftPayload(
      id: draftId,
      entryId: entryId,
      payload: decoded is Map ? Map<String, dynamic>.from(decoded) : const {},
      updatedAt: updatedAt,
    );
  }
}

@collection
class SyncStateRecord {
  SyncStateRecord();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;
  late String deviceId;
  late String cursor;
  DateTime? lastSuccessAt;
  String? lastError;
  late int status;

  SyncState toEntity() => SyncState(
    deviceId: deviceId,
    cursor: cursor,
    lastSuccessAt: lastSuccessAt,
    lastError: lastError,
    status: SyncStatus.values[_safeIndex(status, SyncStatus.values.length)],
  );
}

int _safeIndex(int value, int length) => value < 0 ? 0 : value >= length ? length - 1 : value;

@collection
class ConflictRecord {
  ConflictRecord();

  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String conflictId;
  @Index()
  late String entryId;
  late String entryJson;
  late String serverEntryJson;
  late String sourceDeviceId;
  late String sourceMutationId;
  late DateTime createdAt;
  @Index()
  late String status;

  factory ConflictRecord.fromEntity(Conflict value) {
    return ConflictRecord()
      ..conflictId = value.conflictId
      ..entryId = value.entryId
      ..entryJson = jsonEncode(value.entry.toJson())
      ..serverEntryJson = jsonEncode(value.serverEntry.toJson())
      ..sourceDeviceId = value.sourceDeviceId
      ..sourceMutationId = value.sourceMutationId
      ..createdAt = value.createdAt
      ..status = value.status;
  }

  Conflict toEntity() => Conflict(
    conflictId: conflictId,
    entryId: entryId,
    entry: DiaryEntry.fromJson(Map<String, dynamic>.from(jsonDecode(entryJson) as Map)),
    serverEntry: DiaryEntry.fromJson(Map<String, dynamic>.from(jsonDecode(serverEntryJson) as Map)),
    sourceDeviceId: sourceDeviceId,
    sourceMutationId: sourceMutationId,
    createdAt: createdAt,
    status: status,
  );
}
