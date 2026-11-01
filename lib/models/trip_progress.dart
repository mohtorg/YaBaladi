// lib/models/trip_progress.dart
class TripProgress {
  final String tripId;
  final Set<String> visitedPlaceIds;
  final String? lastVisitedPlaceId;
  final DateTime lastUpdatedAt;

  const TripProgress({
    required this.tripId,
    this.visitedPlaceIds = const {},
    this.lastVisitedPlaceId,
    required this.lastUpdatedAt,
  });

  TripProgress copyWith({
    Set<String>? visitedPlaceIds,
    String? lastVisitedPlaceId,
    DateTime? lastUpdatedAt,
  }) =>
      TripProgress(
        tripId: tripId,
        visitedPlaceIds: visitedPlaceIds ?? this.visitedPlaceIds,
        lastVisitedPlaceId: lastVisitedPlaceId ?? this.lastVisitedPlaceId,
        lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      );

  Map<String, dynamic> toJson() => {
        'tripId': tripId,
        'visitedPlaceIds': visitedPlaceIds.toList(),
        'lastVisitedPlaceId': lastVisitedPlaceId,
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      };

  factory TripProgress.fromJson(Map<String, dynamic> json) => TripProgress(
        tripId: json['tripId'] as String,
        visitedPlaceIds:
            Set<String>.from(json['visitedPlaceIds'] as List? ?? []),
        lastVisitedPlaceId: json['lastVisitedPlaceId'] as String?,
        lastUpdatedAt: DateTime.tryParse(
              json['lastUpdatedAt'] as String? ?? '',
            ) ??
            DateTime.now(),
      );

  int visitedCountIn(Iterable<String> placeIds) =>
      placeIds.where(visitedPlaceIds.contains).length;

  bool isVisited(String placeId) => visitedPlaceIds.contains(placeId);

  @override
  String toString() =>
      'TripProgress($tripId, ${visitedPlaceIds.length} visited)';
}
