import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary/domain/diary_entry.dart';
import 'package:diary/domain/diary_settings.dart';

abstract interface class DiarySettingsStore {
  Future<DiarySettings> load();

  Future<void> save(DiarySettings settings);
}

class SharedPreferencesDiarySettingsStore implements DiarySettingsStore {
  static const _themeModeKey = 'diary.settings.theme_mode';
  static const _themePresetKey = 'diary.settings.theme_preset';
  static const _customThemeColorKey = 'diary.settings.custom_theme_color';
  static const _chatBackgroundPathKey = 'diary.settings.chat_background_path';
  static const _chatBackgroundScaleKey = 'diary.settings.chat_background_scale';
  static const _chatBackgroundAlignmentXKey =
      'diary.settings.chat_background_alignment_x';
  static const _chatBackgroundAlignmentYKey =
      'diary.settings.chat_background_alignment_y';
  static const _chatBackgroundOpacityKey =
      'diary.settings.chat_background_opacity';
  static const _fontScaleKey = 'diary.settings.font_scale';
  static const _editorTypeKey = 'diary.settings.default_editor';
  static const _showWordCountKey = 'diary.settings.show_word_count';
  static const _dailyReminderKey = 'diary.settings.daily_reminder';
  static const _dailyReminderMinuteKey = 'diary.settings.daily_reminder_minute';
  static const _biometricLockKey = 'diary.settings.biometric_lock';
  static const _syncEndpointKey = 'diary.settings.sync_endpoint';
  static const _syncTokenKey = 'diary.settings.sync_token';
  static const _amapAndroidKey = 'diary.settings.amap_android_key';
  static const _updateEndpointKey = 'diary.settings.update_endpoint';
  static const _quickCaptureSideKey = 'diary.settings.quick_capture_side';
  static const _defaultHomeModeKey = 'diary.settings.default_home_mode';
  static const _chatTitleKey = 'diary.settings.chat_title';
  static const _profileSignatureKey = 'diary.settings.profile_signature';
  static const _showProfileSignatureKey =
      'diary.settings.show_profile_signature';
  static const _profileAvatarPathKey = 'diary.settings.profile_avatar_path';
  static const _showChatAvatarKey = 'diary.settings.show_chat_avatar';

  @override
  Future<DiarySettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return DiarySettings(
      themeMode: DiaryThemeModeCodec.fromWireValue(
        preferences.getString(_themeModeKey),
      ),
      themePreset: DiaryThemePresetCodec.fromWireValue(
        preferences.getString(_themePresetKey),
      ),
      customThemeColor: preferences.getInt(_customThemeColorKey),
      chatBackground: DiaryChatBackground(
        imagePath: preferences.getString(_chatBackgroundPathKey),
        scale: _safeRange(
          preferences.getDouble(_chatBackgroundScaleKey),
          fallback: 1,
          minimum: 1,
          maximum: 2.5,
        ),
        alignmentX: _safeRange(
          preferences.getDouble(_chatBackgroundAlignmentXKey),
          fallback: 0,
          minimum: -1,
          maximum: 1,
        ),
        alignmentY: _safeRange(
          preferences.getDouble(_chatBackgroundAlignmentYKey),
          fallback: 0,
          minimum: -1,
          maximum: 1,
        ),
        opacity: _safeRange(
          preferences.getDouble(_chatBackgroundOpacityKey),
          fallback: .22,
          minimum: .08,
          maximum: .5,
        ),
      ).normalized(),
      fontScale: _safeScale(preferences.getDouble(_fontScaleKey)),
      defaultEditorType: DiaryEditorTypeCodec.fromWireValue(
        preferences.getString(_editorTypeKey),
      ),
      showWordCount: preferences.getBool(_showWordCountKey) ?? true,
      dailyReminder: preferences.getBool(_dailyReminderKey) ?? false,
      dailyReminderTime: DiaryReminderTime.fromMinuteOfDay(
        preferences.getInt(_dailyReminderMinuteKey),
      ),
      biometricLock: preferences.getBool(_biometricLockKey) ?? false,
      syncEndpoint: preferences.getString(_syncEndpointKey) ?? '',
      syncToken: preferences.getString(_syncTokenKey) ?? '',
      amapAndroidKey: preferences.getString(_amapAndroidKey) ?? '',
      updateEndpoint: preferences.getString(_updateEndpointKey) ?? '',
      quickCaptureSide: QuickCaptureSideCodec.fromWireValue(
        preferences.getString(_quickCaptureSideKey),
      ),
      defaultHomeMode: DiaryHomeModeCodec.fromWireValue(
        preferences.getString(_defaultHomeModeKey),
      ),
      chatTitle: preferences.getString(_chatTitleKey) ?? diaryDefaultChatTitle,
      profileSignature: preferences.getString(_profileSignatureKey) ?? '',
      showProfileSignature:
          preferences.getBool(_showProfileSignatureKey) ?? true,
      profileAvatarPath: _optionalPath(
        preferences.getString(_profileAvatarPathKey),
      ),
      showChatAvatar: preferences.getBool(_showChatAvatarKey) ?? true,
    );
  }

  @override
  Future<void> save(DiarySettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeModeKey, settings.themeMode.wireValue);
    await preferences.setString(
      _themePresetKey,
      settings.themePreset.wireValue,
    );
    if (settings.customThemeColor == null) {
      await preferences.remove(_customThemeColorKey);
    } else {
      await preferences.setInt(
        _customThemeColorKey,
        settings.customThemeColor!,
      );
    }
    final chatBackground = settings.chatBackground.normalized();
    if (!chatBackground.hasImage) {
      await preferences.remove(_chatBackgroundPathKey);
      await preferences.remove(_chatBackgroundScaleKey);
      await preferences.remove(_chatBackgroundAlignmentXKey);
      await preferences.remove(_chatBackgroundAlignmentYKey);
      await preferences.remove(_chatBackgroundOpacityKey);
    } else {
      await preferences.setString(
        _chatBackgroundPathKey,
        chatBackground.imagePath!,
      );
      await preferences.setDouble(
        _chatBackgroundScaleKey,
        chatBackground.scale,
      );
      await preferences.setDouble(
        _chatBackgroundAlignmentXKey,
        chatBackground.alignmentX,
      );
      await preferences.setDouble(
        _chatBackgroundAlignmentYKey,
        chatBackground.alignmentY,
      );
      await preferences.setDouble(
        _chatBackgroundOpacityKey,
        chatBackground.opacity,
      );
    }
    await preferences.setDouble(_fontScaleKey, settings.fontScale);
    await preferences.setString(
      _editorTypeKey,
      settings.defaultEditorType.wireValue,
    );
    await preferences.setBool(_showWordCountKey, settings.showWordCount);
    await preferences.setBool(_dailyReminderKey, settings.dailyReminder);
    await preferences.setInt(
      _dailyReminderMinuteKey,
      settings.dailyReminderTime.minuteOfDay,
    );
    await preferences.setBool(_biometricLockKey, settings.biometricLock);
    await preferences.setString(_syncEndpointKey, settings.syncEndpoint);
    await preferences.setString(_syncTokenKey, settings.syncToken);
    await preferences.setString(_amapAndroidKey, settings.amapAndroidKey);
    await preferences.setString(_updateEndpointKey, settings.updateEndpoint);
    await preferences.setString(
      _quickCaptureSideKey,
      settings.quickCaptureSide.name,
    );
    await preferences.setString(
      _defaultHomeModeKey,
      settings.defaultHomeMode.wireValue,
    );
    await preferences.setString(_chatTitleKey, settings.chatTitle);
    await preferences.setString(
      _profileSignatureKey,
      settings.profileSignature,
    );
    await preferences.setBool(
      _showProfileSignatureKey,
      settings.showProfileSignature,
    );
    final profileAvatarPath = _optionalPath(settings.profileAvatarPath);
    if (profileAvatarPath == null) {
      await preferences.remove(_profileAvatarPathKey);
    } else {
      await preferences.setString(_profileAvatarPathKey, profileAvatarPath);
    }
    await preferences.setBool(_showChatAvatarKey, settings.showChatAvatar);
  }
}

double _safeScale(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return 1;
  return value.clamp(.85, 1.3);
}

String? _optionalPath(String? value) {
  final path = value?.trim();
  return path == null || path.isEmpty ? null : path;
}

double _safeRange(
  double? value, {
  required double fallback,
  required double minimum,
  required double maximum,
}) {
  if (value == null || value.isNaN || value.isInfinite) return fallback;
  return value.clamp(minimum, maximum);
}
