import 'dart:convert';

import 'package:path/path.dart' as p;

import '../domain/diary_entry.dart';
import 'diary_repository.dart';
import 'mobile_attachment_store.dart';

/// Restores ZIP media before any diary record is written.
class PortableBackupImporter {
  PortableBackupImporter({MobileAttachmentStore? attachmentStore})
    : _attachmentStore = attachmentStore ?? MobileAttachmentStore();

  final MobileAttachmentStore _attachmentStore;

  Future<List<DiaryEntry>> materialize(ImportPackage package) async {
    final paths = <String, String>{};
    for (final attachment in package.attachments) {
      final hash = attachment.sha256.toLowerCase();
      final bytes = package.attachmentBytes[hash];
      if (bytes == null) {
        throw const FormatException('attachment missing');
      }
      final extension = switch (attachment.mimeType.toLowerCase()) {
        'image/jpeg' => '.jpg',
        'image/png' => '.png',
        'image/webp' => '.webp',
        'image/gif' => '.gif',
        'audio/mpeg' => '.mp3',
        'audio/mp4' => '.m4a',
        'audio/wav' => '.wav',
        'video/mp4' => '.mp4',
        'video/quicktime' => '.mov',
        _ => p.extension(attachment.originalName),
      };
      paths['attachments/$hash'] = await _attachmentStore.storeDownloadedBytes(
        sha256: hash,
        extension: extension,
        bytes: bytes,
      );
    }

    String resolve(String path) {
      if (!path.startsWith('attachments/')) return path;
      final resolved = paths[path];
      if (resolved == null) {
        throw const FormatException('attachment missing');
      }
      return resolved;
    }

    return package.entries
        .map((entry) {
          var content = entry.content;
          if (entry.editorType == DiaryEditorType.richText) {
            final decoded = jsonDecode(content);
            if (decoded is! List) {
              throw const FormatException('invalid rich text');
            }
            for (final operation in decoded) {
              if (operation is! Map || operation['insert'] is! Map) {
                continue;
              }
              final insert = operation['insert'] as Map;
              if (insert['image'] is String) {
                insert['image'] = resolve(insert['image'] as String);
              }
            }
            content = jsonEncode(decoded);
          } else if (entry.editorType == DiaryEditorType.markdown) {
            for (final marker in paths.keys) {
              content = content.replaceAll(marker, paths[marker]!);
            }
          }
          return entry.copyWith(
            content: content,
            imagePaths: entry.imagePaths.map(resolve).toList(growable: false),
            audioPaths: entry.audioPaths.map(resolve).toList(growable: false),
            videoPaths: entry.videoPaths.map(resolve).toList(growable: false),
          );
        })
        .toList(growable: false);
  }
}
