import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class PinSecretStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class SecurePinSecretStore implements PinSecretStore {
  const SecurePinSecretStore();

  static const _storage = FlutterSecureStorage();
  static const _key = 'diary.app_lock.pin_verifier.v1';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String value) => _storage.write(key: _key, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _key);
}

class AppLockService extends ChangeNotifier {
  AppLockService({PinSecretStore? store})
    : _store = store ?? const SecurePinSecretStore();

  static final instance = AppLockService();
  static const pinLength = 6;

  final PinSecretStore _store;
  String? _verifier;
  bool _loaded = false;
  Future<void>? _loading;

  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _read();
  }

  Future<void> _read() async {
    try {
      _verifier = await _store.read();
      _loaded = true;
    } finally {
      _loading = null;
    }
  }

  bool get hasPin => _verifier != null;

  Future<void> setPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw ArgumentError('PIN must contain exactly six digits');
    }
    final random = Random.secure();
    final salt = List<int>.generate(32, (_) => random.nextInt(256));
    final verifier = '${base64UrlEncode(salt)}:${_digest(salt, pin)}';
    await _store.write(verifier);
    _verifier = verifier;
    _loaded = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) async {
    await load();
    final parts = _verifier?.split(':');
    if (parts == null || parts.length != 2 || pin.length != pinLength) {
      return false;
    }
    try {
      final expected = base64Url.decode(parts[1]);
      final actual = base64Url.decode(_digest(base64Url.decode(parts[0]), pin));
      var difference = expected.length ^ actual.length;
      for (var i = 0; i < expected.length && i < actual.length; i++) {
        difference |= expected[i] ^ actual[i];
      }
      return difference == 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> removePin() async {
    await _store.delete();
    _verifier = null;
    _loaded = true;
    notifyListeners();
  }

  String _digest(List<int> salt, String pin) =>
      base64UrlEncode(sha256.convert([...salt, ...utf8.encode(pin)]).bytes);
}
