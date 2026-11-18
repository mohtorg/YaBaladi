// lib/core/services/adjusted_score_service.dart
// [v1.2 — 2026-11-15] — Added `minRatingsForRanking` (static const) to fix
//                     place.dart reference. No logic change.
// [v1.1 — 2026-11-12] — Phase 12: `minRatingsForRanking = 3` was planned
//                     but omitted; now added.
// [v1.0 — 2026-11-12] — ADJUSTED SCORE SERVICE.
//
// Problem: A place with 2 reviews averaging 5.0 must not outrank a place
// with 500 reviews averaging 4.6. Pure arithmetic mean punishes confidence.
//
// Solution: Bayesian-style shrinkage toward a global prior.
//   adjusted = (W / (W + C)) × weightedMean + (C / (W + C)) × prior
//
//   W: total effective weight (post-freshness)
//   C: confidence threshold, category-specific
//   prior: global average for the category (fallback: 3.5)
//
// Bonus: `sampleQuality` returns a 0-1 score that expresses "how much
// can we trust this mean?" — directly usable in the UI as a confidence
// badge next to the rating (e.g., "92% ثقة").

import 'dart:math' as math;

abstract final class AdjustedScoreService {
  AdjustedScoreService._();

  /// Phase 12: minimum number of ratings before a place is considered
  /// "rankable" (i.e., eligible to appear in ranked lists and to display
  /// a real average). Below this threshold, the place gets a "جديد" badge
  /// and its `averageRating` is treated as provisional.
  ///
  /// Static const so that `Place.fromMap` and `PlaceAggregate` can use it
  /// without instantiating the service or depending on a singleton.
  static const int minRatingsForRanking = 3;

  static const double _defaultConfidence = 10.0;
  static const double _defaultGlobalPrior = 3.5;

  /// C (confidence threshold) لكل تصنيف.
  /// - الأماكن ذات التقلب العالي (مطاعم) تحتاج عينات أكبر → C أعلى.
  /// - الأماكن المستقرة (معالم) يكفيها عينة صغيرة → C أقل.
  static const Map<String, double> _confidences = {
    'restaurants': 15.0,
    'cafes': 12.0,
    'shopping': 12.0,
    'pharmacies': 8.0,
    'clinics': 8.0,
    'hospitals': 8.0,
    'hotels': 10.0,
    'landmarks': 5.0,
    'entertainment': 10.0,
    'services': 10.0,
  };

  static double confidenceForCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      return _defaultConfidence;
    }
    return _confidences[categoryId] ?? _defaultConfidence;
  }

  /// يحسب Adjusted Score.
  /// إذا كانت W = 0، يعيد prior كأفضل تقدير أولي.
  static double computeAdjustedScore({
    required double weightedMean,
    required double effectiveWeight,
    double? globalPrior,
    double? confidence,
  }) {
    final prior = globalPrior ?? _defaultGlobalPrior;
    final c = confidence ?? _defaultConfidence;

    if (effectiveWeight <= 0) {
      return prior;
    }

    return (effectiveWeight / (effectiveWeight + c)) * weightedMean +
        (c / (effectiveWeight + c)) * prior;
  }

  /// جودة العينة (0.0 → 1.0).
  /// 0.0: لا توجد بيانات.
  /// 1.0: عينة وافرة (تتجاوز C بـ 10×، أي ثقة 90%+).
  ///
  /// مفيدة للعرض في الواجهة كشارة ثقة.
  static double computeSampleQuality({
    required double effectiveWeight,
    double? confidence,
  }) {
    final c = confidence ?? _defaultConfidence;
    if (effectiveWeight <= 0) {
      return 0.0;
    }
    // نستخدم 10×C كمرجع (يمثل ثقة 90%+).
    return math.min(1.0, effectiveWeight / (10.0 * c));
  }

  /// يُرجع نسبة الثقة كنص جاهز للعرض.
  /// "68% ثقة" | "92% ثقة"
  static String formatConfidence(double sampleQuality) {
    final pct = (sampleQuality * 100).round().clamp(0, 100);
    return '$pct% ثقة';
  }

  /// يُرجع تسمية وصفية لمستوى الثقة.
  static String describeConfidence(double sampleQuality) {
    if (sampleQuality >= 0.75) {
      return 'ثقة عالية';
    }
    if (sampleQuality >= 0.4) {
      return 'ثقة متوسطة';
    }
    return 'ثقة منخفضة';
  }

  /// الـ prior الافتراضي — يمكن استبداله لاحقاً بمتوسط يُحسب من Firestore.
  static const double defaultGlobalPrior = _defaultGlobalPrior;
}
