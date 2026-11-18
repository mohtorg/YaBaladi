// lib/core/services/freshness_service.dart
// [v1.0 — 2026-11-12] — FRESHNESS WEIGHT SERVICE.
//
// Philosophy: Not all places age equally. A restaurant's quality changes
// monthly; a historical landmark's does not. Using a single decay constant
// for all categories is naive. This service uses per-category λ (decay rate).
//
// Formula:
//   freshness = e^(-λ × ageInDays)
//   halfLife  = ln(2) / λ  (age at which freshness hits 0.5)
//
// No external dependencies. Pure math. Safe to call from anywhere.

import 'dart:math' as math;

abstract final class FreshnessService {
  FreshnessService._();

  /// Per-category decay rates (λ). Larger = decays faster.
  /// Values chosen so that half-life is meaningful for each domain:
  ///   restaurants: ~231 days  (taste/premises change quickly)
  ///   cafes:       ~347 days
  ///   clinics:     ~1386 days (~4 years)
  ///   landmarks:   ~2310 days (~6 years)
  static const Map<String, double> _lambdas = {
    'restaurants': 0.003,
    'cafes': 0.002,
    'pharmacies': 0.001,
    'hospitals': 0.0005,
    'clinics': 0.0005,
    'shopping': 0.0015,
    'hotels': 0.001,
    'landmarks': 0.0003,
    'entertainment': 0.002,
    'services': 0.001,
  };

  static const double _defaultLambda = 0.0015; // ~462-day half-life

  /// يسترجع λ المناسب لتصنيف، أو الافتراضي إذا لم يُعرَف.
  static double lambdaForCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      return _defaultLambda;
    }
    return _lambdas[categoryId] ?? _defaultLambda;
  }

  /// يحسب وزن الحداثة (0.0 → 1.0).
  /// - 1.0: تقييم اليوم.
  /// - 0.5: عمره يساوي نصف العمر.
  /// - → 0.0: قديم جداً.
  static double computeWeight({
    required DateTime createdAt,
    String? categoryId,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final ageDays =
        current.difference(createdAt).inSeconds.toDouble() / 86400.0;

    if (ageDays <= 0) {
      return 1.0;
    }

    final lambda = lambdaForCategory(categoryId);
    if (lambda <= 0) {
      return 1.0;
    }

    return math.exp(-lambda * ageDays);
  }

  /// نصف عمر التقييم (بالأيام). مفيد للعرض والتشخيص.
  static double computeHalfLifeDays(String? categoryId) {
    final lambda = lambdaForCategory(categoryId);
    if (lambda <= 0) {
      return double.infinity;
    }
    return math.log(2) / lambda;
  }

  /// تصنيف بشري لعمر التقييم (للعرض في الواجهة).
  /// "تقييم حديث" | "تقييم متوسط" | "تقييم قديم"
  static String describeAge({
    required DateTime createdAt,
    String? categoryId,
    DateTime? now,
  }) {
    final weight = computeWeight(
      createdAt: createdAt,
      categoryId: categoryId,
      now: now,
    );
    if (weight >= 0.75) {
      return 'تقييم حديث';
    }
    if (weight >= 0.4) {
      return 'تقييم متوسط';
    }
    return 'تقييم قديم';
  }
}