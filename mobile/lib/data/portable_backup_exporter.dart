import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../domain/attachment.dart';
import '../domain/diary_entry.dart';
import 'diary_backup_service.dart';
import 'mobile_attachment_store.dart';

/// Builds a self-contained ZIP from the records and their local media files.
class PortableBackupExporter {
  PortableBackupExporter({MobileAttachmentStore? attachmentStore})
    : _attachmentStore = attachmentStore ?? MobileAttachmentStore();

  final MobileAttachmentStore _attachmentStore;
  static const _backupService = DiaryBackupService();

  Future<Uint8List> export(List<DiaryEntry> entries) async {
    final byPath = <String, Attachment>{};
    final byHash = <String, Attachment>{};

    Future<String> collect(String path, AttachmentKind kind) async {
      if (path.startsWith('data:') ||
          path.startsWith('http:') ||
          path.startsWith('https:')) {
        return path;
      }
      final existing = byPath[path];
      if (existing != null) return 'attachments/${existing.sha256}';
      if (!await File(path).exists()) {
        throw const FileSystemException('日记附件已不存在，无法生成完整备份');
      }
      final attachment = await _attachmentStore.importFile(path, kind: kind);
      byPath[path] = attachment;
      byHash[attachment.sha256] = attachment;
      return 'attachments/${attachment.sha256}';
    }

    final portableEntries = <DiaryEntry>[];
    for (final entry in entries) {
      final entryAssetIds = <String>{...entry.attachmentIds};
      Future<String> collectForEntry(String path, AttachmentKind kind) async {
        final marker = await collect(path, kind);
        final attachment = byPath[path];
        if (attachment != null) entryAssetIds.add(attachment.assetId);
        return marker;
      }

      final images = <String>[];
      final audio = <String>[];
      final video = <String>[];
      for (final path in entry.imagePaths) {
        images.add(await collectForEntry(path, AttachmentKind.image));
      }
      for (final path in entry.audioPaths) {
        audio.add(await collectForEntry(path, AttachmentKind.audio));
      }
      for (final path in entry.videoPaths) {
        video.add(await collectForEntry(path, AttachmentKind.video));
      }

      var content = entry.content;
      if (entry.editorType == DiaryEditorType.richText) {
        final operations = jsonDecode(content);
        if (operations is! List) {
          throw const FormatException('invalid rich text');
        }
        for (final operation in operations) {
          if (operation is! Map || operation['insert'] is! Map) continue;
          final insert = operation['insert'] as Map;
          final image = insert['image'];
          if (image is String) {
            insert['image'] = await collectForEntry(
              image,
              AttachmentKind.image,
            );
          }
        }
        content = jsonEncode(operations);
      } else if (entry.editorType == DiaryEditorType.markdown) {
        for (final item in byPath.entries) {
          content = content.replaceAll(
            item.key,
            'attachments/${item.value.sha256}',
          );
        }
      }
      portableEntries.add(
        entry.copyWith(
          content: content,
          imagePaths: images,
          audioPaths: audio,
          videoPaths: video,
          attachmentIds: entryAssetIds.toList(growable: false),
        ),
      );
    }

    return _backupService.exportZipAsync(
      entries: portableEntries,
      attachments: byHash.values,
      readAttachment: (attachment) => _attachmentStore.readBytes(attachment),
    );
  }
}
