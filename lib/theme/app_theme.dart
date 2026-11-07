import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

enum Tone { mint, sand, blush, lime }

class AppTheme {
  // Soft tinted backgrounds for stat tiles, each with a stronger colour for its icon and number.
  static (Color, Color) tone(Brightness brightness, Tone tone) {
    final dark = brightness == Brightness.dark;
    return switch (tone) {
      Tone.mint =>
        dark
            ? (const Color(0xFF12301F), const Color(0xFF4CCB85))
            : (const Color(0xFFE3F4EA), const Color(0xFF1E8E4E)),
      Tone.sand =>
        dark
            ? (const Color(0xFF33280F), const Color(0xFFE6B04E))
            : (const Color(0xFFFBF0DA), const Color(0xFFB7791F)),
      Tone.blush =>
        dark
            ? (const Color(0xFF361B1A), const Color(0xFFF08A82))
            : (const Color(0xFFFBE4E1), const Color(0xFFC8423B)),
      Tone.lime =>
        dark
            ? (const Color(0xFF24301A), const Color(0xFF9CD05A))
            : (const Color(0xFFEAF3D6), const Color(0xFF5C8A1E)),
    };
  }

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
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: .35),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      inputDecorationTheme: _inputTheme(colors, dark),
    );
  }

  static InputDecorationTheme _inputTheme(ColorScheme colors, bool dark) {
    final fill = dark ? const Color(0xFF141816) : const Color(0xFFF5F7F5);
    final line = dark ? const Color(0xFF262C28) : const Color(0xFFE4E8E4);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border(line),
      enabledBorder: border(line),
      disabledBorder: border(line),
      focusedBorder: border(colors.primary, 1.8),
      errorBorder: border(colors.error, 1.4),
      focusedErrorBorder: border(colors.error, 1.8),
      labelStyle: TextStyle(color: colors.onSurfaceVariant),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (states) => TextStyle(
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.error)
              ? colors.error
              : states.contains(WidgetState.focused)
              ? colors.primary
              : colors.onSurfaceVariant,
        ),
      ),
      hintStyle: TextStyle(color: colors.onSurfaceVariant),
      prefixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.error)
            ? colors.error
            : states.contains(WidgetState.focused)
            ? colors.primary
            : colors.onSurfaceVariant,
      ),
      suffixIconColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? colors.primary
            : colors.onSurfaceVariant,
      ),
      counterStyle: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
    );
  }

  static ThemeData get light => _make(Brightness.light);
  static ThemeData get dark => _make(Brightness.dark);
}
