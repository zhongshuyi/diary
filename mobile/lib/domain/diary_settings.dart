import 'package:diary/domain/diary_entry.dart';

enum DiaryThemeMode { system, light, dark }

enum QuickCaptureSide { left, right }

extension QuickCaptureSideCodec on QuickCaptureSide {
  static QuickCaptureSide fromWireValue(String? value) =>
      value == QuickCaptureSide.left.name
      ? QuickCaptureSide.left
      : QuickCaptureSide.right;
}

extension DiaryThemeModeCodec on DiaryThemeMode {
  String get wireValue => name;

  String get label {
    switch (this) {
      case DiaryThemeMode.system:
        return '跟随系统';
      case DiaryThemeMode.light:
        return '暖纸浅色';
      case DiaryThemeMode.dark:
        return '夜间阅读';
    }
  }

  static DiaryThemeMode fromWireValue(String? value) {
    return DiaryThemeMode.values.firstWhere(
      (mode) => mode.wireValue == value,
      orElse: () => DiaryThemeMode.system,
    );
  }
}

class DiarySettings {
  const DiarySettings({
    this.themeMode = DiaryThemeMode.system,
    this.fontScale = 1,
    this.defaultEditorType = DiaryEditorType.plainText,
    this.showWordCount = true,
    this.dailyReminder = false,
    this.biometricLock = false,
    this.syncEndpoint = '',
    this.syncToken = '',
    this.quickCaptureSide = QuickCaptureSide.right,
  });

  final DiaryThemeMode themeMode;
  final double fontScale;
  final DiaryEditorType defaultEditorType;
  final bool showWordCount;
  final bool dailyReminder;
  final bool biometricLock;
  final String syncEndpoint;
  final String syncToken;
  final QuickCaptureSide quickCaptureSide;

  DiarySettings copyWith({
    DiaryThemeMode? themeMode,
    double? fontScale,
    DiaryEditorType? defaultEditorType,
    bool? showWordCount,
    bool? dailyReminder,
    bool? biometricLock,
    String? syncEndpoint,
    String? syncToken,
    QuickCaptureSide? quickCaptureSide,
  }) {
    return DiarySettings(
      themeMode: themeMode ?? this.themeMode,
      fontScale: fontScale ?? this.fontScale,
      defaultEditorType: defaultEditorType ?? this.defaultEditorType,
      showWordCount: showWordCount ?? this.showWordCount,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      biometricLock: biometricLock ?? this.biometricLock,
      syncEndpoint: syncEndpoint ?? this.syncEndpoint,
      syncToken: syncToken ?? this.syncToken,
      quickCaptureSide: quickCaptureSide ?? this.quickCaptureSide,
    );
  }
}
