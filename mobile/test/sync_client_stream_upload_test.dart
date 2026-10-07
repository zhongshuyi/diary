import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:diary/domain/attachment.dart';
import 'package:diary/sync/attachment_sync_queue.dart';
import 'package:diary/sync/sync_client.dart';
import 'package:diary/sync/sync_models.dart';

void main() {
  test(
    'upload emits the original first chunk before reading the rest',
    () async {
      final firstChunk = Uint8List.fromList([1, 2]);
      final secondChunk = Uint8List.fromList([3, 4]);
      final firstReceived = Completer<void>();
      final releaseSecondChunk = Completer<void>();
      var produced = 0;
      var responseDrained = false;
      Stream<List<int>> source() async* {
        produced++;
        yield firstChunk;
        await releaseSecondChunk.future;
        produced++;
        yield secondChunk;
      }

      Stream<List<int>> responseBody() async* {
        yield [1];
        responseDrained = true;
      }

      final transport = _StreamClient((request) async {
        expect(produced, 0);
        expect(request.method, 'PUT');
        expect(request.contentLength, 4);
        expect(request.headers['content-length'], '4');
        expect(request.headers['content-type'], 'video/mp4');
        expect(request.headers['authorization'], 'Bearer secret');
        expect(request.headers['x-asset-kind'], 'video');
        var consumed = 0;
        await for (final chunk in request.finalize()) {
          consumed++;
          if (consumed == 1) {
            expect(produced, 1);
            expect(chunk, same(firstChunk));
            firstReceived.complete();
          } else {
            expect(chunk, same(secondChunk));
          }
        }
        expect(consumed, 2);
        return http.StreamedResponse(responseBody(), 201);
      });
      final client = SyncClient(
        baseUrl: 'https://example.test',
        token: 'secret',
        client: transport,
      );
      addTearDown(client.close);

      final upload = client.uploadAsset(_attachment(), source());
      await firstReceived.future;
      expect(produced, 1);
      releaseSecondChunk.complete();
      await upload;
      expect(responseDrained, isTrue);
    },
  );

  for (final chunks in [
    [
      [1, 2],
      [3],
    ],
    [
      [1, 2],
      [3, 4, 5],
    ],
  ]) {
    final short = chunks.last.length == 1;
    test('rejects a ${short ? 'short' : 'long'} upload stream', () async {
      final transport = _StreamClient((request) async {
        await request.finalize().drain<void>();
        return http.StreamedResponse(const Stream.empty(), 201);
      });
      final client = SyncClient(
        baseUrl: 'https://example.test',
        client: transport,
      );
      addTearDown(client.close);

      await expectLater(
        client.uploadAsset(_attachment(), Stream.fromIterable(chunks)),
        throwsA(
          isA<SyncFailure>().having(
            (error) => error.code,
            'code',
            'asset_size_mismatch',
          ),
        ),
      );
    });
  }

  test(
    'failed HTTP upload drains its response and keeps the status code',
    () async {
      var responseDrained = false;
      Stream<List<int>> responseBody() async* {
        yield [1, 2];
        responseDrained = true;
      }

      final transport = _StreamClient((request) async {
        await request.finalize().drain<void>();
        return http.StreamedResponse(responseBody(), 503);
      });
      final client = SyncClient(
        baseUrl: 'https://example.test',
        client: transport,
      );
      addTearDown(client.close);

      await expectLater(
        client.uploadAsset(_attachment(), Stream.value([1, 2, 3, 4])),
        throwsA(
          isA<SyncFailure>()
              .having((error) => error.code, 'code', 'asset_upload_failed')
              .having((error) => error.statusCode, 'statusCode', 503),
        ),
      );
      expect(responseDrained, isTrue);
    },
  );

  for (final useStream in [false, true]) {
    test(
      'attachment queue uses ${useStream ? 'openRead without readBytes' : 'the existing readBytes fallback'}',
      () async {
        var reads = 0;
        var opens = 0;
        var uploads = 0;
        final transport = _StreamClient((request) async {
          if (request.method == 'HEAD') {
            return http.StreamedResponse(const Stream.empty(), 404);
          }
          expect(request.method, 'PUT');
          uploads++;
          expect(await request.finalize().toBytes(), [1, 2, 3, 4]);
          return http.StreamedResponse(const Stream.empty(), 201);
        });
        final client = SyncClient(
          baseUrl: 'https://example.test',
          client: transport,
        );
        addTearDown(client.close);

        final result = await AttachmentSyncQueue(client: client).uploadMissing(
          [_attachment()],
          (_) async {
            reads++;
            if (useStream) {
              throw StateError('stream upload must not read all bytes');
            }
            return [1, 2, 3, 4];
          },
          openRead: useStream
              ? (_) {
                  opens++;
                  return Stream.fromIterable([
                    [1, 2],
                    [3, 4],
                  ]);
                }
              : null,
        );

        expect(result.single.remoteState, AttachmentRemoteState.uploaded);
        expect(uploads, 1);
        expect(reads, useStream ? 0 : 1);
        expect(opens, useStream ? 1 : 0);
      },
    );
  }
}

Attachment _attachment() => Attachment(
  assetId: 'asset-video',
  sha256: 'a' * 64,
  byteSize: 4,
  mimeType: 'video/mp4',
  kind: AttachmentKind.video,
  originalName: 'video.mp4',
  createdAt: DateTime(2026, 10, 7),
);

class _StreamClient extends http.BaseClient {
  _StreamClient(this.onSend);

  final Future<http.StreamedResponse> Function(http.BaseRequest) onSend;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      onSend(request);
}
