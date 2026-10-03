import 'package:flutter/material.dart';

/// Central typography tokens for Ya Baladi.
///
/// Source: approved Ya Baladi heading typography document.
/// Font: Cairo (loaded from assets/fonts/).
///
/// Hierarchy:
/// - Display  : Hero / Splash
/// - H1       : Screen title (headingScreen)
/// - H2       : Section title (headingSection)
/// - H3       : Subsection / Card title (headingSubsection)
/// - H4       : Label (headingLabel)
/// - Body     : Large / Medium / Small
/// - Button   : Button text
/// - Caption  : Small auxiliary text
/// - Overline : Small uppercase label
abstract final class YaBaladiTypography {
  YaBaladiTypography._();

  static const String fontFamily = 'Cairo';

  // ============================================================
  // DISPLAY (Hero / Splash)
  // ============================================================

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // ============================================================
  // HEADINGS (From approved Ya Baladi heading typography document)
  // ============================================================

  /// H1 — Screen title.
  static const TextStyle headingScreen = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  /// H2 — Section title.
  static const TextStyle headingSection = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// H3 — Subsection / Card title.
  static const TextStyle headingSubsection = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// H4 — Small label above fields or groups.
  static const TextStyle headingLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ============================================================
  // BODY (Content text)
  // ============================================================

  /// Body Large — Long paragraphs, descriptions.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Body Medium — Standard content, list items.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// Body Small — Secondary content.
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ============================================================
  // LABELS (Buttons, chips, tags)
  // ============================================================

  /// Label Large — Button text.
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// Label Medium — Chip text, small buttons.
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  /// Label Small — Tags, badges.
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // ============================================================
  // CAPTION / OVERLINE
  // ============================================================

  /// Caption — Auxiliary text below inputs.
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// Overline — Small uppercase label above sections.
  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );
}