import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/application/diary_controller.dart';
import 'package:diary/data/diary_backup_service.dart';
import 'package:diary/data/diary_repository.dart';
import 'package:diary/data/mobile_attachment_store.dart';
import 'package:diary/data/portable_backup_exporter.dart';
import 'package:diary/data/portable_backup_importer.dart';
import 'package:diary/domain/attachment.dart';
import 'package:diary/domain/diary_entry.dart';

DiaryEntry _entry() => DiaryEntry(
  id: 'backup-1',
  createdAt: DateTime(2026, 9, 16),
  updatedAt: DateTime(2026, 9, 16),
  title: '备份',
  content: '内容',
  contentText: '内容',
  category: '生活',
);

void main() {
  test('round trips entries through portable zip manifest', () {
    const service = DiaryBackupService();
    final bytes = service.exportZip(
      entries: [_entry()],
      settings: const {'theme': 'dark'},
    );
    final package = service.importZip(bytes);
    expect(package.entries.single.id, 'backup-1');
    expect(package.settings['theme'], 'dark');
    expect(bytes, isNotEmpty);
  });

  test(
    'restores ZIP images and merges without replacing existing entries',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'diary-backup-test-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final imageBytes = utf8.encode('small image fixture');
      final hash = crypto.sha256.convert(imageBytes).toString();
      final marker = 'attachments/$hash';
      final attachment = Attachment(
        assetId: 'asset-$hash',
        sha256: hash,
        kind: AttachmentKind.image,
        mimeType: 'image/jpeg',
        byteSize: imageBytes.length,
        originalName: 'photo.jpg',
        createdAt: DateTime(2026, 9, 16),
      );
      final entry = DiaryEntry(
        id: 'migrated',
        createdAt: DateTime(2026, 9, 16),
        updatedAt: DateTime(2026, 9, 16),
        title: '',
        content: jsonEncode([
          {
            'insert': {'image': marker},
          },
          {'insert': '\n'},
        ]),
        contentText: '',
        editorType: DiaryEditorType.richText,
        category: '生活',
        imagePaths: [marker],
        attachmentIds: ['asset-$hash'],
      );
      const service = DiaryBackupService();
      final zip = await service.exportZipAsync(
        entries: [entry],
        attachments: [attachment],
        readAttachment: (_) async => imageBytes,
      );
      final imported = service.importZip(zip);
      final materialized = await PortableBackupImporter(
        attachmentStore: MobileAttachmentStore(rootDirectory: directory),
      ).materialize(imported);
      final imagePath = materialized.single.imagePaths.single;
      expect(await File(imagePath).readAsBytes(), imageBytes);
      expect(
        jsonDecode(materialized.single.content)[0]['insert']['image'],
        imagePath,
      );

      final repository = MemoryDiaryRepository([_entry()]);
      final controller = DiaryController(repository: repository);
      expect(await controller.addMissingEntries(materialized), 1);
      expect(await controller.addMissingEntries(materialized), 0);
      expect(
        (await repository.load()).map((item) => item.id),
        containsAll(['backup-1', 'migrated']),
      );
    },
  );

  test(
    'full ZIP export includes local image bytes and portable paths',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'diary-full-backup-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final source = File('${directory.path}/photo.jpg');
      final imageBytes = utf8.encode('local image fixture');
      await source.writeAsBytes(imageBytes);
      final entry = DiaryEntry(
        id: 'with-photo',
        createdAt: DateTime(2026, 9, 16),
        updatedAt: DateTime(2026, 9, 16),
        title: '',
        content: jsonEncode([
          {
            'insert': {'image': source.path},
          },
          {'insert': '\n'},
        ]),
        contentText: '',
        editorType: DiaryEditorType.richText,
        category: '生活',
        imagePaths: [source.path],
      );
      final zip = await PortableBackupExporter(
        attachmentStore: MobileAttachmentStore(
          rootDirectory: Directory('${directory.path}/staged'),
        ),
      ).export([entry]);
      final imported = const DiaryBackupService().importZip(zip);
      expect(imported.entries, hasLength(1));
      expect(imported.attachments, hasLength(1));
      expect(imported.attachmentBytes.values.single, imageBytes);
      final marker = imported.entries.single.imagePaths.single;
      expect(marker, startsWith('attachments/'));
      expect(
        jsonDecode(imported.entries.single.content)[0]['insert']['image'],
        marker,
      );
      final restored = await PortableBackupImporter(
        attachmentStore: MobileAttachmentStore(
          rootDirectory: Directory('${directory.path}/restored'),
        ),
      ).materialize(imported);
      expect(
        await File(restored.single.imagePaths.single).readAsBytes(),
        imageBytes,
      );
    },
  );
}
