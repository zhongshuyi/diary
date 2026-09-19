// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'isar_diary_record.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDiaryRecordCollection on Isar {
  IsarCollection<DiaryRecord> get diaryRecords => this.collection();
}

const DiaryRecordSchema = CollectionSchema(
  name: r'DiaryRecord',
  id: 1446996613889110507,
  properties: {
    r'attachmentIds': PropertySchema(
      id: 0,
      name: r'attachmentIds',
      type: IsarType.stringList,
    ),
    r'audioPaths': PropertySchema(
      id: 1,
      name: r'audioPaths',
      type: IsarType.stringList,
    ),
    r'category': PropertySchema(
      id: 2,
      name: r'category',
      type: IsarType.string,
    ),
    r'colorValue': PropertySchema(
      id: 3,
      name: r'colorValue',
      type: IsarType.long,
    ),
    r'conflictOf': PropertySchema(
      id: 4,
      name: r'conflictOf',
      type: IsarType.string,
    ),
    r'conflictStatus': PropertySchema(
      id: 5,
      name: r'conflictStatus',
      type: IsarType.string,
    ),
    r'content': PropertySchema(id: 6, name: r'content', type: IsarType.string),
    r'contentText': PropertySchema(
      id: 7,
      name: r'contentText',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 8,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'deletedAt': PropertySchema(
      id: 9,
      name: r'deletedAt',
      type: IsarType.dateTime,
    ),
    r'deviceId': PropertySchema(
      id: 10,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'editorType': PropertySchema(
      id: 11,
      name: r'editorType',
      type: IsarType.long,
    ),
    r'imagePaths': PropertySchema(
      id: 12,
      name: r'imagePaths',
      type: IsarType.stringList,
    ),
    r'isConflict': PropertySchema(
      id: 13,
      name: r'isConflict',
      type: IsarType.bool,
    ),
    r'isFavorite': PropertySchema(
      id: 14,
      name: r'isFavorite',
      type: IsarType.bool,
    ),
    r'isInTrash': PropertySchema(
      id: 15,
      name: r'isInTrash',
      type: IsarType.bool,
    ),
    r'latitude': PropertySchema(
      id: 16,
      name: r'latitude',
      type: IsarType.double,
    ),
    r'longitude': PropertySchema(
      id: 17,
      name: r'longitude',
      type: IsarType.double,
    ),
    r'mood': PropertySchema(id: 18, name: r'mood', type: IsarType.double),
    r'moodLabel': PropertySchema(
      id: 19,
      name: r'moodLabel',
      type: IsarType.string,
    ),
    r'occurredAt': PropertySchema(
      id: 20,
      name: r'occurredAt',
      type: IsarType.dateTime,
    ),
    r'positions': PropertySchema(
      id: 21,
      name: r'positions',
      type: IsarType.stringList,
    ),
    r'revision': PropertySchema(id: 22, name: r'revision', type: IsarType.long),
    r'tags': PropertySchema(id: 23, name: r'tags', type: IsarType.stringList),
    r'title': PropertySchema(id: 24, name: r'title', type: IsarType.string),
    r'updatedAt': PropertySchema(
      id: 25,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
    r'uuid': PropertySchema(id: 26, name: r'uuid', type: IsarType.string),
    r'videoPaths': PropertySchema(
      id: 27,
      name: r'videoPaths',
      type: IsarType.stringList,
    ),
    r'weather': PropertySchema(
      id: 28,
      name: r'weather',
      type: IsarType.stringList,
    ),
  },

  estimateSize: _diaryRecordEstimateSize,
  serialize: _diaryRecordSerialize,
  deserialize: _diaryRecordDeserialize,
  deserializeProp: _diaryRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'updatedAt': IndexSchema(
      id: -6238191080293565125,
      name: r'updatedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'updatedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'occurredAt': IndexSchema(
      id: 1229694562040044173,
      name: r'occurredAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'occurredAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'deletedAt': IndexSchema(
      id: -8969437169173379604,
      name: r'deletedAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'deletedAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'title': IndexSchema(
      id: -7636685945352118059,
      name: r'title',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'title',
          type: IndexType.value,
          caseSensitive: true,
        ),
      ],
    ),
    r'contentText': IndexSchema(
      id: 4288155445751344368,
      name: r'contentText',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'contentText',
          type: IndexType.value,
          caseSensitive: true,
        ),
      ],
    ),
    r'editorType': IndexSchema(
      id: -5620793257549274782,
      name: r'editorType',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'editorType',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
    r'category': IndexSchema(
      id: -7560358558326323820,
      name: r'category',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'category',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'isInTrash': IndexSchema(
      id: -4420884820235290327,
      name: r'isInTrash',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isInTrash',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _diaryRecordGetId,
  getLinks: _diaryRecordGetLinks,
  attach: _diaryRecordAttach,
  version: '3.3.2',
);

int _diaryRecordEstimateSize(
  DiaryRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.attachmentIds.length * 3;
  {
    for (var i = 0; i < object.attachmentIds.length; i++) {
      final value = object.attachmentIds[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.audioPaths.length * 3;
  {
    for (var i = 0; i < object.audioPaths.length; i++) {
      final value = object.audioPaths[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.category.length * 3;
  {
    final value = object.conflictOf;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.conflictStatus.length * 3;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.contentText.length * 3;
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.imagePaths.length * 3;
  {
    for (var i = 0; i < object.imagePaths.length; i++) {
      final value = object.imagePaths[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.moodLabel;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.positions.length * 3;
  {
    for (var i = 0; i < object.positions.length; i++) {
      final value = object.positions[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.tags.length * 3;
  {
    for (var i = 0; i < object.tags.length; i++) {
      final value = object.tags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.title.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  bytesCount += 3 + object.videoPaths.length * 3;
  {
    for (var i = 0; i < object.videoPaths.length; i++) {
      final value = object.videoPaths[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.weather.length * 3;
  {
    for (var i = 0; i < object.weather.length; i++) {
      final value = object.weather[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _diaryRecordSerialize(
  DiaryRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.attachmentIds);
  writer.writeStringList(offsets[1], object.audioPaths);
  writer.writeString(offsets[2], object.category);
  writer.writeLong(offsets[3], object.colorValue);
  writer.writeString(offsets[4], object.conflictOf);
  writer.writeString(offsets[5], object.conflictStatus);
  writer.writeString(offsets[6], object.content);
  writer.writeString(offsets[7], object.contentText);
  writer.writeDateTime(offsets[8], object.createdAt);
  writer.writeDateTime(offsets[9], object.deletedAt);
  writer.writeString(offsets[10], object.deviceId);
  writer.writeLong(offsets[11], object.editorType);
  writer.writeStringList(offsets[12], object.imagePaths);
  writer.writeBool(offsets[13], object.isConflict);
  writer.writeBool(offsets[14], object.isFavorite);
  writer.writeBool(offsets[15], object.isInTrash);
  writer.writeDouble(offsets[16], object.latitude);
  writer.writeDouble(offsets[17], object.longitude);
  writer.writeDouble(offsets[18], object.mood);
  writer.writeString(offsets[19], object.moodLabel);
  writer.writeDateTime(offsets[20], object.occurredAt);
  writer.writeStringList(offsets[21], object.positions);
  writer.writeLong(offsets[22], object.revision);
  writer.writeStringList(offsets[23], object.tags);
  writer.writeString(offsets[24], object.title);
  writer.writeDateTime(offsets[25], object.updatedAt);
  writer.writeString(offsets[26], object.uuid);
  writer.writeStringList(offsets[27], object.videoPaths);
  writer.writeStringList(offsets[28], object.weather);
}

DiaryRecord _diaryRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DiaryRecord();
  object.attachmentIds = reader.readStringList(offsets[0]) ?? [];
  object.audioPaths = reader.readStringList(offsets[1]) ?? [];
  object.category = reader.readString(offsets[2]);
  object.colorValue = reader.readLong(offsets[3]);
  object.conflictOf = reader.readStringOrNull(offsets[4]);
  object.conflictStatus = reader.readString(offsets[5]);
  object.content = reader.readString(offsets[6]);
  object.contentText = reader.readString(offsets[7]);
  object.createdAt = reader.readDateTime(offsets[8]);
  object.deletedAt = reader.readDateTimeOrNull(offsets[9]);
  object.deviceId = reader.readString(offsets[10]);
  object.editorType = reader.readLong(offsets[11]);
  object.id = id;
  object.imagePaths = reader.readStringList(offsets[12]) ?? [];
  object.isConflict = reader.readBool(offsets[13]);
  object.isFavorite = reader.readBool(offsets[14]);
  object.isInTrash = reader.readBool(offsets[15]);
  object.latitude = reader.readDoubleOrNull(offsets[16]);
  object.longitude = reader.readDoubleOrNull(offsets[17]);
  object.mood = reader.readDouble(offsets[18]);
  object.moodLabel = reader.readStringOrNull(offsets[19]);
  object.occurredAt = reader.readDateTimeOrNull(offsets[20]);
  object.positions = reader.readStringList(offsets[21]) ?? [];
  object.revision = reader.readLong(offsets[22]);
  object.tags = reader.readStringList(offsets[23]) ?? [];
  object.title = reader.readString(offsets[24]);
  object.updatedAt = reader.readDateTime(offsets[25]);
  object.uuid = reader.readString(offsets[26]);
  object.videoPaths = reader.readStringList(offsets[27]) ?? [];
  object.weather = reader.readStringList(offsets[28]) ?? [];
  return object;
}

P _diaryRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset) ?? []) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    case 9:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    case 13:
      return (reader.readBool(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readDoubleOrNull(offset)) as P;
    case 17:
      return (reader.readDoubleOrNull(offset)) as P;
    case 18:
      return (reader.readDouble(offset)) as P;
    case 19:
      return (reader.readStringOrNull(offset)) as P;
    case 20:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 21:
      return (reader.readStringList(offset) ?? []) as P;
    case 22:
      return (reader.readLong(offset)) as P;
    case 23:
      return (reader.readStringList(offset) ?? []) as P;
    case 24:
      return (reader.readString(offset)) as P;
    case 25:
      return (reader.readDateTime(offset)) as P;
    case 26:
      return (reader.readString(offset)) as P;
    case 27:
      return (reader.readStringList(offset) ?? []) as P;
    case 28:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _diaryRecordGetId(DiaryRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _diaryRecordGetLinks(DiaryRecord object) {
  return [];
}

void _diaryRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  DiaryRecord object,
) {
  object.id = id;
}

extension DiaryRecordByIndex on IsarCollection<DiaryRecord> {
  Future<DiaryRecord?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  DiaryRecord? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<DiaryRecord?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<DiaryRecord?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(DiaryRecord object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(DiaryRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<DiaryRecord> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(
    List<DiaryRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension DiaryRecordQueryWhereSort
    on QueryBuilder<DiaryRecord, DiaryRecord, QWhere> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'updatedAt'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'occurredAt'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'deletedAt'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'title'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyContentText() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'contentText'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyEditorType() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'editorType'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhere> anyIsInTrash() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isInTrash'),
      );
    });
  }
}

extension DiaryRecordQueryWhere
    on QueryBuilder<DiaryRecord, DiaryRecord, QWhereClause> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> uuidEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'uuid', value: [uuid]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> uuidNotEqualTo(
    String uuid,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [uuid],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'uuid',
                lower: [],
                upper: [uuid],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> createdAtEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> createdAtNotEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  createdAtGreaterThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> updatedAtEqualTo(
    DateTime updatedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'updatedAt', value: [updatedAt]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> updatedAtNotEqualTo(
    DateTime updatedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [updatedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'updatedAt',
                lower: [],
                upper: [updatedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  updatedAtGreaterThan(DateTime updatedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [updatedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> updatedAtLessThan(
    DateTime updatedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [],
          upper: [updatedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> updatedAtBetween(
    DateTime lowerUpdatedAt,
    DateTime upperUpdatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'updatedAt',
          lower: [lowerUpdatedAt],
          includeLower: includeLower,
          upper: [upperUpdatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> occurredAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'occurredAt', value: [null]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  occurredAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> occurredAtEqualTo(
    DateTime? occurredAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'occurredAt', value: [occurredAt]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  occurredAtNotEqualTo(DateTime? occurredAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [],
                upper: [occurredAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [occurredAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [occurredAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'occurredAt',
                lower: [],
                upper: [occurredAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  occurredAtGreaterThan(DateTime? occurredAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [occurredAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> occurredAtLessThan(
    DateTime? occurredAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [],
          upper: [occurredAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> occurredAtBetween(
    DateTime? lowerOccurredAt,
    DateTime? upperOccurredAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'occurredAt',
          lower: [lowerOccurredAt],
          includeLower: includeLower,
          upper: [upperOccurredAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [null]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [null],
          includeLower: false,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> deletedAtEqualTo(
    DateTime? deletedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'deletedAt', value: [deletedAt]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> deletedAtNotEqualTo(
    DateTime? deletedAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [],
                upper: [deletedAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [deletedAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [deletedAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'deletedAt',
                lower: [],
                upper: [deletedAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  deletedAtGreaterThan(DateTime? deletedAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [deletedAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> deletedAtLessThan(
    DateTime? deletedAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [],
          upper: [deletedAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> deletedAtBetween(
    DateTime? lowerDeletedAt,
    DateTime? upperDeletedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'deletedAt',
          lower: [lowerDeletedAt],
          includeLower: includeLower,
          upper: [upperDeletedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> titleEqualTo(
    String title,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: [title]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> titleNotEqualTo(
    String title,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [],
                upper: [title],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [title],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [title],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'title',
                lower: [],
                upper: [title],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> titleGreaterThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [title],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> titleLessThan(
    String title, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [],
          upper: [title],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> titleBetween(
    String lowerTitle,
    String upperTitle, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [lowerTitle],
          includeLower: includeLower,
          upper: [upperTitle],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> titleStartsWith(
    String TitlePrefix,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'title',
          lower: [TitlePrefix],
          upper: ['$TitlePrefix\u{FFFFF}'],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'title', value: ['']),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'title', upper: ['']),
            )
            .addWhereClause(
              IndexWhereClause.greaterThan(indexName: r'title', lower: ['']),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.greaterThan(indexName: r'title', lower: ['']),
            )
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'title', upper: ['']),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> contentTextEqualTo(
    String contentText,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'contentText',
          value: [contentText],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  contentTextNotEqualTo(String contentText) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contentText',
                lower: [],
                upper: [contentText],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contentText',
                lower: [contentText],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contentText',
                lower: [contentText],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'contentText',
                lower: [],
                upper: [contentText],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  contentTextGreaterThan(String contentText, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'contentText',
          lower: [contentText],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> contentTextLessThan(
    String contentText, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'contentText',
          lower: [],
          upper: [contentText],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> contentTextBetween(
    String lowerContentText,
    String upperContentText, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'contentText',
          lower: [lowerContentText],
          includeLower: includeLower,
          upper: [upperContentText],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  contentTextStartsWith(String ContentTextPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'contentText',
          lower: [ContentTextPrefix],
          upper: ['$ContentTextPrefix\u{FFFFF}'],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  contentTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'contentText', value: ['']),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  contentTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'contentText', upper: ['']),
            )
            .addWhereClause(
              IndexWhereClause.greaterThan(
                indexName: r'contentText',
                lower: [''],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.greaterThan(
                indexName: r'contentText',
                lower: [''],
              ),
            )
            .addWhereClause(
              IndexWhereClause.lessThan(indexName: r'contentText', upper: ['']),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> editorTypeEqualTo(
    int editorType,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'editorType', value: [editorType]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  editorTypeNotEqualTo(int editorType) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'editorType',
                lower: [],
                upper: [editorType],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'editorType',
                lower: [editorType],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'editorType',
                lower: [editorType],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'editorType',
                lower: [],
                upper: [editorType],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause>
  editorTypeGreaterThan(int editorType, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'editorType',
          lower: [editorType],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> editorTypeLessThan(
    int editorType, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'editorType',
          lower: [],
          upper: [editorType],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> editorTypeBetween(
    int lowerEditorType,
    int upperEditorType, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'editorType',
          lower: [lowerEditorType],
          includeLower: includeLower,
          upper: [upperEditorType],
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> categoryEqualTo(
    String category,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'category', value: [category]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> categoryNotEqualTo(
    String category,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'category',
                lower: [],
                upper: [category],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'category',
                lower: [category],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'category',
                lower: [category],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'category',
                lower: [],
                upper: [category],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> isInTrashEqualTo(
    bool isInTrash,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'isInTrash', value: [isInTrash]),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterWhereClause> isInTrashNotEqualTo(
    bool isInTrash,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isInTrash',
                lower: [],
                upper: [isInTrash],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isInTrash',
                lower: [isInTrash],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isInTrash',
                lower: [isInTrash],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'isInTrash',
                lower: [],
                upper: [isInTrash],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension DiaryRecordQueryFilter
    on QueryBuilder<DiaryRecord, DiaryRecord, QFilterCondition> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'attachmentIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'attachmentIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'attachmentIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'attachmentIds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'attachmentIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'attachmentIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'attachmentIds',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'attachmentIds',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'attachmentIds', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'attachmentIds', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachmentIds', length, true, length, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachmentIds', 0, true, 0, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachmentIds', 0, false, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachmentIds', 0, true, length, include);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'attachmentIds', length, include, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  attachmentIdsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'attachmentIds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'audioPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'audioPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'audioPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'audioPaths',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'audioPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'audioPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'audioPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'audioPaths',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'audioPaths', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'audioPaths', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'audioPaths', length, true, length, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'audioPaths', 0, true, 0, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'audioPaths', 0, false, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'audioPaths', 0, true, length, include);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'audioPaths', length, include, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  audioPathsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'audioPaths',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> categoryEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  categoryGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  categoryLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> categoryBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'category',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  categoryStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  categoryEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'category',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> categoryMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'category',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'category', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  colorValueEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'colorValue', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  colorValueGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'colorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  colorValueLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'colorValue',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  colorValueBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'colorValue',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'conflictOf'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'conflictOf'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'conflictOf',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conflictOf',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conflictOf',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conflictOf',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'conflictOf',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'conflictOf',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'conflictOf',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'conflictOf',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conflictOf', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictOfIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'conflictOf', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'conflictStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conflictStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conflictStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conflictStatus',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'conflictStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'conflictStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'conflictStatus',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'conflictStatus',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conflictStatus', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  conflictStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'conflictStatus', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> contentEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'content',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> contentEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> contentContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> contentMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'content',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'contentText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'contentText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'contentText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'contentText',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'contentText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'contentText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'contentText',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'contentText',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'contentText', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  contentTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'contentText', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deletedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deletedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'deletedAt'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deletedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deletedAt', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deletedAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deletedAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deletedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deletedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deletedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> deviceIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deviceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deviceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deviceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deviceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> deviceIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'deviceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  editorTypeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'editorType', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  editorTypeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'editorType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  editorTypeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'editorType',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  editorTypeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'editorType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'imagePaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'imagePaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'imagePaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'imagePaths',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'imagePaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'imagePaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'imagePaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'imagePaths',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'imagePaths', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'imagePaths', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'imagePaths', length, true, length, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'imagePaths', 0, true, 0, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'imagePaths', 0, false, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'imagePaths', 0, true, length, include);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'imagePaths', length, include, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  imagePathsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'imagePaths',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  isConflictEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isConflict', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  isFavoriteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isFavorite', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  isInTrashEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'isInTrash', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  latitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  latitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'latitude'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> latitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  latitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  latitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'latitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> latitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'latitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  longitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  longitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'longitude'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  longitudeEqualTo(double? value, {double epsilon = Query.epsilon}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  longitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  longitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'longitude',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  longitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'longitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> moodEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mood',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> moodGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mood',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> moodLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mood',
          value: value,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> moodBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mood',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,

          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'moodLabel'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'moodLabel'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'moodLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'moodLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'moodLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'moodLabel',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'moodLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'moodLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'moodLabel',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'moodLabel',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'moodLabel', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  moodLabelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'moodLabel', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  occurredAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'occurredAt'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  occurredAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'occurredAt'),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  occurredAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'occurredAt', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  occurredAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'occurredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  occurredAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'occurredAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  occurredAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'occurredAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'positions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'positions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'positions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'positions',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'positions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'positions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'positions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'positions',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'positions', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'positions', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'positions', length, true, length, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'positions', 0, true, 0, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'positions', 0, false, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'positions', 0, true, length, include);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'positions', length, include, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  positionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'positions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> revisionEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'revision', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  revisionGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'revision',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  revisionLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'revision',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> revisionBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'revision',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tags', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, true, length, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, 0, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, false, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', 0, true, length, include);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tags', length, include, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> titleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  titleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> titleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> titleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'title',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> titleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> titleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> titleContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'title',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> titleMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'title',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> titleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  titleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'title', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'uuid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'uuid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'uuid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'uuid', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'videoPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'videoPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'videoPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'videoPaths',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'videoPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'videoPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'videoPaths',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'videoPaths',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'videoPaths', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'videoPaths', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'videoPaths', length, true, length, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'videoPaths', 0, true, 0, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'videoPaths', 0, false, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'videoPaths', 0, true, length, include);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'videoPaths', length, include, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  videoPathsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'videoPaths',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'weather',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'weather',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'weather',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'weather',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'weather',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'weather',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'weather',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'weather',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'weather', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'weather', value: ''),
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weather', length, true, length, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weather', 0, true, 0, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weather', 0, false, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weather', 0, true, length, include);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'weather', length, include, 999999, true);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterFilterCondition>
  weatherLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'weather',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension DiaryRecordQueryObject
    on QueryBuilder<DiaryRecord, DiaryRecord, QFilterCondition> {}

extension DiaryRecordQueryLinks
    on QueryBuilder<DiaryRecord, DiaryRecord, QFilterCondition> {}

extension DiaryRecordQuerySortBy
    on QueryBuilder<DiaryRecord, DiaryRecord, QSortBy> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByConflictOf() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictOf', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByConflictOfDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictOf', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByConflictStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictStatus', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
  sortByConflictStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictStatus', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByContentText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentText', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByContentTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentText', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByEditorType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editorType', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByEditorTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editorType', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByIsConflict() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConflict', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByIsConflictDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConflict', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByIsInTrash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInTrash', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByIsInTrashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInTrash', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByMood() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mood', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByMoodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mood', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByMoodLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodLabel', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByMoodLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodLabel', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByRevision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revision', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByRevisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revision', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension DiaryRecordQuerySortThenBy
    on QueryBuilder<DiaryRecord, DiaryRecord, QSortThenBy> {
  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByColorValueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'colorValue', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByConflictOf() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictOf', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByConflictOfDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictOf', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByConflictStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictStatus', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy>
  thenByConflictStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictStatus', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByContentText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentText', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByContentTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'contentText', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByDeletedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deletedAt', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByEditorType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editorType', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByEditorTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'editorType', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsConflict() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConflict', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsConflictDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isConflict', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsFavoriteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isFavorite', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsInTrash() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInTrash', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByIsInTrashDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isInTrash', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByLatitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'latitude', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByLongitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'longitude', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByMood() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mood', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByMoodDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mood', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByMoodLabel() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodLabel', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByMoodLabelDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'moodLabel', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByOccurredAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'occurredAt', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByRevision() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revision', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByRevisionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'revision', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'title', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension DiaryRecordQueryWhereDistinct
    on QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> {
  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByAttachmentIds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'attachmentIds');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByAudioPaths() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'audioPaths');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByCategory({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByColorValue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'colorValue');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByConflictOf({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'conflictOf', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByConflictStatus({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'conflictStatus',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByContent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByContentText({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'contentText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByDeletedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deletedAt');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByDeviceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByEditorType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'editorType');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByImagePaths() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'imagePaths');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByIsConflict() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isConflict');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByIsFavorite() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isFavorite');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByIsInTrash() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isInTrash');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByLatitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'latitude');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByLongitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'longitude');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByMood() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mood');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByMoodLabel({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'moodLabel', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByOccurredAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'occurredAt');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByPositions() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'positions');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByRevision() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'revision');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByTitle({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'title', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByUuid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByVideoPaths() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'videoPaths');
    });
  }

  QueryBuilder<DiaryRecord, DiaryRecord, QDistinct> distinctByWeather() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weather');
    });
  }
}

extension DiaryRecordQueryProperty
    on QueryBuilder<DiaryRecord, DiaryRecord, QQueryProperty> {
  QueryBuilder<DiaryRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DiaryRecord, List<String>, QQueryOperations>
  attachmentIdsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'attachmentIds');
    });
  }

  QueryBuilder<DiaryRecord, List<String>, QQueryOperations>
  audioPathsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'audioPaths');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<DiaryRecord, int, QQueryOperations> colorValueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'colorValue');
    });
  }

  QueryBuilder<DiaryRecord, String?, QQueryOperations> conflictOfProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conflictOf');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> conflictStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conflictStatus');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> contentTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'contentText');
    });
  }

  QueryBuilder<DiaryRecord, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<DiaryRecord, DateTime?, QQueryOperations> deletedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deletedAt');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<DiaryRecord, int, QQueryOperations> editorTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'editorType');
    });
  }

  QueryBuilder<DiaryRecord, List<String>, QQueryOperations>
  imagePathsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'imagePaths');
    });
  }

  QueryBuilder<DiaryRecord, bool, QQueryOperations> isConflictProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isConflict');
    });
  }

  QueryBuilder<DiaryRecord, bool, QQueryOperations> isFavoriteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isFavorite');
    });
  }

  QueryBuilder<DiaryRecord, bool, QQueryOperations> isInTrashProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isInTrash');
    });
  }

  QueryBuilder<DiaryRecord, double?, QQueryOperations> latitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'latitude');
    });
  }

  QueryBuilder<DiaryRecord, double?, QQueryOperations> longitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'longitude');
    });
  }

  QueryBuilder<DiaryRecord, double, QQueryOperations> moodProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mood');
    });
  }

  QueryBuilder<DiaryRecord, String?, QQueryOperations> moodLabelProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'moodLabel');
    });
  }

  QueryBuilder<DiaryRecord, DateTime?, QQueryOperations> occurredAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'occurredAt');
    });
  }

  QueryBuilder<DiaryRecord, List<String>, QQueryOperations>
  positionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'positions');
    });
  }

  QueryBuilder<DiaryRecord, int, QQueryOperations> revisionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'revision');
    });
  }

  QueryBuilder<DiaryRecord, List<String>, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> titleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'title');
    });
  }

  QueryBuilder<DiaryRecord, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }

  QueryBuilder<DiaryRecord, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<DiaryRecord, List<String>, QQueryOperations>
  videoPathsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'videoPaths');
    });
  }

  QueryBuilder<DiaryRecord, List<String>, QQueryOperations> weatherProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weather');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAttachmentRecordCollection on Isar {
  IsarCollection<AttachmentRecord> get attachmentRecords => this.collection();
}

const AttachmentRecordSchema = CollectionSchema(
  name: r'AttachmentRecord',
  id: 4565848209226651718,
  properties: {
    r'assetId': PropertySchema(id: 0, name: r'assetId', type: IsarType.string),
    r'byteSize': PropertySchema(id: 1, name: r'byteSize', type: IsarType.long),
    r'createdAt': PropertySchema(
      id: 2,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'kind': PropertySchema(id: 3, name: r'kind', type: IsarType.long),
    r'lastError': PropertySchema(
      id: 4,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'localPath': PropertySchema(
      id: 5,
      name: r'localPath',
      type: IsarType.string,
    ),
    r'mimeType': PropertySchema(
      id: 6,
      name: r'mimeType',
      type: IsarType.string,
    ),
    r'originalName': PropertySchema(
      id: 7,
      name: r'originalName',
      type: IsarType.string,
    ),
    r'remoteState': PropertySchema(
      id: 8,
      name: r'remoteState',
      type: IsarType.long,
    ),
    r'sha256': PropertySchema(id: 9, name: r'sha256', type: IsarType.string),
  },

  estimateSize: _attachmentRecordEstimateSize,
  serialize: _attachmentRecordSerialize,
  deserialize: _attachmentRecordDeserialize,
  deserializeProp: _attachmentRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'assetId': IndexSchema(
      id: 174362542210192109,
      name: r'assetId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'assetId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'sha256': IndexSchema(
      id: 5834825609754713283,
      name: r'sha256',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'sha256',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _attachmentRecordGetId,
  getLinks: _attachmentRecordGetLinks,
  attach: _attachmentRecordAttach,
  version: '3.3.2',
);

int _attachmentRecordEstimateSize(
  AttachmentRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assetId.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.localPath;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.mimeType.length * 3;
  bytesCount += 3 + object.originalName.length * 3;
  bytesCount += 3 + object.sha256.length * 3;
  return bytesCount;
}

void _attachmentRecordSerialize(
  AttachmentRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assetId);
  writer.writeLong(offsets[1], object.byteSize);
  writer.writeDateTime(offsets[2], object.createdAt);
  writer.writeLong(offsets[3], object.kind);
  writer.writeString(offsets[4], object.lastError);
  writer.writeString(offsets[5], object.localPath);
  writer.writeString(offsets[6], object.mimeType);
  writer.writeString(offsets[7], object.originalName);
  writer.writeLong(offsets[8], object.remoteState);
  writer.writeString(offsets[9], object.sha256);
}

AttachmentRecord _attachmentRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AttachmentRecord();
  object.assetId = reader.readString(offsets[0]);
  object.byteSize = reader.readLong(offsets[1]);
  object.createdAt = reader.readDateTime(offsets[2]);
  object.id = id;
  object.kind = reader.readLong(offsets[3]);
  object.lastError = reader.readStringOrNull(offsets[4]);
  object.localPath = reader.readStringOrNull(offsets[5]);
  object.mimeType = reader.readString(offsets[6]);
  object.originalName = reader.readString(offsets[7]);
  object.remoteState = reader.readLong(offsets[8]);
  object.sha256 = reader.readString(offsets[9]);
  return object;
}

P _attachmentRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readLong(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _attachmentRecordGetId(AttachmentRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _attachmentRecordGetLinks(AttachmentRecord object) {
  return [];
}

void _attachmentRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  AttachmentRecord object,
) {
  object.id = id;
}

extension AttachmentRecordByIndex on IsarCollection<AttachmentRecord> {
  Future<AttachmentRecord?> getByAssetId(String assetId) {
    return getByIndex(r'assetId', [assetId]);
  }

  AttachmentRecord? getByAssetIdSync(String assetId) {
    return getByIndexSync(r'assetId', [assetId]);
  }

  Future<bool> deleteByAssetId(String assetId) {
    return deleteByIndex(r'assetId', [assetId]);
  }

  bool deleteByAssetIdSync(String assetId) {
    return deleteByIndexSync(r'assetId', [assetId]);
  }

  Future<List<AttachmentRecord?>> getAllByAssetId(List<String> assetIdValues) {
    final values = assetIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'assetId', values);
  }

  List<AttachmentRecord?> getAllByAssetIdSync(List<String> assetIdValues) {
    final values = assetIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'assetId', values);
  }

  Future<int> deleteAllByAssetId(List<String> assetIdValues) {
    final values = assetIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'assetId', values);
  }

  int deleteAllByAssetIdSync(List<String> assetIdValues) {
    final values = assetIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'assetId', values);
  }

  Future<Id> putByAssetId(AttachmentRecord object) {
    return putByIndex(r'assetId', object);
  }

  Id putByAssetIdSync(AttachmentRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'assetId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByAssetId(List<AttachmentRecord> objects) {
    return putAllByIndex(r'assetId', objects);
  }

  List<Id> putAllByAssetIdSync(
    List<AttachmentRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'assetId', objects, saveLinks: saveLinks);
  }

  Future<AttachmentRecord?> getBySha256(String sha256) {
    return getByIndex(r'sha256', [sha256]);
  }

  AttachmentRecord? getBySha256Sync(String sha256) {
    return getByIndexSync(r'sha256', [sha256]);
  }

  Future<bool> deleteBySha256(String sha256) {
    return deleteByIndex(r'sha256', [sha256]);
  }

  bool deleteBySha256Sync(String sha256) {
    return deleteByIndexSync(r'sha256', [sha256]);
  }

  Future<List<AttachmentRecord?>> getAllBySha256(List<String> sha256Values) {
    final values = sha256Values.map((e) => [e]).toList();
    return getAllByIndex(r'sha256', values);
  }

  List<AttachmentRecord?> getAllBySha256Sync(List<String> sha256Values) {
    final values = sha256Values.map((e) => [e]).toList();
    return getAllByIndexSync(r'sha256', values);
  }

  Future<int> deleteAllBySha256(List<String> sha256Values) {
    final values = sha256Values.map((e) => [e]).toList();
    return deleteAllByIndex(r'sha256', values);
  }

  int deleteAllBySha256Sync(List<String> sha256Values) {
    final values = sha256Values.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'sha256', values);
  }

  Future<Id> putBySha256(AttachmentRecord object) {
    return putByIndex(r'sha256', object);
  }

  Id putBySha256Sync(AttachmentRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'sha256', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySha256(List<AttachmentRecord> objects) {
    return putAllByIndex(r'sha256', objects);
  }

  List<Id> putAllBySha256Sync(
    List<AttachmentRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'sha256', objects, saveLinks: saveLinks);
  }
}

extension AttachmentRecordQueryWhereSort
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QWhere> {
  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension AttachmentRecordQueryWhere
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QWhereClause> {
  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause>
  assetIdEqualTo(String assetId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'assetId', value: [assetId]),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause>
  assetIdNotEqualTo(String assetId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'assetId',
                lower: [],
                upper: [assetId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'assetId',
                lower: [assetId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'assetId',
                lower: [assetId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'assetId',
                lower: [],
                upper: [assetId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause>
  sha256EqualTo(String sha256) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'sha256', value: [sha256]),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterWhereClause>
  sha256NotEqualTo(String sha256) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sha256',
                lower: [],
                upper: [sha256],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sha256',
                lower: [sha256],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sha256',
                lower: [sha256],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'sha256',
                lower: [],
                upper: [sha256],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension AttachmentRecordQueryFilter
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QFilterCondition> {
  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'assetId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'assetId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'assetId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'assetId', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  assetIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'assetId', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  byteSizeEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'byteSize', value: value),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  byteSizeGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'byteSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  byteSizeLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'byteSize',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  byteSizeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'byteSize',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  kindEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: value),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  kindGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  kindLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  kindBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastError'),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastError'),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastError',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastError',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastError', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastError', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'localPath'),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'localPath'),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'localPath',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'localPath',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'localPath',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'localPath', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  localPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'localPath', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mimeType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mimeType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mimeType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mimeType', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  mimeTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mimeType', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originalName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originalName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originalName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originalName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'originalName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'originalName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'originalName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'originalName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'originalName', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  originalNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'originalName', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  remoteStateEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'remoteState', value: value),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  remoteStateGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'remoteState',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  remoteStateLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'remoteState',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  remoteStateBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'remoteState',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256EqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256GreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256LessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256Between(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sha256',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256StartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256EndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256Contains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sha256',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256Matches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sha256',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sha256', value: ''),
      );
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterFilterCondition>
  sha256IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sha256', value: ''),
      );
    });
  }
}

extension AttachmentRecordQueryObject
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QFilterCondition> {}

extension AttachmentRecordQueryLinks
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QFilterCondition> {}

extension AttachmentRecordQuerySortBy
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QSortBy> {
  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByAssetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetId', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByAssetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetId', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByByteSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'byteSize', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByByteSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'byteSize', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy> sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByMimeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByMimeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByOriginalName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalName', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByOriginalNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalName', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByRemoteState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteState', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortByRemoteStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteState', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortBySha256() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sha256', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  sortBySha256Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sha256', Sort.desc);
    });
  }
}

extension AttachmentRecordQuerySortThenBy
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QSortThenBy> {
  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByAssetId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetId', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByAssetIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetId', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByByteSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'byteSize', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByByteSizeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'byteSize', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy> thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByLocalPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByLocalPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localPath', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByMimeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByMimeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mimeType', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByOriginalName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalName', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByOriginalNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalName', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByRemoteState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteState', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenByRemoteStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteState', Sort.desc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenBySha256() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sha256', Sort.asc);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QAfterSortBy>
  thenBySha256Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sha256', Sort.desc);
    });
  }
}

extension AttachmentRecordQueryWhereDistinct
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct> {
  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct>
  distinctByAssetId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assetId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct>
  distinctByByteSize() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'byteSize');
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct> distinctByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind');
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct>
  distinctByLastError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct>
  distinctByLocalPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'localPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct>
  distinctByMimeType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mimeType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct>
  distinctByOriginalName({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct>
  distinctByRemoteState() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteState');
    });
  }

  QueryBuilder<AttachmentRecord, AttachmentRecord, QDistinct> distinctBySha256({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sha256', caseSensitive: caseSensitive);
    });
  }
}

extension AttachmentRecordQueryProperty
    on QueryBuilder<AttachmentRecord, AttachmentRecord, QQueryProperty> {
  QueryBuilder<AttachmentRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AttachmentRecord, String, QQueryOperations> assetIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assetId');
    });
  }

  QueryBuilder<AttachmentRecord, int, QQueryOperations> byteSizeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'byteSize');
    });
  }

  QueryBuilder<AttachmentRecord, DateTime, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<AttachmentRecord, int, QQueryOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<AttachmentRecord, String?, QQueryOperations>
  lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<AttachmentRecord, String?, QQueryOperations>
  localPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localPath');
    });
  }

  QueryBuilder<AttachmentRecord, String, QQueryOperations> mimeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mimeType');
    });
  }

  QueryBuilder<AttachmentRecord, String, QQueryOperations>
  originalNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalName');
    });
  }

  QueryBuilder<AttachmentRecord, int, QQueryOperations> remoteStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteState');
    });
  }

  QueryBuilder<AttachmentRecord, String, QQueryOperations> sha256Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sha256');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOutboxRecordCollection on Isar {
  IsarCollection<OutboxRecord> get outboxRecords => this.collection();
}

const OutboxRecordSchema = CollectionSchema(
  name: r'OutboxRecord',
  id: -2568400676741027040,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'entityId': PropertySchema(
      id: 1,
      name: r'entityId',
      type: IsarType.string,
    ),
    r'entityType': PropertySchema(
      id: 2,
      name: r'entityType',
      type: IsarType.string,
    ),
    r'mutationId': PropertySchema(
      id: 3,
      name: r'mutationId',
      type: IsarType.string,
    ),
    r'nextRetryAt': PropertySchema(
      id: 4,
      name: r'nextRetryAt',
      type: IsarType.dateTime,
    ),
    r'payloadJson': PropertySchema(
      id: 5,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'retryCount': PropertySchema(
      id: 6,
      name: r'retryCount',
      type: IsarType.long,
    ),
  },

  estimateSize: _outboxRecordEstimateSize,
  serialize: _outboxRecordSerialize,
  deserialize: _outboxRecordDeserialize,
  deserializeProp: _outboxRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'mutationId': IndexSchema(
      id: 4450546051540618180,
      name: r'mutationId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'mutationId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'entityId': IndexSchema(
      id: 745355021660786263,
      name: r'entityId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entityId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'createdAt': IndexSchema(
      id: -3433535483987302584,
      name: r'createdAt',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'createdAt',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _outboxRecordGetId,
  getLinks: _outboxRecordGetLinks,
  attach: _outboxRecordAttach,
  version: '3.3.2',
);

int _outboxRecordEstimateSize(
  OutboxRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.entityId.length * 3;
  bytesCount += 3 + object.entityType.length * 3;
  bytesCount += 3 + object.mutationId.length * 3;
  bytesCount += 3 + object.payloadJson.length * 3;
  return bytesCount;
}

void _outboxRecordSerialize(
  OutboxRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.entityId);
  writer.writeString(offsets[2], object.entityType);
  writer.writeString(offsets[3], object.mutationId);
  writer.writeDateTime(offsets[4], object.nextRetryAt);
  writer.writeString(offsets[5], object.payloadJson);
  writer.writeLong(offsets[6], object.retryCount);
}

OutboxRecord _outboxRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OutboxRecord();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.entityId = reader.readString(offsets[1]);
  object.entityType = reader.readString(offsets[2]);
  object.id = id;
  object.mutationId = reader.readString(offsets[3]);
  object.nextRetryAt = reader.readDateTimeOrNull(offsets[4]);
  object.payloadJson = reader.readString(offsets[5]);
  object.retryCount = reader.readLong(offsets[6]);
  return object;
}

P _outboxRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _outboxRecordGetId(OutboxRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _outboxRecordGetLinks(OutboxRecord object) {
  return [];
}

void _outboxRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  OutboxRecord object,
) {
  object.id = id;
}

extension OutboxRecordByIndex on IsarCollection<OutboxRecord> {
  Future<OutboxRecord?> getByMutationId(String mutationId) {
    return getByIndex(r'mutationId', [mutationId]);
  }

  OutboxRecord? getByMutationIdSync(String mutationId) {
    return getByIndexSync(r'mutationId', [mutationId]);
  }

  Future<bool> deleteByMutationId(String mutationId) {
    return deleteByIndex(r'mutationId', [mutationId]);
  }

  bool deleteByMutationIdSync(String mutationId) {
    return deleteByIndexSync(r'mutationId', [mutationId]);
  }

  Future<List<OutboxRecord?>> getAllByMutationId(
    List<String> mutationIdValues,
  ) {
    final values = mutationIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'mutationId', values);
  }

  List<OutboxRecord?> getAllByMutationIdSync(List<String> mutationIdValues) {
    final values = mutationIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'mutationId', values);
  }

  Future<int> deleteAllByMutationId(List<String> mutationIdValues) {
    final values = mutationIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'mutationId', values);
  }

  int deleteAllByMutationIdSync(List<String> mutationIdValues) {
    final values = mutationIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'mutationId', values);
  }

  Future<Id> putByMutationId(OutboxRecord object) {
    return putByIndex(r'mutationId', object);
  }

  Id putByMutationIdSync(OutboxRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'mutationId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByMutationId(List<OutboxRecord> objects) {
    return putAllByIndex(r'mutationId', objects);
  }

  List<Id> putAllByMutationIdSync(
    List<OutboxRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'mutationId', objects, saveLinks: saveLinks);
  }
}

extension OutboxRecordQueryWhereSort
    on QueryBuilder<OutboxRecord, OutboxRecord, QWhere> {
  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhere> anyCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'createdAt'),
      );
    });
  }
}

extension OutboxRecordQueryWhere
    on QueryBuilder<OutboxRecord, OutboxRecord, QWhereClause> {
  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> mutationIdEqualTo(
    String mutationId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'mutationId', value: [mutationId]),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause>
  mutationIdNotEqualTo(String mutationId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mutationId',
                lower: [],
                upper: [mutationId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mutationId',
                lower: [mutationId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mutationId',
                lower: [mutationId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'mutationId',
                lower: [],
                upper: [mutationId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> entityIdEqualTo(
    String entityId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entityId', value: [entityId]),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause>
  entityIdNotEqualTo(String entityId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [],
                upper: [entityId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [entityId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [entityId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entityId',
                lower: [],
                upper: [entityId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> createdAtEqualTo(
    DateTime createdAt,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'createdAt', value: [createdAt]),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause>
  createdAtNotEqualTo(DateTime createdAt) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [createdAt],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'createdAt',
                lower: [],
                upper: [createdAt],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause>
  createdAtGreaterThan(DateTime createdAt, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [createdAt],
          includeLower: include,
          upper: [],
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> createdAtLessThan(
    DateTime createdAt, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [],
          upper: [createdAt],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterWhereClause> createdAtBetween(
    DateTime lowerCreatedAt,
    DateTime upperCreatedAt, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'createdAt',
          lower: [lowerCreatedAt],
          includeLower: includeLower,
          upper: [upperCreatedAt],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension OutboxRecordQueryFilter
    on QueryBuilder<OutboxRecord, OutboxRecord, QFilterCondition> {
  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityId', value: ''),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityId', value: ''),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entityType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entityType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entityType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entityType', value: ''),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  entityTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entityType', value: ''),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'mutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'mutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'mutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'mutationId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'mutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'mutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'mutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'mutationId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'mutationId', value: ''),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  mutationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'mutationId', value: ''),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  nextRetryAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'nextRetryAt'),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  nextRetryAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'nextRetryAt'),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  nextRetryAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'nextRetryAt', value: value),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  nextRetryAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'nextRetryAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  nextRetryAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'nextRetryAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  nextRetryAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'nextRetryAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payloadJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payloadJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  retryCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'retryCount', value: value),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  retryCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'retryCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  retryCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'retryCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterFilterCondition>
  retryCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'retryCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension OutboxRecordQueryObject
    on QueryBuilder<OutboxRecord, OutboxRecord, QFilterCondition> {}

extension OutboxRecordQueryLinks
    on QueryBuilder<OutboxRecord, OutboxRecord, QFilterCondition> {}

extension OutboxRecordQuerySortBy
    on QueryBuilder<OutboxRecord, OutboxRecord, QSortBy> {
  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  sortByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByMutationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mutationId', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  sortByMutationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mutationId', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  sortByNextRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> sortByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  sortByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }
}

extension OutboxRecordQuerySortThenBy
    on QueryBuilder<OutboxRecord, OutboxRecord, QSortThenBy> {
  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByEntityId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByEntityIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityId', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByEntityType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  thenByEntityTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entityType', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByMutationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mutationId', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  thenByMutationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mutationId', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  thenByNextRetryAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nextRetryAt', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy> thenByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.asc);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QAfterSortBy>
  thenByRetryCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'retryCount', Sort.desc);
    });
  }
}

extension OutboxRecordQueryWhereDistinct
    on QueryBuilder<OutboxRecord, OutboxRecord, QDistinct> {
  QueryBuilder<OutboxRecord, OutboxRecord, QDistinct> distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QDistinct> distinctByEntityId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QDistinct> distinctByEntityType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entityType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QDistinct> distinctByMutationId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mutationId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QDistinct> distinctByNextRetryAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nextRetryAt');
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QDistinct> distinctByPayloadJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OutboxRecord, OutboxRecord, QDistinct> distinctByRetryCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'retryCount');
    });
  }
}

extension OutboxRecordQueryProperty
    on QueryBuilder<OutboxRecord, OutboxRecord, QQueryProperty> {
  QueryBuilder<OutboxRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OutboxRecord, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<OutboxRecord, String, QQueryOperations> entityIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityId');
    });
  }

  QueryBuilder<OutboxRecord, String, QQueryOperations> entityTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entityType');
    });
  }

  QueryBuilder<OutboxRecord, String, QQueryOperations> mutationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mutationId');
    });
  }

  QueryBuilder<OutboxRecord, DateTime?, QQueryOperations>
  nextRetryAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nextRetryAt');
    });
  }

  QueryBuilder<OutboxRecord, String, QQueryOperations> payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<OutboxRecord, int, QQueryOperations> retryCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'retryCount');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDraftRecordCollection on Isar {
  IsarCollection<DraftRecord> get draftRecords => this.collection();
}

const DraftRecordSchema = CollectionSchema(
  name: r'DraftRecord',
  id: -6572266749494032866,
  properties: {
    r'draftId': PropertySchema(id: 0, name: r'draftId', type: IsarType.string),
    r'entryId': PropertySchema(id: 1, name: r'entryId', type: IsarType.string),
    r'payloadJson': PropertySchema(
      id: 2,
      name: r'payloadJson',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 3,
      name: r'updatedAt',
      type: IsarType.dateTime,
    ),
  },

  estimateSize: _draftRecordEstimateSize,
  serialize: _draftRecordSerialize,
  deserialize: _draftRecordDeserialize,
  deserializeProp: _draftRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'draftId': IndexSchema(
      id: 5577587084572475806,
      name: r'draftId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'draftId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _draftRecordGetId,
  getLinks: _draftRecordGetLinks,
  attach: _draftRecordAttach,
  version: '3.3.2',
);

int _draftRecordEstimateSize(
  DraftRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.draftId.length * 3;
  {
    final value = object.entryId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.payloadJson.length * 3;
  return bytesCount;
}

void _draftRecordSerialize(
  DraftRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.draftId);
  writer.writeString(offsets[1], object.entryId);
  writer.writeString(offsets[2], object.payloadJson);
  writer.writeDateTime(offsets[3], object.updatedAt);
}

DraftRecord _draftRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DraftRecord();
  object.draftId = reader.readString(offsets[0]);
  object.entryId = reader.readStringOrNull(offsets[1]);
  object.id = id;
  object.payloadJson = reader.readString(offsets[2]);
  object.updatedAt = reader.readDateTime(offsets[3]);
  return object;
}

P _draftRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _draftRecordGetId(DraftRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _draftRecordGetLinks(DraftRecord object) {
  return [];
}

void _draftRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  DraftRecord object,
) {
  object.id = id;
}

extension DraftRecordByIndex on IsarCollection<DraftRecord> {
  Future<DraftRecord?> getByDraftId(String draftId) {
    return getByIndex(r'draftId', [draftId]);
  }

  DraftRecord? getByDraftIdSync(String draftId) {
    return getByIndexSync(r'draftId', [draftId]);
  }

  Future<bool> deleteByDraftId(String draftId) {
    return deleteByIndex(r'draftId', [draftId]);
  }

  bool deleteByDraftIdSync(String draftId) {
    return deleteByIndexSync(r'draftId', [draftId]);
  }

  Future<List<DraftRecord?>> getAllByDraftId(List<String> draftIdValues) {
    final values = draftIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'draftId', values);
  }

  List<DraftRecord?> getAllByDraftIdSync(List<String> draftIdValues) {
    final values = draftIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'draftId', values);
  }

  Future<int> deleteAllByDraftId(List<String> draftIdValues) {
    final values = draftIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'draftId', values);
  }

  int deleteAllByDraftIdSync(List<String> draftIdValues) {
    final values = draftIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'draftId', values);
  }

  Future<Id> putByDraftId(DraftRecord object) {
    return putByIndex(r'draftId', object);
  }

  Id putByDraftIdSync(DraftRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'draftId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByDraftId(List<DraftRecord> objects) {
    return putAllByIndex(r'draftId', objects);
  }

  List<Id> putAllByDraftIdSync(
    List<DraftRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'draftId', objects, saveLinks: saveLinks);
  }
}

extension DraftRecordQueryWhereSort
    on QueryBuilder<DraftRecord, DraftRecord, QWhere> {
  QueryBuilder<DraftRecord, DraftRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DraftRecordQueryWhere
    on QueryBuilder<DraftRecord, DraftRecord, QWhereClause> {
  QueryBuilder<DraftRecord, DraftRecord, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterWhereClause> draftIdEqualTo(
    String draftId,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'draftId', value: [draftId]),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterWhereClause> draftIdNotEqualTo(
    String draftId,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'draftId',
                lower: [],
                upper: [draftId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'draftId',
                lower: [draftId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'draftId',
                lower: [draftId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'draftId',
                lower: [],
                upper: [draftId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension DraftRecordQueryFilter
    on QueryBuilder<DraftRecord, DraftRecord, QFilterCondition> {
  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> draftIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'draftId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  draftIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'draftId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> draftIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'draftId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> draftIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'draftId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  draftIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'draftId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> draftIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'draftId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> draftIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'draftId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> draftIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'draftId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  draftIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'draftId', value: ''),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  draftIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'draftId', value: ''),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  entryIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'entryId'),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  entryIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'entryId'),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> entryIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  entryIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> entryIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> entryIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entryId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  entryIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> entryIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> entryIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> entryIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entryId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  entryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entryId', value: ''),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  entryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entryId', value: ''),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'payloadJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'payloadJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'payloadJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  payloadJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'payloadJson', value: ''),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  updatedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  updatedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterFilterCondition>
  updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension DraftRecordQueryObject
    on QueryBuilder<DraftRecord, DraftRecord, QFilterCondition> {}

extension DraftRecordQueryLinks
    on QueryBuilder<DraftRecord, DraftRecord, QFilterCondition> {}

extension DraftRecordQuerySortBy
    on QueryBuilder<DraftRecord, DraftRecord, QSortBy> {
  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> sortByDraftId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'draftId', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> sortByDraftIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'draftId', Sort.desc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> sortByEntryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> sortByEntryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.desc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> sortByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> sortByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DraftRecordQuerySortThenBy
    on QueryBuilder<DraftRecord, DraftRecord, QSortThenBy> {
  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByDraftId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'draftId', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByDraftIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'draftId', Sort.desc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByEntryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByEntryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.desc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByPayloadJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByPayloadJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'payloadJson', Sort.desc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension DraftRecordQueryWhereDistinct
    on QueryBuilder<DraftRecord, DraftRecord, QDistinct> {
  QueryBuilder<DraftRecord, DraftRecord, QDistinct> distinctByDraftId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'draftId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QDistinct> distinctByEntryId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QDistinct> distinctByPayloadJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'payloadJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DraftRecord, DraftRecord, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension DraftRecordQueryProperty
    on QueryBuilder<DraftRecord, DraftRecord, QQueryProperty> {
  QueryBuilder<DraftRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DraftRecord, String, QQueryOperations> draftIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'draftId');
    });
  }

  QueryBuilder<DraftRecord, String?, QQueryOperations> entryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryId');
    });
  }

  QueryBuilder<DraftRecord, String, QQueryOperations> payloadJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'payloadJson');
    });
  }

  QueryBuilder<DraftRecord, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSyncStateRecordCollection on Isar {
  IsarCollection<SyncStateRecord> get syncStateRecords => this.collection();
}

const SyncStateRecordSchema = CollectionSchema(
  name: r'SyncStateRecord',
  id: 933615554399557578,
  properties: {
    r'cursor': PropertySchema(id: 0, name: r'cursor', type: IsarType.string),
    r'deviceId': PropertySchema(
      id: 1,
      name: r'deviceId',
      type: IsarType.string,
    ),
    r'key': PropertySchema(id: 2, name: r'key', type: IsarType.string),
    r'lastError': PropertySchema(
      id: 3,
      name: r'lastError',
      type: IsarType.string,
    ),
    r'lastSuccessAt': PropertySchema(
      id: 4,
      name: r'lastSuccessAt',
      type: IsarType.dateTime,
    ),
    r'status': PropertySchema(id: 5, name: r'status', type: IsarType.long),
  },

  estimateSize: _syncStateRecordEstimateSize,
  serialize: _syncStateRecordSerialize,
  deserialize: _syncStateRecordDeserialize,
  deserializeProp: _syncStateRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _syncStateRecordGetId,
  getLinks: _syncStateRecordGetLinks,
  attach: _syncStateRecordAttach,
  version: '3.3.2',
);

int _syncStateRecordEstimateSize(
  SyncStateRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cursor.length * 3;
  bytesCount += 3 + object.deviceId.length * 3;
  bytesCount += 3 + object.key.length * 3;
  {
    final value = object.lastError;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _syncStateRecordSerialize(
  SyncStateRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cursor);
  writer.writeString(offsets[1], object.deviceId);
  writer.writeString(offsets[2], object.key);
  writer.writeString(offsets[3], object.lastError);
  writer.writeDateTime(offsets[4], object.lastSuccessAt);
  writer.writeLong(offsets[5], object.status);
}

SyncStateRecord _syncStateRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SyncStateRecord();
  object.cursor = reader.readString(offsets[0]);
  object.deviceId = reader.readString(offsets[1]);
  object.id = id;
  object.key = reader.readString(offsets[2]);
  object.lastError = reader.readStringOrNull(offsets[3]);
  object.lastSuccessAt = reader.readDateTimeOrNull(offsets[4]);
  object.status = reader.readLong(offsets[5]);
  return object;
}

P _syncStateRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _syncStateRecordGetId(SyncStateRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _syncStateRecordGetLinks(SyncStateRecord object) {
  return [];
}

void _syncStateRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  SyncStateRecord object,
) {
  object.id = id;
}

extension SyncStateRecordByIndex on IsarCollection<SyncStateRecord> {
  Future<SyncStateRecord?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  SyncStateRecord? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<SyncStateRecord?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<SyncStateRecord?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(SyncStateRecord object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(SyncStateRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<SyncStateRecord> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(
    List<SyncStateRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension SyncStateRecordQueryWhereSort
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QWhere> {
  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension SyncStateRecordQueryWhere
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QWhereClause> {
  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterWhereClause> keyEqualTo(
    String key,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'key', value: [key]),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterWhereClause>
  keyNotEqualTo(String key) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SyncStateRecordQueryFilter
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QFilterCondition> {
  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cursor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cursor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cursor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cursor',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cursor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cursor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cursor',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cursor',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cursor', value: ''),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  cursorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cursor', value: ''),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'deviceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'deviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'deviceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  deviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'deviceId', value: ''),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'key',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastError'),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastError'),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastError',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastError',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastError',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastError', value: ''),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastErrorIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'lastError', value: ''),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastSuccessAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lastSuccessAt'),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastSuccessAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lastSuccessAt'),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastSuccessAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastSuccessAt', value: value),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastSuccessAtGreaterThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastSuccessAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastSuccessAtLessThan(DateTime? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastSuccessAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  lastSuccessAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastSuccessAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  statusEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: value),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  statusGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  statusLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterFilterCondition>
  statusBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SyncStateRecordQueryObject
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QFilterCondition> {}

extension SyncStateRecordQueryLinks
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QFilterCondition> {}

extension SyncStateRecordQuerySortBy
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QSortBy> {
  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> sortByCursor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursor', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  sortByCursorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursor', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  sortByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  sortByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  sortByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  sortByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  sortByLastSuccessAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessAt', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  sortByLastSuccessAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessAt', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension SyncStateRecordQuerySortThenBy
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QSortThenBy> {
  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> thenByCursor() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursor', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  thenByCursorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cursor', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  thenByDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  thenByDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deviceId', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  thenByLastError() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  thenByLastErrorDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastError', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  thenByLastSuccessAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessAt', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  thenByLastSuccessAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastSuccessAt', Sort.desc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension SyncStateRecordQueryWhereDistinct
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QDistinct> {
  QueryBuilder<SyncStateRecord, SyncStateRecord, QDistinct> distinctByCursor({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cursor', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QDistinct> distinctByDeviceId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deviceId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QDistinct> distinctByKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QDistinct>
  distinctByLastError({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastError', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QDistinct>
  distinctByLastSuccessAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastSuccessAt');
    });
  }

  QueryBuilder<SyncStateRecord, SyncStateRecord, QDistinct> distinctByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status');
    });
  }
}

extension SyncStateRecordQueryProperty
    on QueryBuilder<SyncStateRecord, SyncStateRecord, QQueryProperty> {
  QueryBuilder<SyncStateRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SyncStateRecord, String, QQueryOperations> cursorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cursor');
    });
  }

  QueryBuilder<SyncStateRecord, String, QQueryOperations> deviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deviceId');
    });
  }

  QueryBuilder<SyncStateRecord, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<SyncStateRecord, String?, QQueryOperations> lastErrorProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastError');
    });
  }

  QueryBuilder<SyncStateRecord, DateTime?, QQueryOperations>
  lastSuccessAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastSuccessAt');
    });
  }

  QueryBuilder<SyncStateRecord, int, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetConflictRecordCollection on Isar {
  IsarCollection<ConflictRecord> get conflictRecords => this.collection();
}

const ConflictRecordSchema = CollectionSchema(
  name: r'ConflictRecord',
  id: -5537671177465713733,
  properties: {
    r'conflictId': PropertySchema(
      id: 0,
      name: r'conflictId',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'entryId': PropertySchema(id: 2, name: r'entryId', type: IsarType.string),
    r'entryJson': PropertySchema(
      id: 3,
      name: r'entryJson',
      type: IsarType.string,
    ),
    r'serverEntryJson': PropertySchema(
      id: 4,
      name: r'serverEntryJson',
      type: IsarType.string,
    ),
    r'sourceDeviceId': PropertySchema(
      id: 5,
      name: r'sourceDeviceId',
      type: IsarType.string,
    ),
    r'sourceMutationId': PropertySchema(
      id: 6,
      name: r'sourceMutationId',
      type: IsarType.string,
    ),
    r'status': PropertySchema(id: 7, name: r'status', type: IsarType.string),
  },

  estimateSize: _conflictRecordEstimateSize,
  serialize: _conflictRecordSerialize,
  deserialize: _conflictRecordDeserialize,
  deserializeProp: _conflictRecordDeserializeProp,
  idName: r'id',
  indexes: {
    r'conflictId': IndexSchema(
      id: -1679575242341205871,
      name: r'conflictId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'conflictId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'entryId': IndexSchema(
      id: 3733379884318738402,
      name: r'entryId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'entryId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'status': IndexSchema(
      id: -107785170620420283,
      name: r'status',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'status',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _conflictRecordGetId,
  getLinks: _conflictRecordGetLinks,
  attach: _conflictRecordAttach,
  version: '3.3.2',
);

int _conflictRecordEstimateSize(
  ConflictRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.conflictId.length * 3;
  bytesCount += 3 + object.entryId.length * 3;
  bytesCount += 3 + object.entryJson.length * 3;
  bytesCount += 3 + object.serverEntryJson.length * 3;
  bytesCount += 3 + object.sourceDeviceId.length * 3;
  bytesCount += 3 + object.sourceMutationId.length * 3;
  bytesCount += 3 + object.status.length * 3;
  return bytesCount;
}

void _conflictRecordSerialize(
  ConflictRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.conflictId);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeString(offsets[2], object.entryId);
  writer.writeString(offsets[3], object.entryJson);
  writer.writeString(offsets[4], object.serverEntryJson);
  writer.writeString(offsets[5], object.sourceDeviceId);
  writer.writeString(offsets[6], object.sourceMutationId);
  writer.writeString(offsets[7], object.status);
}

ConflictRecord _conflictRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ConflictRecord();
  object.conflictId = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.entryId = reader.readString(offsets[2]);
  object.entryJson = reader.readString(offsets[3]);
  object.id = id;
  object.serverEntryJson = reader.readString(offsets[4]);
  object.sourceDeviceId = reader.readString(offsets[5]);
  object.sourceMutationId = reader.readString(offsets[6]);
  object.status = reader.readString(offsets[7]);
  return object;
}

P _conflictRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _conflictRecordGetId(ConflictRecord object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _conflictRecordGetLinks(ConflictRecord object) {
  return [];
}

void _conflictRecordAttach(
  IsarCollection<dynamic> col,
  Id id,
  ConflictRecord object,
) {
  object.id = id;
}

extension ConflictRecordByIndex on IsarCollection<ConflictRecord> {
  Future<ConflictRecord?> getByConflictId(String conflictId) {
    return getByIndex(r'conflictId', [conflictId]);
  }

  ConflictRecord? getByConflictIdSync(String conflictId) {
    return getByIndexSync(r'conflictId', [conflictId]);
  }

  Future<bool> deleteByConflictId(String conflictId) {
    return deleteByIndex(r'conflictId', [conflictId]);
  }

  bool deleteByConflictIdSync(String conflictId) {
    return deleteByIndexSync(r'conflictId', [conflictId]);
  }

  Future<List<ConflictRecord?>> getAllByConflictId(
    List<String> conflictIdValues,
  ) {
    final values = conflictIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'conflictId', values);
  }

  List<ConflictRecord?> getAllByConflictIdSync(List<String> conflictIdValues) {
    final values = conflictIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'conflictId', values);
  }

  Future<int> deleteAllByConflictId(List<String> conflictIdValues) {
    final values = conflictIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'conflictId', values);
  }

  int deleteAllByConflictIdSync(List<String> conflictIdValues) {
    final values = conflictIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'conflictId', values);
  }

  Future<Id> putByConflictId(ConflictRecord object) {
    return putByIndex(r'conflictId', object);
  }

  Id putByConflictIdSync(ConflictRecord object, {bool saveLinks = true}) {
    return putByIndexSync(r'conflictId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByConflictId(List<ConflictRecord> objects) {
    return putAllByIndex(r'conflictId', objects);
  }

  List<Id> putAllByConflictIdSync(
    List<ConflictRecord> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'conflictId', objects, saveLinks: saveLinks);
  }
}

extension ConflictRecordQueryWhereSort
    on QueryBuilder<ConflictRecord, ConflictRecord, QWhere> {
  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ConflictRecordQueryWhere
    on QueryBuilder<ConflictRecord, ConflictRecord, QWhereClause> {
  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause>
  conflictIdEqualTo(String conflictId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'conflictId', value: [conflictId]),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause>
  conflictIdNotEqualTo(String conflictId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conflictId',
                lower: [],
                upper: [conflictId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conflictId',
                lower: [conflictId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conflictId',
                lower: [conflictId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'conflictId',
                lower: [],
                upper: [conflictId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause>
  entryIdEqualTo(String entryId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'entryId', value: [entryId]),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause>
  entryIdNotEqualTo(String entryId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entryId',
                lower: [],
                upper: [entryId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entryId',
                lower: [entryId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entryId',
                lower: [entryId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'entryId',
                lower: [],
                upper: [entryId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause> statusEqualTo(
    String status,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'status', value: [status]),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterWhereClause>
  statusNotEqualTo(String status) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [],
                upper: [status],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [status],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [status],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'status',
                lower: [],
                upper: [status],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension ConflictRecordQueryFilter
    on QueryBuilder<ConflictRecord, ConflictRecord, QFilterCondition> {
  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'conflictId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'conflictId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'conflictId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'conflictId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'conflictId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'conflictId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'conflictId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'conflictId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'conflictId', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  conflictIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'conflictId', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  createdAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  createdAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entryId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entryId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entryId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entryId', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entryId', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'entryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'entryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'entryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'entryJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'entryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'entryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'entryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'entryJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'entryJson', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  entryJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'entryJson', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'serverEntryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'serverEntryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'serverEntryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'serverEntryJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'serverEntryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'serverEntryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'serverEntryJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'serverEntryJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'serverEntryJson', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  serverEntryJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'serverEntryJson', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceDeviceId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceDeviceId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceDeviceId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceDeviceId', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceDeviceIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceDeviceId', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sourceMutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sourceMutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sourceMutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sourceMutationId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sourceMutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sourceMutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sourceMutationId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sourceMutationId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sourceMutationId', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  sourceMutationIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sourceMutationId', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'status',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'status',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'status',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'status', value: ''),
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterFilterCondition>
  statusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'status', value: ''),
      );
    });
  }
}

extension ConflictRecordQueryObject
    on QueryBuilder<ConflictRecord, ConflictRecord, QFilterCondition> {}

extension ConflictRecordQueryLinks
    on QueryBuilder<ConflictRecord, ConflictRecord, QFilterCondition> {}

extension ConflictRecordQuerySortBy
    on QueryBuilder<ConflictRecord, ConflictRecord, QSortBy> {
  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortByConflictId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictId', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortByConflictIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictId', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> sortByEntryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortByEntryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> sortByEntryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryJson', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortByEntryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryJson', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortByServerEntryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverEntryJson', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortByServerEntryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverEntryJson', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortBySourceDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceDeviceId', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortBySourceDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceDeviceId', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortBySourceMutationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceMutationId', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortBySourceMutationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceMutationId', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> sortByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  sortByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension ConflictRecordQuerySortThenBy
    on QueryBuilder<ConflictRecord, ConflictRecord, QSortThenBy> {
  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenByConflictId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictId', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenByConflictIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'conflictId', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> thenByEntryId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenByEntryIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryId', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> thenByEntryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryJson', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenByEntryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'entryJson', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenByServerEntryJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverEntryJson', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenByServerEntryJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'serverEntryJson', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenBySourceDeviceId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceDeviceId', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenBySourceDeviceIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceDeviceId', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenBySourceMutationId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceMutationId', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenBySourceMutationIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sourceMutationId', Sort.desc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy> thenByStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.asc);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QAfterSortBy>
  thenByStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'status', Sort.desc);
    });
  }
}

extension ConflictRecordQueryWhereDistinct
    on QueryBuilder<ConflictRecord, ConflictRecord, QDistinct> {
  QueryBuilder<ConflictRecord, ConflictRecord, QDistinct> distinctByConflictId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'conflictId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QDistinct> distinctByEntryId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QDistinct> distinctByEntryJson({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'entryJson', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QDistinct>
  distinctByServerEntryJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'serverEntryJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QDistinct>
  distinctBySourceDeviceId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceDeviceId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QDistinct>
  distinctBySourceMutationId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'sourceMutationId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<ConflictRecord, ConflictRecord, QDistinct> distinctByStatus({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'status', caseSensitive: caseSensitive);
    });
  }
}

extension ConflictRecordQueryProperty
    on QueryBuilder<ConflictRecord, ConflictRecord, QQueryProperty> {
  QueryBuilder<ConflictRecord, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ConflictRecord, String, QQueryOperations> conflictIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'conflictId');
    });
  }

  QueryBuilder<ConflictRecord, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<ConflictRecord, String, QQueryOperations> entryIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryId');
    });
  }

  QueryBuilder<ConflictRecord, String, QQueryOperations> entryJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'entryJson');
    });
  }

  QueryBuilder<ConflictRecord, String, QQueryOperations>
  serverEntryJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'serverEntryJson');
    });
  }

  QueryBuilder<ConflictRecord, String, QQueryOperations>
  sourceDeviceIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceDeviceId');
    });
  }

  QueryBuilder<ConflictRecord, String, QQueryOperations>
  sourceMutationIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sourceMutationId');
    });
  }

  QueryBuilder<ConflictRecord, String, QQueryOperations> statusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'status');
    });
  }
}
