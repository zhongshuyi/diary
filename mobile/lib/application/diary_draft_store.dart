import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class DiaryDraftStore {
  Future<Map<String, dynamic>?> load(String key);

  Future<void> save(String key, Map<String, dynamic> value);

  Future<void> clear(String key);
}

class MemoryDiaryDraftStore implements DiaryDraftStore {
  final _drafts = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    final draft = _drafts[key];
    return draft == null ? null : Map<String, dynamic>.from(draft);
  }

  @override
  Future<void> save(String key, Map<String, dynamic> value) async {
    _drafts[key] = Map<String, dynamic>.from(value);
  }

  @override
  Future<void> clear(String key) async {
    _drafts.remove(key);
  }
}

class SharedPreferencesDiaryDraftStore implements DiaryDraftStore {
  static const _keyPrefix = 'diary.draft.';

  @override
  Future<Map<String, dynamic>?> load(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString('$_keyPrefix$key');
    if (encoded == null || encoded.isEmpty) return null;
    try {
      final decoded = jsonDecode(encoded);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(String key, Map<String, dynamic> value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('$_keyPrefix$key', jsonEncode(value));
  }

  @override
  Future<void> clear(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove('$_keyPrefix$key');
  }
}
