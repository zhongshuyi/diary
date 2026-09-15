import 'package:flutter/material.dart';

import 'package:diary/domain/diary_settings.dart';

extension DiaryThemeModeMaterial on DiaryThemeMode {
  ThemeMode get materialMode {
    switch (this) {
      case DiaryThemeMode.system:
        return ThemeMode.system;
      case DiaryThemeMode.light:
        return ThemeMode.light;
      case DiaryThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

abstract final class DiaryPalette {
  static const paper = Color(0xFFF7F3EC);
  static const surface = Color(0xFFFFFCF7);
  static const ink = Color(0xFF24231F);
  static const mutedInk = Color(0xFF77736C);
  static const line = Color(0xFFE6DED2);
  static const terracotta = Color(0xFFB85E45);
  static const terracottaSoft = Color(0xFFF1D8CE);
  static const sage = Color(0xFFDCE7D8);
  static const butter = Color(0xFFF1E4B8);
  static const lavender = Color(0xFFE6E1EF);
}

abstract final class DiaryTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: DiaryPalette.terracotta,
      brightness: Brightness.light,
      surface: DiaryPalette.surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: DiaryPalette.terracotta,
        onPrimary: DiaryPalette.surface,
        secondary: DiaryPalette.sage,
        onSecondary: DiaryPalette.ink,
        surface: DiaryPalette.surface,
        onSurface: DiaryPalette.ink,
      ),
      scaffoldBackgroundColor: DiaryPalette.paper,
      fontFamily: 'Aptos',
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: DiaryPalette.ink,
          fontFamily: 'Georgia',
          fontSize: 36,
          fontWeight: FontWeight.w700,
          height: 1.08,
        ),
        headlineSmall: TextStyle(
          color: DiaryPalette.ink,
          fontFamily: 'Georgia',
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: DiaryPalette.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: DiaryPalette.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: DiaryPalette.mutedInk,
          fontSize: 15,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          color: DiaryPalette.mutedInk,
          fontSize: 13,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: DiaryPalette.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
        labelSmall: TextStyle(
          color: DiaryPalette.mutedInk,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DiaryPalette.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DiaryPalette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: DiaryPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: DiaryPalette.terracotta,
            width: 1.5,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      cardTheme: CardThemeData(
        color: DiaryPalette.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: DiaryPalette.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: DiaryPalette.line, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DiaryPalette.ink,
        contentTextStyle: const TextStyle(color: DiaryPalette.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: DiaryPalette.terracotta,
      brightness: Brightness.dark,
      surface: const Color(0xFF24231F),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: const Color(0xFFE89578),
        onPrimary: const Color(0xFF2A1710),
        secondary: const Color(0xFFB5CDAF),
        onSecondary: const Color(0xFF172016),
        surface: const Color(0xFF2D2B27),
        onSurface: const Color(0xFFF7F3EC),
      ),
      scaffoldBackgroundColor: const Color(0xFF1A1917),
      fontFamily: 'Aptos',
      textTheme: light.textTheme.apply(
        bodyColor: const Color(0xFFEDE7DD),
        displayColor: const Color(0xFFF7F3EC),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2B27),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4A4741)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF4A4741)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE89578), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D2B27),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF4A4741)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF4A4741), space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFF7F3EC),
        contentTextStyle: const TextStyle(color: DiaryPalette.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

String diaryDateLabel(DateTime date) {
  const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
  return '${date.month}月${date.day}日 · 星期${weekdays[date.weekday - 1]}';
}

String diaryMonthLabel(DateTime date) => '${date.year}年 ${date.month}月';

String diaryTimeLabel(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String diaryMoodLabel(double value) {
  if (value >= .8) return '明亮';
  if (value >= .6) return '平静';
  if (value >= .4) return '平常';
  if (value >= .2) return '低落';
  return '阴天';
}
