import 'package:flutter/foundation.dart';

import 'package:diary/data/settings_store.dart';
import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required DiarySettingsStore store}) : _store = store;

  final DiarySettingsStore _store;
  DiarySettings _settings = const DiarySettings();
  bool _isLoading = true;

  DiarySettings get settings => _settings;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    if (!_isLoading) return;
    try {
      final loaded = await _store.load();
      _settings = loaded.copyWith(
        fontScale: loaded.fontScale.clamp(.85, 1.3).toDouble(),
      );
    } catch (_) {
      // Settings are a convenience layer. A storage failure must not block
      // the diary from opening; defaults are safe and usable.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(DiaryThemeMode value) =>
      _update(_settings.copyWith(themeMode: value));

  Future<void> setFontScale(double value) =>
      _update(_settings.copyWith(fontScale: value.clamp(.85, 1.3)));

  Future<void> setDefaultEditorType(DiaryEditorType value) =>
      _update(_settings.copyWith(defaultEditorType: value));

  Future<void> setShowWordCount(bool value) =>
      _update(_settings.copyWith(showWordCount: value));

  Future<void> setQuickCaptureSide(QuickCaptureSide value) =>
      _update(_settings.copyWith(quickCaptureSide: value));

  Future<void> setDailyReminder(bool value) =>
      _update(_settings.copyWith(dailyReminder: value));

  Future<void> setBiometricLock(bool value) =>
      _update(_settings.copyWith(biometricLock: value));

  Future<void> setSyncEndpoint(String value) =>
      _update(_settings.copyWith(syncEndpoint: value.trim()));

  Future<void> setSyncToken(String value) =>
      _update(_settings.copyWith(syncToken: value));

  Future<void> _update(DiarySettings next) async {
    _settings = next;
    notifyListeners();
    try {
      await _store.save(next);
    } catch (_) {
      // Keep the in-memory setting active even if the platform store is
      // temporarily unavailable. The next change will retry persistence.
    }
  }
}
