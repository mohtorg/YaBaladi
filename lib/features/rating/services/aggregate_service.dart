// lib/features/rating/services/aggregate_service.dart
// [v8.1 — 2026-11-15] — PHASE 8: aggregation uses `effectiveScore`.
//   - Replaced `rating.overall` with `rating.effectiveScore` in all
//     weighted-sum computations (sumWeightedOverall, sumWeightedOverallSquared,
//     and their Effective counterparts). This makes `averageOverall`,
//     `adjustedScore`, `variance`, and `freshnessScore` reflect the
//     weighted-mean of dimensions, not the raw star input.
//   - `distribution` (1-5 int buckets) STILL uses `overall` — that's the
//     user-facing raw stars, intentional per philosophy: "trust before stars".
//   - Legacy ratings (no `baseScore`): `effectiveScore` getter falls back
//     to `overall` — zero behavior change for pre-Phase-8 data.
// [v8.0.2 — 2026-11-15] — Phase 12: writes `isRankable` to both docs.

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/adjusted_score_service.dart';
import '../../../core/services/freshness_service.dart';
import '../../../models/place_aggregate_model.dart';
import '../../../models/rating_model.dart';

class AggregateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> onNewRating({
    required String placeId,
    required RatingModel rating,
  }) async {
    if (!rating.isPublished) return;

    final aggRef = _firestore.collection('place_aggregates').doc(placeId);
    final placeRef = _firestore.collection('places').doc(placeId);

    await _firestore.runTransaction((tx) async {
      final aggSnap = await tx.get(aggRef);
      final placeSnap = await tx.get(placeRef);

      final categoryId = placeSnap.data()?['categoryId']?.toString();
      final lambda = FreshnessService.lambdaForCategory(categoryId);
      final confidence = AdjustedScoreService.confidenceForCategory(categoryId);
      final now = DateTime.now();

      double sumWeight = 0.0;
      double sumWeightedOverall = 0.0;
      double sumWeightedOverallSquared = 0.0;
      double effectiveWeight = 0.0;
      double sumWeightedOverallEffective = 0.0;
      double sumWeightedOverallSquaredEffective = 0.0;
      int totalRatings = 0;
      final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      final Map<String, double> dimensionSums = {};
      final Map<String, double> dimensionSumsEffective = {};
      DateTime? lastRecomputedAt;

      if (aggSnap.exists) {
        final data = aggSnap.data()!;
        sumWeight = (data['sumWeight'] as num?)?.toDouble() ?? 0.0;
        sumWeightedOverall =
            (data['sumWeightedOverall'] as num?)?.toDouble() ?? 0.0;
        sumWeightedOverallSquared =
            (data['sumWeightedOverallSquared'] as num?)?.toDouble() ?? 0.0;
        effectiveWeight =
            (data['effectiveWeight'] as num?)?.toDouble() ?? sumWeight;
        sumWeightedOverallEffective =
            (data['sumWeightedOverallEffective'] as num?)?.toDouble() ??
                sumWeightedOverall;
        sumWeightedOverallSquaredEffective =
            (data['sumWeightedOverallSquaredEffective'] as num?)?.toDouble() ??
                sumWeightedOverallSquared;
        totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;

        final distRaw = data['distribution'] as Map<String, dynamic>?;
        if (distRaw != null) {
          distRaw.forEach((k, v) {
            final key = int.tryParse(k);
            if (key != null && v is num) dist[key] = v.toInt();
          });
        }
        final dsRaw = data['dimensionSums'] as Map<String, dynamic>?;
        if (dsRaw != null) {
          dsRaw.forEach((k, v) {
            if (v is num) dimensionSums[k] = v.toDouble();
          });
        }
        final dseRaw = data['dimensionSumsEffective'] as Map<String, dynamic>?;
        if (dseRaw != null) {
          dseRaw.forEach((k, v) {
            if (v is num) dimensionSumsEffective[k] = v.toDouble();
          });
        } else {
          dimensionSumsEffective.addAll(dimensionSums);
        }
        lastRecomputedAt = _parseDate(data['lastRecomputedAt']);
      }

      if (lastRecomputedAt != null) {
        final daysSince =
            now.difference(lastRecomputedAt).inSeconds.toDouble() / 86400.0;
        if (daysSince > 0 && lambda > 0) {
          final decayFactor = math.exp(-lambda * daysSince);
          effectiveWeight *= decayFactor;
          sumWeightedOverallEffective *= decayFactor;
          sumWeightedOverallSquaredEffective *= decayFactor;
          dimensionSumsEffective.updateAll((k, v) => v * decayFactor);
        }
      }

      final w = rating.trustWeight;
      // ✅ Phase 8: aggregation uses effectiveScore (baseScore ?? overall)
      final s = rating.effectiveScore;
      sumWeight += w;
      sumWeightedOverall += w * s;
      sumWeightedOverallSquared += w * s * s;
      effectiveWeight += w;
      sumWeightedOverallEffective += w * s;
      sumWeightedOverallSquaredEffective += w * s * s;
      totalRatings += 1;
      // Distribution يبقى على overall (int 1-5) — هذا هو تقييم المستخدم النجمي الخام
      dist[rating.overall] = (dist[rating.overall] ?? 0) + 1;
      rating.dimensions.forEach((key, score) {
        dimensionSums[key] = (dimensionSums[key] ?? 0.0) + (w * score);
        dimensionSumsEffective[key] =
            (dimensionSumsEffective[key] ?? 0.0) + (w * score);
      });

      _writeAggregate(
        tx: tx,
        aggRef: aggRef,
        placeRef: placeRef,
        sumWeight: sumWeight,
        sumWeightedOverall: sumWeightedOverall,
        sumWeightedOverallSquared: sumWeightedOverallSquared,
        effectiveWeight: effectiveWeight,
        sumWeightedOverallEffective: sumWeightedOverallEffective,
        sumWeightedOverallSquaredEffective: sumWeightedOverallSquaredEffective,
        totalRatings: totalRatings,
        dist: dist,
        dimensionSums: dimensionSums,
        dimensionSumsEffective: dimensionSumsEffective,
        confidence: confidence,
      );
    });
  }

  Future<void> onRatingUpdated({
    required String placeId,
    required RatingModel oldRating,
    required RatingModel newRating,
  }) async {
    final aggRef = _firestore.collection('place_aggregates').doc(placeId);
    final placeRef = _firestore.collection('places').doc(placeId);

    await _firestore.runTransaction((tx) async {
      final aggSnap = await tx.get(aggRef);
      final placeSnap = await tx.get(placeRef);

      final categoryId = placeSnap.data()?['categoryId']?.toString();
      final lambda = FreshnessService.lambdaForCategory(categoryId);
      final confidence = AdjustedScoreService.confidenceForCategory(categoryId);
      final now = DateTime.now();

      double sumWeight = 0.0;
      double sumWeightedOverall = 0.0;
      double sumWeightedOverallSquared = 0.0;
      double effectiveWeight = 0.0;
      double sumWeightedOverallEffective = 0.0;
      double sumWeightedOverallSquaredEffective = 0.0;
      int totalRatings = 0;
      final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      final Map<String, double> dimensionSums = {};
      final Map<String, double> dimensionSumsEffective = {};
      DateTime? lastRecomputedAt;

      if (aggSnap.exists) {
        final data = aggSnap.data()!;
        sumWeight = (data['sumWeight'] as num?)?.toDouble() ?? 0.0;
        sumWeightedOverall =
            (data['sumWeightedOverall'] as num?)?.toDouble() ?? 0.0;
        sumWeightedOverallSquared =
            (data['sumWeightedOverallSquared'] as num?)?.toDouble() ?? 0.0;
        effectiveWeight =
            (data['effectiveWeight'] as num?)?.toDouble() ?? sumWeight;
        sumWeightedOverallEffective =
            (data['sumWeightedOverallEffective'] as num?)?.toDouble() ??
                sumWeightedOverall;
        sumWeightedOverallSquaredEffective =
            (data['sumWeightedOverallSquaredEffective'] as num?)?.toDouble() ??
                sumWeightedOverallSquared;
        totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;

        final distRaw = data['distribution'] as Map<String, dynamic>?;
        if (distRaw != null) {
          distRaw.forEach((k, v) {
            final key = int.tryParse(k);
            if (key != null && v is num) dist[key] = v.toInt();
          });
        }
        final dsRaw = data['dimensionSums'] as Map<String, dynamic>?;
        if (dsRaw != null) {
          dsRaw.forEach((k, v) {
            if (v is num) dimensionSums[k] = v.toDouble();
          });
        }
        final dseRaw = data['dimensionSumsEffective'] as Map<String, dynamic>?;
        if (dseRaw != null) {
          dseRaw.forEach((k, v) {
            if (v is num) dimensionSumsEffective[k] = v.toDouble();
          });
        } else {
          dimensionSumsEffective.addAll(dimensionSums);
        }
        lastRecomputedAt = _parseDate(data['lastRecomputedAt']);
      }

      if (lastRecomputedAt != null) {
        final daysSince =
            now.difference(lastRecomputedAt).inSeconds.toDouble() / 86400.0;
        if (daysSince > 0 && lambda > 0) {
          final decayFactor = math.exp(-lambda * daysSince);
          effectiveWeight *= decayFactor;
          sumWeightedOverallEffective *= decayFactor;
          sumWeightedOverallSquaredEffective *= decayFactor;
          dimensionSumsEffective.updateAll((k, v) => v * decayFactor);
        }
      }

      final wOld = oldRating.trustWeight;
      final sOld = oldRating.effectiveScore;
      sumWeight -= wOld;
      sumWeightedOverall -= wOld * sOld;
      sumWeightedOverallSquared -= wOld * sOld * sOld;
      effectiveWeight -= wOld;
      sumWeightedOverallEffective -= wOld * sOld;
      sumWeightedOverallSquaredEffective -= wOld * sOld * sOld;
      totalRatings -= 1;
      // Distribution يبقى على overall
      dist[oldRating.overall] = (dist[oldRating.overall] ?? 1) - 1;
      if ((dist[oldRating.overall] ?? 0) < 0) dist[oldRating.overall] = 0;
      oldRating.dimensions.forEach((key, score) {
        dimensionSums[key] = (dimensionSums[key] ?? 0.0) - (wOld * score);
        if ((dimensionSums[key] ?? 0) < 0) dimensionSums[key] = 0.0;
        dimensionSumsEffective[key] =
            (dimensionSumsEffective[key] ?? 0.0) - (wOld * score);
        if ((dimensionSumsEffective[key] ?? 0) < 0) {
          dimensionSumsEffective[key] = 0.0;
        }
      });

      final wNew = newRating.trustWeight;
      final sNew = newRating.effectiveScore;
      sumWeight += wNew;
      sumWeightedOverall += wNew * sNew;
      sumWeightedOverallSquared += wNew * sNew * sNew;
      effectiveWeight += wNew;
      sumWeightedOverallEffective += wNew * sNew;
      sumWeightedOverallSquaredEffective += wNew * sNew * sNew;
      totalRatings += 1;
      // Distribution يبقى على overall
      dist[newRating.overall] = (dist[newRating.overall] ?? 0) + 1;
      newRating.dimensions.forEach((key, score) {
        dimensionSums[key] = (dimensionSums[key] ?? 0.0) + (wNew * score);
        dimensionSumsEffective[key] =
            (dimensionSumsEffective[key] ?? 0.0) + (wNew * score);
      });

      if (sumWeight < 0) sumWeight = 0;
      if (effectiveWeight < 0) effectiveWeight = 0;
      if (totalRatings < 0) totalRatings = 0;

      _writeAggregate(
        tx: tx,
        aggRef: aggRef,
        placeRef: placeRef,
        sumWeight: sumWeight,
        sumWeightedOverall: sumWeightedOverall,
        sumWeightedOverallSquared: sumWeightedOverallSquared,
        effectiveWeight: effectiveWeight,
        sumWeightedOverallEffective: sumWeightedOverallEffective,
        sumWeightedOverallSquaredEffective: sumWeightedOverallSquaredEffective,
        totalRatings: totalRatings,
        dist: dist,
        dimensionSums: dimensionSums,
        dimensionSumsEffective: dimensionSumsEffective,
        confidence: confidence,
      );
    });
  }

  Future<void> onRatingRemoved({
    required String placeId,
    required RatingModel rating,
  }) async {
    final aggRef = _firestore.collection('place_aggregates').doc(placeId);
    final placeRef = _firestore.collection('places').doc(placeId);

    await _firestore.runTransaction((tx) async {
      final aggSnap = await tx.get(aggRef);
      if (!aggSnap.exists) return;
      final placeSnap = await tx.get(placeRef);

      final categoryId = placeSnap.data()?['categoryId']?.toString();
      final lambda = FreshnessService.lambdaForCategory(categoryId);
      final confidence = AdjustedScoreService.confidenceForCategory(categoryId);
      final now = DateTime.now();

      final data = aggSnap.data()!;
      final w = rating.trustWeight;
      // ✅ Phase 8: effectiveScore
      final s = rating.effectiveScore;

      double sumWeight = (data['sumWeight'] as num?)?.toDouble() ?? 0.0;
      double sumWeightedOverall =
          (data['sumWeightedOverall'] as num?)?.toDouble() ?? 0.0;
      double sumWeightedOverallSquared =
          (data['sumWeightedOverallSquared'] as num?)?.toDouble() ?? 0.0;
      double effectiveWeight =
          (data['effectiveWeight'] as num?)?.toDouble() ?? sumWeight;
      double sumWeightedOverallEffective =
          (data['sumWeightedOverallEffective'] as num?)?.toDouble() ??
              sumWeightedOverall;
      double sumWeightedOverallSquaredEffective =
          (data['sumWeightedOverallSquaredEffective'] as num?)?.toDouble() ??
              sumWeightedOverallSquared;
      int totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;

      final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      final distRaw = data['distribution'] as Map<String, dynamic>?;
      if (distRaw != null) {
        distRaw.forEach((k, v) {
          final key = int.tryParse(k);
          if (key != null && v is num) dist[key] = v.toInt();
        });
      }

      final Map<String, double> dimensionSums = {};
      final dsRaw = data['dimensionSums'] as Map<String, dynamic>?;
      if (dsRaw != null) {
        dsRaw.forEach((k, v) {
          if (v is num) dimensionSums[k] = v.toDouble();
        });
      }
      final Map<String, double> dimensionSumsEffective = {};
      final dseRaw = data['dimensionSumsEffective'] as Map<String, dynamic>?;
      if (dseRaw != null) {
        dseRaw.forEach((k, v) {
          if (v is num) dimensionSumsEffective[k] = v.toDouble();
        });
      } else {
        dimensionSumsEffective.addAll(dimensionSums);
      }

      final lastRecomputedAt = _parseDate(data['lastRecomputedAt']);
      if (lastRecomputedAt != null) {
        final daysSince =
            now.difference(lastRecomputedAt).inSeconds.toDouble() / 86400.0;
        if (daysSince > 0 && lambda > 0) {
          final decayFactor = math.exp(-lambda * daysSince);
          effectiveWeight *= decayFactor;
          sumWeightedOverallEffective *= decayFactor;
          sumWeightedOverallSquaredEffective *= decayFactor;
          dimensionSumsEffective.updateAll((k, v) => v * decayFactor);
        }
      }

      sumWeight -= w;
      sumWeightedOverall -= w * s;
      sumWeightedOverallSquared -= w * s * s;
      effectiveWeight -= w;
      sumWeightedOverallEffective -= w * s;
      sumWeightedOverallSquaredEffective -= w * s * s;
      totalRatings -= 1;

      if (sumWeight < 0) sumWeight = 0;
      if (effectiveWeight < 0) effectiveWeight = 0;
      if (totalRatings < 0) totalRatings = 0;

      // Distribution يبقى على overall
      dist[rating.overall] = (dist[rating.overall] ?? 1) - 1;
      if ((dist[rating.overall] ?? 0) < 0) dist[rating.overall] = 0;

      rating.dimensions.forEach((key, score) {
        dimensionSums[key] = (dimensionSums[key] ?? 0.0) - (w * score);
        if ((dimensionSums[key] ?? 0) < 0) dimensionSums[key] = 0.0;
        dimensionSumsEffective[key] =
            (dimensionSumsEffective[key] ?? 0.0) - (w * score);
        if ((dimensionSumsEffective[key] ?? 0) < 0) {
          dimensionSumsEffective[key] = 0.0;
        }
      });

      _writeAggregate(
        tx: tx,
        aggRef: aggRef,
        placeRef: placeRef,
        sumWeight: sumWeight,
        sumWeightedOverall: sumWeightedOverall,
        sumWeightedOverallSquared: sumWeightedOverallSquared,
        effectiveWeight: effectiveWeight,
        sumWeightedOverallEffective: sumWeightedOverallEffective,
        sumWeightedOverallSquaredEffective: sumWeightedOverallSquaredEffective,
        totalRatings: totalRatings,
        dist: dist,
        dimensionSums: dimensionSums,
        dimensionSumsEffective: dimensionSumsEffective,
        confidence: confidence,
      );
    });
  }

  void _writeAggregate({
    required Transaction tx,
    required DocumentReference aggRef,
    required DocumentReference placeRef,
    required double sumWeight,
    required double sumWeightedOverall,
    required double sumWeightedOverallSquared,
    required double effectiveWeight,
    required double sumWeightedOverallEffective,
    required double sumWeightedOverallSquaredEffective,
    required int totalRatings,
    required Map<int, int> dist,
    required Map<String, double> dimensionSums,
    required Map<String, double> dimensionSumsEffective,
    required double confidence,
  }) {
    final avgO = sumWeight > 0 ? sumWeightedOverall / sumWeight : 0.0;
    final avgOSq = sumWeight > 0 ? sumWeightedOverallSquared / sumWeight : 0.0;
    double variance = avgOSq - (avgO * avgO);
    if (variance < 0) variance = 0;

    final currentQuality = effectiveWeight > 0
        ? sumWeightedOverallEffective / effectiveWeight
        : 0.0;
    final freshnessScore = sumWeight > 0 ? effectiveWeight / sumWeight : 0.0;

    final adjustedScore = AdjustedScoreService.computeAdjustedScore(
      weightedMean: currentQuality,
      effectiveWeight: effectiveWeight,
      confidence: confidence,
    );
    final sampleQuality = AdjustedScoreService.computeSampleQuality(
      effectiveWeight: effectiveWeight,
      confidence: confidence,
    );

    final isRankable =
        totalRatings >= AdjustedScoreService.minRatingsForRanking;

    final dimensionAverages = <String, double>{};
    dimensionSums.forEach((k, sum) {
      dimensionAverages[k] = sumWeight > 0 ? sum / sumWeight : 0.0;
    });
    final dimensionAveragesEffective = <String, double>{};
    dimensionSumsEffective.forEach((k, sum) {
      dimensionAveragesEffective[k] =
          effectiveWeight > 0 ? sum / effectiveWeight : 0.0;
    });

    tx.set(
      aggRef,
      {
        'totalRatings': totalRatings,
        'averageOverall': _round2(avgO),
        'ratingVariance': _round2(variance),
        'sumWeight': sumWeight,
        'sumWeightedOverall': sumWeightedOverall,
        'sumWeightedOverallSquared': sumWeightedOverallSquared,
        'effectiveWeight': effectiveWeight,
        'sumWeightedOverallEffective': sumWeightedOverallEffective,
        'sumWeightedOverallSquaredEffective':
            sumWeightedOverallSquaredEffective,
        'dimensionSums': dimensionSums,
        'dimensionSumsEffective': dimensionSumsEffective,
        'dimensionAverages': dimensionAverages,
        'dimensionAveragesEffective': dimensionAveragesEffective,
        'distribution': {
          '1': dist[1] ?? 0,
          '2': dist[2] ?? 0,
          '3': dist[3] ?? 0,
          '4': dist[4] ?? 0,
          '5': dist[5] ?? 0,
        },
        'adjustedScore': _round2(adjustedScore),
        'sampleQuality': _round2(sampleQuality),
        'freshnessScore': _round2(freshnessScore),
        'isRankable': isRankable,
        'averageCleanliness': _round2(dimensionAverages['cleanliness'] ?? 0.0),
        'averageService': _round2(dimensionAverages['service'] ?? 0.0),
        'averagePrice': _round2(dimensionAverages['price'] ?? 0.0),
        'averageAccess': _round2(dimensionAverages['access'] ?? 0.0),
        'sumWeightedCleanliness': dimensionSums['cleanliness'] ?? 0.0,
        'sumWeightedService': dimensionSums['service'] ?? 0.0,
        'sumWeightedPrice': dimensionSums['price'] ?? 0.0,
        'sumWeightedAccess': dimensionSums['access'] ?? 0.0,
        'lastRecomputedAt': FieldValue.serverTimestamp(),
        'lastComputedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    tx.update(placeRef, {
      'averageRating': _round2(avgO),
      'reviewCount': totalRatings,
      'adjustedScore': _round2(adjustedScore),
      'sampleQuality': _round2(sampleQuality),
      'isRankable': isRankable,
    });
  }

  Future<PlaceAggregateModel> getAggregate(String placeId) async {
    final snap =
        await _firestore.collection('place_aggregates').doc(placeId).get();
    if (!snap.exists) return PlaceAggregateModel.empty(placeId);
    return PlaceAggregateModel.fromMap(placeId, snap.data() ?? {});
  }

  double _round2(double n) => (n * 100).roundToDouble() / 100;

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
