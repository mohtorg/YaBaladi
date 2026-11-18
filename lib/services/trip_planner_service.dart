// lib/services/trip_planner_service.dart
//
// [v1.5 - LOCATION SAFETY + CLARITY]
//   - FIXED (CRITICAL): Places without coordinates were given the BEST
//     proximity score (distance fallback to startLat/startLng → distance=0
//     → proximityScore=1.0). Now they are excluded in _filterCandidates.
//   - IMPROVED: _haversineKm now computes rad(lat1), rad(lat2) once each.
//   - DOCUMENTED: Priority boost affects SELECTION, not ordering; the
//     final order is always nearest-neighbor optimized.
//   - DOCUMENTED: _estimateTimes starts at 9:00 AM on today as a provisional
//     estimate; the actual date range is set later by the user.
//   - KEPT: All scoring weights, category durations, tie-breaking, and the
//     exact public API signature.

import 'dart:math' as math;

import '../core/location/egypt_governorates.dart';
import '../models/companion_type.dart';
import '../models/place.dart';
import '../models/place_categories.dart';
import '../models/trip_plan.dart';

class TripPlannerService {
  TripPlannerService._();

  static const double _ratingWeight = 0.6;
  static const double _proximityWeight = 0.4;
  static const double _proximityRadiusKm = 10.0;

  /// Generates a draft trip plan.
  ///
  /// Pipeline:
  ///   filter → rank → select → optimize route → estimate times → totals
  ///
  /// Priority semantics:
  ///   [priorityPlaceIds] heavily boosts the candidate's rank score,
  ///   ensuring it gets SELECTED. The final ORDER of stops is always
  ///   nearest-neighbor optimized, regardless of priority.
  static TripPlan generateTrip({
    required List<Place> allPlaces,
    required String governorateId,
    required TripDurationType durationType,
    required Set<String> interests,
    required TripTransportMode transportMode,
    required double startLat,
    required double startLng,
    String userId = 'guest',
    CompanionType companion = CompanionType.family,
    Set<String> priorityPlaceIds = const {},
  }) {
    final governorate = governorateById(governorateId) ?? kDefaultGovernorate;

    final candidates = _filterCandidates(
      allPlaces: allPlaces,
      governorateNameAr: governorate.nameAr,
      interests: interests,
    );

    final ranked = _rankCandidates(
      candidates: candidates,
      startLat: startLat,
      startLng: startLng,
      companion: companion,
      priorityPlaceIds: priorityPlaceIds,
    );

    final selected = _selectStops(
      ranked: ranked,
      durationType: durationType,
      companion: companion,
    );

    final optimized = _optimizeRoute(
      places: selected,
      startLat: startLat,
      startLng: startLng,
    );

    final stops = _estimateTimes(
      places: optimized,
      startLat: startLat,
      startLng: startLng,
      transportMode: transportMode,
    );

    final totalDistance = _totalDistance(
      stops: stops,
      startLat: startLat,
      startLng: startLng,
    );
    final totalDuration = stops.fold<int>(
          0,
          (acc, s) => acc + (s.plannedDurationMin ?? 0),
        ) +
        _totalTravelTime(
          stops: stops,
          startLat: startLat,
          startLng: startLng,
          transportMode: transportMode,
        );

    return TripPlan(
      id: '',
      userId: userId,
      title: _generateTitle(governorate.nameAr, durationType),
      governorateId: governorateId,
      governorateNameAr: governorate.nameAr,
      transportMode: transportMode,
      durationType: durationType,
      interests: interests.toList(),
      status: TripStatus.draft,
      stops: stops,
      totalDistanceKm: totalDistance,
      totalDurationMin: totalDuration,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FILTER
  // ═══════════════════════════════════════════════════════════════

  static Set<String> _placeCategorySet(Place place) {
    final raw = place.categories.isNotEmpty
        ? place.categories
        : (place.categoryId.isNotEmpty ? [place.categoryId] : <String>[]);
    return raw.map(PlaceCategories.normalizeId).toSet();
  }

  static Set<String> _normalizeSet(Set<String> raw) =>
      raw.map(PlaceCategories.normalizeId).toSet();

  static Set<String> _normalizeList(List<String> raw) =>
      raw.map(PlaceCategories.normalizeId).toSet();

  static List<Place> _filterCandidates({
    required List<Place> allPlaces,
    required String governorateNameAr,
    required Set<String> interests,
  }) {
    bool matchesGov(String placeGov, String targetGov) {
      final pg = placeGov.trim().toLowerCase();
      final tg = targetGov.trim().toLowerCase();
      if (pg == tg) return true;
      if (tg == 'بورسعيد' &&
          (pg == 'portsaid' || pg == 'port said' || pg == 'port_said')) {
        return true;
      }
      if (tg == 'القاهرة' && pg == 'cairo') return true;
      return false;
    }

    var list = allPlaces
        .where((p) => matchesGov(p.governorate, governorateNameAr))
        // ✅ Exclude places without valid coordinates. Otherwise they'd
        //    fall back to startLat/startLng downstream, causing distance=0
        //    and a falsely perfect proximity score.
        .where((p) => p.location != null)
        .toList();

    if (interests.isNotEmpty) {
      final normalizedInterests = _normalizeSet(interests);

      list = list.where((p) {
        final placeCats = _placeCategorySet(p);
        return placeCats.intersection(normalizedInterests).isNotEmpty;
      }).toList();
    }

    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // RANK
  // ═══════════════════════════════════════════════════════════════

  static List<Place> _rankCandidates({
    required List<Place> candidates,
    required double startLat,
    required double startLng,
    required CompanionType companion,
    Set<String> priorityPlaceIds = const {},
  }) {
    final preferred = _normalizeList(companion.preferredCategories);
    final avoided = _normalizeList(companion.avoidedCategories);

    final scored = candidates.map((p) {
      final ratingScore = (p.averageRating / 5.0).clamp(0.0, 1.0);

      // Safe cast — candidates already filtered to have non-null location.
      final pLat = p.location!.latitude;
      final pLng = p.location!.longitude;
      final distance = _haversineKm(startLat, startLng, pLat, pLng);
      final proximityScore = 1.0 / (1.0 + distance / _proximityRadiusKm);

      var score =
          ratingScore * _ratingWeight + proximityScore * _proximityWeight;

      final placeCats = _placeCategorySet(p);

      if (placeCats.intersection(preferred).isNotEmpty) {
        score *= 1.3;
      }
      if (placeCats.intersection(avoided).isNotEmpty) {
        score *= 0.7;
      }

      // Priority boost for user-selected bag items.
      if (priorityPlaceIds.contains(p.id)) {
        score *= 5.0;
      }

      return _ScoredPlace(place: p, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.place).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // SELECT
  // ═══════════════════════════════════════════════════════════════

  static List<Place> _selectStops({
    required List<Place> ranked,
    required TripDurationType durationType,
    required CompanionType companion,
  }) {
    final maxStops = durationType.maxStops;
    if (ranked.length <= maxStops) return ranked;

    final preferred = _normalizeList(companion.preferredCategories);
    final avoided = _normalizeList(companion.avoidedCategories);

    final preferredList = <Place>[];
    final neutralList = <Place>[];
    final avoidedList = <Place>[];

    for (final p in ranked) {
      final cats = _placeCategorySet(p);
      if (cats.intersection(preferred).isNotEmpty) {
        preferredList.add(p);
      } else if (cats.intersection(avoided).isNotEmpty) {
        avoidedList.add(p);
      } else {
        neutralList.add(p);
      }
    }

    final selected = <Place>[];
    final usedIds = <String>{};

    for (final p in preferredList) {
      if (selected.length >= maxStops) break;
      if (usedIds.add(p.id)) selected.add(p);
    }

    for (final p in neutralList) {
      if (selected.length >= maxStops) break;
      if (usedIds.add(p.id)) selected.add(p);
    }

    for (final p in avoidedList) {
      if (selected.length >= maxStops) break;
      if (usedIds.add(p.id)) selected.add(p);
    }

    // Preserve original ranked order.
    final rankIndex = <String, int>{};
    for (var i = 0; i < ranked.length; i++) {
      rankIndex[ranked[i].id] = i;
    }
    selected
        .sort((a, b) => (rankIndex[a.id] ?? 0).compareTo(rankIndex[b.id] ?? 0));
    return selected;
  }

  // ═══════════════════════════════════════════════════════════════
  // OPTIMIZE ROUTE (Greedy nearest-neighbor)
  // ═══════════════════════════════════════════════════════════════

  /// Greedy nearest-neighbor reordering from the start point.
  /// For ≤ 8 stops this is fast and good enough. Optimal TSP requires
  /// brute force (n!) or 2-opt heuristics — overkill for this use case.
  static List<Place> _optimizeRoute({
    required List<Place> places,
    required double startLat,
    required double startLng,
  }) {
    if (places.length <= 1) return places;

    final remaining = List<Place>.from(places);
    final result = <Place>[];

    var curLat = startLat;
    var curLng = startLng;

    while (remaining.isNotEmpty) {
      var nearestIdx = 0;
      var nearestDist = double.infinity;

      for (var i = 0; i < remaining.length; i++) {
        final p = remaining[i];
        final pLat = p.location!.latitude;
        final pLng = p.location!.longitude;
        final d = _haversineKm(curLat, curLng, pLat, pLng);

        if (d < nearestDist) {
          nearestDist = d;
          nearestIdx = i;
        }
      }

      final next = remaining.removeAt(nearestIdx);
      result.add(next);
      curLat = next.location!.latitude;
      curLng = next.location!.longitude;
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // ESTIMATE TIMES
  // ═══════════════════════════════════════════════════════════════

  /// Provisional time estimates.
  ///
  /// Starts at **9:00 AM today** as a reasonable default. The actual date
  /// range is picked by the user in the Save step and stored separately
  /// in `TripPlan.startDate/endDate`. Times here are relative and only
  /// used for display order.
  static List<TripStop> _estimateTimes({
    required List<Place> places,
    required double startLat,
    required double startLng,
    required TripTransportMode transportMode,
  }) {
    final stops = <TripStop>[];
    final startTime = DateTime.now();
    var currentTime =
        DateTime(startTime.year, startTime.month, startTime.day, 9, 0);

    var curLat = startLat;
    var curLng = startLng;

    for (final place in places) {
      final pLat = place.location!.latitude;
      final pLng = place.location!.longitude;

      final travelKm = _haversineKm(curLat, curLng, pLat, pLng);
      final travelMin = (travelKm / transportMode.speedKmH * 60).round();
      currentTime = currentTime.add(Duration(minutes: travelMin));

      final primaryCategory = place.categories.isNotEmpty
          ? place.categories.first
          : place.categoryId;
      final visitDuration = _visitDurationForCategory(primaryCategory);

      stops.add(TripStop(
        placeId: place.id,
        placeNameAr: place.nameAr,
        placeNameEn: place.nameEn,
        placeImageUrl:
            place.imageUrls.isNotEmpty ? place.imageUrls.first : null,
        lat: pLat,
        lng: pLng,
        categoryId: place.categoryId,
        rating: place.averageRating,
        reviewCount: place.reviewCount,
        plannedArrival: currentTime,
        plannedDurationMin: visitDuration,
      ));

      currentTime = currentTime.add(Duration(minutes: visitDuration));
      curLat = pLat;
      curLng = pLng;
    }

    return stops;
  }

  static int _visitDurationForCategory(String categoryId) {
    final normalized = PlaceCategories.normalizeId(categoryId);
    return switch (normalized) {
      'restaurants' || 'food' => 75,
      'cafes' => 45,
      'landmarks' || 'history' || 'museums' || 'culture' => 90,
      'beaches' || 'water_activities' => 120,
      'hotels' || 'tourist_villages' => 30,
      'shopping' => 90,
      'parks' || 'nature' || 'tourist_areas' => 60,
      'family' || 'kids' => 120,
      'events' || 'nightlife' || 'entertainment' => 90,
      'trips' => 180,
      'beauty_centers' || 'women_salons' || 'men_salons' || 'clubs_gyms' => 60,
      _ => 60,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // TOTALS
  // ═══════════════════════════════════════════════════════════════

  static double _totalDistance({
    required List<TripStop> stops,
    required double startLat,
    required double startLng,
  }) {
    if (stops.isEmpty) return 0.0;
    var total = 0.0;
    var curLat = startLat;
    var curLng = startLng;
    for (final s in stops) {
      total += _haversineKm(curLat, curLng, s.lat, s.lng);
      curLat = s.lat;
      curLng = s.lng;
    }
    return total;
  }

  static int _totalTravelTime({
    required List<TripStop> stops,
    required double startLat,
    required double startLng,
    required TripTransportMode transportMode,
  }) {
    if (stops.isEmpty) return 0;
    var totalMin = 0;
    var curLat = startLat;
    var curLng = startLng;
    for (final s in stops) {
      final km = _haversineKm(curLat, curLng, s.lat, s.lng);
      totalMin += (km / transportMode.speedKmH * 60).round();
      curLat = s.lat;
      curLng = s.lng;
    }
    return totalMin;
  }

  // ═══════════════════════════════════════════════════════════════
  // TITLE
  // ═══════════════════════════════════════════════════════════════

  static String _generateTitle(
    String governorateNameAr,
    TripDurationType durationType,
  ) {
    final suffix = switch (durationType) {
      TripDurationType.halfDay => 'نصف يوم',
      TripDurationType.fullDay => 'يوم كامل',
      TripDurationType.weekend => 'عطلة نهاية أسبوع',
    };
    return 'رحلة $governorateNameAr — $suffix';
  }

  // ═══════════════════════════════════════════════════════════════
  // HAVERSINE
  // ═══════════════════════════════════════════════════════════════

  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Compute rad() of each latitude once (was computed twice before).
    final rLat1 = lat1 * math.pi / 180.0;
    final rLat2 = lat2 * math.pi / 180.0;
    final dLat = (lat2 - lat1) * math.pi / 180.0;
    final dLng = (lng2 - lng1) * math.pi / 180.0;

    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);

    final a = sinDLat * sinDLat +
        math.cos(rLat1) * math.cos(rLat2) * sinDLng * sinDLng;
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return 6371.0 * c;
  }
}

class _ScoredPlace {
  const _ScoredPlace({required this.place, required this.score});
  final Place place;
  final double score;

  @override
  String toString() =>
      '_ScoredPlace(${place.nameAr}, ${score.toStringAsFixed(2)})';
}
