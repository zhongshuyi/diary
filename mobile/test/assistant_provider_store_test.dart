import 'dart:convert';
import 'dart:io';

import 'package:diary/data/assistant_provider_store.dart';
import 'package:diary/domain/assistant_provider_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  const deepSeek = OnlineModelProvider.deepSeek;
  const compatible = OnlineModelProvider.compatible;

  group('API configuration', () {
    test('defaults retain local replies and do not enable image uploads', () {
      const settings = AssistantProviderSettings();
      expect(settings.source, AssistantReplySource.local);
      expect(settings.provider, deepSeek);
      final configuration = settings.configurationFor(deepSeek);
      expect(configuration.baseUrl, 'https://api.deepseek.com');
      expect(configuration.model, 'deepseek-flash');
      expect(configuration.sendImages, isFalse);
      expect(configuration.validate, returnsNormally);
      expect(settings.configurationFor(compatible).model, isEmpty);
    });

    test('both base URLs and complete endpoints normalize to one endpoint', () {
      for (final baseUrl in [
        'https://example.com/v1',
        'https://example.com/v1/',
        'https://example.com/v1/chat/completions',
        'https://example.com/v1/chat/completions/',
      ]) {
        final configuration = OnlineModelConfiguration(
          provider: compatible,
          baseUrl: baseUrl,
          model: 'custom-vision-model',
        );
        configuration.validate();
        expect(
          configuration.completionUri,
          Uri.parse('https://example.com/v1/chat/completions'),
        );
      }
    });

    test('rejects credentials, query strings, fragments and insecure URLs', () {
      for (final baseUrl in [
        'https://user:secret-token@example.com',
        'https://example.com?api_key=secret-token',
        'https://example.com#secret-token',
        'https://example.com?',
        'https://example.com#',
        'http://example.com/v1',
        'file:///tmp/secret-token',
        '/relative/path',
        'https://',
        'https://example.com:65536',
        ' https://example.com',
        'https://example.com\n',
      ]) {
        final configuration = OnlineModelConfiguration(
          provider: compatible,
          baseUrl: baseUrl,
          model: 'model',
        );
        expect(
          configuration.validate,
          throwsA(
            isA<FormatException>().having(
              (error) => error.toString(),
              'sanitized error',
              isNot(contains('secret-token')),
            ),
          ),
        );
      }
    });

    test('HTTP loopback requires the explicit test flag', () {
      for (final host in ['127.0.0.1', 'localhost', '[::1]']) {
        final configuration = OnlineModelConfiguration(
          provider: compatible,
          baseUrl: 'http://$host:8181/v1',
          model: 'model',
        );
        expect(configuration.validate, throwsFormatException);
        expect(
          () => configuration.validate(allowInsecureLoopback: true),
          returnsNormally,
        );
      }
      const remote = OnlineModelConfiguration(
        provider: compatible,
        baseUrl: 'http://example.com/v1',
        model: 'model',
      );
      expect(
        () => remote.validate(allowInsecureLoopback: true),
        throwsFormatException,
      );
    });

    test(
      'MiniMax has its own editable default configuration and credentials',
      () async {
        const settings = AssistantProviderSettings();
        final configuration = settings.configurationFor(
          OnlineModelProvider.miniMax,
        );
        expect(configuration.provider.label, 'MiniMax');
        expect(configuration.baseUrl, 'https://api.minimaxi.com/v1');
        expect(configuration.model, 'MiniMax-M3');
        configuration.validate();
        expect(configuration.sendImages, isFalse);
        final international = configuration.copyWith(
          baseUrl: 'https://api.minimax.io/v1',
          model: 'my-minimax-model',
        );
        international.validate();
        expect(
          international.completionUri.toString(),
          'https://api.minimax.io/v1/chat/completions',
        );
        expect(international.model, 'my-minimax-model');
      },
    );

    test('rejects empty or oversized configuration values', () {
      for (final model in ['', ' model ', 'model\n', 'a' * 201]) {
        expect(
          OnlineModelConfiguration(
            provider: compatible,
            baseUrl: 'https://example.com/v1',
            model: model,
          ).validate,
          throwsFormatException,
        );
      }
      expect(
        OnlineModelConfiguration(
          provider: compatible,
          baseUrl: 'https://example.com/${'a' * 2048}',
          model: 'model',
        ).validate,
        throwsFormatException,
      );
    });

    test('copyWith and JSON retain provider selection and explicit images', () {
      const configuration = OnlineModelConfiguration(
        provider: compatible,
        baseUrl: 'https://example.com/v1',
        model: 'original',
      );
      final changed = configuration.copyWith(
        model: 'vision-model',
        sendImages: true,
      );
      final settings = const AssistantProviderSettings().copyWith(
        source: AssistantReplySource.online,
        provider: compatible,
        configurations: {compatible: changed},
      );
      final restored = AssistantProviderSettings.fromJson(settings.toJson());
      expect(restored.source, AssistantReplySource.online);
      expect(restored.provider, compatible);
      expect(restored.configurationFor(compatible).model, 'vision-model');
      expect(restored.configurationFor(compatible).sendImages, isTrue);
      expect(restored.configurationFor(deepSeek).sendImages, isFalse);
      expect(configuration.sendImages, isFalse);
    });

    test('unknown config metadata never becomes a secret-bearing output', () {
      final settings = AssistantProviderSettings.fromJson({
        'version': 1,
        'configurations': {
          'deepSeek': {
            'baseUrl': 'https://api.deepseek.com',
            'model': 'deepseek-flash',
            'apiKey': 'secret-token',
          },
        },
        'apiKey': 'another-secret-token',
      });
      expect(jsonEncode(settings.toJson()), isNot(contains('secret-token')));
      expect(settings.configurationFor(deepSeek).sendImages, isFalse);
    });

    test('rejects mismatched providers and unknown saved enum values', () {
      final inconsistent = AssistantProviderSettings(
        configurations: {
          deepSeek: OnlineModelConfiguration(
            provider: compatible,
            baseUrl: 'https://example.com',
            model: 'model',
          ),
        },
      );
      expect(inconsistent.toJson, throwsFormatException);
      for (final json in [
        {'version': 3},
        {'version': 1, 'source': 'invalid'},
        {'version': 1, 'provider': 'invalid'},
        {'version': 1, 'configurations': []},
        {
          'version': 1,
          'configurations': {'unknown': {}},
        },
      ]) {
        expect(
          () => AssistantProviderSettings.fromJson(json),
          throwsFormatException,
        );
      }
    });
  });

  group('provider store', () {
    late Directory temporary;
    late FakeApiKeyStore keys;
    late AssistantProviderStore store;
    setUp(() async {
      temporary = await Directory.systemTemp.createTemp('diary_api_settings_');
      keys = FakeApiKeyStore();
      store = AssistantProviderStore(rootDirectory: temporary, keys: keys);
    });
    tearDown(() async => temporary.delete(recursive: true));

    test('missing preferences do not enable online replies', () async {
      final settings = await store.readSettings();
      expect(settings.source, AssistantReplySource.local);
      expect(await store.readApiKey(deepSeek), isNull);
    });

    test(
      'configuration survives restart without persisting API credentials',
      () async {
        await store.writeApiKey(deepSeek, 'deepseek-secret-token');
        await store.writeApiKey(compatible, 'compatible-secret-token');
        const settings = AssistantProviderSettings(
          source: AssistantReplySource.online,
          provider: compatible,
          configurations: {
            compatible: OnlineModelConfiguration(
              provider: compatible,
              baseUrl: 'https://example.com/v1',
              model: 'vision-model',
              sendImages: true,
            ),
          },
        );
        await store.writeSettings(settings);
        final restarted = AssistantProviderStore(
          rootDirectory: temporary,
          keys: keys,
        );
        final restored = await restarted.readSettings();
        expect(restored.source, AssistantReplySource.online);
        expect(restored.configurationFor(compatible).model, 'vision-model');
        expect(restored.configurationFor(compatible).sendImages, isTrue);
        final files = await temporary.list().toList();
        expect(files, hasLength(1));
        final text = await (files.single as File).readAsString();
        expect(text, isNot(contains('secret-token')));
        expect(text, isNot(contains('apiKey')));
        expect(await restarted.readApiKey(deepSeek), 'deepseek-secret-token');
        expect(
          await restarted.readApiKey(compatible),
          'compatible-secret-token',
        );
      },
    );

    test('credential overwrite and deletion isolate each provider', () async {
      await store.writeApiKey(deepSeek, 'first-secret');
      await store.writeApiKey(compatible, 'other-secret');
      await store.writeApiKey(OnlineModelProvider.miniMax, 'minimax-secret');
      await store.writeApiKey(deepSeek, '  newer-secret  ');
      expect(await store.readApiKey(deepSeek), 'newer-secret');
      expect(await store.readApiKey(compatible), 'other-secret');
      expect(
        await store.readApiKey(OnlineModelProvider.miniMax),
        'minimax-secret',
      );
      await store.deleteApiKey(deepSeek);
      expect(await store.readApiKey(deepSeek), isNull);
      expect(await store.readApiKey(compatible), 'other-secret');
      expect(await temporary.list().isEmpty, isTrue);
    });

    test(
      'concurrent preference writes retain the latest complete snapshot',
      () async {
        final first = store.writeSettings(const AssistantProviderSettings());
        final latest = store.writeSettings(
          const AssistantProviderSettings(source: AssistantReplySource.online),
        );
        await Future.wait([first, latest]);
        expect(
          (await store.readSettings()).source,
          AssistantReplySource.online,
        );
        expect(
          await File(
            p.join(temporary.path, 'provider-settings.json.part'),
          ).exists(),
          isFalse,
        );
      },
    );

    test(
      'oversized and malformed configuration errors redact raw contents',
      () async {
        final file = File(p.join(temporary.path, 'provider-settings.json'));
        await file.writeAsString('secret-token' * 2000);
        await expectLater(store.readSettings(), throwsFormatException);
        await file.writeAsString('{"apiKey":"secret-token",broken json');
        await expectLater(
          store.readSettings(),
          throwsA(
            isA<FormatException>().having(
              (error) => error.toString(),
              'sanitized error',
              isNot(contains('secret-token')),
            ),
          ),
        );
      },
    );

    test('secure storage failures never echo the credential', () async {
      keys.fail = true;
      final safeError = throwsA(
        isA<StateError>().having(
          (error) => error.toString(),
          'sanitized error',
          isNot(contains('secret-token')),
        ),
      );
      await expectLater(store.readApiKey(deepSeek), safeError);
      await expectLater(store.writeApiKey(deepSeek, 'secret-token'), safeError);
      await expectLater(store.deleteApiKey(deepSeek), safeError);
      keys.fail = false;
      await store.writeApiKey(deepSeek, 'new-key');
      expect(await store.readApiKey(deepSeek), 'new-key');
    });

    test('invalid keys are rejected without writing to either store', () async {
      for (final key in [
        '',
        ' ',
        'has whitespace',
        'line\nbreak',
        'a' * 8193,
      ]) {
        expect(() => store.writeApiKey(deepSeek, key), throwsFormatException);
      }
      expect(keys.values, isEmpty);
      expect(await temporary.list().isEmpty, isTrue);
    });
  });
}

class FakeApiKeyStore implements AssistantApiKeyStore {
  final values = <OnlineModelProvider, String>{};
  bool fail = false;

  @override
  Future<String?> read(OnlineModelProvider provider) async {
    if (fail) throw StateError('platform rejected secret-token');
    return values[provider];
  }

  @override
  Future<void> write(OnlineModelProvider provider, String key) async {
    if (fail) throw StateError('platform rejected secret-token');
    values[provider] = key;
  }

  @override
  Future<void> delete(OnlineModelProvider provider) async {
    if (fail) throw StateError('platform rejected secret-token');
    values.remove(provider);
  }
}
