// lib/services/trip_planner_service.dart
//
// [v1.1 — 2026-10-18] — Resilience Fixes
//   - FIX: Fallback to startLat/startLng if location is null (fixes "Not enough places")
//   - FIX: Flexible governorate matching (supports 'بورسعيد' & 'PortSaid')
//   - FIX: Flexible category matching (supports 'categories' list or 'categoryId')
import 'dart:math' as math;

import '../core/location/egypt_governorates.dart';
import '../models/place.dart';
import '../models/trip_plan.dart';

class TripPlannerService {
  TripPlannerService._();

  static const double _ratingWeight = 0.6;
  static const double _proximityWeight = 0.4;
  static const double _proximityRadiusKm = 10.0;

  // ═══════════════════════════════════════════════════════════════
  // MAIN
  // ═══════════════════════════════════════════════════════════════

  static TripPlan generateTrip({
    required List<Place> allPlaces,
    required String governorateId,
    required TripDurationType durationType,
    required Set<String> interests,
    required TripTransportMode transportMode,
    required double startLat,
    required double startLng,
    String userId = 'guest',
  }) {
    final governorate = governorateById(governorateId) ?? kDefaultGovernorate;

    // 1. جمع المرشحين
    final candidates = _filterCandidates(
      allPlaces: allPlaces,
      governorateNameAr: governorate.nameAr,
      interests: interests,
    );

    // 2. ترتيب حسب score
    final ranked = _rankCandidates(
      candidates: candidates,
      startLat: startLat,
      startLng: startLng,
    );

    // 3. اختيار Top N
    final selected = _selectStops(
      ranked: ranked,
      durationType: durationType,
    );

    // 4. تحسين المسار
    final optimized = _optimizeRoute(
      places: selected,
      startLat: startLat,
      startLng: startLng,
    );

    // 5. حساب الأوقات
    final stops = _estimateTimes(
      places: optimized,
      startLat: startLat,
      startLng: startLng,
      transportMode: transportMode,
    );

    // 6. الإجماليات
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
  // 1. FILTER
  // ═══════════════════════════════════════════════════════════════

  static List<Place> _filterCandidates({
    required List<Place> allPlaces,
    required String governorateNameAr,
    required Set<String> interests,
  }) {
    // ✅ مطابقة مرنة للمحافظة (عربي/إنجليزي)
    bool matchesGov(String placeGov, String targetGov) {
      final pg = placeGov.trim().toLowerCase();
      final tg = targetGov.trim().toLowerCase();
      if (pg == tg) return true;
      if (tg == 'بورسعيد' && (pg == 'portsaid' || pg == 'port said' || pg == 'port_said')) return true;
      if (tg == 'القاهرة' && pg == 'cairo') return true;
      return false;
    }

    // ✅ لا نستبعد الأماكن التي ليس لها location (لتجنب الشاشة الفارغة)
    var list = allPlaces
        .where((p) => matchesGov(p.governorate, governorateNameAr))
        .toList();

    // فلترة حسب الاهتمامات
    if (interests.isNotEmpty) {
      list = list.where((p) {
        if (p.categories.isNotEmpty) {
          return p.categories.any((c) => interests.contains(c.toLowerCase()));
        }
        return interests.contains(p.categoryId.toLowerCase());
      }).toList();
    }

    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. RANK
  // ═══════════════════════════════════════════════════════════════

  static List<Place> _rankCandidates({
    required List<Place> candidates,
    required double startLat,
    required double startLng,
  }) {
    final scored = candidates.map((p) {
      final ratingScore = (p.averageRating / 5.0).clamp(0.0, 1.0);
      
      // ✅ استخدام نقطة البداية كاحتياطي إذا لم يوجد location
      final pLat = p.location?.latitude ?? startLat;
      final pLng = p.location?.longitude ?? startLng;
      
      final distance = _haversineKm(startLat, startLng, pLat, pLng);
      final proximityScore = 1.0 / (1.0 + distance / _proximityRadiusKm);

      final score = ratingScore * _ratingWeight + proximityScore * _proximityWeight;
      return _ScoredPlace(place: p, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.place).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. SELECT
  // ═══════════════════════════════════════════════════════════════

  static List<Place> _selectStops({
    required List<Place> ranked,
    required TripDurationType durationType,
  }) {
    final maxStops = durationType.maxStops;
    if (ranked.length <= maxStops) return ranked;

    final byCategory = <String, List<Place>>{};
    for (final p in ranked) {
      final cat = p.categories.isNotEmpty ? p.categories.first : p.categoryId;
      byCategory.putIfAbsent(cat, () => []).add(p);
    }

    final selected = <Place>[];
    final usedIds = <String>{};

    for (final cat in byCategory.keys) {
      if (selected.length >= maxStops) break;
      final p = byCategory[cat]!.first;
      if (usedIds.add(p.id)) selected.add(p);
    }

    for (final p in ranked) {
      if (selected.length >= maxStops) break;
      if (usedIds.add(p.id)) selected.add(p);
    }

    selected.sort((a, b) => ranked.indexOf(a).compareTo(ranked.indexOf(b)));
    return selected;
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. OPTIMIZE ROUTE
  // ═══════════════════════════════════════════════════════════════

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
        final pLat = p.location?.latitude ?? startLat;
        final pLng = p.location?.longitude ?? startLng;
        final d = _haversineKm(curLat, curLng, pLat, pLng);
        
        if (d < nearestDist) {
          nearestDist = d;
          nearestIdx = i;
        }
      }

      final next = remaining.removeAt(nearestIdx);
      result.add(next);
      curLat = next.location?.latitude ?? startLat;
      curLng = next.location?.longitude ?? startLng;
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. TIMES
  // ═══════════════════════════════════════════════════════════════

  static List<TripStop> _estimateTimes({
    required List<Place> places,
    required double startLat,
    required double startLng,
    required TripTransportMode transportMode,
  }) {
    final stops = <TripStop>[];
    final startTime = DateTime.now();
    var currentTime = DateTime(startTime.year, startTime.month, startTime.day, 9, 0);

    var curLat = startLat;
    var curLng = startLng;

    for (final place in places) {
      final pLat = place.location?.latitude ?? startLat;
      final pLng = place.location?.longitude ?? startLng;
      
      final travelKm = _haversineKm(curLat, curLng, pLat, pLng);
      final travelMin = (travelKm / transportMode.speedKmH * 60).round();
      currentTime = currentTime.add(Duration(minutes: travelMin));

      final visitDuration = _visitDurationForCategory(place.categories.isNotEmpty ? place.categories.first : place.categoryId);

      stops.add(TripStop(
        placeId: place.id,
        placeNameAr: place.nameAr,
        placeNameEn: place.nameEn,
        placeImageUrl: place.imageUrls.isNotEmpty ? place.imageUrls.first : null,
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
    return switch (categoryId.toLowerCase()) {
      'restaurants' || 'food' => 75,
      'cafes' => 45,
      'landmarks' || 'history' || 'culture' => 90,
      'beaches' || 'beach' => 120,
      'hotels' => 30,
      'shopping' => 90,
      'parks' || 'nature' => 60,
      'family' => 120,
      'events' || 'nightlife' => 90,
      _ => 60,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. TOTALS
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
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  static String _generateTitle(String governorateNameAr, TripDurationType durationType) {
    final suffix = switch (durationType) {
      TripDurationType.halfDay => 'نصف يوم',
      TripDurationType.fullDay => 'يوم كامل',
      TripDurationType.weekend => 'عطلة نهاية أسبوع',
    };
    return 'رحلة $governorateNameAr — $suffix';
  }

  static double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return 6371.0 * c;
  }
}

class _ScoredPlace {
  const _ScoredPlace({required this.place, required this.score});
  final Place place;
  final double score;
  @override
  String toString() => '_ScoredPlace(${place.nameAr}, ${score.toStringAsFixed(2)})';
}