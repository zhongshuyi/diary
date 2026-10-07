import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:diary/data/local_assistant_store.dart';
import 'package:diary/data/local_model_store.dart';
import 'package:diary/domain/local_assistant_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporary;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('diary_local_assistant_');
  });
  tearDown(() async {
    await temporary.delete(recursive: true);
  });

  test(
    'legacy conversations migrate to replies without retaining user diary text',
    () async {
      final file = File(p.join(temporary.path, 'conversation.json'));
      await file.writeAsString(
        jsonEncode({
          'version': 1,
          'messages': [
            LocalAssistantMessage(
              id: 'user',
              role: LocalAssistantRole.user,
              text: '不应该重复保存的日记正文',
              createdAt: DateTime.utc(2026),
            ).toJson(),
            LocalAssistantMessage(
              id: 'entry',
              role: LocalAssistantRole.assistant,
              text: '愿你今晚休息得好一些。',
              createdAt: DateTime.utc(2026),
            ).toJson(),
          ],
        }),
      );
      final store = LocalAssistantStore(rootDirectory: temporary);
      final replies = await store.load();
      expect(replies.single.id, 'entry');
      expect(await file.readAsString(), isNot(contains('不应该重复保存的日记正文')));
      await store.save([
        LocalAssistantMessage(
          id: 'temporary',
          role: LocalAssistantRole.user,
          text: '临时推理输入也不能落盘',
          createdAt: DateTime.utc(2026),
        ),
        ...replies,
      ]);
      expect(await file.readAsString(), isNot(contains('临时推理输入也不能落盘')));
    },
  );

  test(
    'version one model preferences without style fields retain safe defaults',
    () async {
      final file = File(p.join(temporary.path, 'model-settings.json'));
      await file.writeAsString(
        jsonEncode({'version': 1, 'enabled': true, 'path': null, 'name': null}),
      );
      final store = LocalModelStore(rootDirectory: temporary);
      final oldSettings = await store.readSettings();
      expect(oldSettings.tone, LocalAssistantTone.gentle);
      expect(oldSettings.persona, defaultLocalAssistantPersona);
      await store.writeSettings(
        const LocalModelSettings(
          enabled: true,
          tone: LocalAssistantTone.cheerful,
          persona: '像开朗的朋友一样理解我的心情',
        ),
      );
      final newSettings = await store.readSettings();
      expect(newSettings.tone, LocalAssistantTone.cheerful);
      expect(newSettings.persona, '像开朗的朋友一样理解我的心情');
      expect((jsonDecode(await file.readAsString()) as Map)['version'], 1);
    },
  );

  test(
    'serial conversation writes retain the newest 100 messages with roles',
    () async {
      final store = LocalAssistantStore(rootDirectory: temporary);
      final messages = List.generate(
        110,
        (i) => LocalAssistantMessage(
          id: 'message-$i',
          role: LocalAssistantRole.assistant,
          text: '文字 $i',
          createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
        ),
      );
      final older = store.save(messages.sublist(0, 20));
      final newer = store.save(messages);
      await Future.wait([older, newer]);
      final loaded = await store.load();
      expect(loaded, hasLength(100));
      expect(loaded.first.id, 'message-10');
      expect(loaded.last.id, 'message-109');
      expect(loaded.last.role, LocalAssistantRole.assistant);
      expect(loaded.last.createdAt, messages.last.createdAt);
      expect(
        await File(p.join(temporary.path, 'conversation.json.part')).exists(),
        isFalse,
      );
      await store.save([]);
      expect(await store.load(), isEmpty);
    },
  );

  test(
    'corrupt conversation records are rejected without silently replacing them',
    () async {
      final file = File(p.join(temporary.path, 'conversation.json'));
      final source = jsonEncode({
        'version': 1,
        'messages': [
          {
            'id': 'one',
            'role': 'system',
            'text': 'bad',
            'createdAt': '2026-01-01',
          },
        ],
      });
      await file.writeAsString(source);
      final store = LocalAssistantStore(rootDirectory: temporary);
      await expectLater(store.load(), throwsFormatException);
      expect(await file.readAsString(), source);
    },
  );

  test(
    'model import copies privately and settings are independent of conversation',
    () async {
      final source = File(p.join(temporary.path, 'source.gguf'));
      final bytes = _modelFixture();
      await source.writeAsBytes(bytes);
      final root = Directory(p.join(temporary.path, 'private'));
      final models = LocalModelStore(rootDirectory: root);
      final installed = await models.importModel(
        source.path,
        operation: LocalModelOperation(),
      );
      expect(p.isWithin(p.join(root.path, 'models'), installed.path), isTrue);
      expect(await File(installed.path).readAsBytes(), bytes);
      expect(await source.exists(), isTrue);
      await models.writeSettings(
        LocalModelSettings(
          enabled: true,
          path: installed.path,
          name: installed.name,
        ),
      );
      // Windows replacement also has to work without deleting the old preferences.
      await models.writeSettings(
        LocalModelSettings(
          enabled: false,
          path: installed.path,
          name: installed.name,
        ),
      );
      final settings = await models.readSettings();
      expect(settings.enabled, isFalse);
      expect(settings.path, installed.path);
      expect(await models.exists(installed.path), isTrue);
      expect(await LocalAssistantStore(rootDirectory: root).load(), isEmpty);
      await models.removeModel(installed.path);
      expect(await models.exists(installed.path), isFalse);
      expect(await source.exists(), isTrue);
    },
  );

  test(
    'failed and cancelled imports remove temporary files and retain earlier models',
    () async {
      final root = Directory(p.join(temporary.path, 'private'));
      final models = LocalModelStore(rootDirectory: root);
      final source = File(p.join(temporary.path, 'source.gguf'));
      await source.writeAsBytes(_modelFixture());
      final previous = await models.importModel(
        source.path,
        operation: LocalModelOperation(),
      );
      await source.writeAsBytes(Uint8List(128));
      await expectLater(
        models.importModel(source.path, operation: LocalModelOperation()),
        throwsFormatException,
      );
      await source.writeAsBytes(_modelFixture());
      final cancellation = LocalModelOperation();
      await expectLater(
        models.importModel(
          source.path,
          operation: cancellation,
          onProgress: (_) => cancellation.cancel(),
        ),
        throwsA(isA<LocalModelCancelled>()),
      );
      final files = await Directory(
        p.join(root.path, 'models'),
      ).list().toList();
      expect(files.map((file) => file.path), [previous.path]);
      expect(await File(previous.path).exists(), isTrue);
    },
  );

  test(
    'metadata cannot point outside the model directory and removal cannot delete a source',
    () async {
      final root = Directory(p.join(temporary.path, 'private'));
      final models = LocalModelStore(rootDirectory: root);
      final source = File(p.join(temporary.path, 'external.gguf'));
      await source.writeAsBytes(_modelFixture());
      await models.writeSettings(
        LocalModelSettings(enabled: true, path: source.path, name: 'external'),
      );
      await expectLater(models.readSettings(), throwsFormatException);
      await expectLater(
        models.removeModel(source.path),
        throwsA(isA<FileSystemException>()),
      );
      expect(await source.exists(), isTrue);
    },
  );

  test(
    'recommended download verifies SHA before committing and cleans mismatches',
    () async {
      final bytes = _modelFixture();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        await request.response.close();
      });
      try {
        final uri = Uri.parse('http://127.0.0.1:${server.port}/model.gguf');
        final root = Directory(p.join(temporary.path, 'private'));
        final models = LocalModelStore(
          rootDirectory: root,
          recommendedModelUri: uri,
          recommendedSha256: sha256.convert(bytes).toString(),
        );
        final progress = <double?>[];
        final stages = <LocalModelInstallProgress>[];
        final installed = await models.downloadRecommendedModel(
          operation: LocalModelOperation(),
          onProgress: progress.add,
          onInstallProgress: stages.add,
        );
        expect(progress.first, 0);
        expect(progress.last, 1);
        expect(await File(installed.path).readAsBytes(), bytes);
        expect(installed.sizeBytes, bytes.length);
        expect(installed.isRecommended, isTrue);
        expect(stages.first.stage, LocalModelInstallStage.connecting);
        expect(
          stages.any(
            (event) =>
                event.stage == LocalModelInstallStage.downloading &&
                event.receivedBytes == bytes.length,
          ),
          isTrue,
        );
        expect(stages.last.stage, LocalModelInstallStage.verifying);
        expect(stages.last.fraction, isNull);
        final invalid = LocalModelStore(
          rootDirectory: root,
          recommendedModelUri: uri,
          recommendedSha256: '0' * 64,
        );
        await expectLater(
          invalid.downloadRecommendedModel(operation: LocalModelOperation()),
          throwsFormatException,
        );
        final files = await Directory(
          p.join(root.path, 'models'),
        ).list().toList();
        expect(files.map((file) => file.path), [installed.path]);
      } finally {
        await server.close(force: true);
      }
    },
  );

  test('imports reject an oversized model before copying', () async {
    final source = File(p.join(temporary.path, 'oversized.gguf'));
    final handle = await source.open(mode: FileMode.write);
    await handle.truncate(LocalModelStore.maxModelBytes + 1);
    await handle.close();
    final root = Directory(p.join(temporary.path, 'private'));
    final models = LocalModelStore(rootDirectory: root);
    await expectLater(
      models.importModel(source.path, operation: LocalModelOperation()),
      throwsFormatException,
    );
    expect(await root.exists(), isFalse);
  });

  test(
    'legacy selected file and original import name migrate to the catalog without validating by name',
    () async {
      final source = File(p.join(temporary.path, 'source.gguf'));
      await source.writeAsBytes(_modelFixture());
      final root = Directory(p.join(temporary.path, 'private'));
      final store = LocalModelStore(rootDirectory: root);
      final installed = await store.importModel(
        source.path,
        operation: LocalModelOperation(),
      );
      await store.writeSettings(
        LocalModelSettings(
          enabled: true,
          path: installed.path,
          name: 'diary-Qwen3-0.6B-Q4_0.gguf',
        ),
      );
      await File(p.join(root.path, 'model-catalog.json')).delete();
      // Migration only checks presence/size. A familiar file name is never used
      // as proof that corrupted contents are safe to pass to the native engine.
      await File(installed.path).writeAsBytes(Uint8List(24));
      final library = await store.listInstalledModels();
      expect(library.single.name, 'diary-Qwen3-0.6B-Q4_0.gguf');
      expect(library.single.path, installed.path);
      expect(library.single.sizeBytes, 24);
      expect(library.single.isRecommended, isFalse);
      expect(library.single.modelId, localLightweightModel.id);
      expect(localLightweightModel.matches(library.single), isTrue);
      expect(localQualityModel.matches(library.single), isFalse);
      await expectLater(
        store.validateModel(installed.path),
        throwsFormatException,
      );
      final stored =
          jsonDecode(
                await File(
                  p.join(root.path, 'model-catalog.json'),
                ).readAsString(),
              )
              as Map;
      expect(stored['version'], 1);
      expect(stored['models'], hasLength(1));
    },
  );

  test(
    'concurrent imports serialize catalog updates and inactive removal retains the other file',
    () async {
      final source = File(p.join(temporary.path, 'source.gguf'));
      await source.writeAsBytes(_modelFixture());
      final root = Directory(p.join(temporary.path, 'private'));
      final store = LocalModelStore(rootDirectory: root);
      final imported = await Future.wait([
        store.importModel(source.path, operation: LocalModelOperation()),
        store.importModel(source.path, operation: LocalModelOperation()),
      ]);
      final library = await store.listInstalledModels();
      expect(
        library.map((model) => model.path).toSet(),
        imported.map((model) => model.path).toSet(),
      );
      expect(library, hasLength(2));
      await store.removeModel(imported.first.path);
      final retained = await store.listInstalledModels();
      expect(retained.single.path, imported.last.path);
      expect(await File(imported.last.path).exists(), isTrue);
      expect(await source.exists(), isTrue);
      expect(
        await File(p.join(root.path, 'model-catalog.json.part')).exists(),
        isFalse,
      );
    },
  );

  test(
    'import progress exposes bytes and an indeterminate verification stage',
    () async {
      final bytes = _modelFixture();
      final source = File(p.join(temporary.path, 'chosen.gguf'));
      await source.writeAsBytes(bytes);
      final stages = <LocalModelInstallProgress>[];
      final store = LocalModelStore(
        rootDirectory: Directory(p.join(temporary.path, 'private')),
      );
      final installed = await store.importModel(
        source.path,
        operation: LocalModelOperation(),
        onInstallProgress: stages.add,
      );
      expect(stages.first.stage, LocalModelInstallStage.importing);
      expect(stages.first.receivedBytes, 0);
      expect(stages.first.totalBytes, bytes.length);
      expect(stages.any((progress) => progress.fraction == 1), isTrue);
      expect(stages.last.stage, LocalModelInstallStage.verifying);
      expect(stages.last.fraction, isNull);
      expect(installed.sizeBytes, bytes.length);
      expect(installed.name, 'chosen.gguf');
      expect(installed.isRecommended, isFalse);
    },
  );

  test(
    'download choices pin independent manifests within the supported size bound',
    () {
      expect(
        localRecommendedModels.map((model) => model.id).toSet(),
        hasLength(3),
      );
      expect(localRecommendedModels.first, localQualityModel);
      expect(localQualityModel.isRecommended, isTrue);
      expect(localLightweightModel.isRecommended, isFalse);
      expect(localQualityModel, localInstructModel);
      expect(localQualityModel.sizeBytes, 2497280736);
      expect(localBalancedModel.sizeBytes, 1282439264);
      expect(localBalancedModel.isRecommended, isFalse);
      expect(localInstructModel.sizeBytes, 2497280736);
      expect(localInstructModel.isRecommended, isTrue);
      expect(LocalModelStore.recommendedModelName, localQualityModel.name);
      expect(LocalModelStore.recommendedModelUrl, localQualityModel.url);
      expect(LocalModelStore.recommendedModelSha256, localQualityModel.sha256);
      expect(
        localBalancedModel.matches(
          const InstalledLocalModel(
            path: 'old.gguf',
            name: 'Qwen3-1.7B · 质量优先',
          ),
        ),
        isTrue,
      );
      expect(localLightweightModel.sizeBytes, 428970080);
      expect(LocalModelStore.maxModelBytes, 3 * 1024 * 1024 * 1024);
      for (final model in localRecommendedModels) {
        expect(model.sizeBytes, lessThan(LocalModelStore.maxModelBytes));
        expect(model.sha256, matches(RegExp(r'^[a-f0-9]{64}$')));
        expect(Uri.parse(model.url).host, 'huggingface.co');
      }
    },
  );

  test(
    'version one catalogs without model ids still distinguish lightweight from quality',
    () async {
      final root = Directory(p.join(temporary.path, 'private'));
      final modelsDirectory = Directory(p.join(root.path, 'models'));
      await modelsDirectory.create(recursive: true);
      final model = File(p.join(modelsDirectory.path, 'old.gguf'));
      await model.writeAsBytes(_modelFixture());
      await File(p.join(root.path, 'model-catalog.json')).writeAsString(
        jsonEncode({
          'version': 1,
          'models': [
            {
              'path': model.path,
              'name': 'Qwen3-0.6B · Q4_0',
              'sizeBytes': 400,
              'isRecommended': true,
            },
          ],
        }),
      );
      final library = await LocalModelStore(
        rootDirectory: root,
      ).listInstalledModels();

      expect(library.single.modelId, localLightweightModel.id);
      expect(localLightweightModel.matches(library.single), isTrue);
      expect(localQualityModel.matches(library.single), isFalse);
      expect(library.single.path, model.path);
    },
  );

  test(
    'all download descriptors persist identities and import uses digest rather than filename',
    () async {
      final qualityBytes = _modelFixture();
      final lightBytes = _modelFixture()..[qualityBytes.length - 1] = 1;
      final instructBytes = _modelFixture()..[qualityBytes.length - 1] = 3;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final bytes = request.uri.path.contains('quality')
            ? qualityBytes
            : request.uri.path.contains('instruct')
            ? instructBytes
            : lightBytes;
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        await request.response.close();
      });
      try {
        final quality = LocalModelDescriptor(
          id: localBalancedModel.id,
          name: localBalancedModel.name,
          description: '',
          url: 'http://127.0.0.1:${server.port}/quality.gguf',
          sha256: sha256.convert(qualityBytes).toString(),
          sizeBytes: qualityBytes.length,
        );
        final lightweight = LocalModelDescriptor(
          id: localLightweightModel.id,
          name: localLightweightModel.name,
          description: '',
          url: 'http://127.0.0.1:${server.port}/lightweight.gguf',
          sha256: sha256.convert(lightBytes).toString(),
          sizeBytes: lightBytes.length,
        );
        final instruct = LocalModelDescriptor(
          id: localInstructModel.id,
          name: localInstructModel.name,
          description: '',
          url: 'http://127.0.0.1:${server.port}/instruct.gguf',
          sha256: sha256.convert(instructBytes).toString(),
          sizeBytes: instructBytes.length,
          isRecommended: true,
        );
        final root = Directory(p.join(temporary.path, 'private'));
        final store = LocalModelStore(
          rootDirectory: root,
          recommendedModels: [instruct, quality, lightweight],
        );
        final installedQuality = await store.downloadRecommendedModel(
          model: quality,
          operation: LocalModelOperation(),
        );
        final installedLightweight = await store.downloadRecommendedModel(
          model: lightweight,
          operation: LocalModelOperation(),
        );
        final installedInstruct = await store.downloadRecommendedModel(
          model: instruct,
          operation: LocalModelOperation(),
        );
        expect(installedQuality.modelId, quality.id);
        expect(installedLightweight.modelId, lightweight.id);
        expect(installedInstruct.modelId, instruct.id);
        expect(installedQuality.isRecommended, isFalse);
        expect(installedInstruct.isRecommended, isTrue);
        expect(installedLightweight.isRecommended, isFalse);
        expect(await File(installedQuality.path).exists(), isTrue);
        expect(await File(installedLightweight.path).exists(), isTrue);

        final misleadingSource = File(
          p.join(temporary.path, 'Qwen3-1.7B-Q4_K_M.gguf'),
        );
        await misleadingSource.writeAsBytes(lightBytes);
        final importedLightweight = await store.importModel(
          misleadingSource.path,
          operation: LocalModelOperation(),
        );
        expect(importedLightweight.modelId, lightweight.id);
        expect(lightweight.matches(importedLightweight), isTrue);
        expect(quality.matches(importedLightweight), isFalse);
        final unknownBytes = _modelFixture()..[qualityBytes.length - 1] = 2;
        await misleadingSource.writeAsBytes(unknownBytes);
        final custom = await store.importModel(
          misleadingSource.path,
          operation: LocalModelOperation(),
        );
        expect(custom.modelId, 'custom');
        expect(localQualityModel.matches(custom), isFalse);
        expect(localLightweightModel.matches(custom), isFalse);
        final restored = await LocalModelStore(
          rootDirectory: root,
        ).listInstalledModels();
        expect(restored, hasLength(5));
        expect(restored.map((model) => model.modelId), [
          quality.id,
          lightweight.id,
          instruct.id,
          lightweight.id,
          'custom',
        ]);
      } finally {
        await server.close(force: true);
      }
    },
  );

  test(
    'descriptor size mismatch rejects a download while preserving the existing library',
    () async {
      final bytes = _modelFixture();
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        await request.response.close();
      });
      try {
        final source = File(p.join(temporary.path, 'old.gguf'));
        await source.writeAsBytes(bytes);
        final store = LocalModelStore(
          rootDirectory: Directory(p.join(temporary.path, 'private')),
        );
        final old = await store.importModel(
          source.path,
          operation: LocalModelOperation(),
        );
        final invalidSize = LocalModelDescriptor(
          id: 'fixture',
          name: 'fixture',
          description: '',
          url: 'http://127.0.0.1:${server.port}/model.gguf',
          sha256: sha256.convert(bytes).toString(),
          sizeBytes: bytes.length + 1,
        );
        await expectLater(
          store.downloadRecommendedModel(
            model: invalidSize,
            operation: LocalModelOperation(),
          ),
          throwsFormatException,
        );
        expect((await store.listInstalledModels()).single.path, old.path);
        expect(await File(old.path).exists(), isTrue);
      } finally {
        await server.close(force: true);
      }
    },
  );

  test(
    'old 1.7B catalog titles migrate as balanced rather than the new default',
    () async {
      final root = Directory(p.join(temporary.path, 'private'));
      final directory = Directory(p.join(root.path, 'models'));
      await directory.create(recursive: true);
      final file = File(p.join(directory.path, 'old.gguf'));
      await file.writeAsBytes(_modelFixture());
      await File(p.join(root.path, 'model-catalog.json')).writeAsString(
        jsonEncode({
          'version': 1,
          'models': [
            {
              'path': file.path,
              'name': 'Qwen3-1.7B · 质量优先',
              'sizeBytes': 400,
              'isRecommended': true,
            },
          ],
        }),
      );
      final library = await LocalModelStore(
        rootDirectory: root,
      ).listInstalledModels();
      expect(library.single.modelId, localBalancedModel.id);
      expect(library.single.isRecommended, isFalse);
      expect(localInstructModel.matches(library.single), isFalse);
      expect(localBalancedModel.matches(library.single), isTrue);
      expect(library.single.name, 'Qwen3-1.7B · 质量优先');
    },
  );
}

Uint8List _modelFixture() {
  final builder = BytesBuilder();
  void u32(int value) {
    builder.add(
      (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List(),
    );
  }

  void u64(int value) {
    builder.add(
      (ByteData(8)..setUint64(0, value, Endian.little)).buffer.asUint8List(),
    );
  }

  void text(String value) {
    final bytes = utf8.encode(value);
    u64(bytes.length);
    builder.add(bytes);
  }

  u32(0x46554747);
  u32(3);
  u64(1);
  u64(6);
  text('general.architecture');
  u32(8);
  text('qwen3');
  text('qwen3.block_count');
  u32(4);
  u32(28);
  text('qwen3.embedding_length');
  u32(4);
  u32(1024);
  text('qwen3.attention.head_count');
  u32(4);
  u32(16);
  text('qwen3.attention.head_count_kv');
  u32(4);
  u32(8);
  text('qwen3.feed_forward_length');
  u32(4);
  u32(2048);
  text('test.weight');
  u32(1);
  u64(32);
  u32(1);
  u64(0);
  builder.add(Uint8List((32 - builder.length % 32) % 32));
  builder.add(Uint8List(64));
  return builder.takeBytes();
}
