// lib/services/location_service.dart
// [v6.4 — 2026-11-15] — LINTER FIX: Added curly braces to 2 single-line if statements
//   in _getCachedZoneId and _getCachedPolygon.
// [v6.3 — 2026-11-12] — ANALYZER-STABILITY FIX.
//   - Rewrote `_getCachedPolygon` and `_getCachedZoneId` in imperative style:
//       * Removed ternary with `<Map<String, double>>[]` on the RHS — this
//         specific pattern crashes the analyzer's parser in some SDK versions
//         and produces a cascade: "Expected to find ':'" + "Expected an
//         identifier" + "Conditions must have a static type of 'bool'".
//       * Replaced `doc.data()?.x` with `final dynamic raw = doc.data();
//         if (raw != null) { final data = raw as Map<String, dynamic>; ... }`
//         — robust against both nullable and non-nullable `data()` signatures
//         across cloud_firestore versions.
//   - No behavioral changes. Same cache TTL (1h), same fallback logic.
//
// [v6.2 — 2026-11-12] — POLYGON + ZONE CACHING.
//   - ADDED: In-memory `_polygonCache` (keyed by geoZoneId) — TTL 1 hour.
//   - ADDED: In-memory `_zoneCache` (keyed by zoneId → geoZoneId) — TTL 1 hour.
//   - ADDED: `clearPolygonCache()` — for admin use after polygon updates.
//   - ADDED: `isPolygonVerified` / `isRadiusVerified` getters on the result.
//
// [v6.1 — GEO-VALIDATION INTEGRATION]
//   - ADDED: validatePresenceWithGeoZone — primary validation using polygon.
//   - KEPT: validatePresence (radius-based) as fallback.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/location/location_source.dart';
import '../core/helpers/location_url_helper.dart';
import '../core/utils/geo_polygon_helper.dart';

// ─────────────────────────────────────────────────────────────
// 1. DATA MODELS
// ─────────────────────────────────────────────────────────────

class LocationData {
  final double latitude;
  final double longitude;
  final String? nameAr;
  final String? governorate;
  final String? neighborhood;
  final double? accuracyMeters;
  final bool isMocked;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.nameAr,
    this.governorate,
    this.neighborhood,
    this.accuracyMeters,
    this.isMocked = false,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        if (nameAr != null) 'nameAr': nameAr,
        if (governorate != null) 'governorate': governorate,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (accuracyMeters != null) 'accuracy': accuracyMeters,
        'isMocked': isMocked,
      };

  static LocationData? fromJson(Map<String, dynamic> j) {
    final latRaw = j['lat'];
    final lngRaw = j['lng'];
    final double? lat = (latRaw is num)
        ? latRaw.toDouble()
        : double.tryParse(latRaw.toString());
    final double? lng = (lngRaw is num)
        ? lngRaw.toDouble()
        : double.tryParse(lngRaw.toString());
    if (lat == null || lng == null) {
      return null;
    }

    return LocationData(
      latitude: lat,
      longitude: lng,
      nameAr: j['nameAr'] as String?,
      governorate: j['governorate'] as String?,
      neighborhood: j['neighborhood'] as String?,
      accuracyMeters: (j['accuracy'] as num?)?.toDouble(),
      isMocked: j['isMocked'] as bool? ?? false,
    );
  }

  double distanceTo(double otherLat, double otherLng) {
    return LocationUrlHelper.calculateDistanceMeters(
      latitude,
      longitude,
      otherLat,
      otherLng,
    );
  }

  bool withinRangeOf(
    double otherLat,
    double otherLng, {
    double maxMeters = LocationService.maxPresenceDistanceMeters,
  }) {
    return distanceTo(otherLat, otherLng) <= maxMeters;
  }

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? nameAr,
    String? governorate,
    String? neighborhood,
    double? accuracyMeters,
    bool? isMocked,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      nameAr: nameAr ?? this.nameAr,
      governorate: governorate ?? this.governorate,
      neighborhood: neighborhood ?? this.neighborhood,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      isMocked: isMocked ?? this.isMocked,
    );
  }
}

class PlaceSearchResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const PlaceSearchResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });
}

class LocationValidationResult {
  final bool success;
  final double? distanceMeters;
  final bool isMocked;
  final double? latitude;
  final double? longitude;
  final String? reason;
  final bool? withinPolygon;

  const LocationValidationResult({
    required this.success,
    this.distanceMeters,
    this.isMocked = false,
    this.latitude,
    this.longitude,
    this.reason,
    this.withinPolygon,
  });

  factory LocationValidationResult.failure(String reason) {
    return LocationValidationResult(success: false, reason: reason);
  }

  factory LocationValidationResult.mock() {
    return const LocationValidationResult(
      success: false,
      isMocked: true,
      reason: 'تم اكتشاف موقع مزيّف — لا يمكن قبول التقييم',
    );
  }

  bool get isWithinRange => success;
  bool get hasFailure => !success;

  /// True فقط إذا نجح التحقق عبر Polygon (وليس المسافة).
  /// يُستخدم في Phase 2 لتطبيق وزن 1.4 أو 1.7.
  bool get isPolygonVerified => success && withinPolygon == true;

  /// True إذا نجح التحقق بالمسافة الدائرية (احتياطي).
  bool get isRadiusVerified => success && withinPolygon == null;

  String get displayLabel {
    if (isMocked) {
      return 'موقع مزيّف';
    }
    if (success) {
      if (withinPolygon == true) {
        return 'داخل حدود المنطقة';
      }
      return 'داخل النطاق';
    }
    if (withinPolygon == false) {
      return 'خارج حدود المنطقة';
    }
    return 'خارج النطاق';
  }
}

// ─────────────────────────────────────────────────────────────
// 2. CACHE HELPERS (private)
// ─────────────────────────────────────────────────────────────

const Duration _polygonCacheValidity = Duration(hours: 1);

class _CachedZoneEntry {
  final String? geoZoneId;
  final DateTime cachedAt;
  _CachedZoneEntry(this.geoZoneId) : cachedAt = DateTime.now();
  bool get isFresh =>
      DateTime.now().difference(cachedAt) < _polygonCacheValidity;
}

class _CachedPolygonEntry {
  final List<Map<String, double>>? polygon;
  final DateTime cachedAt;
  _CachedPolygonEntry(this.polygon) : cachedAt = DateTime.now();
  bool get isFresh =>
      DateTime.now().difference(cachedAt) < _polygonCacheValidity;
}

// ─────────────────────────────────────────────────────────────
// 3. LOCATION SERVICE
// ─────────────────────────────────────────────────────────────

class LocationService {
  static LocationData? _cached;
  static DateTime? _cachedAt;
  static const _cacheValidity = Duration(minutes: 5);

  /// كاش في الذاكرة: zoneId → geoZoneId (صالح لساعة).
  static final Map<String, _CachedZoneEntry> _zoneCache = {};

  /// كاش في الذاكرة: geoZoneId → polygon (صالح لساعة).
  static final Map<String, _CachedPolygonEntry> _polygonCache = {};

  /// الحد الأقصى للمسافة المسموح بها (احتياطي إذا لم توجد حدود جغرافية).
  static const double maxPresenceDistanceMeters = 150;

  static const _bdcBase =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';
  static const _nominatimBase = 'https://nominatim.openstreetmap.org/reverse';
  static const _nominatimSearchBase =
      'https://nominatim.openstreetmap.org/search';
  static const _nominatimUserAgent = 'YaBaladi/1.0 (contact@yabaladi.app)';

  static Future<void> clearCache() async {
    _cached = null;
    _cachedAt = null;
  }

  /// مسح كاش الـ Polygons والـ Zones.
  /// يجب استدعاؤها من شاشة الأدمن بعد تحديث حدود منطقة.
  static void clearPolygonCache() {
    _zoneCache.clear();
    _polygonCache.clear();
  }

  static String _cleanGov(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '';
    }
    return raw.replaceAll('محافظة ', '').replaceAll('Governorate', '').trim();
  }

  static Future<LocationData?> getBySource(LocationSource source) async {
    switch (source) {
      case LocationSource.gps:
        return getCurrentLocation(
            forceRefresh: true, accuracy: LocationAccuracy.best);
      case LocationSource.network:
        return getCurrentLocation(
            forceRefresh: true, accuracy: LocationAccuracy.low);
      case LocationSource.lastKnown:
        return _readLastKnown();
      case LocationSource.manual:
      case LocationSource.onlineSearch:
        return null;
    }
  }

  static Future<LocationData?> _readLastKnown() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        return null;
      }
      final name = await _resolvePlaceName(last.latitude, last.longitude);
      return LocationData(
        latitude: last.latitude,
        longitude: last.longitude,
        accuracyMeters: last.accuracy,
        isMocked: last.isMocked,
        nameAr: name.nameAr,
        governorate: _cleanGov(name.governorate),
        neighborhood: name.neighborhood,
      );
    } on Exception {
      return null;
    }
  }

  static Future<LocationData?> getCurrentLocation({
    bool forceRefresh = false,
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    if (!forceRefresh && _cached != null && _cachedAt != null) {
      final age = DateTime.now().difference(_cachedAt!);
      if (age < _cacheValidity && accuracy == LocationAccuracy.best) {
        return _cached;
      }
    }

    final gps = await _readGps(accuracy: accuracy);
    if (gps == null) {
      return null;
    }

    final resolved = await _resolvePlaceName(gps.latitude, gps.longitude);

    final data = LocationData(
      latitude: gps.latitude,
      longitude: gps.longitude,
      accuracyMeters: gps.accuracyMeters,
      isMocked: gps.isMocked,
      nameAr: resolved.nameAr,
      governorate: _cleanGov(resolved.governorate),
      neighborhood: resolved.neighborhood,
    );

    if (accuracy == LocationAccuracy.best) {
      _cached = data;
      _cachedAt = DateTime.now();
    }
    return data;
  }

  // ═══════════════════════════════════════════════════════════════
  // ★ CACHE HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// يجلب geoZoneId من وثيقة المنطقة مع كاش 1 ساعة.
  /// يعيد null إذا لم تكن المنطقة موجودة أو لم تُربط بحدود جغرافية.
  ///
  /// ملاحظة: مكتوبة بأسلوب أمري (imperative) — بدون تيرنري — لتفادي
  /// اختلاف استنتاج nullability لـ `data()` بين نسخ cloud_firestore.
  static Future<String?> _getCachedZoneId(
    String zoneId, {
    bool forceRefresh = false,
  }) async {
    if (zoneId.isEmpty) {
      return null;
    }

    if (!forceRefresh) {
      final cached = _zoneCache[zoneId];
      if (cached != null && cached.isFresh) {
        return cached.geoZoneId;
      }
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('zones')
          .doc(zoneId)
          .get();

      String? geoZoneId;

      if (doc.exists) {
        final dynamic rawData = doc.data();
        if (rawData != null) {
          final Map<String, dynamic> data = rawData as Map<String, dynamic>;
          final rawValue = data['geoZoneId'];
          if (rawValue != null) {
            final value = rawValue.toString();
            if (value.isNotEmpty) {
              geoZoneId = value;
            }
          }
        }
      }

      _zoneCache[zoneId] = _CachedZoneEntry(geoZoneId);
      return geoZoneId;
    } catch (e) {
      debugPrint('Error fetching zone $zoneId: $e');
      return null;
    }
  }

  /// يجلب Polygon الخاص بـ geoZoneId مع كاش 1 ساعة.
  /// يعيد null إذا لم توجد الحدود أو كانت غير صالحة (أقل من 3 نقاط).
  ///
  /// ملاحظة: مكتوبة بأسلوب أمري (imperative) — بدون تيرنري ذي
  /// type-argument على يمينه — لتفادي انهيار المُحلِّل.
  static Future<List<Map<String, double>>?> _getCachedPolygon(
    String geoZoneId, {
    bool forceRefresh = false,
  }) async {
    if (geoZoneId.isEmpty) {
      return null;
    }

    if (!forceRefresh) {
      final cached = _polygonCache[geoZoneId];
      if (cached != null && cached.isFresh) {
        return cached.polygon;
      }
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('geo_zones')
          .doc(geoZoneId)
          .get();

      if (!doc.exists) {
        _polygonCache[geoZoneId] = _CachedPolygonEntry(null);
        return null;
      }

      final dynamic rawData = doc.data();
      if (rawData == null) {
        _polygonCache[geoZoneId] = _CachedPolygonEntry(null);
        return null;
      }

      final Map<String, dynamic> data = rawData as Map<String, dynamic>;
      final parsed = GeoPolygonHelper.parsePolygon(data['polygon']);

      List<Map<String, double>>? polygon;
      if (parsed.length >= 3) {
        polygon = parsed;
      }

      _polygonCache[geoZoneId] = _CachedPolygonEntry(polygon);
      return polygon;
    } catch (e) {
      debugPrint('Error fetching polygon $geoZoneId: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ★ PRIMARY VALIDATION: Polygon + Fallback
  // ═══════════════════════════════════════════════════════════════
  /// التحقق من الحضور باستخدام الحدود الجغرافية للمنطقة (إن وُجدت).
  ///
  /// المنطق:
  ///   1. جلب موقع المستخدم (GPS) — دائماً fresh.
  ///   2. إذا كان للمكان `zoneId` وللمنطقة `geoZoneId` صالح → Polygon (صارم).
  ///   3. إذا غاب أي منهما → مسافة 150 متر (احتياطي).
  ///
  /// Cache: geoZoneId + polygon مُخزَّنان في الذاكرة (1 ساعة).
  static Future<LocationValidationResult> validatePresenceWithGeoZone({
    required double placeLat,
    required double placeLng,
    required String? zoneId,
    double maxDistanceMeters = maxPresenceDistanceMeters,
    bool forceRefresh = true,
  }) async {
    // 1. GPS
    final location = await getCurrentLocation(
      forceRefresh: forceRefresh,
      accuracy: LocationAccuracy.best,
    );

    if (location == null) {
      return LocationValidationResult.failure(
        'تعذر الحصول على موقعك — فعّل خدمة الموقع وأعد المحاولة',
      );
    }

    if (location.isMocked) {
      return LocationValidationResult.mock();
    }

    // المسافة — تُحسب دائماً (تُستخدم في الاحتياطي والتقارير)
    final distance = LocationUrlHelper.calculateDistanceMeters(
      location.latitude,
      location.longitude,
      placeLat,
      placeLng,
    );

    // 2. لا توجد منطقة → احتياطي
    if (zoneId == null || zoneId.isEmpty) {
      return _radiusFallback(location, distance, maxDistanceMeters);
    }

    // 3. المنطقة → geoZoneId (cached)
    final geoZoneId = await _getCachedZoneId(zoneId);
    if (geoZoneId == null || geoZoneId.isEmpty) {
      return _radiusFallback(location, distance, maxDistanceMeters);
    }

    // 4. geoZoneId → polygon (cached)
    final polygon = await _getCachedPolygon(geoZoneId);
    if (polygon == null || polygon.length < 3) {
      return _radiusFallback(location, distance, maxDistanceMeters);
    }

    // 5. التحقق الفعلي داخل المضلع
    final withinPolygon = GeoPolygonHelper.isPointInPolygon(
      lat: location.latitude,
      lng: location.longitude,
      polygon: polygon,
    );

    return LocationValidationResult(
      success: withinPolygon,
      distanceMeters: distance,
      isMocked: false,
      latitude: location.latitude,
      longitude: location.longitude,
      withinPolygon: withinPolygon,
      reason:
          withinPolygon ? null : 'أنت خارج حدود المنطقة المعتمدة لهذا المكان',
    );
  }

  static LocationValidationResult _radiusFallback(
    LocationData location,
    double distance,
    double maxDistanceMeters,
  ) {
    final withinRange = distance <= maxDistanceMeters;
    return LocationValidationResult(
      success: withinRange,
      distanceMeters: distance,
      isMocked: false,
      latitude: location.latitude,
      longitude: location.longitude,
      withinPolygon: null,
      reason: withinRange
          ? null
          : 'أنت بعيد عن المكان بحوالي ${distance.round()} مترًا — اقترب أكثر ثم أعد المحاولة',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ★ LEGACY VALIDATION: Radius only (kept for backward compatibility)
  // ═══════════════════════════════════════════════════════════════
  static Future<LocationValidationResult> validatePresence({
    required double placeLat,
    required double placeLng,
    double maxDistanceMeters = maxPresenceDistanceMeters,
    bool forceRefresh = true,
    LocationData? currentLocation,
  }) async {
    final location = currentLocation ??
        await getCurrentLocation(
          forceRefresh: forceRefresh,
          accuracy: LocationAccuracy.best,
        );

    if (location == null) {
      return LocationValidationResult.failure(
        'تعذر الحصول على موقعك — فعّل خدمة الموقع وأعد المحاولة',
      );
    }

    if (location.isMocked) {
      return LocationValidationResult.mock();
    }

    final distance = LocationUrlHelper.calculateDistanceMeters(
      location.latitude,
      location.longitude,
      placeLat,
      placeLng,
    );

    final withinRange = distance <= maxDistanceMeters;

    return LocationValidationResult(
      success: withinRange,
      distanceMeters: distance,
      isMocked: false,
      latitude: location.latitude,
      longitude: location.longitude,
      withinPolygon: null,
      reason: withinRange
          ? null
          : 'أنت بعيد عن المكان بحوالي ${distance.round()} مترًا — اقترب أكثر ثم أعد المحاولة',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ★ SEARCH & REVERSE GEOCODING
  // ═══════════════════════════════════════════════════════════════

  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.trim().length < 2) {
      return const [];
    }
    try {
      final uri = Uri.parse(
        '$_nominatimSearchBase?q=${Uri.encodeComponent(query)}'
        '&format=jsonv2&accept-language=ar&limit=8&countrycodes=eg',
      );
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': _nominatimUserAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode != 200) {
        return const [];
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      return list
          .map((e) {
            final m = e as Map<String, dynamic>;
            return PlaceSearchResult(
              displayName: (m['display_name'] as String?)?.trim() ?? '',
              latitude: double.tryParse('${m['lat']}') ?? 0,
              longitude: double.tryParse('${m['lon']}') ?? 0,
            );
          })
          .where((r) => r.latitude != 0 && r.longitude != 0)
          .toList();
    } on Exception {
      return const [];
    }
  }

  static Future<LocationData?> _readGps(
      {required LocationAccuracy accuracy}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final locationSettings = LocationSettings(
          accuracy: accuracy,
          timeLimit:
              Duration(seconds: accuracy == LocationAccuracy.best ? 15 : 8));
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);

      return LocationData(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracyMeters: pos.accuracy,
          isMocked: pos.isMocked);
    } catch (e) {
      debugPrint('GPS Error: $e. Attempting fallback...');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) {
          return null;
        }
        return LocationData(
            latitude: last.latitude,
            longitude: last.longitude,
            accuracyMeters: last.accuracy,
            isMocked: last.isMocked);
      } catch (_) {
        return null;
      }
    }
  }

  static Future<_PlaceNameResult> _resolvePlaceName(
      double lat, double lng) async {
    final bdc = await _bigDataCloudReverse(lat, lng);
    if (bdc.nameAr != null && bdc.nameAr!.isNotEmpty) {
      return bdc;
    }
    return await _nominatimReverse(lat, lng);
  }

  static Future<_PlaceNameResult> _bigDataCloudReverse(
      double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '$_bdcBase?latitude=$lat&longitude=$lng&localityLanguage=ar');
      final res = await http.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        return const _PlaceNameResult();
      }

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final locality = (j['locality'] as String?)?.trim();
      final city = (j['city'] as String?)?.trim();
      final region = (j['principalSubdivision'] as String?)?.trim();

      return _PlaceNameResult(
        governorate: region,
        neighborhood: locality ?? city,
        nameAr: [locality, city, region]
            .where((e) => e != null && e.isNotEmpty)
            .toSet()
            .join('، '),
      );
    } on Exception {
      return const _PlaceNameResult();
    }
  }

  static Future<_PlaceNameResult> _nominatimReverse(
      double lat, double lng) async {
    try {
      final uri = Uri.parse(
          '$_nominatimBase?lat=$lat&lon=$lng&format=jsonv2&accept-language=ar&addressdetails=1');
      final res = await http.get(uri, headers: {
        'User-Agent': _nominatimUserAgent,
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) {
        return const _PlaceNameResult();
      }

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final address = j['address'] as Map<String, dynamic>?;
      if (address == null) {
        return const _PlaceNameResult();
      }

      final suburb = (address['suburb'] as String?)?.trim();
      final city =
          (address['city'] ?? address['town'] ?? address['village']) as String?;
      final state = (address['state'] as String?)?.trim();

      return _PlaceNameResult(
        governorate: state,
        neighborhood: suburb ?? city,
        nameAr: [suburb, city, state]
            .where((e) => e != null && e.isNotEmpty)
            .toSet()
            .join('، '),
      );
    } on Exception {
      return const _PlaceNameResult();
    }
  }
}

class _PlaceNameResult {
  final String? nameAr;
  final String? governorate;
  final String? neighborhood;
  const _PlaceNameResult({this.nameAr, this.governorate, this.neighborhood});
}
