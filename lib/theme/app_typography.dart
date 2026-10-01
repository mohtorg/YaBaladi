import 'package:flutter/material.dart';

/// Central typography tokens for Ya Baladi.
/// Source: approved Ya Baladi heading typography document.
abstract final class YaBaladiTypography {
  YaBaladiTypography._();

  static const String fontFamily = 'Cairo';

  static const TextStyle headingScreen = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle headingSection = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle headingSubsection = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle headingLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
}
