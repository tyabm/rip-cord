import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Relative luminance (0–1) per WCAG sRGB.
double relativeLuminance(Color c) {
  double lin(double channel) {
    final v = channel;
    return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  final r = lin(c.r);
  final g = lin(c.g);
  final b = lin(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

/// Contrast ratio between two colors (≥ 1).
double contrastRatio(Color a, Color b) {
  final l1 = relativeLuminance(a);
  final l2 = relativeLuminance(b);
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Black or white for maximum contrast on [background].
Color onColorFor(Color background) {
  return relativeLuminance(background) > 0.4 ? Colors.black : Colors.white;
}

/// Adjust [seed] so it works as a primary accent on light or dark surfaces.
///
/// Pale pinks are darkened for light mode; very dark salmon is lightened for
/// dark mode so buttons and emphasis text stay visible.
Color ensureAccentVisible(Color seed, Brightness brightness) {
  final hsl = HSLColor.fromColor(seed);
  var h = hsl.hue;
  var s = hsl.saturation.clamp(0.35, 1.0);
  var l = hsl.lightness;

  if (brightness == Brightness.light) {
    // Need enough darkness to show on white/light grey.
    if (l > 0.62) l = 0.48;
    if (l > 0.55) l = 0.45;
    if (s < 0.4) s = 0.55;
    // Ensure contrast vs typical light surface (~0.98 luminance white).
    var candidate = HSLColor.fromAHSL(1, h, s, l).toColor();
    var guard = 0;
    while (contrastRatio(candidate, const Color(0xFFFAFAFA)) < 3.0 &&
        l > 0.18 &&
        guard < 12) {
      l -= 0.05;
      candidate = HSLColor.fromAHSL(1, h, s, l).toColor();
      guard++;
    }
    return candidate;
  }

  // Dark theme: need enough lightness on dark surfaces.
  if (l < 0.38) l = 0.58;
  if (l < 0.45) l = 0.55;
  if (s < 0.35) s = 0.5;
  var candidate = HSLColor.fromAHSL(1, h, s, l).toColor();
  var guard = 0;
  while (contrastRatio(candidate, const Color(0xFF121212)) < 3.0 &&
      l < 0.85 &&
      guard < 12) {
    l += 0.05;
    candidate = HSLColor.fromAHSL(1, h, s, l).toColor();
    guard++;
  }
  return candidate;
}

/// Build a [ColorScheme] from a user seed with visibility fixes for primary roles.
ColorScheme contrastSafeSchemeFromSeed(Color seed, Brightness brightness) {
  final accent = ensureAccentVisible(seed, brightness);
  final base = ColorScheme.fromSeed(seedColor: accent, brightness: brightness);
  final onPrimary = onColorFor(accent);
  // Soft container tone still related to seed but readable.
  final container = Color.lerp(
        accent,
        brightness == Brightness.light ? Colors.white : Colors.black,
        brightness == Brightness.light ? 0.75 : 0.55,
      ) ??
      accent;
  final onContainer = onColorFor(container);

  return base.copyWith(
    primary: accent,
    onPrimary: onPrimary,
    primaryContainer: container,
    onPrimaryContainer: onContainer,
    secondary: accent,
    onSecondary: onPrimary,
  );
}
