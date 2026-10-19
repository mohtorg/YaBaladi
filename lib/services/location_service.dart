// lib/services/location_service.dart
//
// [v5.0.1 — 2026-10-19] — Wave 5.5c: defensive fromJson
//   - FIX: fromJson يقبل num أو String رقمي، يرفض الباقي بـ null
//   - KEPT: getBySource, searchPlaces, BigDataCloud, Nominatim (v5.0)
//
// [v5.0 — 2026-10-19] — Wave 5.5c: getBySource + searchPlaces
//   - ADD: getBySource(LocationSource) — ADR-5
//   - ADD: searchPlaces(query) — Nominatim search
//   - ADD: PlaceSearchResult model
//   - CHANGE: _readGps({required LocationAccuracy accuracy})
//   - KEPT: fromJson static + governorateAr/En deprecated (v4.2)

import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/location/location_source.dart';

class LocationData {
  final double latitude;
  final double longitude;

  @Deprecated('Use nameAr for fine locality. Will be removed in Wave 5.6.')
  final String? governorateAr;

  @Deprecated('Will be removed in Wave 5.6.')
  final String? governorateEn;

  /// اسم المكان بالعربية (مثال: "الشرق، بورسعيد")
  final String? nameAr;

  /// دقة القراءة بالأمتار
  final double? accuracyMeters;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.governorateAr,
    this.governorateEn,
    this.nameAr,
    this.accuracyMeters,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        if (governorateAr != null) 'governorateAr': governorateAr,
        if (governorateEn != null) 'governorateEn': governorateEn,
        if (nameAr != null) 'nameAr': nameAr,
        if (accuracyMeters != null) 'accuracy': accuracyMeters,
      };

  /// ✅ [v5.0.1] defensive parsing — يقبل num أو String رقمي، يرفض الباقي بـ null
  static LocationData? fromJson(Map<String, dynamic> j) {
    final latRaw = j['lat'];
    final lngRaw = j['lng'];

    double? lat;
    double? lng;

    if (latRaw is num) {
      lat = latRaw.toDouble();
    } else if (latRaw is String) {
      lat = double.tryParse(latRaw);
    }

    if (lngRaw is num) {
      lng = lngRaw.toDouble();
    } else if (lngRaw is String) {
      lng = double.tryParse(lngRaw);
    }

    if (lat == null || lng == null) return null;

    return LocationData(
      latitude: lat,
      longitude: lng,
      governorateAr: j['governorateAr'] as String?,
      governorateEn: j['governorateEn'] as String?,
      nameAr: j['nameAr'] as String?,
      accuracyMeters: (j['accuracy'] as num?)?.toDouble(),
    );
  }
}

/// نتيجة بحث Nominatim
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

class LocationService {
  static LocationData? _cached;

  static const _bdcBase =
      'https://api.bigdatacloud.net/data/reverse-geocode-client';
  static const _nominatimBase = 'https://nominatim.openstreetmap.org/reverse';
  static const _nominatimSearchBase =
      'https://nominatim.openstreetmap.org/search';
  static const _nominatimUserAgent = 'YaBaladi/1.0 (contact@yabaladi.app)';

  static Future<void> clearCache() async {
    _cached = null;
  }

  // ═══════════════════════════════════════════════════════════════
  // [v5.0] getBySource — ADR-5
  // ═══════════════════════════════════════════════════════════════

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
        return null; // UI يتولى
    }
  }

  /// آخر موقع معروف (سريع جداً، لا يطلب إذن)
  static Future<LocationData?> _readLastKnown() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) return null;
      final name = await _resolvePlaceName(last.latitude, last.longitude);
      return LocationData(
        latitude: last.latitude,
        longitude: last.longitude,
        accuracyMeters: last.accuracy,
        nameAr: name.nameAr,
        governorateAr: name.governorateAr,
      );
    } on Exception {
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // الحصول على الموقع (مع إتاحة اختيار الدقة)
  // ═══════════════════════════════════════════════════════════════

  static Future<LocationData?> getCurrentLocation({
    bool forceRefresh = false,
    LocationAccuracy accuracy = LocationAccuracy.best,
  }) async {
    if (!forceRefresh && _cached != null && accuracy == LocationAccuracy.best) {
      return _cached;
    }

    final gps = await _readGps(accuracy: accuracy);
    if (gps == null) return null;

    final resolved = await _resolvePlaceName(gps.latitude, gps.longitude);

    final data = LocationData(
      latitude: gps.latitude,
      longitude: gps.longitude,
      accuracyMeters: gps.accuracyMeters,
      nameAr: resolved.nameAr,
      governorateAr: resolved.governorateAr,
      governorateEn: null,
    );

    // لا نخزن دقة منخفضة في الكاش الثابت كقيمة أساسية
    if (accuracy == LocationAccuracy.best) _cached = data;

    return data;
  }

  // ═══════════════════════════════════════════════════════════════
  // [v5.0] searchPlaces — Nominatim search
  // ═══════════════════════════════════════════════════════════════

  static Future<List<PlaceSearchResult>> searchPlaces(String query) async {
    if (query.trim().length < 2) return const [];
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

      if (res.statusCode != 200) return const [];
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

  // ═══════════════════════════════════════════════════════════════
  // Internals
  // ═══════════════════════════════════════════════════════════════

  static Future<LocationData?> _readGps({
    required LocationAccuracy accuracy,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: const Duration(seconds: 8),
        ),
      );

      return LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracyMeters: pos.accuracy,
      );
    } on TimeoutException {
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return null;
        return LocationData(
          latitude: last.latitude,
          longitude: last.longitude,
          accuracyMeters: last.accuracy,
        );
      } on Exception {
        return null;
      }
    } on Exception {
      return null;
    }
  }

  static Future<_PlaceNameResult> _resolvePlaceName(
    double lat,
    double lng,
  ) async {
    final bdc = await _bigDataCloudReverse(lat, lng);
    if (bdc.nameAr != null && bdc.nameAr!.isNotEmpty) return bdc;
    return await _nominatimReverse(lat, lng);
  }

  static Future<_PlaceNameResult> _bigDataCloudReverse(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.parse(
        '$_bdcBase?latitude=$lat&longitude=$lng&localityLanguage=ar',
      );
      final res = await http.get(uri, headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return const _PlaceNameResult();

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final locality = (j['locality'] as String?)?.trim();
      final city = (j['city'] as String?)?.trim();
      final region = (j['principalSubdivision'] as String?)?.trim();

      final parts = <String>[];
      if (locality != null && locality.isNotEmpty) parts.add(locality);
      if (city != null && city.isNotEmpty && city != locality) {
        parts.add(city);
      }
      if (parts.isEmpty && region != null && region.isNotEmpty) {
        parts.add(region);
      }

      return _PlaceNameResult(
        nameAr: parts.isEmpty ? null : parts.join('، '),
        governorateAr: region,
      );
    } on Exception {
      return const _PlaceNameResult();
    }
  }

  static Future<_PlaceNameResult> _nominatimReverse(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.parse(
        '$_nominatimBase?lat=$lat&lon=$lng'
        '&format=jsonv2&accept-language=ar&addressdetails=1',
      );
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': _nominatimUserAgent,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) return const _PlaceNameResult();
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final address = j['address'] as Map<String, dynamic>?;
      if (address == null) return const _PlaceNameResult();

      final suburb = (address['suburb'] as String?)?.trim();
      final city =
          (address['city'] ?? address['town'] ?? address['village']) as String?;
      final state = (address['state'] as String?)?.trim();
      final cityTrim = city?.trim();

      final parts = <String>[];
      if (suburb != null && suburb.isNotEmpty) parts.add(suburb);
      if (cityTrim != null && cityTrim.isNotEmpty && cityTrim != suburb) {
        parts.add(cityTrim);
      }
      if (parts.isEmpty && state != null && state.isNotEmpty) {
        parts.add(state);
      }

      return _PlaceNameResult(
        nameAr: parts.isEmpty ? null : parts.join('، '),
        governorateAr: state,
      );
    } on Exception {
      return const _PlaceNameResult();
    }
  }
}

class _PlaceNameResult {
  final String? nameAr;
  final String? governorateAr;

  const _PlaceNameResult({this.nameAr, this.governorateAr});
}
