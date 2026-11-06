import 'package:flutter/material.dart';

class AppTheme {
  static const green = Color(0xFF1E8E4E);
  static const deepGreen = Color(0xFF14663A);
  static const red = Color(0xFFC8423B);
  static const amber = Color(0xFFE0A030);

  static ThemeData _make(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF050505) : Colors.white;
    final card = dark ? const Color(0xFF121212) : Colors.white;
    final border = dark ? const Color(0xFF2A2A2A) : const Color(0xFFE3E6E3);
    final softGreen = dark ? const Color(0xFF12301F) : const Color(0xFFE6F5EC);

    // Neutral surfaces so nothing picks up a tint from the green seed.
    final colors =
        ColorScheme.fromSeed(seedColor: green, brightness: brightness).copyWith(
          primary: dark ? const Color(0xFF4CCB85) : green,
          onPrimary: dark ? const Color(0xFF00210F) : Colors.white,
          primaryContainer: softGreen,
          onPrimaryContainer: dark
              ? const Color(0xFFBFF0D2)
              : const Color(0xFF0B3B21),
          secondary: dark ? const Color(0xFFE6A39B) : red,
          secondaryContainer: softGreen,
          onSecondaryContainer: dark
              ? const Color(0xFFBFF0D2)
              : const Color(0xFF0B3B21),
          surface: background,
          onSurface: dark ? const Color(0xFFEDEDED) : const Color(0xFF111111),
          onSurfaceVariant: dark
              ? const Color(0xFFA3A3A3)
              : const Color(0xFF5F6368),
          surfaceTint: Colors.transparent,
          surfaceContainerLowest: background,
          surfaceContainerLow: dark
              ? const Color(0xFF0C0C0C)
              : const Color(0xFFF8F8F8),
          surfaceContainer: dark
              ? const Color(0xFF121212)
              : const Color(0xFFF4F4F4),
          surfaceContainerHigh: dark
              ? const Color(0xFF191919)
              : const Color(0xFFEFEFEF),
          surfaceContainerHighest: dark
              ? const Color(0xFF202020)
              : const Color(0xFFEAEAEA),
          outline: dark ? const Color(0xFF5A5A5A) : const Color(0xFF9AA09A),
          outlineVariant: border,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      fontFamily: 'Ubuntu',
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Ubuntu',
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        indicatorColor: softGreen,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: background,
        selectedColor: softGreen,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: colors.onSurface, fontFamily: 'Ubuntu'),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
      ),
    );
  }

  static ThemeData get light => _make(Brightness.light);
  static ThemeData get dark => _make(Brightness.dark);
}
