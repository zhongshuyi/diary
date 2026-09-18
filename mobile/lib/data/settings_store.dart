import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';

abstract interface class DiarySettingsStore {
  Future<DiarySettings> load();

  Future<void> save(DiarySettings settings);
}

class SharedPreferencesDiarySettingsStore implements DiarySettingsStore {
  static const _themeModeKey = 'diary.settings.theme_mode';
  static const _fontScaleKey = 'diary.settings.font_scale';
  static const _editorTypeKey = 'diary.settings.default_editor';
  static const _showWordCountKey = 'diary.settings.show_word_count';
  static const _dailyReminderKey = 'diary.settings.daily_reminder';
  static const _biometricLockKey = 'diary.settings.biometric_lock';
  static const _syncEndpointKey = 'diary.settings.sync_endpoint';
  static const _syncTokenKey = 'diary.settings.sync_token';
  static const _updateEndpointKey = 'diary.settings.update_endpoint';
  static const _quickCaptureSideKey = 'diary.settings.quick_capture_side';

  @override
  Future<DiarySettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return DiarySettings(
      themeMode: DiaryThemeModeCodec.fromWireValue(
        preferences.getString(_themeModeKey),
      ),
      fontScale: _safeScale(preferences.getDouble(_fontScaleKey)),
      defaultEditorType: DiaryEditorTypeCodec.fromWireValue(
        preferences.getString(_editorTypeKey),
      ),
      showWordCount: preferences.getBool(_showWordCountKey) ?? true,
      dailyReminder: preferences.getBool(_dailyReminderKey) ?? false,
      biometricLock: preferences.getBool(_biometricLockKey) ?? false,
      syncEndpoint: preferences.getString(_syncEndpointKey) ?? '',
      syncToken: preferences.getString(_syncTokenKey) ?? '',
      updateEndpoint: preferences.getString(_updateEndpointKey) ?? '',
      quickCaptureSide: QuickCaptureSideCodec.fromWireValue(
        preferences.getString(_quickCaptureSideKey),
      ),
    );
  }

  @override
  Future<void> save(DiarySettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, settings.themeMode.wireValue);
    await preferences.setDouble(_fontScaleKey, settings.fontScale);
    await preferences.setString(
      _editorTypeKey,
      settings.defaultEditorType.wireValue,
    );
    await preferences.setBool(_showWordCountKey, settings.showWordCount);
    await preferences.setBool(_dailyReminderKey, settings.dailyReminder);
    await preferences.setBool(_biometricLockKey, settings.biometricLock);
    await preferences.setString(_syncEndpointKey, settings.syncEndpoint);
    await preferences.setString(_syncTokenKey, settings.syncToken);
    await preferences.setString(_updateEndpointKey, settings.updateEndpoint);
    await preferences.setString(
      _quickCaptureSideKey,
      settings.quickCaptureSide.name,
    );
  }
}

double _safeScale(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return 1;
  return value.clamp(.85, 1.3);
}
