// lib/core/services/aggregate_recompute_service.dart
// [v1.1 — 2026-11-15] — Phase 12: writes `isRankable`.

import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../services/adjusted_score_service.dart';
import '../services/freshness_service.dart';

class RecomputeResult {
  final int processed;
  final int failed;
  final int skipped;
  final Duration elapsed;

  const RecomputeResult({
    required this.processed,
    required this.failed,
    required this.skipped,
    required this.elapsed,
  });
}

class AggregateRecomputeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> recomputePlace({
    required String placeId,
    DateTime? now,
  }) async {
    final reference = now ?? DateTime.now();

    final ratingsSnap = await _firestore
        .collection('ratings')
        .where('placeId', isEqualTo: placeId)
        .where('status', isEqualTo: 'PUBLISHED')
        .get();

    final ratings = ratingsSnap.docs;

    final placeRef = _firestore.collection('places').doc(placeId);
    final placeSnap = await placeRef.get();
    if (!placeSnap.exists) {
      throw 'المكان غير موجود: $placeId';
    }
    final placeData = placeSnap.data() ?? {};
    final categoryId = placeData['categoryId']?.toString();

    final lambda = FreshnessService.lambdaForCategory(categoryId);
    final confidence = AdjustedScoreService.confidenceForCategory(categoryId);

    double sumWeight = 0.0;
    double sumWeightedOverall = 0.0;
    double sumWeightedOverallSquared = 0.0;
    double effectiveWeight = 0.0;
    double sumWeightedOverallEffective = 0.0;
    double sumWeightedOverallSquaredEffective = 0.0;
    final Map<int, int> dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final Map<String, double> dimensionSums = {};
    final Map<String, double> dimensionSumsEffective = {};

    for (final ratingDoc in ratings) {
      final r = ratingDoc.data();
      final w = (r['trustWeight'] as num?)?.toDouble() ?? 1.0;
      final overall = (r['overall'] as num?)?.toInt() ?? 0;
      if (overall < 1 || overall > 5) continue;

      final createdAt = r['createdAt'];
      DateTime? created;
      if (createdAt is Timestamp) {
        created = createdAt.toDate();
      } else if (createdAt is DateTime) {
        created = createdAt;
      }
      final ageDays = created != null
          ? reference.difference(created).inSeconds.toDouble() / 86400.0
          : 0.0;

      final freshness = ageDays <= 0 ? 1.0 : math.exp(-lambda * ageDays);

      sumWeight += w;
      sumWeightedOverall += w * overall;
      sumWeightedOverallSquared += w * overall * overall;

      final wEff = w * freshness;
      effectiveWeight += wEff;
      sumWeightedOverallEffective += wEff * overall;
      sumWeightedOverallSquaredEffective += wEff * overall * overall;

      dist[overall] = (dist[overall] ?? 0) + 1;

      final dims = r['dimensions'];
      if (dims is Map) {
        dims.forEach((key, value) {
          if (value is num) {
            final k = key.toString();
            dimensionSums[k] = (dimensionSums[k] ?? 0.0) + (w * value);
            dimensionSumsEffective[k] =
                (dimensionSumsEffective[k] ?? 0.0) + (wEff * value);
          }
        });
      }
    }

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

    // ✅ Phase 12
    final isRankable =
        ratings.length >= AdjustedScoreService.minRatingsForRanking;

    final dimensionAverages = <String, double>{};
    dimensionSums.forEach((k, sum) {
      dimensionAverages[k] = sumWeight > 0 ? sum / sumWeight : 0.0;
    });
    final dimensionAveragesEffective = <String, double>{};
    dimensionSumsEffective.forEach((k, sum) {
      dimensionAveragesEffective[k] =
          effectiveWeight > 0 ? sum / effectiveWeight : 0.0;
    });

    final aggRef = _firestore.collection('place_aggregates').doc(placeId);
    await _firestore.runTransaction((tx) async {
      tx.set(
        aggRef,
        {
          'totalRatings': ratings.length,
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
          'averageCleanliness':
              _round2(dimensionAverages['cleanliness'] ?? 0.0),
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
        'reviewCount': ratings.length,
        'adjustedScore': _round2(adjustedScore),
        'sampleQuality': _round2(sampleQuality),
        'isRankable': isRankable,
      });
    });
  }

  Future<RecomputeResult> recomputeAll({
    int batchSize = 10,
    void Function(int processed, int total)? onProgress,
  }) async {
    final started = DateTime.now();

    final placesSnap = await _firestore.collection('places').get();
    final placeIds = placesSnap.docs.map((d) => d.id).toList();
    final total = placeIds.length;

    int processed = 0;
    int failed = 0;
    int skipped = 0;

    for (var i = 0; i < placeIds.length; i += batchSize) {
      final batch = placeIds.skip(i).take(batchSize).toList();

      for (final placeId in batch) {
        try {
          final ratingsCountSnap = await _firestore
              .collection('ratings')
              .where('placeId', isEqualTo: placeId)
              .where('status', isEqualTo: 'PUBLISHED')
              .count()
              .get();

          final count = ratingsCountSnap.count ?? 0;
          if (count == 0) {
            skipped++;
            continue;
          }

          await recomputePlace(placeId: placeId);
          processed++;
        } catch (e) {
          debugPrint('⚠️ Recompute failed for $placeId: $e');
          failed++;
        }
      }

      onProgress?.call(processed + failed + skipped, total);
    }

    final elapsed = DateTime.now().difference(started);

    return RecomputeResult(
      processed: processed,
      failed: failed,
      skipped: skipped,
      elapsed: elapsed,
    );
  }

  double _round2(double n) => (n * 100).roundToDouble() / 100;
}
