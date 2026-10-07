import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/assistant_provider_settings.dart';

abstract interface class AssistantApiKeyStore {
  Future<String?> read(OnlineModelProvider provider);
  Future<void> write(OnlineModelProvider provider, String key);
  Future<void> delete(OnlineModelProvider provider);
}

class SecureAssistantApiKeyStore implements AssistantApiKeyStore {
  const SecureAssistantApiKeyStore();

  static const _storage = FlutterSecureStorage();
  static String _key(OnlineModelProvider provider) =>
      'diary.assistant.api_key.v1.${provider.name}';

  @override
  Future<String?> read(OnlineModelProvider provider) =>
      _storage.read(key: _key(provider));

  @override
  Future<void> write(OnlineModelProvider provider, String key) =>
      _storage.write(key: _key(provider), value: key);

  @override
  Future<void> delete(OnlineModelProvider provider) =>
      _storage.delete(key: _key(provider));
}

/// This folder is excluded from diary export, sync and Android backups.
/// API credentials are only ever passed to the platform secure store.
class AssistantProviderStore {
  AssistantProviderStore({Directory? rootDirectory, AssistantApiKeyStore? keys})
    : _rootDirectory = rootDirectory,
      _keys = keys ?? const SecureAssistantApiKeyStore();

  static const _maxSettingsBytes = 16 * 1024;
  final Directory? _rootDirectory;
  final AssistantApiKeyStore _keys;
  Future<void> _writes = Future<void>.value();
  Future<void> _keyWrites = Future<void>.value();

  Future<Directory> _root() async =>
      _rootDirectory ??
      Directory(
        p.join(
          (await getApplicationSupportDirectory()).path,
          'local-assistant',
        ),
      );

  Future<AssistantProviderSettings> readSettings() async {
    await _writes;
    final file = File(p.join((await _root()).path, 'provider-settings.json'));
    if (!await file.exists()) return const AssistantProviderSettings();
    if (await file.length() > _maxSettingsBytes) {
      throw const FormatException('模型服务配置文件过大');
    }
    try {
      final json = jsonDecode(await file.readAsString());
      if (json is! Map<String, dynamic>) {
        throw const FormatException('模型服务配置格式不正确');
      }
      return AssistantProviderSettings.fromJson(json);
    } on FormatException {
      // jsonDecode errors can otherwise echo the offending source contents.
      throw const FormatException('模型服务配置格式不正确，请重新保存设置');
    }
  }

  Future<void> writeSettings(AssistantProviderSettings settings) {
    final contents = jsonEncode(settings.toJson());
    if (utf8.encode(contents).length > _maxSettingsBytes) {
      throw const FormatException('模型服务配置过大');
    }
    final write = _writes.then((_) async {
      final root = await _root();
      await root.create(recursive: true);
      final destination = File(p.join(root.path, 'provider-settings.json'));
      final staging = File('${destination.path}.part');
      try {
        await staging.writeAsString(contents, flush: true);
        await staging.rename(destination.path);
      } finally {
        if (await staging.exists()) await staging.delete();
      }
    });
    _writes = write.catchError((Object _) {});
    return write;
  }

  Future<String?> readApiKey(OnlineModelProvider provider) async {
    await _keyWrites;
    try {
      return await _keys.read(provider);
    } catch (_) {
      throw StateError('无法读取模型 API Key，请重新保存');
    }
  }

  Future<void> writeApiKey(OnlineModelProvider provider, String value) {
    final key = value.trim();
    if (key.isEmpty ||
        key.length > 8192 ||
        RegExp(r'\s|[\x00-\x1f\x7f]').hasMatch(key)) {
      throw const FormatException('请填写有效的 API Key');
    }
    return _writeKey(() => _keys.write(provider, key));
  }

  Future<void> deleteApiKey(OnlineModelProvider provider) =>
      _writeKey(() => _keys.delete(provider));

  Future<void> _writeKey(Future<void> Function() operation) {
    final write = _keyWrites.then((_) async {
      try {
        await operation();
      } catch (_) {
        throw StateError('无法保存模型 API Key，请重试');
      }
    });
    _keyWrites = write.catchError((Object _) {});
    return write;
  }
}
