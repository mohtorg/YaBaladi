// lib/models/trip_progress.dart
//
// [v1.2 - HARDENED] - Minor safety improvements:
//   - IMPROVED: Empty strings for lastVisitedPlaceId are normalized to null.
//   - ADDED: Dart doc comments for better IDE hints.
//   - KEPT: All v1.1 fixes (dual serialization paths, safe JSON).

import 'package:cloud_firestore/cloud_firestore.dart';

class TripProgress {
  final String tripId;
  final Set<String> visitedPlaceIds;
  final String? lastVisitedPlaceId;
  final DateTime lastUpdatedAt;

  const TripProgress({
    required this.tripId,
    required this.visitedPlaceIds,
    this.lastVisitedPlaceId,
    required this.lastUpdatedAt,
  });

  // ═══════════════════════════════════════════════════════════════
  // FIRESTORE — fromMap / toMap  (Timestamp-based)
  // ═══════════════════════════════════════════════════════════════

  /// Creates a TripProgress from a Firestore document map.
  /// [tripId] is passed explicitly because it's the doc ID.
  factory TripProgress.fromMap(String tripId, Map<String, dynamic> map) {
    final rawVisited = map['visitedPlaceIds'];
    final visited = rawVisited is List
        ? Set<String>.from(rawVisited.whereType<String>())
        : <String>{};

    final lastVisited = map['lastVisitedPlaceId'] as String?;

    return TripProgress(
      tripId: tripId,
      visitedPlaceIds: visited,
      lastVisitedPlaceId:
          (lastVisited != null && lastVisited.isNotEmpty) ? lastVisited : null,
      lastUpdatedAt:
          (map['lastUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'visitedPlaceIds': visitedPlaceIds.toList(),
        if (lastVisitedPlaceId != null && lastVisitedPlaceId!.isNotEmpty)
          'lastVisitedPlaceId': lastVisitedPlaceId,
        'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      };

  // ═══════════════════════════════════════════════════════════════
  // LOCAL — fromJson / toJson  (JSON-safe, no Firestore types)
  // ═══════════════════════════════════════════════════════════════

  /// Creates a TripProgress from a local JSON map (SharedPreferences).
  /// Throws [FormatException] if `tripId` is missing.
  factory TripProgress.fromJson(Map<String, dynamic> json) {
    final rawTripId = json['tripId'];
    if (rawTripId is! String || rawTripId.isEmpty) {
      throw const FormatException(
        'TripProgress.fromJson: missing or empty "tripId"',
      );
    }

    final rawVisited = json['visitedPlaceIds'];
    final visited = rawVisited is List
        ? Set<String>.from(rawVisited.whereType<String>())
        : <String>{};

    final lastVisited = json['lastVisitedPlaceId'] as String?;

    final rawUpdated = json['lastUpdatedAt'];
    DateTime updated;
    if (rawUpdated is int) {
      updated = DateTime.fromMillisecondsSinceEpoch(rawUpdated, isUtc: true)
          .toLocal();
    } else if (rawUpdated is String) {
      updated = DateTime.tryParse(rawUpdated)?.toLocal() ?? DateTime.now();
    } else {
      updated = DateTime.now();
    }

    return TripProgress(
      tripId: rawTripId,
      visitedPlaceIds: visited,
      lastVisitedPlaceId:
          (lastVisited != null && lastVisited.isNotEmpty) ? lastVisited : null,
      lastUpdatedAt: updated,
    );
  }

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'visitedPlaceIds': visitedPlaceIds.toList(),
        if (lastVisitedPlaceId != null && lastVisitedPlaceId!.isNotEmpty)
          'lastVisitedPlaceId': lastVisitedPlaceId,
        'lastUpdatedAt': lastUpdatedAt.toUtc().millisecondsSinceEpoch,
      };
}
