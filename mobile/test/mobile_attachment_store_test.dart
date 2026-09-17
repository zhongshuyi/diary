import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:diary/data/mobile_attachment_store.dart';
import 'package:diary/domain/attachment.dart';

void main() {
  test(
    'imports a picked image into stable storage with an image extension',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'diary-photo-test-',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final source = File(p.join(sandbox.path, 'picked.jpg'));
      await source.writeAsBytes([0xff, 0xd8, 0xff, 0xd9]);
      final store = MobileAttachmentStore(
        rootDirectory: Directory(p.join(sandbox.path, 'app-attachments')),
      );

      final imported = await store.importFile(source.path);
      await source.delete();

      expect(imported.kind, AttachmentKind.image);
      expect(imported.localPath, endsWith('.jpg'));
      expect(await File(imported.localPath!).readAsBytes(), [
        0xff,
        0xd8,
        0xff,
        0xd9,
      ]);
      expect(
        (await store.importFile(imported.localPath!)).sha256,
        imported.sha256,
      );
    },
  );
}
