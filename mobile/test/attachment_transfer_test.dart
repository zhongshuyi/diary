import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:diary/data/mobile_attachment_store.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/outbox_mutation.dart';
import 'package:diary/sync/attachment_transfer.dart';
import 'package:diary/sync/sync_client.dart';

class _AssetClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method == 'HEAD') return _response('', 200);
    if (request.method == 'GET') return _response('asset-bytes', 200);
    return _response('', 201);
  }

  http.StreamedResponse _response(String body, int status) =>
      http.StreamedResponse(Stream<List<int>>.value(utf8.encode(body)), status);
}

void main() {
  test(
    'uploads local mobile media before replacing it with a portable asset reference',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'diary-transfer-test-',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final source = File(p.join(sandbox.path, 'photo.png'));
      await source.writeAsBytes(const [1, 2, 3, 4]);
      final transfer = AttachmentTransfer(
        client: SyncClient(
          baseUrl: 'http://localhost:8787',
          client: _AssetClient(),
        ),
        store: MobileAttachmentStore(
          rootDirectory: Directory(p.join(sandbox.path, 'attachments')),
        ),
      );
      final entry = DiaryEntry(
        id: 'entry-1',
        createdAt: DateTime(2026, 9, 18),
        updatedAt: DateTime(2026, 9, 18),
        title: '照片',
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

      final prepared = await transfer.prepareChanges([
        OutboxMutation(
          mutationId: 'mobile:entry-1:1',
          entityType: 'entry',
          entityId: entry.id,
          payload: {'mutationId': 'mobile:entry-1:1', 'entry': entry.toJson()},
          createdAt: DateTime(2026, 9, 18),
        ),
      ]);

      final sha256 = crypto.sha256.convert(const [1, 2, 3, 4]).toString();
      final wireEntry = Map<String, dynamic>.from(
        prepared.single['entry'] as Map,
      );
      expect(wireEntry['imagePaths'], ['asset://$sha256.png']);
      expect(
        jsonDecode(wireEntry['content'] as String)[0]['insert']['image'],
        'asset://$sha256.png',
      );
      expect(wireEntry['attachmentIds'], ['asset-$sha256']);
    },
  );

  test(
    'hydrates an incoming portable photo into stable local storage',
    () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'diary-transfer-download-test-',
      );
      addTearDown(() => sandbox.delete(recursive: true));
      final transfer = AttachmentTransfer(
        client: SyncClient(
          baseUrl: 'http://localhost:8787',
          client: _AssetClient(),
        ),
        store: MobileAttachmentStore(
          rootDirectory: Directory(p.join(sandbox.path, 'attachments')),
        ),
      );
      final sha256 = crypto.sha256
          .convert(utf8.encode('asset-bytes'))
          .toString();
      final entry = DiaryEntry(
        id: 'entry-2',
        createdAt: DateTime(2026, 9, 18),
        updatedAt: DateTime(2026, 9, 18),
        title: '来自桌面',
        content: jsonEncode([
          {
            'insert': {'image': 'asset://$sha256.jpg'},
          },
          {'insert': '\n'},
        ]),
        contentText: '',
        editorType: DiaryEditorType.richText,
        category: '生活',
        imagePaths: ['asset://$sha256.jpg'],
      );

      final hydrated = await transfer.hydrateEntry(entry);

      expect(hydrated.imagePaths.single, endsWith('.jpg'));
      expect(
        jsonDecode(hydrated.content)[0]['insert']['image'],
        hydrated.imagePaths.single,
      );
      expect(
        await File(hydrated.imagePaths.single).readAsString(),
        'asset-bytes',
      );
    },
  );
}
