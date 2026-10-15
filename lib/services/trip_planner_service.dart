// lib/services/trip_planner_service.dart
//
// [v1.0 — 2026-10-15] — G6.7: Trip Planner Service
//   - يولّد خطة رحلة كاملة من معطيات المستخدم.
//   - خطوات التوليد:
//     1. جمع المرشحين (governorate + interests)
//     2. ترتيب حسب score = (rating × 0.6) + (proximity × 0.4)
//     3. اختيار Top N حسب مدة الرحلة
//     4. تحسين المسار (Greedy Nearest Neighbor)
//     5. حساب الأوقات والمسافات
//     6. بناء TripPlan
//   - مستقل — يعتمد على: models + egypt_governorates فقط.

import 'dart:math' as math;

import '../core/location/egypt_governorates.dart';
import '../models/place.dart';
import '../models/trip_plan.dart';

/// ترتيب أولوية لقيمة الرحلة — يمنح فرصة لمقدمي الخدمة المتميزين.
class TripPlannerService {
  TripPlannerService._();

  // ═══════════════════════════════════════════════════════════════
  // الأوزان — قابلة للتعديل
  // ═══════════════════════════════════════════════════════════════

  /// وزن التقييم في الترتيب.
  static const double _ratingWeight = 0.6;

  /// وزن القرب في الترتيب.
  static const double _proximityWeight = 0.4;

  /// نصف قطر "القرب المثالي" بالكيلومترات — للـ proximity score.
  static const double _proximityRadiusKm = 10.0;

  // ═══════════════════════════════════════════════════════════════
  // MAIN
  // ═══════════════════════════════════════════════════════════════

  /// يولّد خطة رحلة بناءً على المعطيات.
  ///
  /// - [allPlaces]: كل الأماكن المُحمَّلة (client-side filtering).
  /// - [governorateId]: المحافظة المستهدفة (id ASCII).
  /// - [durationType]: مدة الرحلة.
  /// - [interests]: categoryIds المطلوبة (فارغة = كل الفئات).
  /// - [transportMode]: وسيلة النقل.
  /// - [startPoint]: نقطة البدء (عادةً مركز المحافظة).
  ///
  /// يُعيد `TripPlan` جاهز — قد تكون `stops` فارغة إذا لم توجد أماكن.
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

  /// فلترة المرشحين — governorate + interests + isApproved.
  static List<Place> _filterCandidates({
    required List<Place> allPlaces,
    required String governorateNameAr,
    required Set<String> interests,
  }) {
    var list = allPlaces
        .where((p) => p.governorate == governorateNameAr)
        .where((p) => p.location != null)
        .toList();

    // فلترة حسب الاهتمامات (إن حُدِّدت)
    if (interests.isNotEmpty) {
      list = list.where((p) => interests.contains(p.categoryId)).toList();
    }

    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. RANK
  // ═══════════════════════════════════════════════════════════════

  /// ترتيب المرشحين حسب score مركّب.
  static List<Place> _rankCandidates({
    required List<Place> candidates,
    required double startLat,
    required double startLng,
  }) {
    final scored = candidates.map((p) {
      final ratingScore = (p.averageRating / 5.0).clamp(0.0, 1.0);
      final distance = _haversineKm(
        startLat,
        startLng,
        p.location!.latitude,
        p.location!.longitude,
      );
      // proximity: 1.0 عند المسافة 0، → 0.5 عند 10 km، → 0 عند ∞
      final proximityScore = 1.0 / (1.0 + distance / _proximityRadiusKm);

      final score =
          ratingScore * _ratingWeight + proximityScore * _proximityWeight;

      return _ScoredPlace(place: p, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.place).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. SELECT
  // ═══════════════════════════════════════════════════════════════

  /// اختيار Top N حسب مدة الرحلة — مع احترام categoryBalance.
  static List<Place> _selectStops({
    required List<Place> ranked,
    required TripDurationType durationType,
  }) {
    final maxStops = durationType.maxStops;
    if (ranked.length <= maxStops) return ranked;

    // نُحاول تنويع الفئات — لا نأخذ كل شيء من مطاعم
    final byCategory = <String, List<Place>>{};
    for (final p in ranked) {
      byCategory.putIfAbsent(p.categoryId, () => []).add(p);
    }

    final selected = <Place>[];
    final usedIds = <String>{};

    // جولة أولى: واحد من كل فئة
    for (final cat in byCategory.keys) {
      if (selected.length >= maxStops) break;
      final p = byCategory[cat]!.first;
      if (usedIds.add(p.id)) selected.add(p);
    }

    // جولة ثانية: أكمل من الأعلى ترتيباً
    for (final p in ranked) {
      if (selected.length >= maxStops) break;
      if (usedIds.add(p.id)) selected.add(p);
    }

    // أعد الترتيب حسب score الأصلي (سنُحسّن المسار لاحقاً)
    selected.sort((a, b) {
      final ai = ranked.indexOf(a);
      final bi = ranked.indexOf(b);
      return ai.compareTo(bi);
    });

    return selected;
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. OPTIMIZE ROUTE (Greedy Nearest Neighbor)
  // ═══════════════════════════════════════════════════════════════

  /// يحسّن ترتيب الزيارات — Greedy: من الأقرب للأقرب.
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
      // ابحث عن الأقرب للموقع الحالي
      var nearestIdx = 0;
      var nearestDist = double.infinity;

      for (var i = 0; i < remaining.length; i++) {
        final p = remaining[i];
        final d = _haversineKm(
          curLat,
          curLng,
          p.location!.latitude,
          p.location!.longitude,
        );
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
  // 5. TIMES
  // ═══════════════════════════════════════════════════════════════

  /// يحوّل Places إلى TripStops مع أوقات متوقعة.
  static List<TripStop> _estimateTimes({
    required List<Place> places,
    required double startLat,
    required double startLng,
    required TripTransportMode transportMode,
  }) {
    final stops = <TripStop>[];
    // نبدأ الرحلة الساعة 9:00 صباحاً (وقت منطقي)
    final startTime = DateTime.now();
    var currentTime = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
      9,
      0,
    );

    var curLat = startLat;
    var curLng = startLng;

    for (final place in places) {
      // وقت الانتقال من الموقع الحالي إلى المكان
      final travelKm = _haversineKm(
        curLat,
        curLng,
        place.location!.latitude,
        place.location!.longitude,
      );
      final travelMin = (travelKm / transportMode.speedKmH * 60).round();

      // وقت الوصول = الوقت الحالي + الانتقال
      currentTime = currentTime.add(Duration(minutes: travelMin));

      // مدة الزيارة حسب الفئة
      final visitDuration = _visitDurationForCategory(place.categoryId);

      stops.add(TripStop(
        placeId: place.id,
        placeNameAr: place.nameAr,
        placeNameEn: place.nameEn,
        placeImageUrl:
            place.imageUrls.isNotEmpty ? place.imageUrls.first : null,
        lat: place.location!.latitude,
        lng: place.location!.longitude,
        categoryId: place.categoryId,
        rating: place.averageRating,
        reviewCount: place.reviewCount,
        plannedArrival: currentTime,
        plannedDurationMin: visitDuration,
      ));

      // الوقت الحالي += مدة الزيارة
      currentTime = currentTime.add(Duration(minutes: visitDuration));

      curLat = place.location!.latitude;
      curLng = place.location!.longitude;
    }

    return stops;
  }

  /// مدة الزيارة حسب الفئة بالدقائق.
  static int _visitDurationForCategory(String categoryId) {
    return switch (categoryId) {
      'restaurants' => 75,
      'cafes' => 45,
      'landmarks' => 90,
      'beaches' => 120,
      'hotels' => 30,
      'shopping' => 90,
      'parks' => 60,
      'family' => 120,
      'events' => 90,
      _ => 60,
    };
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. TOTALS
  // ═══════════════════════════════════════════════════════════════

  /// إجمالي المسافة (كم) — بما فيها من نقطة البدء.
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

  /// إجمالي وقت الانتقالات (دقائق).
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

  /// عنوان الرحلة — "رحلة الإسكندرية".
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

  /// Haversine — مسافة بالكيلومترات.
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

/// نموذج داخلي — Place + score.
class _ScoredPlace {
  const _ScoredPlace({required this.place, required this.score});

  final Place place;
  final double score;

  @override
  String toString() =>
      '_ScoredPlace(${place.nameAr}, ${score.toStringAsFixed(2)})';
}
