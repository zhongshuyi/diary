import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:diary/data/speech_model_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporary;
  late HttpServer server;
  late SpeechModelStore store;
  final modelBytes = List<int>.generate(2048, (index) => index % 251);
  final tokenBytes = utf8.encode('<blank> 0\n你 1\n好 2\n');

  SpeechModelPackage fixturePackage({String? modelDigest}) =>
      SpeechModelPackage(
        modelUrl: 'http://127.0.0.1:${server.port}/model',
        tokensUrl: 'http://127.0.0.1:${server.port}/tokens',
        modelBytes: modelBytes.length,
        tokensBytes: tokenBytes.length,
        modelSha256: modelDigest ?? sha256.convert(modelBytes).toString(),
        tokensSha256: sha256.convert(tokenBytes).toString(),
      );

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp(
      'diary_speech_model_test_',
    );
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    store = SpeechModelStore(
      directoryProvider: () async => temporary,
      package: fixturePackage(),
    );
  });

  tearDown(() async {
    await store.dispose();
    await server.close(force: true);
    final target = p.normalize(temporary.absolute.path);
    if (!p.equals(
          p.dirname(target),
          p.normalize(Directory.systemTemp.absolute.path),
        ) ||
        !p.basename(target).startsWith('diary_speech_model_test_')) {
      throw StateError('Unexpected temporary speech model directory.');
    }
    await temporary.delete(recursive: true);
  });

  void serve(Future<void> Function(HttpRequest) handler) {
    server.listen((request) async {
      try {
        await handler(request);
      } on SocketException {
        // Expected for cancellation fixtures.
      } on HttpException {
        // Expected for cancellation fixtures.
      }
    });
  }

  void servePackage({void Function()? onRequest}) {
    serve((request) async {
      onRequest?.call();
      final bytes = request.uri.path == '/model' ? modelBytes : tokenBytes;
      request.response.contentLength = bytes.length;
      request.response.add(bytes);
      await request.response.close();
    });
  }

  test(
    'reading absent model/settings stays offline and creates no files',
    () async {
      var requests = 0;
      servePackage(onRequest: () => requests++);
      expect(await store.installed(), isNull);
      expect(await store.readAutoTranscribe(), false);
      expect(requests, 0);
      expect(await temporary.list().toList(), isEmpty);
    },
  );

  test(
    'explicit download verifies pair and atomically installs with attribution',
    () async {
      servePackage();
      final progress = <double>[];
      final result = await store.download(onProgress: progress.add);
      expect(await File(result.modelPath).readAsBytes(), modelBytes);
      expect(await File(result.tokensPath).readAsBytes(), tokenBytes);
      expect((await store.installed())?.modelPath, result.modelPath);
      expect(progress.first, 0);
      expect(progress.last, 1);
      expect(progress, everyElement(inInclusiveRange(0, 1)));
      for (var index = 1; index < progress.length; index++) {
        expect(progress[index], greaterThanOrEqualTo(progress[index - 1]));
      }
      final directory = Directory(p.dirname(result.modelPath));
      expect(
        await File(p.join(directory.path, 'MODEL_LICENSE.txt')).readAsString(),
        allOf(
          contains('SenseVoice'),
          contains('Alibaba'),
          contains('FunASR Model Open Source License Agreement'),
          contains('Version: 1.1'),
          contains('模型开源协议'),
        ),
      );
      expect(
        await Directory(
          p.join(temporary.path, 'speech-models'),
        ).list().where((entry) => entry.path.contains('install-')).toList(),
        isEmpty,
      );
    },
  );

  test('valid installed model avoids any second download', () async {
    var requests = 0;
    servePackage(onRequest: () => requests++);
    final first = await store.download();
    expect(requests, 2);
    final second = await store.download();
    expect(second.modelPath, first.modelPath);
    expect(requests, 2);
  });

  test(
    'checksum mismatch removes staging and never marks model installed',
    () async {
      await store.dispose();
      store = SpeechModelStore(
        directoryProvider: () async => temporary,
        package: fixturePackage(modelDigest: List.filled(64, '0').join()),
      );
      servePackage();
      await expectLater(
        store.download(),
        throwsA(
          isA<SpeechModelException>().having(
            (e) => e.message,
            'message',
            contains('校验失败'),
          ),
        ),
      );
      expect(await store.installed(), isNull);
      expect(
        await Directory(
          p.join(temporary.path, 'speech-models'),
        ).list().toList(),
        isEmpty,
      );
    },
  );

  test('wrong content length aborts before installation', () async {
    serve((request) async {
      request.response.add([1, 2]);
      await request.response.close();
    });
    await expectLater(store.download(), throwsA(isA<SpeechModelException>()));
    expect(await store.installed(), isNull);
  });

  test('oversized chunked body is stopped at pinned size', () async {
    serve((request) async {
      request.response.headers.chunkedTransferEncoding = true;
      request.response.add(List.filled(modelBytes.length + 100, 1));
      await request.response.close();
    });
    await expectLater(
      store.download(),
      throwsA(
        isA<SpeechModelException>().having(
          (e) => e.message,
          'message',
          contains('大小不匹配'),
        ),
      ),
    );
    expect(await store.installed(), isNull);
  });

  test(
    'cancel interrupts waiting headers and permits a later download',
    () async {
      final received = Completer<void>();
      final release = Completer<void>();
      var requests = 0;
      serve((request) async {
        requests++;
        if (requests == 1) {
          received.complete();
          await release.future;
        }
        final bytes = request.uri.path == '/model' ? modelBytes : tokenBytes;
        request.response.add(bytes);
        await request.response.close();
      });
      final pending = expectLater(
        store.download(),
        throwsA(isA<SpeechModelCancelled>()),
      );
      await received.future;
      await store.cancelDownload().timeout(const Duration(seconds: 2));
      await pending;
      expect(await store.installed(), isNull);
      release.complete();
      expect(await store.download(), isA<SpeechModelFiles>());
    },
  );

  test('idle download timeout is safe and removes partial install', () async {
    await store.dispose();
    store = SpeechModelStore(
      directoryProvider: () async => temporary,
      package: fixturePackage(),
      idleTimeout: const Duration(milliseconds: 100),
    );
    serve((request) async {
      request.response.headers.chunkedTransferEncoding = true;
      request.response.add([1]);
      await request.response.flush();
    });
    await expectLater(store.download(), throwsA(isA<SpeechModelException>()));
    expect(await store.installed(), isNull);
  });

  test('HTTP error body does not leak into the UI exception', () async {
    serve((request) async {
      request.response.statusCode = 500;
      request.response.write('private server secret');
      await request.response.close();
    });
    await expectLater(
      store.download(),
      throwsA(
        isA<SpeechModelException>().having(
          (e) => e.message,
          'message',
          isNot(contains('private server secret')),
        ),
      ),
    );
  });

  test('auto setting persists locally with ordered atomic writes', () async {
    await Future.wait([
      store.writeAutoTranscribe(true),
      store.writeAutoTranscribe(false),
      store.writeAutoTranscribe(true),
    ]);
    expect(await store.readAutoTranscribe(), true);
    final restored = SpeechModelStore(
      directoryProvider: () async => temporary,
      package: fixturePackage(),
    );
    expect(await restored.readAutoTranscribe(), true);
    await restored.dispose();
    expect(
      await File(
        p.join(temporary.path, 'speech-models', 'settings.json.part'),
      ).exists(),
      false,
    );
  });

  test(
    'remove deletes model and disables auto without touching recordings',
    () async {
      final originalAudio = File(
        p.join(temporary.path, 'original-recording.m4a'),
      );
      await originalAudio.writeAsBytes([10, 20, 30]);
      servePackage();
      await store.download();
      await store.writeAutoTranscribe(true);
      await store.remove();
      expect(await store.installed(), isNull);
      expect(await store.readAutoTranscribe(), false);
      expect(await originalAudio.readAsBytes(), [10, 20, 30]);
    },
  );

  test(
    'corrupted marker or changed file size is not an installed model',
    () async {
      servePackage();
      final result = await store.download();
      await File(result.tokensPath).writeAsString('corrupted');
      expect(await store.installed(), isNull);
    },
  );
}
