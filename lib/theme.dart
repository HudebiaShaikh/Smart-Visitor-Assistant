import 'package:flutter/material.dart';

/// Amazon / Ring developer brand palette used across the app.
///
/// Colours are taken from the Amazon Developer portal (developer.amazon.com):
/// Squid Ink navy headers, Amazon Orange CTAs/accents and Amazon link blue.
abstract final class Brand {
  // Squid ink (dark navy) - app bar, navigation, footer, secondary buttons
  static const Color squidInk = Color(0xFF232F3E);
  static const Color squidInkLight = Color(0xFF37475A);

  // Amazon orange - primary accent, logo smile, main actions
  static const Color orange = Color(0xFFFF9900);
  static const Color orangeDark = Color(0xFFEC7211);
  static const Color orangeLight = Color(0xFFFFB84D);
  static const Color orangeSoft = Color(0xFFFFF1DC);

  // Amazon link blue
  static const Color linkBlue = Color(0xFF146EB4);
  static const Color linkBlueSoft = Color(0xFFE8F0F8);

  // Surfaces & text
  static const Color bg = Color(0xFFF4F5F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE3E6E6);
  static const Color textPrimary = Color(0xFF232F3E);
  static const Color textMuted = Color(0xFF5F6B76);
  static const Color surfaceContainerHighest = Color(0xFFE3E6E6);

  // Priority colours - always shown together with an icon + word, never alone.
  static const Color critical = Color(0xFFB3261E);
  static const Color high = Color(0xFFB45309);
  static const Color medium = Color(0xFF1E5AA8);
  static const Color low = Color(0xFF2E7D32);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [squidInk, squidInkLight],
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [orangeLight, orange],
  );
}

ThemeData buildAppTheme({required bool highContrast}) {
  if (highContrast) {
    // Accessibility theme: black & yellow, high contrast. Kept for the
    // "High contrast" switch in Settings.
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Brand.orange,
        onPrimary: Colors.black,
        secondary: Colors.white,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Color(0xFFFF6B6B),
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.black, indicatorColor: Brand.orange),
      cardTheme: CardThemeData(
        color: const Color(0xFF101010),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Brand.orange, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  const colorScheme = ColorScheme.light(
    primary: Brand.orange,
    onPrimary: Brand.squidInk,
    primaryContainer: Brand.orangeSoft,
    onPrimaryContainer: Color(0xFF5C3A00),
    secondary: Brand.squidInk,
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFE7EAEC),
    onSecondaryContainer: Brand.squidInk,
    tertiary: Brand.linkBlue,
    onTertiary: Colors.white,
    error: Brand.critical,
    onError: Colors.white,
    surface: Brand.surface,
    onSurface: Brand.textPrimary,
    outline: Brand.divider,
    outlineVariant: Color(0xFFD3D8DC),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: Brand.bg,
    textTheme: _textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
    ),
    cardTheme: CardThemeData(
      color: Brand.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Brand.divider),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Brand.surface,
      selectedColor: Brand.orangeSoft,
      side: const BorderSide(color: Brand.divider),
      labelStyle: const TextStyle(color: Brand.textPrimary, fontWeight: FontWeight.w600),
      secondaryLabelStyle: const TextStyle(color: Brand.textPrimary, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 54),
        side: const BorderSide(color: Brand.squidInkLight),
        foregroundColor: Brand.squidInk,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Brand.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Brand.orangeSoft,
      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 3,
      shadowColor: Colors.black26,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Brand.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      height: 68,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Brand.surface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Brand.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Brand.divider)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Brand.orange, width: 2)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Brand.squidInk,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Brand.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Brand.orange : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Brand.orangeSoft : Brand.surfaceContainerHighest,
      ),
      trackOutlineColor: WidgetStateProperty.all(Brand.divider),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: Brand.orange,
      thumbColor: Brand.orange,
      inactiveTrackColor: Brand.surfaceContainerHighest,
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Brand.orange,
      unselectedLabelColor: Brand.textMuted,
      indicatorColor: Brand.orange,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Brand.orange,
      foregroundColor: Brand.squidInk,
      shape: StadiumBorder(),
    ),
  );
}

final TextTheme _textTheme = const TextTheme(
  headlineSmall: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Brand.textPrimary),
  titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Brand.textPrimary),
  titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Brand.textPrimary),
  titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Brand.textPrimary),
  bodyLarge: TextStyle(fontSize: 17, color: Brand.textPrimary, height: 1.35),
  bodyMedium: TextStyle(fontSize: 15, color: Brand.textMuted, height: 1.35),
  labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Brand.textPrimary),
).apply(bodyColor: Brand.textPrimary, displayColor: Brand.textPrimary);
