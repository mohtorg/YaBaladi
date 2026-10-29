// lib/theme/app_typography.dart
//
// [v3.1 — 2026-10-20] — Fixed typography tokens to match approved hierarchy.
//   - headingScreen:     28/w800/h1.3 → 22/w700/h1.4
//   - headingSection:    20/w700/h1.4 → 18/w600/h1.4
//   - headingSubsection: 17/w600/h1.4 → 16/w500/h1.5
//   - headingLabel:      15/w700/h1.3 → 13/w600/h1.4
//   - Uses `Cairo` (variable font from assets/fonts/Cairo-Variable.ttf).
//   - Named to match `app_theme.dart` expectations: YaBaladiTypography.

import 'package:flutter/material.dart';

/// نظام الخطوط المركزي لتطبيق YaBaladi.
/// يعتمد على خط "Cairo" (متوفر في assets/fonts/Cairo-Variable.ttf).
abstract final class YaBaladiTypography {
  YaBaladiTypography._();

  static const String fontFamily = 'Cairo';

  // ═══════════════════════════════════════════════════════════════
  // DISPLAY (عناوين ضخمة للـ Splash/Empty States)
  // ═══════════════════════════════════════════════════════════════
  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
  );

  // ═══════════════════════════════════════════════════════════════
  // HEADINGS (عناوين الشاشات والأقسام)
  // ═══════════════════════════════════════════════════════════════

  /// عنوان رئيسي لشاشة كاملة (مثلاً: "خطط رحلتك")
  static const TextStyle headingScreen = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.2,
  );

  /// عنوان قسم رئيسي (مثلاً: "الأعلى تقييماً")
  static const TextStyle headingSection = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  /// عنوان فرعي داخل قسم (مثلاً: "مطعم أبو طارق")
  static const TextStyle headingSubsection = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// عنوان صغير (مثلاً: "تفاصيل المحطة")
  static const TextStyle headingLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // ═══════════════════════════════════════════════════════════════
  // BODY (النصوص الأساسية)
  // ═══════════════════════════════════════════════════════════════

  /// نص أساسي كبير (للقراءة المريحة)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// نص أساسي متوسط (معياري)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
  );

  /// نص صغير (وصف ثانوي)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ═══════════════════════════════════════════════════════════════
  // LABELS (الأزرار والرقائق)
  // ═══════════════════════════════════════════════════════════════

  /// زر أساسي
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.2,
  );

  /// زر ثانوي / رقاقة
  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  /// تسمية صغيرة
  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  // ═══════════════════════════════════════════════════════════════
  // CAPTION (نصوص مساعدة صغيرة جداً)
  // ═══════════════════════════════════════════════════════════════
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
