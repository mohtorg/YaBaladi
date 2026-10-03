import 'package:flutter/material.dart';

/// Central Design Tokens foundation for Ya Baladi.
///
/// Source: approved Ya Baladi Visual Identity document.
/// This file is the SINGLE SOURCE OF TRUTH for:
/// - Brand colors
/// - Semantic colors
/// - Spacing scale
/// - Radius scale
/// - Elevation scale
/// - Text colors
/// - Surface colors
abstract final class YaBaladiDesignTokens {
  YaBaladiDesignTokens._();

  // ============================================================
  // BRAND COLORS (From approved Visual Identity document)
  // ============================================================

  static const Color navy = Color(0xFF0B2D5B);
  static const Color primaryBlue = Color(0xFF0D6EFD);
  static const Color accentOrange = Color(0xFFFF8A00);
  static const Color white = Color(0xFFFFFFFF);

  // Official publication colors (Navy / White / Gold)
  static const Color gold = Color(0xFFD4AF37);

  // ============================================================
  // SEMANTIC COLORS (Light Mode)
  // ============================================================

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ============================================================
  // NEUTRAL SCALE (for text, backgrounds, borders)
  // ============================================================

  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // ============================================================
  // TEXT COLORS (Light Mode)
  // ============================================================

  static const Color textPrimary = Color(0xFF111827);   // Almost black
  static const Color textSecondary = Color(0xFF6B7280); // Grey 500
  static const Color textTertiary = Color(0xFF9CA3AF);  // Grey 400
  static const Color textInverse = Color(0xFFFFFFFF);   // On dark backgrounds
  static const Color textBrand = primaryBlue;           // Links, brand text

  // ============================================================
  // SURFACE COLORS (Light Mode)
  // ============================================================

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);   // Grey 100
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF9FAFB);        // Grey 50
  static const Color divider = Color(0xFFE5E7EB);           // Grey 200
  static const Color border = Color(0xFFD1D5DB);            // Grey 300

  // ============================================================
  // TEXT COLORS (Dark Mode)
  // ============================================================

  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);
  static const Color textTertiaryDark = Color(0xFF9CA3AF);
  static const Color textInverseDark = Color(0xFF111827);

  // ============================================================
  // SURFACE COLORS (Dark Mode)
  // ============================================================

  static const Color surfaceDark = Color(0xFF1F2937);         // Grey 800
  static const Color surfaceVariantDark = Color(0xFF374151);   // Grey 700
  static const Color surfaceElevatedDark = Color(0xFF374151);
  static const Color backgroundDark = Color(0xFF111827);       // Grey 900
  static const Color dividerDark = Color(0xFF374151);
  static const Color borderDark = Color(0xFF4B5563);

  // ============================================================
  // SPACING SCALE (4pt grid)
  // ============================================================

  static const double space0 = 0;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;
  static const double space7 = 40;
  static const double space8 = 48;

  // ============================================================
  // RADIUS SCALE
  // ============================================================

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusPill = 999;

  // ============================================================
  // ELEVATION SCALE
  // ============================================================

  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 2;
  static const double elevation4 = 4;

  // ============================================================
  // LAYOUT CONSTRAINTS
  // ============================================================

  static const double maxContentWidth = 1200;
  static const double minTouchTarget = 48;

  // ============================================================
  // COMMON PADDINGS
  // ============================================================

  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: space4,
  );

  static const EdgeInsets pagePaddingLarge = EdgeInsets.symmetric(
    horizontal: space5,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(space4);

  // ============================================================
  // COMMON BORDER RADII
  // ============================================================

  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(radiusMedium));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(radiusSmall));
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(radiusLarge),
  );
}