import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rip_cord/theme/color_contrast.dart';

void main() {
  test('pale pink is darkened for light theme', () {
    const pink = Color(0xFFFFC0CB);
    final accent = ensureAccentVisible(pink, Brightness.light);
    expect(
      contrastRatio(accent, const Color(0xFFFAFAFA)),
      greaterThanOrEqualTo(3.0),
    );
    expect(onColorFor(accent), Colors.white);
  });

  test('dark salmon is lightened for dark theme', () {
    const salmon = Color(0xFF8B4513); // saddle brown / dark warm
    final accent = ensureAccentVisible(salmon, Brightness.dark);
    expect(
      contrastRatio(accent, const Color(0xFF121212)),
      greaterThanOrEqualTo(3.0),
    );
  });

  test('contrastSafeScheme sets onPrimary for readability', () {
    final scheme = contrastSafeSchemeFromSeed(
      const Color(0xFFFFB6C1),
      Brightness.light,
    );
    expect(
      contrastRatio(scheme.primary, scheme.onPrimary),
      greaterThanOrEqualTo(3.0),
    );
  });
}
