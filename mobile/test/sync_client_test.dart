import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:diary/domain/attachment.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/sync/sync_client.dart';
import 'package:diary/sync/sync_models.dart';

class FakeClient extends http.BaseClient {
  final requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    if (request.method == 'POST') {
      final body = request is http.Request
          ? jsonDecode(request.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final entry = DiaryEntry(
        id: 'remote-1',
        createdAt: DateTime(2026, 9, 16),
        updatedAt: DateTime(2026, 9, 16),
        title: '远端',
        content: '远端内容',
        contentText: '远端内容',
        category: '工作',
      );
      final requestChanges = body['changes'] is List
          ? (body['changes'] as List)
          : const [];
      final acknowledged = requestChanges
          .whereType<Map>()
          .map((item) => item['mutationId'])
          .whereType<String>()
          .toList();
      final response = jsonEncode({
        'data': {
          'nextCursor': '4',
          'changes': [
            {
              'sequence': 4,
              'mutationId': 'remote-mutation',
              'entry': entry.toJson(),
            },
          ],
          'conflicts': const [],
          'appliedMutationIds': acknowledged,
        },
      });
      return _streamed(response, 200, {'content-type': 'application/json'});
    }
    if (request.method == 'HEAD') return _streamed('', 200);
    if (request.method == 'GET')
      return _streamed('asset-bytes', 200, {'content-type': 'text/plain'});
    if (request.method == 'PUT') {
      return _streamed(
        jsonEncode({
          'data': {'sha256': 'a' * 64},
        }),
        201,
        {'content-type': 'application/json'},
      );
    }
    return _streamed('', 404);
  }

  http.StreamedResponse _streamed(
    String body,
    int status, [
    Map<String, String>? headers,
  ]) => http.StreamedResponse(
    Stream<List<int>>.value(utf8.encode(body)),
    status,
    headers: headers ?? const {},
  );
}

void main() {
  test('serializes v2 sync and parses remote changes', () async {
    final fake = FakeClient();
    final client = SyncClient(
      baseUrl: 'http://localhost:8787/',
      token: 'secret',
      client: fake,
    );
    final response = await client.sync(
      SyncRequest(
        deviceId: 'mobile-1',
        cursor: '3',
        changes: const [
          {
            'mutationId': 'local-mutation',
            'entry': {'id': 'local-1'},
          },
        ],
      ),
    );

    expect(response.nextCursor, '4');
    expect(response.changes.single.id, 'remote-1');
    expect(response.acknowledgedMutationIds, contains('local-mutation'));
    final request = fake.requests.single as http.Request;
    expect(request.headers['authorization'], 'Bearer secret');
    expect((jsonDecode(request.body) as Map)['protocolVersion'], 2);
  });

  test('supports asset head, upload and download', () async {
    final fake = FakeClient();
    final client = SyncClient(baseUrl: 'http://localhost:8787', client: fake);
    final attachment = Attachment(
      assetId: 'a1',
      sha256: 'a' * 64,
      byteSize: 11,
      mimeType: 'text/plain',
      kind: AttachmentKind.file,
      originalName: 'a.txt',
      localPath: 'a',
      createdAt: DateTime(2026, 9, 16),
    );
    expect(await client.headAsset(attachment.sha256), isTrue);
    await client.uploadAsset(
      attachment,
      Stream<List<int>>.value(utf8.encode('asset-bytes')),
    );
    expect(
      utf8.decode(await client.downloadAsset(attachment.sha256)),
      'asset-bytes',
    );
    expect(
      fake.requests.map((request) => request.method),
      containsAll(<String>['HEAD', 'PUT', 'GET']),
    );
  });
}
