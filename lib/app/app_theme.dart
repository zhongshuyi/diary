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

@immutable
class DiaryThemeColors extends ThemeExtension<DiaryThemeColors> {
  const DiaryThemeColors({
    required this.paper,
    required this.surface,
    required this.ink,
    required this.hero,
    required this.onHero,
    required this.mutedInk,
    required this.line,
    required this.terracotta,
    required this.terracottaSoft,
    required this.sage,
    required this.butter,
    required this.lavender,
  });

  static const light = DiaryThemeColors(
    paper: DiaryPalette.paper,
    surface: DiaryPalette.surface,
    ink: DiaryPalette.ink,
    hero: DiaryPalette.ink,
    onHero: DiaryPalette.surface,
    mutedInk: DiaryPalette.mutedInk,
    line: DiaryPalette.line,
    terracotta: DiaryPalette.terracotta,
    terracottaSoft: DiaryPalette.terracottaSoft,
    sage: DiaryPalette.sage,
    butter: DiaryPalette.butter,
    lavender: DiaryPalette.lavender,
  );

  static const dark = DiaryThemeColors(
    paper: Color(0xFF1A1917),
    surface: Color(0xFF2D2B27),
    ink: Color(0xFFF7F3EC),
    hero: Color(0xFF11100F),
    onHero: Color(0xFFF7F3EC),
    mutedInk: Color(0xFFB8B1A7),
    line: Color(0xFF4A4741),
    terracotta: Color(0xFFE89578),
    terracottaSoft: Color(0xFF5A332A),
    sage: Color(0xFF32422F),
    butter: Color(0xFF5A4A25),
    lavender: Color(0xFF413B50),
  );

  final Color paper;
  final Color surface;
  final Color ink;
  final Color hero;
  final Color onHero;
  final Color mutedInk;
  final Color line;
  final Color terracotta;
  final Color terracottaSoft;
  final Color sage;
  final Color butter;
  final Color lavender;

  static DiaryThemeColors of(BuildContext context) =>
      Theme.of(context).extension<DiaryThemeColors>() ?? light;

  @override
  DiaryThemeColors copyWith({
    Color? paper,
    Color? surface,
    Color? ink,
    Color? hero,
    Color? onHero,
    Color? mutedInk,
    Color? line,
    Color? terracotta,
    Color? terracottaSoft,
    Color? sage,
    Color? butter,
    Color? lavender,
  }) {
    return DiaryThemeColors(
      paper: paper ?? this.paper,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      hero: hero ?? this.hero,
      onHero: onHero ?? this.onHero,
      mutedInk: mutedInk ?? this.mutedInk,
      line: line ?? this.line,
      terracotta: terracotta ?? this.terracotta,
      terracottaSoft: terracottaSoft ?? this.terracottaSoft,
      sage: sage ?? this.sage,
      butter: butter ?? this.butter,
      lavender: lavender ?? this.lavender,
    );
  }

  @override
  DiaryThemeColors lerp(ThemeExtension<DiaryThemeColors>? other, double t) {
    if (other is! DiaryThemeColors) return this;
    return DiaryThemeColors(
      paper: Color.lerp(paper, other.paper, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      hero: Color.lerp(hero, other.hero, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      mutedInk: Color.lerp(mutedInk, other.mutedInk, t)!,
      line: Color.lerp(line, other.line, t)!,
      terracotta: Color.lerp(terracotta, other.terracotta, t)!,
      terracottaSoft: Color.lerp(terracottaSoft, other.terracottaSoft, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      butter: Color.lerp(butter, other.butter, t)!,
      lavender: Color.lerp(lavender, other.lavender, t)!,
    );
  }
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
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: DiaryPalette.line, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: DiaryPalette.ink,
        contentTextStyle: const TextStyle(color: DiaryPalette.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      extensions: const [DiaryThemeColors.light],
    );
  }

  static ThemeData get dark {
    final colors = DiaryThemeColors.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: DiaryPalette.terracotta,
      brightness: Brightness.dark,
      surface: colors.surface,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme.copyWith(
        primary: colors.terracotta,
        onPrimary: colors.hero,
        secondary: colors.sage,
        onSecondary: colors.onHero,
        surface: colors.surface,
        onSurface: colors.ink,
      ),
      scaffoldBackgroundColor: colors.paper,
      fontFamily: 'Aptos',
      textTheme: TextTheme(
        displaySmall: TextStyle(
          color: colors.ink,
          fontFamily: 'Georgia',
          fontSize: 36,
          fontWeight: FontWeight.w700,
          height: 1.08,
        ),
        headlineSmall: TextStyle(
          color: colors.ink,
          fontFamily: 'Georgia',
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: colors.ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: colors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: colors.mutedInk,
          fontSize: 15,
          height: 1.55,
        ),
        bodyMedium: TextStyle(
          color: colors.mutedInk,
          fontSize: 13,
          height: 1.5,
        ),
        labelLarge: TextStyle(
          color: colors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
        labelSmall: TextStyle(
          color: colors.mutedInk,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.terracotta, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(color: colors.line, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.onHero,
        contentTextStyle: TextStyle(color: colors.hero),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      extensions: const [DiaryThemeColors.dark],
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
