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

  static DiaryThemeColors lightFor(DiaryThemePreset preset) {
    return switch (preset) {
      DiaryThemePreset.warmPaper => light,
      DiaryThemePreset.mistBlue => const DiaryThemeColors(
        paper: Color(0xFFF2F6F8),
        surface: Color(0xFFFCFDFE),
        ink: Color(0xFF1E2A32),
        hero: Color(0xFF1E2A32),
        onHero: Color(0xFFFCFDFE),
        mutedInk: Color(0xFF687780),
        line: Color(0xFFD7E2E8),
        terracotta: Color(0xFF3E7895),
        terracottaSoft: Color(0xFFCFE3EC),
        sage: Color(0xFFD6E9E1),
        butter: Color(0xFFE7E4BC),
        lavender: Color(0xFFDEE2F1),
      ),
      DiaryThemePreset.evergreen => const DiaryThemeColors(
        paper: Color(0xFFF4F6F0),
        surface: Color(0xFFFDFFF9),
        ink: Color(0xFF253027),
        hero: Color(0xFF253027),
        onHero: Color(0xFFFDFFF9),
        mutedInk: Color(0xFF6D786C),
        line: Color(0xFFDCE4D7),
        terracotta: Color(0xFF5B7D55),
        terracottaSoft: Color(0xFFD7E6D1),
        sage: Color(0xFFC7DEC2),
        butter: Color(0xFFEDE2B9),
        lavender: Color(0xFFE4E1EF),
      ),
      DiaryThemePreset.lavender => const DiaryThemeColors(
        paper: Color(0xFFF7F4FA),
        surface: Color(0xFFFFFCFF),
        ink: Color(0xFF28232E),
        hero: Color(0xFF28232E),
        onHero: Color(0xFFFFFCFF),
        mutedInk: Color(0xFF746C7C),
        line: Color(0xFFE5DDED),
        terracotta: Color(0xFF8465A8),
        terracottaSoft: Color(0xFFE4D8F1),
        sage: Color(0xFFD6E6DC),
        butter: Color(0xFFF0E1B7),
        lavender: Color(0xFFE5DDF1),
      ),
    };
  }

  static DiaryThemeColors darkFor(DiaryThemePreset preset) {
    return switch (preset) {
      DiaryThemePreset.warmPaper => dark,
      DiaryThemePreset.mistBlue => const DiaryThemeColors(
        paper: Color(0xFF182126),
        surface: Color(0xFF273239),
        ink: Color(0xFFEFF6F8),
        hero: Color(0xFF111A1E),
        onHero: Color(0xFFEFF6F8),
        mutedInk: Color(0xFFB4C4CB),
        line: Color(0xFF47565E),
        terracotta: Color(0xFF7DBAD4),
        terracottaSoft: Color(0xFF284E60),
        sage: Color(0xFF2F4D44),
        butter: Color(0xFF574E2F),
        lavender: Color(0xFF3D455D),
      ),
      DiaryThemePreset.evergreen => const DiaryThemeColors(
        paper: Color(0xFF192019),
        surface: Color(0xFF2B3329),
        ink: Color(0xFFF0F6ED),
        hero: Color(0xFF11170F),
        onHero: Color(0xFFF0F6ED),
        mutedInk: Color(0xFFBBC8B7),
        line: Color(0xFF4B5848),
        terracotta: Color(0xFF91B58A),
        terracottaSoft: Color(0xFF3D5538),
        sage: Color(0xFF3D5738),
        butter: Color(0xFF574D2F),
        lavender: Color(0xFF464252),
      ),
      DiaryThemePreset.lavender => const DiaryThemeColors(
        paper: Color(0xFF211C25),
        surface: Color(0xFF302A35),
        ink: Color(0xFFF5EFF9),
        hero: Color(0xFF17121B),
        onHero: Color(0xFFF5EFF9),
        mutedInk: Color(0xFFC8BECF),
        line: Color(0xFF514857),
        terracotta: Color(0xFFC5A8E5),
        terracottaSoft: Color(0xFF544263),
        sage: Color(0xFF3B5046),
        butter: Color(0xFF574A2F),
        lavender: Color(0xFF4B4158),
      ),
    };
  }

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

  DiaryThemeColors withCustomAccent(
    int colorValue, {
    required Brightness brightness,
  }) {
    final source = HSLColor.fromColor(Color(colorValue));
    final accent = brightness == Brightness.dark && source.lightness < .66
        ? source.withLightness(.66).toColor()
        : source.toColor();
    final softSaturation = source.saturation == 0
        ? 0.0
        : (source.saturation * .72).clamp(.18, .62).toDouble();
    final soft = source
        .withSaturation(softSaturation)
        .withLightness(brightness == Brightness.light ? .88 : .30)
        .toColor();
    return copyWith(terracotta: accent, terracottaSoft: soft);
  }

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
  static ThemeData lightFor(DiaryThemePreset preset, {int? customAccent}) {
    if (preset == DiaryThemePreset.warmPaper && customAccent == null) {
      return light;
    }
    final colors = DiaryThemeColors.lightFor(preset);
    return _withColors(
      base: light,
      colors: customAccent == null
          ? colors
          : colors.withCustomAccent(customAccent, brightness: Brightness.light),
      brightness: Brightness.light,
    );
  }

  static ThemeData darkFor(DiaryThemePreset preset, {int? customAccent}) {
    if (preset == DiaryThemePreset.warmPaper && customAccent == null) {
      return dark;
    }
    final colors = DiaryThemeColors.darkFor(preset);
    return _withColors(
      base: dark,
      colors: customAccent == null
          ? colors
          : colors.withCustomAccent(customAccent, brightness: Brightness.dark),
      brightness: Brightness.dark,
    );
  }

  static ThemeData _withColors({
    required ThemeData base,
    required DiaryThemeColors colors,
    required Brightness brightness,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: colors.terracotta,
          brightness: brightness,
          surface: colors.surface,
        ).copyWith(
          primary: colors.terracotta,
          onPrimary:
              ThemeData.estimateBrightnessForColor(colors.terracotta) ==
                  Brightness.dark
              ? colors.surface
              : colors.ink,
          secondary: colors.sage,
          onSecondary: brightness == Brightness.light
              ? colors.ink
              : colors.onHero,
          surface: colors.surface,
          onSurface: colors.ink,
        );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.line),
    );
    final focusedInputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: colors.terracotta, width: 1.5),
    );
    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(color: colors.ink),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(color: colors.ink),
      titleLarge: base.textTheme.titleLarge?.copyWith(color: colors.ink),
      titleMedium: base.textTheme.titleMedium?.copyWith(color: colors.ink),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(color: colors.mutedInk),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(color: colors.mutedInk),
      labelLarge: base.textTheme.labelLarge?.copyWith(color: colors.ink),
      labelSmall: base.textTheme.labelSmall?.copyWith(color: colors.mutedInk),
    );
    final snackBarBackground = brightness == Brightness.light
        ? colors.ink
        : colors.onHero;
    final snackBarForeground = brightness == Brightness.light
        ? colors.surface
        : colors.hero;

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.paper,
      textTheme: textTheme,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: colors.paper,
        foregroundColor: colors.ink,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        fillColor: colors.surface,
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: focusedInputBorder,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.line),
        ),
      ),
      dividerTheme: base.dividerTheme.copyWith(color: colors.line),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: snackBarBackground,
        contentTextStyle: TextStyle(color: snackBarForeground),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      extensions: [colors],
    );
  }

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
