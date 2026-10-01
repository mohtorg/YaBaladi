import 'package:flutter/material.dart';

/// Central Design Tokens foundation for Ya Baladi.
///
/// This file intentionally does not invent final brand values.
/// The approved design document states that final secondary colors,
/// typography scale, radius, and elevation still require fixation.
abstract final class YaBaladiDesignTokens {
  YaBaladiDesignTokens._();

  // Approved Ya Baladi brand colors from the Visual Identity document.
  static const Color navy = Color(0xFF0B2D5B);
  static const Color primaryBlue = Color(0xFF0D6EFD);
  static const Color accentOrange = Color(0xFFFF8A00);
  static const Color white = Color(0xFFFFFFFF);
  // Spacing scale â€” structural tokens only.
  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 40;
  static const double space8 = 48;

  // Radius scale â€” reserved central values; final brand radius
  // remains subject to the approved design-system fixation.
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;

  // Elevation scale.
  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation4 = 4;

  // Standard content constraints.
  static const double maxContentWidth = 1200;

  // Direction-independent page padding.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: space4,
  );
}