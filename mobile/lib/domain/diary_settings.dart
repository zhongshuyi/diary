import 'package:diary/domain/diary_entry.dart';

enum DiaryThemeMode { system, light, dark }

enum DiaryThemePreset {
  warmPaper,
  carbon,
  deepSea,
  pine,
  dusk,
  terracotta,
  roseMist,
  moonstone,
}

enum QuickCaptureSide { left, right }

enum DiaryHomeMode { timeline, chat }

const diaryDefaultChatTitle = '我的日记';

class DiaryReminderTime {
  const DiaryReminderTime({this.hour = 21, this.minute = 30})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;

  int get minuteOfDay => hour * 60 + minute;

  String get label =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  static DiaryReminderTime fromMinuteOfDay(int? value) {
    if (value == null || value < 0 || value >= 24 * 60) {
      return const DiaryReminderTime();
    }
    return DiaryReminderTime(hour: value ~/ 60, minute: value % 60);
  }
}

class DiaryChatBackground {
  const DiaryChatBackground({
    this.imagePath,
    this.scale = 1,
    this.alignmentX = 0,
    this.alignmentY = 0,
    this.opacity = .22,
  });

  final String? imagePath;
  final double scale;
  final double alignmentX;
  final double alignmentY;
  final double opacity;

  bool get hasImage => imagePath != null && imagePath!.trim().isNotEmpty;

  DiaryChatBackground copyWith({
    String? imagePath,
    double? scale,
    double? alignmentX,
    double? alignmentY,
    double? opacity,
  }) {
    return DiaryChatBackground(
      imagePath: imagePath ?? this.imagePath,
      scale: scale ?? this.scale,
      alignmentX: alignmentX ?? this.alignmentX,
      alignmentY: alignmentY ?? this.alignmentY,
      opacity: opacity ?? this.opacity,
    );
  }

  DiaryChatBackground normalized() {
    final path = imagePath?.trim();
    return DiaryChatBackground(
      imagePath: path == null || path.isEmpty ? null : path,
      scale: scale.clamp(1, 2.5).toDouble(),
      alignmentX: alignmentX.clamp(-1, 1).toDouble(),
      alignmentY: alignmentY.clamp(-1, 1).toDouble(),
      opacity: opacity.clamp(.08, .5).toDouble(),
    );
  }
}

extension DiaryHomeModeCodec on DiaryHomeMode {
  String get wireValue => name;

  String get label {
    switch (this) {
      case DiaryHomeMode.timeline:
        return '时间线';
      case DiaryHomeMode.chat:
        return '对话';
    }
  }

  static DiaryHomeMode fromWireValue(String? value) {
    return DiaryHomeMode.values.firstWhere(
      (mode) => mode.wireValue == value,
      orElse: () => DiaryHomeMode.timeline,
    );
  }
}

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

extension DiaryThemePresetCodec on DiaryThemePreset {
  String get wireValue => name;

  String get label {
    switch (this) {
      case DiaryThemePreset.warmPaper:
        return '暖纸';
      case DiaryThemePreset.carbon:
        return '碳黑';
      case DiaryThemePreset.deepSea:
        return '深海';
      case DiaryThemePreset.pine:
        return '松针';
      case DiaryThemePreset.dusk:
        return '暮紫';
      case DiaryThemePreset.terracotta:
        return '赤陶';
      case DiaryThemePreset.roseMist:
        return '雾玫';
      case DiaryThemePreset.moonstone:
        return '月岩';
    }
  }

  String get description {
    switch (this) {
      case DiaryThemePreset.warmPaper:
        return '温柔、纸感的暖杏色';
      case DiaryThemePreset.carbon:
        return '中性石墨与柔和琥珀';
      case DiaryThemePreset.deepSea:
        return '清透蓝灰与深海蓝';
      case DiaryThemePreset.pine:
        return '安静松绿与鼠尾草';
      case DiaryThemePreset.dusk:
        return '柔雾紫灰与暮色紫';
      case DiaryThemePreset.terracotta:
        return '暖灰底上的赤陶色';
      case DiaryThemePreset.roseMist:
        return '克制粉灰与雾玫瑰';
      case DiaryThemePreset.moonstone:
        return '冷调月岩与银蓝色';
    }
  }

  static DiaryThemePreset fromWireValue(String? value) {
    return DiaryThemePreset.values.firstWhere(
      (preset) => preset.wireValue == value,
      orElse: () => DiaryThemePreset.warmPaper,
    );
  }
}

class DiarySettings {
  const DiarySettings({
    this.themeMode = DiaryThemeMode.system,
    this.themePreset = DiaryThemePreset.warmPaper,
    this.customThemeColor,
    this.chatBackground = const DiaryChatBackground(),
    this.fontScale = 1,
    this.defaultEditorType = DiaryEditorType.plainText,
    this.showWordCount = true,
    this.dailyReminder = false,
    this.dailyReminderTime = const DiaryReminderTime(),
    this.biometricLock = false,
    this.syncEndpoint = '',
    this.syncToken = '',
    this.updateEndpoint = '',
    this.quickCaptureSide = QuickCaptureSide.right,
    this.defaultHomeMode = DiaryHomeMode.timeline,
    this.chatTitle = diaryDefaultChatTitle,
  });

  final DiaryThemeMode themeMode;
  final DiaryThemePreset themePreset;
  final int? customThemeColor;
  final DiaryChatBackground chatBackground;
  final double fontScale;
  final DiaryEditorType defaultEditorType;
  final bool showWordCount;
  final bool dailyReminder;
  final DiaryReminderTime dailyReminderTime;
  final bool biometricLock;
  final String syncEndpoint;
  final String syncToken;
  final String updateEndpoint;
  final QuickCaptureSide quickCaptureSide;
  final DiaryHomeMode defaultHomeMode;
  final String chatTitle;

  DiarySettings copyWith({
    DiaryThemeMode? themeMode,
    DiaryThemePreset? themePreset,
    int? customThemeColor,
    bool clearCustomThemeColor = false,
    DiaryChatBackground? chatBackground,
    double? fontScale,
    DiaryEditorType? defaultEditorType,
    bool? showWordCount,
    bool? dailyReminder,
    DiaryReminderTime? dailyReminderTime,
    bool? biometricLock,
    String? syncEndpoint,
    String? syncToken,
    String? updateEndpoint,
    QuickCaptureSide? quickCaptureSide,
    DiaryHomeMode? defaultHomeMode,
    String? chatTitle,
  }) {
    return DiarySettings(
      themeMode: themeMode ?? this.themeMode,
      themePreset: themePreset ?? this.themePreset,
      customThemeColor: clearCustomThemeColor
          ? null
          : customThemeColor ?? this.customThemeColor,
      chatBackground: chatBackground ?? this.chatBackground,
      fontScale: fontScale ?? this.fontScale,
      defaultEditorType: defaultEditorType ?? this.defaultEditorType,
      showWordCount: showWordCount ?? this.showWordCount,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      biometricLock: biometricLock ?? this.biometricLock,
      syncEndpoint: syncEndpoint ?? this.syncEndpoint,
      syncToken: syncToken ?? this.syncToken,
      updateEndpoint: updateEndpoint ?? this.updateEndpoint,
      quickCaptureSide: quickCaptureSide ?? this.quickCaptureSide,
      defaultHomeMode: defaultHomeMode ?? this.defaultHomeMode,
      chatTitle: chatTitle ?? this.chatTitle,
    );
  }
}
