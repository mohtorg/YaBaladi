// lib/services/location_service.dart
// [v5.4 — 2026-10-28] — SMART FIX: Clean Governorate names & handle IP-based locations gracefully
// [v5.5 — 2026-10-29] — Lint fix: final on JSON-parsed locals (no logic change)

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../core/location/location_source.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? nameAr;
  final String? governorate;
  final String? neighborhood;
  final double? accuracyMeters;

  const LocationData({
    required this.latitude,
    required this.longitude,
    this.nameAr,
    this.governorate,
    this.neighborhood,
    this.accuracyMeters,
  });

  Map<String, dynamic> toJson() => {
        'lat': latitude,
        'lng': longitude,
        if (nameAr != null) 'nameAr': nameAr,
        if (governorate != null) 'governorate': governorate,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (accuracyMeters != null) 'accuracy': accuracyMeters,
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
    if (lat == null || lng == null) return null;

    return LocationData(
      latitude: lat,
      longitude: lng,
      nameAr: j['nameAr'] as String?,
      governorate: j['governorate'] as String?,
      neighborhood: j['neighborhood'] as String?,
      accuracyMeters: (j['accuracy'] as num?)?.toDouble(),
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

class LocationService {
  static LocationData? _cached;
  static DateTime? _cachedAt;
  static const _cacheValidity = Duration(minutes: 5);

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

  // ✅ دالة ذكية لتنظيف اسم المحافظة (إزالة كلمة "محافظة")
  static String _cleanGov(String? raw) {
    if (raw == null || raw.isEmpty) return '';
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
      if (last == null) return null;
      final name = await _resolvePlaceName(last.latitude, last.longitude);
      return LocationData(
        latitude: last.latitude,
        longitude: last.longitude,
        accuracyMeters: last.accuracy,
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
      if (age < _cacheValidity && accuracy == LocationAccuracy.best)
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
      governorate: _cleanGov(resolved.governorate),
      neighborhood: resolved.neighborhood,
    );

    if (accuracy == LocationAccuracy.best) {
      _cached = data;
      _cachedAt = DateTime.now();
    }
    return data;
  }

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

  static Future<LocationData?> _readGps(
      {required LocationAccuracy accuracy}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return null;

      final locationSettings = LocationSettings(
          accuracy: accuracy,
          timeLimit:
              Duration(seconds: accuracy == LocationAccuracy.best ? 15 : 8));
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings);

      return LocationData(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracyMeters: pos.accuracy);
    } catch (e) {
      debugPrint('GPS Error: $e. Attempting fallback...');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return null;
        return LocationData(
            latitude: last.latitude,
            longitude: last.longitude,
            accuracyMeters: last.accuracy);
      } catch (_) {
        return null;
      }
    }
  }

  static Future<_PlaceNameResult> _resolvePlaceName(
      double lat, double lng) async {
    final bdc = await _bigDataCloudReverse(lat, lng);
    if (bdc.nameAr != null && bdc.nameAr!.isNotEmpty) return bdc;
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
      if (res.statusCode != 200) return const _PlaceNameResult();

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
      if (res.statusCode != 200) return const _PlaceNameResult();

      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final address = j['address'] as Map<String, dynamic>?;
      if (address == null) return const _PlaceNameResult();

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
