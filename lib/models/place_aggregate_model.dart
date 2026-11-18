// lib/models/place_aggregate_model.dart
// [v3.1 — 2026-11-15] — Phase 12: added `isRankable`.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/services/adjusted_score_service.dart';

class PlaceAggregateModel {
  final String placeId;
  final int totalRatings;
  final double averageOverall;
  final double ratingVariance;
  final double averageCleanliness;
  final double averageService;
  final double averagePrice;
  final double averageAccess;
  final Map<String, double> dimensionAverages;
  final double sumWeight;
  final double sumWeightedOverall;
  final double sumWeightedOverallSquared;
  final double effectiveWeight;
  final double freshnessScore;
  final double adjustedScore;
  final double sampleQuality;

  // ✅ Phase 12
  final bool isRankable;

  final DateTime? lastRecomputedAt;
  final Map<int, int> distribution;
  final DateTime? lastComputedAt;

  const PlaceAggregateModel({
    required this.placeId,
    required this.totalRatings,
    required this.averageOverall,
    required this.ratingVariance,
    required this.averageCleanliness,
    required this.averageService,
    required this.averagePrice,
    required this.averageAccess,
    required this.dimensionAverages,
    required this.sumWeight,
    required this.sumWeightedOverall,
    required this.sumWeightedOverallSquared,
    required this.effectiveWeight,
    required this.freshnessScore,
    required this.adjustedScore,
    required this.sampleQuality,
    required this.isRankable,
    this.lastRecomputedAt,
    required this.distribution,
    this.lastComputedAt,
  });

  factory PlaceAggregateModel.empty(String placeId) {
    return PlaceAggregateModel(
      placeId: placeId,
      totalRatings: 0,
      averageOverall: 0.0,
      ratingVariance: 0.0,
      averageCleanliness: 0.0,
      averageService: 0.0,
      averagePrice: 0.0,
      averageAccess: 0.0,
      dimensionAverages: const {},
      sumWeight: 0.0,
      sumWeightedOverall: 0.0,
      sumWeightedOverallSquared: 0.0,
      effectiveWeight: 0.0,
      freshnessScore: 0.0,
      adjustedScore: 0.0,
      sampleQuality: 0.0,
      isRankable: false,
      lastRecomputedAt: null,
      distribution: const {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
      lastComputedAt: null,
    );
  }

  factory PlaceAggregateModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return PlaceAggregateModel.fromMap(doc.id, doc.data() ?? {});
  }

  factory PlaceAggregateModel.fromMap(
      String placeId, Map<String, dynamic> data) {
    final Map<String, double> parsedDimensions = {};
    if (data['dimensionAverages'] != null && data['dimensionAverages'] is Map) {
      (data['dimensionAverages'] as Map).forEach((key, value) {
        if (value is num) parsedDimensions[key.toString()] = value.toDouble();
      });
    } else {
      if (data['averageCleanliness'] != null) {
        parsedDimensions['cleanliness'] =
            (data['averageCleanliness'] as num).toDouble();
      }
      if (data['averageService'] != null) {
        parsedDimensions['service'] =
            (data['averageService'] as num).toDouble();
      }
      if (data['averagePrice'] != null) {
        parsedDimensions['price'] = (data['averagePrice'] as num).toDouble();
      }
      if (data['averageAccess'] != null) {
        parsedDimensions['access'] = (data['averageAccess'] as num).toDouble();
      }
    }

    final Map<int, int> parsedDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final distRaw = data['distribution'] as Map<String, dynamic>?;
    if (distRaw != null) {
      distRaw.forEach((k, v) {
        final key = int.tryParse(k);
        if (key != null && v is num) parsedDist[key] = v.toInt();
      });
    }

    final totalRatings = (data['totalRatings'] as num?)?.toInt() ?? 0;
    final isRankable = (data['isRankable'] as bool?) ??
        (totalRatings >= AdjustedScoreService.minRatingsForRanking);

    return PlaceAggregateModel(
      placeId: placeId,
      totalRatings: totalRatings,
      averageOverall: (data['averageOverall'] as num?)?.toDouble() ?? 0.0,
      ratingVariance: (data['ratingVariance'] as num?)?.toDouble() ?? 0.0,
      averageCleanliness:
          (data['averageCleanliness'] as num?)?.toDouble() ?? 0.0,
      averageService: (data['averageService'] as num?)?.toDouble() ?? 0.0,
      averagePrice: (data['averagePrice'] as num?)?.toDouble() ?? 0.0,
      averageAccess: (data['averageAccess'] as num?)?.toDouble() ?? 0.0,
      dimensionAverages: parsedDimensions,
      sumWeight: (data['sumWeight'] as num?)?.toDouble() ?? 0.0,
      sumWeightedOverall:
          (data['sumWeightedOverall'] as num?)?.toDouble() ?? 0.0,
      sumWeightedOverallSquared:
          (data['sumWeightedOverallSquared'] as num?)?.toDouble() ?? 0.0,
      effectiveWeight: (data['effectiveWeight'] as num?)?.toDouble() ??
          ((data['sumWeight'] as num?)?.toDouble() ?? 0.0),
      freshnessScore: (data['freshnessScore'] as num?)?.toDouble() ?? 1.0,
      adjustedScore: (data['adjustedScore'] as num?)?.toDouble() ??
          (data['averageOverall'] as num?)?.toDouble() ??
          0.0,
      sampleQuality: (data['sampleQuality'] as num?)?.toDouble() ?? 0.0,
      isRankable: isRankable,
      lastRecomputedAt: _parseDate(data['lastRecomputedAt']),
      distribution: parsedDist,
      lastComputedAt: _parseDate(data['lastComputedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalRatings': totalRatings,
      'averageOverall': averageOverall,
      'ratingVariance': ratingVariance,
      'averageCleanliness': averageCleanliness,
      'averageService': averageService,
      'averagePrice': averagePrice,
      'averageAccess': averageAccess,
      'dimensionAverages': dimensionAverages,
      'sumWeight': sumWeight,
      'sumWeightedOverall': sumWeightedOverall,
      'sumWeightedOverallSquared': sumWeightedOverallSquared,
      'effectiveWeight': effectiveWeight,
      'freshnessScore': freshnessScore,
      'adjustedScore': adjustedScore,
      'sampleQuality': sampleQuality,
      'isRankable': isRankable,
      'lastRecomputedAt': lastRecomputedAt != null
          ? Timestamp.fromDate(lastRecomputedAt!)
          : null,
      'distribution': {
        '1': distribution[1] ?? 0,
        '2': distribution[2] ?? 0,
        '3': distribution[3] ?? 0,
        '4': distribution[4] ?? 0,
        '5': distribution[5] ?? 0,
      },
      'lastComputedAt':
          lastComputedAt != null ? Timestamp.fromDate(lastComputedAt!) : null,
    };
  }

  PlaceAggregateModel copyWith({
    String? placeId,
    int? totalRatings,
    double? averageOverall,
    double? ratingVariance,
    double? averageCleanliness,
    double? averageService,
    double? averagePrice,
    double? averageAccess,
    Map<String, double>? dimensionAverages,
    double? sumWeight,
    double? sumWeightedOverall,
    double? sumWeightedOverallSquared,
    double? effectiveWeight,
    double? freshnessScore,
    double? adjustedScore,
    double? sampleQuality,
    bool? isRankable,
    DateTime? lastRecomputedAt,
    Map<int, int>? distribution,
    DateTime? lastComputedAt,
  }) {
    return PlaceAggregateModel(
      placeId: placeId ?? this.placeId,
      totalRatings: totalRatings ?? this.totalRatings,
      averageOverall: averageOverall ?? this.averageOverall,
      ratingVariance: ratingVariance ?? this.ratingVariance,
      averageCleanliness: averageCleanliness ?? this.averageCleanliness,
      averageService: averageService ?? this.averageService,
      averagePrice: averagePrice ?? this.averagePrice,
      averageAccess: averageAccess ?? this.averageAccess,
      dimensionAverages: dimensionAverages ?? this.dimensionAverages,
      sumWeight: sumWeight ?? this.sumWeight,
      sumWeightedOverall: sumWeightedOverall ?? this.sumWeightedOverall,
      sumWeightedOverallSquared:
          sumWeightedOverallSquared ?? this.sumWeightedOverallSquared,
      effectiveWeight: effectiveWeight ?? this.effectiveWeight,
      freshnessScore: freshnessScore ?? this.freshnessScore,
      adjustedScore: adjustedScore ?? this.adjustedScore,
      sampleQuality: sampleQuality ?? this.sampleQuality,
      isRankable: isRankable ?? this.isRankable,
      lastRecomputedAt: lastRecomputedAt ?? this.lastRecomputedAt,
      distribution: distribution ?? this.distribution,
      lastComputedAt: lastComputedAt ?? this.lastComputedAt,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
}
