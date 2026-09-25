import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart' as crypto;

import '../domain/attachment.dart';
import '../domain/diary_entry.dart';
import 'diary_repository.dart';

/// Portable, unencrypted backup format shared by desktop and mobile.
/// The manifest is intentionally human-readable; attachments are content
/// addressed by sha256 and stored below `attachments/` in the zip.
class DiaryBackupService {
  const DiaryBackupService();

  Uint8List exportZip({
    required Iterable<DiaryEntry> entries,
    Iterable<Attachment> attachments = const [],
    Map<String, dynamic> settings = const {},
    Future<List<int>> Function(Attachment)? readAttachment,
  }) {
    final archive = Archive();
    final attachmentList = attachments.toList(growable: false);
    final manifest = <String, dynamic>{
      'format': 'diary-backup',
      'version': 2,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'attachments': attachmentList
          .map(
            (item) => {
              'assetId': item.assetId,
              'sha256': item.sha256,
              'kind': item.kind.name,
              'mimeType': item.mimeType,
              'byteSize': item.byteSize,
              'originalName': item.originalName,
              'createdAt': item.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList(growable: false),
      'settings': settings,
    };
    archive.addFile(
      ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest))),
    );
    if (readAttachment != null) {
      // ArchiveFile is synchronous, so callers that need to include files
      // should use [exportZipAsync]. This method remains useful for metadata.
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  Future<Uint8List> exportZipAsync({
    required Iterable<DiaryEntry> entries,
    Iterable<Attachment> attachments = const [],
    Map<String, dynamic> settings = const {},
    Future<List<int>> Function(Attachment)? readAttachment,
  }) async {
    final archive = Archive();
    final attachmentList = attachments.toList(growable: false);
    final manifest = <String, dynamic>{
      'format': 'diary-backup',
      'version': 2,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
      'attachments': attachmentList
          .map(
            (item) => {
              'assetId': item.assetId,
              'sha256': item.sha256,
              'kind': item.kind.name,
              'mimeType': item.mimeType,
              'byteSize': item.byteSize,
              'originalName': item.originalName,
              'createdAt': item.createdAt.toUtc().toIso8601String(),
            },
          )
          .toList(growable: false),
      'settings': settings,
    };
    archive.addFile(
      ArchiveFile.bytes('manifest.json', utf8.encode(jsonEncode(manifest))),
    );
    if (readAttachment != null) {
      for (final attachment in attachmentList) {
        final bytes = await readAttachment(attachment);
        archive.addFile(
          ArchiveFile.bytes('attachments/${attachment.sha256}', bytes),
        );
      }
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  ImportPackage importZip(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final manifestFile = archive.findFile('manifest.json');
    if (manifestFile == null) {
      throw const FormatException('manifest.json missing');
    }
    final decoded = jsonDecode(utf8.decode(manifestFile.content as List<int>));
    if (decoded is! Map || decoded['format'] != 'diary-backup') {
      throw const FormatException('unsupported diary backup');
    }
    final entries = (decoded['entries'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => DiaryEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
    final attachments = (decoded['attachments'] as List? ?? const [])
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          return Attachment(
            assetId: '${map['assetId'] ?? map['sha256']}',
            sha256: '${map['sha256']}',
            kind: AttachmentKind.values.firstWhere(
              (kind) => kind.name == map['kind'],
              orElse: () => AttachmentKind.file,
            ),
            mimeType: '${map['mimeType'] ?? 'application/octet-stream'}',
            byteSize: (map['byteSize'] as num?)?.toInt() ?? 0,
            originalName: '${map['originalName'] ?? map['sha256']}',
            createdAt:
                DateTime.tryParse('${map['createdAt']}') ?? DateTime.now(),
          );
        })
        .toList(growable: false);
    final attachmentBytes = <String, Uint8List>{};
    for (final attachment in attachments) {
      final hash = attachment.sha256.toLowerCase();
      if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
        throw const FormatException('invalid attachment hash');
      }
      final file = archive.findFile('attachments/$hash');
      if (file == null) {
        throw const FormatException('attachment missing');
      }
      final content = Uint8List.fromList(file.content as List<int>);
      if (content.length > 128 * 1024 * 1024 ||
          content.length != attachment.byteSize ||
          crypto.sha256.convert(content).toString() != hash) {
        throw const FormatException('attachment verification failed');
      }
      attachmentBytes[hash] = content;
    }
    return ImportPackage(
      entries: entries,
      attachments: attachments,
      attachmentBytes: attachmentBytes,
      settings: Map<String, dynamic>.from(
        decoded['settings'] as Map? ?? const {},
      ),
    );
  }
}
