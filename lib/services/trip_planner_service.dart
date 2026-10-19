// lib/services/trip_planner_service.dart
//
// [v1.3 — 2026-10-18] — Category Normalization
//   - FIX (CRITICAL): جميع مقارنات التصنيفات تستخدم PlaceCategories.normalizeId
//     → يحل مشكلة 'beach' (singular) ≠ 'beaches' (plural)
//     → يحل مشكلة Place.categories المخزّنة بصيغ مختلفة
//   - FIX: _visitDurationForCategory يستخدم normalizeId (إزالة التكرار)
//   - FIX: توحيد كل مقارنات interests/preferred/avoided/place categories
//   - NOTE: backward-compatible — لا تغيير في signature
//
// [v1.2 — 2026-10-18] — Wave 5.1: Companion-Aware Generation
//   - NEW: companion param (default: family)
//   - NEW: _rankCandidates — boost +30% / -30%
//   - NEW: _selectStops — 3 مجموعات
//
// [v1.1 — 2026-10-18] — Resilience Fixes

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
    CompanionType companion = CompanionType.family,
  }) {
    final governorate = governorateById(governorateId) ?? kDefaultGovernorate;

    // 1. جمع المرشحين
    final candidates = _filterCandidates(
      allPlaces: allPlaces,
      governorateNameAr: governorate.nameAr,
      interests: interests,
    );

    // 2. ترتيب حسب score (مع companion)
    final ranked = _rankCandidates(
      candidates: candidates,
      startLat: startLat,
      startLng: startLng,
      companion: companion,
    );

    // 3. اختيار Top N (مع companion preference)
    final selected = _selectStops(
      ranked: ranked,
      durationType: durationType,
      companion: companion,
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
  // NORMALIZATION HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// استخراج تصنيفات المكان — موحّدة (normalized lowercase + aliases).
  ///
  /// يشمل `categories` + `categoryId` (fallback) لضمان عدم إهمال
  /// الأماكن القديمة التي تحتوي فقط على `categoryId`.
  static Set<String> _placeCategorySet(Place place) {
    final raw = place.categories.isNotEmpty
        ? place.categories
        : (place.categoryId.isNotEmpty ? [place.categoryId] : <String>[]);
    return raw.map(PlaceCategories.normalizeId).toSet();
  }

  /// توحيد مجموعة تصنيفات (interests / preferred / avoided).
  static Set<String> _normalizeSet(Set<String> raw) =>
      raw.map(PlaceCategories.normalizeId).toSet();

  /// توحيد قائمة تصنيفات (companion.preferredCategories يعيد List).
  static Set<String> _normalizeList(List<String> raw) =>
      raw.map(PlaceCategories.normalizeId).toSet();

  // ═══════════════════════════════════════════════════════════════
  // 1. FILTER
  // ═══════════════════════════════════════════════════════════════

  static List<Place> _filterCandidates({
    required List<Place> allPlaces,
    required String governorateNameAr,
    required Set<String> interests,
  }) {
    // مطابقة مرنة للمحافظة (عربي/إنجليزي)
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
        .toList();

    // ✅ فلترة حسب الاهتمامات — مع normalization
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
  // 2. RANK
  // ═══════════════════════════════════════════════════════════════

  /// ترتيب المرشحين — مع companion boost/penalty (normalized).
  static List<Place> _rankCandidates({
    required List<Place> candidates,
    required double startLat,
    required double startLng,
    required CompanionType companion,
  }) {
    // ✅ توحيد التصنيفات قبل المقارنة
    final preferred = _normalizeList(companion.preferredCategories);
    final avoided = _normalizeList(companion.avoidedCategories);

    final scored = candidates.map((p) {
      final ratingScore = (p.averageRating / 5.0).clamp(0.0, 1.0);

      final pLat = p.location?.latitude ?? startLat;
      final pLng = p.location?.longitude ?? startLng;
      final distance = _haversineKm(startLat, startLng, pLat, pLng);
      final proximityScore = 1.0 / (1.0 + distance / _proximityRadiusKm);

      var score =
          ratingScore * _ratingWeight + proximityScore * _proximityWeight;

      final placeCats = _placeCategorySet(p);

      // ✅ Boost للتصنيفات المفضلة
      if (placeCats.intersection(preferred).isNotEmpty) {
        score *= 1.3;
      }
      // ✅ Penalty للتصنيفات المتجنبة
      if (placeCats.intersection(avoided).isNotEmpty) {
        score *= 0.7;
      }

      return _ScoredPlace(place: p, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.place).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. SELECT
  // ═══════════════════════════════════════════════════════════════

  /// اختيار Top N — يحترم companion.preferredCategories (normalized).
  static List<Place> _selectStops({
    required List<Place> ranked,
    required TripDurationType durationType,
    required CompanionType companion,
  }) {
    final maxStops = durationType.maxStops;
    if (ranked.length <= maxStops) return ranked;

    // ✅ توحيد قبل التقسيم
    final preferred = _normalizeList(companion.preferredCategories);
    final avoided = _normalizeList(companion.avoidedCategories);

    // قسم إلى 3 مجموعات
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

    // 1. أولاً: من المفضلة
    for (final p in preferredList) {
      if (selected.length >= maxStops) break;
      if (usedIds.add(p.id)) selected.add(p);
    }

    // 2. ثانياً: من المحايدة
    for (final p in neutralList) {
      if (selected.length >= maxStops) break;
      if (usedIds.add(p.id)) selected.add(p);
    }

    // 3. أخيراً: من المتجنبة (فقط إذا لم نكمل)
    for (final p in avoidedList) {
      if (selected.length >= maxStops) break;
      if (usedIds.add(p.id)) selected.add(p);
    }

    // أعد الترتيب حسب score الأصلي
    selected.sort((a, b) => ranked.indexOf(a).compareTo(ranked.indexOf(b)));
    return selected;
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. OPTIMIZE ROUTE (بدون تغيير)
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
    var currentTime =
        DateTime(startTime.year, startTime.month, startTime.day, 9, 0);

    var curLat = startLat;
    var curLng = startLng;

    for (final place in places) {
      final pLat = place.location?.latitude ?? startLat;
      final pLng = place.location?.longitude ?? startLng;

      final travelKm = _haversineKm(curLat, curLng, pLat, pLng);
      final travelMin = (travelKm / transportMode.speedKmH * 60).round();
      currentTime = currentTime.add(Duration(minutes: travelMin));

      // ✅ نستخدم التصنيف الأساسي من categories (الأول) أو categoryId
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

  // ═══════════════════════════════════════════════════════════════
  // VISIT DURATIONS — normalized (إزالة التكرار)
  // ═══════════════════════════════════════════════════════════════

  /// مدة الزيارة حسب التصنيف — مع normalization.
  ///
  /// ✅ يستخدم `PlaceCategories.normalizeId` أولاً
  /// → `'beach'` و `'beaches'` يعطيان نفس المدة (120 دقيقة)
  /// → `'restaurant'` و `'restaurants'` يعطيان 75 دقيقة
  /// → لا حاجة لسرد كل صيغة في switch
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
      'beauty_centers' ||
      'women_salons' ||
      'men_salons' ||
      'clubs_gyms' =>
        60,
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

  static double _haversineKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
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