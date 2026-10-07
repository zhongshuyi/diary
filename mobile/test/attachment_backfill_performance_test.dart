import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

import 'package:diary/data/mobile_attachment_store.dart';
import 'package:diary/domain/attachment.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/outbox_mutation.dart';
import 'package:diary/sync/attachment_transfer.dart';
import 'package:diary/sync/sync_client.dart';

class _CountingStore extends MobileAttachmentStore {
  _CountingStore(Directory root) : super(rootDirectory: root);

  int importCalls = 0;

  @override
  Future<Attachment> importFile(
    String sourcePath, {
    AttachmentKind? kind,
    String? mimeType,
  }) {
    importCalls++;
    return super.importFile(sourcePath, kind: kind, mimeType: mimeType);
  }
}

DiaryEntry _entry({
  List<String> images = const [],
  List<String> attachmentIds = const [],
  String content = '',
  DiaryEditorType editorType = DiaryEditorType.plainText,
}) => DiaryEntry(
  id: 'synthetic-entry',
  createdAt: DateTime(2026, 10, 7),
  updatedAt: DateTime(2026, 10, 7),
  title: 'synthetic attachment',
  content: content,
  contentText: '',
  category: 'test',
  editorType: editorType,
  imagePaths: images,
  attachmentIds: attachmentIds,
);

void main() {
  late Directory sandbox;
  late _CountingStore store;
  late AttachmentTransfer transfer;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('diary-backfill-test-');
    store = _CountingStore(Directory(p.join(sandbox.path, 'attachments')));
    final client = MockClient((_) async => http.Response('', 200));
    addTearDown(client.close);
    transfer = AttachmentTransfer(
      client: SyncClient(baseUrl: 'http://localhost', client: client),
      store: store,
    );
  });

  tearDown(() async => sandbox.delete(recursive: true));

  Future<File> source(String name, List<int> bytes) async {
    final file = File(p.join(sandbox.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  test(
    'a second backfill does not import unchanged known local files',
    () async {
      final photo = await source('photo.png', const [1, 2, 3, 4]);
      final saved = <DiaryEntry>[];
      await transfer.backfillEntries([
        _entry(images: [photo.path]),
      ], (entry) async => saved.add(entry));
      expect(store.importCalls, 1);
      expect(saved.single.attachmentIds, [
        'asset-${crypto.sha256.convert(const [1, 2, 3, 4])}',
      ]);

      final completed = saved.single;
      saved.clear();
      store.importCalls = 0;
      await transfer.backfillEntries([
        completed,
      ], (entry) async => saved.add(entry));

      expect(store.importCalls, 0);
      expect(saved, isEmpty);
    },
  );

  test('nonempty IDs do not skip new or previously unknown paths', () async {
    final first = await source('first.png', const [1, 2]);
    final second = await source('second.png', const [3, 4]);
    final saved = <DiaryEntry>[];
    await transfer.backfillEntries([
      _entry(images: [first.path], attachmentIds: const ['legacy-id']),
    ], (entry) async => saved.add(entry));
    expect(store.importCalls, 1);
    final completed = saved.single;

    saved.clear();
    store.importCalls = 0;
    await transfer.backfillEntries([
      completed.copyWith(imagePaths: [first.path, second.path]),
    ], (entry) async => saved.add(entry));

    expect(store.importCalls, 1);
    expect(saved.single.attachmentIds, [
      ...completed.attachmentIds,
      'asset-${crypto.sha256.convert(const [3, 4])}',
    ]);
  });

  test(
    'known paths still repair missing attachment IDs without reimport',
    () async {
      final photo = await source('photo.png', const [1, 2, 3, 4]);
      final saved = <DiaryEntry>[];
      await transfer.backfillEntries([
        _entry(images: [photo.path]),
      ], (entry) async => saved.add(entry));
      final completed = saved.single;
      saved.clear();
      store.importCalls = 0;

      await transfer.backfillEntries([
        completed.copyWith(attachmentIds: const []),
      ], (entry) async => saved.add(entry));

      expect(store.importCalls, 0);
      expect(saved.single.attachmentIds, completed.attachmentIds);
    },
  );

  test('changed source contents invalidate the remembered import', () async {
    final photo = await source('photo.png', const [1, 2]);
    final saved = <DiaryEntry>[];
    await transfer.backfillEntries([
      _entry(images: [photo.path]),
    ], (entry) async => saved.add(entry));
    final completed = saved.single;
    saved.clear();
    store.importCalls = 0;
    await photo.writeAsBytes(const [5, 6, 7], flush: true);

    await transfer.backfillEntries([
      completed,
    ], (entry) async => saved.add(entry));

    expect(store.importCalls, 1);
    expect(
      saved.single.attachmentIds,
      contains('asset-${crypto.sha256.convert(const [5, 6, 7])}'),
    );
  });

  test('a missing stored copy is recreated instead of skipped', () async {
    final photo = await source('photo.png', const [1, 2, 3, 4]);
    final saved = <DiaryEntry>[];
    await transfer.backfillEntries([
      _entry(images: [photo.path]),
    ], (entry) async => saved.add(entry));
    final completed = saved.single;
    final hash = crypto.sha256.convert(const [1, 2, 3, 4]).toString();
    final stored = File(p.join(store.rootDirectory!.path, '$hash.png'));
    await stored.delete();
    saved.clear();
    store.importCalls = 0;

    await transfer.backfillEntries([
      completed,
    ], (entry) async => saved.add(entry));

    expect(store.importCalls, 1);
    expect(await stored.readAsBytes(), const [1, 2, 3, 4]);
    expect(saved, isEmpty);
  });

  test(
    'a missing source invalidates the cache instead of concealing it',
    () async {
      final photo = await source('photo.png', const [1, 2, 3, 4]);
      await transfer.backfillEntries([
        _entry(images: [photo.path]),
      ], (_) async {});
      await photo.delete();

      await expectLater(
        transfer.backfillEntries([
          _entry(images: [photo.path]),
        ], (_) async {}),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test(
    'a changed stored copy is checked and repaired from its source',
    () async {
      final photo = await source('photo.png', const [1, 2, 3, 4]);
      final saved = <DiaryEntry>[];
      await transfer.backfillEntries([
        _entry(images: [photo.path]),
      ], (entry) async => saved.add(entry));
      final completed = saved.single;
      final hash = crypto.sha256.convert(const [1, 2, 3, 4]).toString();
      final stored = File(p.join(store.rootDirectory!.path, '$hash.png'));
      await stored.writeAsBytes(const [9, 8, 7, 6], flush: true);
      await stored.setLastModified(DateTime(2020));
      store.importCalls = 0;

      await transfer.backfillEntries([completed], (_) async {});

      expect(store.importCalls, 1);
      expect(await stored.readAsBytes(), const [1, 2, 3, 4]);
    },
  );

  test('changed kind and MIME requests keep the requested metadata', () async {
    final photo = await source('media.bin', const [1, 2, 3, 4]);
    await store.importFile(
      photo.path,
      kind: AttachmentKind.image,
      mimeType: 'image/png',
    );
    expect(
      await store.findUnchangedImport(
        photo.path,
        kind: AttachmentKind.image,
        mimeType: 'image/png',
      ),
      isNotNull,
    );
    expect(
      await store.findUnchangedImport(
        photo.path,
        kind: AttachmentKind.audio,
        mimeType: 'audio/mpeg',
      ),
      isNull,
    );
    final changed = await store.importFile(
      photo.path,
      kind: AttachmentKind.audio,
      mimeType: 'audio/mpeg',
    );
    final remembered = await store.findUnchangedImport(
      photo.path,
      kind: AttachmentKind.audio,
      mimeType: 'audio/mpeg',
    );

    expect(changed.kind, AttachmentKind.audio);
    expect(changed.mimeType, 'audio/mpeg');
    expect(remembered, same(changed));
  });

  test('download validation also rejects a corrupted existing copy', () async {
    const bytes = [1, 2, 3, 4];
    final hash = crypto.sha256.convert(bytes).toString();
    final path = await store.storeDownloadedBytes(
      sha256: hash,
      extension: '.png',
      bytes: bytes,
    );
    expect(
      await store.storeDownloadedBytes(
        sha256: hash,
        extension: '.png',
        bytes: bytes,
      ),
      path,
    );
    await File(path).writeAsBytes(const [9, 8, 7, 6], flush: true);

    await expectLater(
      store.storeDownloadedBytes(sha256: hash, extension: '.png', bytes: bytes),
      throwsA(isA<FileSystemException>()),
    );
    expect(await File(path).readAsBytes(), const [9, 8, 7, 6]);
  });

  test(
    'remote rich text embeds remain references and require no local import',
    () async {
      final entry = _entry(
        editorType: DiaryEditorType.richText,
        content: jsonEncode([
          {
            'insert': {'image': 'https://example.com/image.png'},
          },
          {'insert': '\n'},
        ]),
      );
      final saved = <DiaryEntry>[];
      await transfer.backfillEntries([
        entry,
      ], (entry) async => saved.add(entry));

      expect(store.importCalls, 0);
      expect(saved, isEmpty);
    },
  );

  for (final wrapOperations in [false, true]) {
    test(
      'repairs embedded rich text images, wrapped ops: $wrapOperations',
      () async {
        final photo = await source('embedded.png', const [1, 2, 3, 4]);
        final operations = [
          {
            'insert': {'image': photo.path},
          },
          {'insert': '\n'},
        ];
        final entry = _entry(
          content: jsonEncode(
            wrapOperations ? {'ops': operations} : operations,
          ),
          editorType: DiaryEditorType.richText,
          attachmentIds: const ['unrelated-id'],
        );
        final saved = <DiaryEntry>[];
        await transfer.backfillEntries([
          entry,
        ], (entry) async => saved.add(entry));
        expect(store.importCalls, 1);
        expect(saved.single.attachmentIds, hasLength(2));
        store.importCalls = 0;
        await transfer.backfillEntries([saved.single], (_) async {});
        expect(store.importCalls, 0);

        final prepared = await transfer.prepareChanges([
          OutboxMutation(
            mutationId: 'synthetic-mutation',
            entityType: 'entry',
            entityId: entry.id,
            payload: {'entry': saved.single.toJson()},
            createdAt: DateTime(2026, 10, 7),
          ),
        ]);
        final wire = prepared.single['entry'] as Map;
        final decoded = jsonDecode(wire['content'] as String);
        final wireOperations = wrapOperations ? decoded['ops'] : decoded;
        final hash = crypto.sha256.convert(const [1, 2, 3, 4]);
        expect(wireOperations[0]['insert']['image'], 'asset://$hash.png');
        expect(store.importCalls, 0);
      },
    );
  }

  test(
    'SHA-256, asset identity, bytes and deduplication are preserved',
    () async {
      final photo = await source('photo.png', const [1, 2, 3, 4]);
      final duplicate = await source('duplicate.png', const [1, 2, 3, 4]);
      final first = await store.importFile(photo.path);
      final stored = File(first.localPath!);
      final modified = (await stored.stat()).modified;
      final second = await store.importFile(duplicate.path);

      expect(
        first.sha256,
        '9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a',
      );
      expect(first.assetId, 'asset-${first.sha256}');
      expect(first.byteSize, 4);
      expect(first.kind, AttachmentKind.image);
      expect(first.localPath, second.localPath);
      expect((await stored.stat()).modified, modified);
      expect(await stored.readAsBytes(), const [1, 2, 3, 4]);
    },
  );
}
