// lib/core/services/user_trust_service.dart
// [v1.1 — 2026-11-12] — REMOVED UNUSED IMPORT:
//   - Removed `import 'dart:math'` (clamp() is a num method, not from math).
//
// [v1.0 — 2026-11-12] — USER TRUST FACTOR SERVICE.
//
// Goal: Reward genuine, varied, sustained contributions. Punish confirmed
// abuse. Never punish negative opinions — only fraudulent behavior.
//
// Factors combined:
//   + Account age      (0.0 – 0.5)
//   + Published count  (0.0 – 0.5)
//   + Category variety (0.0 – 0.3)   ← key differentiator
//   − Confirmed reports (0.0 – 0.4)
//   × Email verified multiplier (×1.15)
//
// Final clamp: [0.1, 1.5]

abstract final class UserTrustService {
  UserTrustService._();

  /// يحسب عامل موثوقية المستخدم (0.1 – 1.5).
  static double computeTrustFactor({
    required Map<String, dynamic> userData,
    required int publishedCount,
    required int distinctCategoriesCount,
    required bool emailVerified,
  }) {
    // ─── 1. عمر الحساب (0.0 – 0.5) ───
    final createdAt = _parseDate(userData['createdAt']);
    final ageDays =
        createdAt != null ? DateTime.now().difference(createdAt).inDays : 0;
    final ageScore = (ageDays / 365.0).clamp(0.0, 0.5);

    // ─── 2. عدد التقييمات (0.0 – 0.5) ───
    final countScore = (publishedCount / 50.0).clamp(0.0, 0.5);

    // ─── 3. تنوع التصنيفات (0.0 – 0.3) ───
    final varietyScore = (distinctCategoriesCount / 5.0).clamp(0.0, 0.3);

    // ─── 4. عقوبة البلاغات (0.0 – 0.4) ───
    final confirmedReports =
        (userData['confirmedReportsCount'] as num?)?.toInt() ?? 0;
    final reportPenalty = (confirmedReports * 0.15).clamp(0.0, 0.4);

    // ─── الحساب ───
    double base = 0.6 + ageScore + countScore + varietyScore - reportPenalty;
    base = base.clamp(0.1, 1.3);

    // ─── مضاعف البريد الموثق ───
    if (emailVerified) {
      base *= 1.15;
    }

    return base.clamp(0.1, 1.5);
  }

  /// يُرجع تصنيفاً وصفياً للموثوقية (للعرض في لوحة الأدمن).
  static String describe(double trustFactor) {
    if (trustFactor >= 1.3) {
      return 'موثوق جداً';
    }
    if (trustFactor >= 1.0) {
      return 'موثوق';
    }
    if (trustFactor >= 0.6) {
      return 'عادي';
    }
    return 'مشكوك فيه';
  }

  /// التاريخ الآمن (timestamp → DateTime).
  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    // Firestore Timestamp — لا نستورد cloud_firestore هنا لتجنب الاعتماد.
    // نستخدم dynamic accessors بدلاً من ذلك.
    try {
      final seconds = (value as dynamic).seconds;
      if (seconds is int) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
