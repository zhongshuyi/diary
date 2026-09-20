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
  static const terracotta = Color(0xFFB55C44);
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
      DiaryThemePreset.carbon => const DiaryThemeColors(
        paper: Color(0xFFF5F5F3),
        surface: Color(0xFFFFFFFF),
        ink: Color(0xFF222222),
        hero: Color(0xFF222222),
        onHero: Color(0xFFFFFFFF),
        mutedInk: Color(0xFF686864),
        line: Color(0xFFDDDCD8),
        terracotta: Color(0xFF8A5A2B),
        terracottaSoft: Color(0xFFE9D9C8),
        sage: Color(0xFFDDE3DC),
        butter: Color(0xFFEDE4C9),
        lavender: Color(0xFFE4E4E5),
      ),
      DiaryThemePreset.deepSea => const DiaryThemeColors(
        paper: Color(0xFFF2F7FA),
        surface: Color(0xFFFCFDFE),
        ink: Color(0xFF1D2B35),
        hero: Color(0xFF1D2B35),
        onHero: Color(0xFFFCFDFE),
        mutedInk: Color(0xFF5E7481),
        line: Color(0xFFD8E5EB),
        terracotta: Color(0xFF2B6F8D),
        terracottaSoft: Color(0xFFCDE6F1),
        sage: Color(0xFFD8E8E2),
        butter: Color(0xFFE7E5C8),
        lavender: Color(0xFFDCE4F0),
      ),
      DiaryThemePreset.pine => const DiaryThemeColors(
        paper: Color(0xFFF3F7F3),
        surface: Color(0xFFFBFDFB),
        ink: Color(0xFF203025),
        hero: Color(0xFF203025),
        onHero: Color(0xFFFBFDFB),
        mutedInk: Color(0xFF5E7162),
        line: Color(0xFFD8E3D8),
        terracotta: Color(0xFF3E7252),
        terracottaSoft: Color(0xFFCFE4D4),
        sage: Color(0xFFC9DFCC),
        butter: Color(0xFFE9E2BD),
        lavender: Color(0xFFE0E4E7),
      ),
      DiaryThemePreset.dusk => const DiaryThemeColors(
        paper: Color(0xFFF8F5FA),
        surface: Color(0xFFFEFCFF),
        ink: Color(0xFF2C2633),
        hero: Color(0xFF2C2633),
        onHero: Color(0xFFFEFCFF),
        mutedInk: Color(0xFF706678),
        line: Color(0xFFE4DDE9),
        terracotta: Color(0xFF78548B),
        terracottaSoft: Color(0xFFE7D7EF),
        sage: Color(0xFFD8E4DE),
        butter: Color(0xFFEDE1BC),
        lavender: Color(0xFFE8DFF0),
      ),
      DiaryThemePreset.terracotta => const DiaryThemeColors(
        paper: Color(0xFFFBF4F0),
        surface: Color(0xFFFFFCFA),
        ink: Color(0xFF35251F),
        hero: Color(0xFF35251F),
        onHero: Color(0xFFFFFCFA),
        mutedInk: Color(0xFF7A6257),
        line: Color(0xFFEDDCD2),
        terracotta: Color(0xFFA95239),
        terracottaSoft: Color(0xFFF2D6C9),
        sage: Color(0xFFDCE4D8),
        butter: Color(0xFFF0DFC0),
        lavender: Color(0xFFE9DFE1),
      ),
      DiaryThemePreset.roseMist => const DiaryThemeColors(
        paper: Color(0xFFFBF4F6),
        surface: Color(0xFFFFFCFD),
        ink: Color(0xFF35252B),
        hero: Color(0xFF35252B),
        onHero: Color(0xFFFFFCFD),
        mutedInk: Color(0xFF7A626B),
        line: Color(0xFFEEDCE2),
        terracotta: Color(0xFF8F5265),
        terracottaSoft: Color(0xFFF0D5DE),
        sage: Color(0xFFDCE4DE),
        butter: Color(0xFFF0E0C8),
        lavender: Color(0xFFE9DFEC),
      ),
      DiaryThemePreset.moonstone => const DiaryThemeColors(
        paper: Color(0xFFF4F6F8),
        surface: Color(0xFFFDFDFE),
        ink: Color(0xFF23303A),
        hero: Color(0xFF23303A),
        onHero: Color(0xFFFDFDFE),
        mutedInk: Color(0xFF61717E),
        line: Color(0xFFDCE3E8),
        terracotta: Color(0xFF58758A),
        terracottaSoft: Color(0xFFD5E3EB),
        sage: Color(0xFFDCE5E5),
        butter: Color(0xFFE9E4C9),
        lavender: Color(0xFFE0E3EC),
      ),
    };
  }

  static DiaryThemeColors darkFor(DiaryThemePreset preset) {
    return switch (preset) {
      DiaryThemePreset.warmPaper => dark,
      DiaryThemePreset.carbon => const DiaryThemeColors(
        paper: Color(0xFF181818),
        surface: Color(0xFF242424),
        ink: Color(0xFFF2F1EF),
        hero: Color(0xFF101010),
        onHero: Color(0xFFF2F1EF),
        mutedInk: Color(0xFFC1BFBA),
        line: Color(0xFF3C3B38),
        terracotta: Color(0xFFD9A56E),
        terracottaSoft: Color(0xFF523A24),
        sage: Color(0xFF37443A),
        butter: Color(0xFF554B2F),
        lavender: Color(0xFF403F42),
      ),
      DiaryThemePreset.deepSea => const DiaryThemeColors(
        paper: Color(0xFF121A20),
        surface: Color(0xFF1E2A32),
        ink: Color(0xFFEAF3F7),
        hero: Color(0xFF0C1216),
        onHero: Color(0xFFEAF3F7),
        mutedInk: Color(0xFFB7C8D0),
        line: Color(0xFF3B4D58),
        terracotta: Color(0xFF82B9D2),
        terracottaSoft: Color(0xFF254D61),
        sage: Color(0xFF2E4A45),
        butter: Color(0xFF514A30),
        lavender: Color(0xFF384658),
      ),
      DiaryThemePreset.pine => const DiaryThemeColors(
        paper: Color(0xFF151B17),
        surface: Color(0xFF202A23),
        ink: Color(0xFFEDF4EE),
        hero: Color(0xFF0F1411),
        onHero: Color(0xFFEDF4EE),
        mutedInk: Color(0xFFB9C9BC),
        line: Color(0xFF3D4E41),
        terracotta: Color(0xFF8AB59A),
        terracottaSoft: Color(0xFF2D4B36),
        sage: Color(0xFF38513D),
        butter: Color(0xFF514A2E),
        lavender: Color(0xFF42454A),
      ),
      DiaryThemePreset.dusk => const DiaryThemeColors(
        paper: Color(0xFF1B1820),
        surface: Color(0xFF28222F),
        ink: Color(0xFFF3EEF6),
        hero: Color(0xFF120F16),
        onHero: Color(0xFFF3EEF6),
        mutedInk: Color(0xFFC9BDCF),
        line: Color(0xFF493F51),
        terracotta: Color(0xFFD0A9E0),
        terracottaSoft: Color(0xFF503D5E),
        sage: Color(0xFF394A44),
        butter: Color(0xFF50482E),
        lavender: Color(0xFF494054),
      ),
      DiaryThemePreset.terracotta => const DiaryThemeColors(
        paper: Color(0xFF201714),
        surface: Color(0xFF30231E),
        ink: Color(0xFFF8F0EB),
        hero: Color(0xFF160E0B),
        onHero: Color(0xFFF8F0EB),
        mutedInk: Color(0xFFD1BDB3),
        line: Color(0xFF503C33),
        terracotta: Color(0xFFF09A79),
        terracottaSoft: Color(0xFF633528),
        sage: Color(0xFF3E4B3D),
        butter: Color(0xFF58472D),
        lavender: Color(0xFF4F4140),
      ),
      DiaryThemePreset.roseMist => const DiaryThemeColors(
        paper: Color(0xFF21171A),
        surface: Color(0xFF302126),
        ink: Color(0xFFF8EEF1),
        hero: Color(0xFF160D10),
        onHero: Color(0xFFF8EEF1),
        mutedInk: Color(0xFFD2BDC4),
        line: Color(0xFF513940),
        terracotta: Color(0xFFEB9BAF),
        terracottaSoft: Color(0xFF603745),
        sage: Color(0xFF3D4B43),
        butter: Color(0xFF57462F),
        lavender: Color(0xFF4F4054),
      ),
      DiaryThemePreset.moonstone => const DiaryThemeColors(
        paper: Color(0xFF171B1E),
        surface: Color(0xFF232B30),
        ink: Color(0xFFEEF3F5),
        hero: Color(0xFF0F1315),
        onHero: Color(0xFFEEF3F5),
        mutedInk: Color(0xFFBEC9CE),
        line: Color(0xFF3E4A50),
        terracotta: Color(0xFF9BC4D8),
        terracottaSoft: Color(0xFF304C5A),
        sage: Color(0xFF3B4A4B),
        butter: Color(0xFF504B31),
        lavender: Color(0xFF404651),
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
              : colors.hero,
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
        onPrimary: Colors.white,
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
