import 'package:flutter/material.dart';

class AppTheme {
  static const blue = Color(0xFF245E9B);
  static const navy = Color(0xFF153C68);
  static const red = Color(0xFFB8413B);
  static const amber = Color(0xFFE9B66B);

  static ThemeData _make(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
      primary: dark ? const Color(0xFF9CC8FA) : blue,
      secondary: dark ? const Color(0xFFE6A39B) : red,
      surface: dark ? const Color(0xFF141A22) : const Color(0xFFF7F8FA),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: colors.surface,
      fontFamily: 'Ubuntu',
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          fontFamily: 'Ubuntu',
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? const Color(0xFF1C2430) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: colors.outlineVariant.withValues(alpha: .55)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1C2430) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );
  }

  static ThemeData get light => _make(Brightness.light);
  static ThemeData get dark => _make(Brightness.dark);
}
