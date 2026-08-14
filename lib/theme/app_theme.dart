import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'color_contrast.dart';

class AppTheme {
  static const seed = Color(0xFF1B6B4A); // calm green — recovery / control

  static ThemeData light({Color? seedColor}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? seed,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark({Color? seedColor}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor ?? seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  /// Light/dark themes for MC mode: seed adjusted for visibility.
  static ThemeData moreColorsLight(Color userSeed) {
    return _base(contrastSafeSchemeFromSeed(userSeed, Brightness.light));
  }

  static ThemeData moreColorsDark(Color userSeed) {
    return _base(contrastSafeSchemeFromSeed(userSeed, Brightness.dark));
  }

  static ThemeData highContrast(Brightness brightness) {
    final scheme = brightness == Brightness.dark
        ? const ColorScheme.highContrastDark(
            primary: Color(0xFF5CFFB0),
            secondary: Color(0xFFFFE066),
          )
        : const ColorScheme.highContrastLight(
            primary: Color(0xFF004D33),
            secondary: Color(0xFF6B4E00),
          );
    return _base(scheme).copyWith(
      textTheme: _base(scheme).textTheme.apply(
            bodyColor: scheme.onSurface,
            displayColor: scheme.onSurface,
          ),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 56),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        indicatorColor: scheme.primaryContainer,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
    );
  }

  static ThemeMode materialThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.system:
      case AppThemeMode.moreColors:
        // MC follows system light/dark so the same seed works both ways.
        return ThemeMode.system;
      case AppThemeMode.light:
      case AppThemeMode.highContrast:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  static Color colorFromArgb(int argb) => Color(argb);

  static ThemeData resolve(
    AppThemeMode mode,
    Brightness platformBrightness, {
    int customSeedArgb = defaultSeedColorArgb,
  }) {
    final seedColor = colorFromArgb(customSeedArgb);
    switch (mode) {
      case AppThemeMode.system:
        return platformBrightness == Brightness.dark ? dark() : light();
      case AppThemeMode.light:
        return moreColorsLight(seedColor);
      case AppThemeMode.dark:
        return moreColorsDark(seedColor);
      case AppThemeMode.highContrast:
        return highContrast(platformBrightness);
      case AppThemeMode.moreColors:
        return platformBrightness == Brightness.dark
            ? moreColorsDark(seedColor)
            : moreColorsLight(seedColor);
    }
  }
}
