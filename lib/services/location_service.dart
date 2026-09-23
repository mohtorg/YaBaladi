// lib/services/location_service.dart
// ط§ظ„ظ…ظˆظ‚ط¹ ط§ظ„ظ…ط±ظƒط²ظٹ ظپظٹ ظٹط§ ط¨ظ„ط¯ظٹ: طµظ„ط§ط­ظٹط§طھ + GPS + ط¢ط®ط± ظ…ظˆظ‚ط¹ ظ…ط¹ط±ظˆظپ + طھطھط¨ط¹ ط§ط®طھظٹط§ط±ظٹ ط£ط«ظ†ط§ط، ط§ظ„ط­ط§ط¬ط©.
// ظ„ط§ ظٹط­ظپط¸ ط§ظ„ظ…ظˆظ‚ط¹ ظپظٹ Firestore طھظ„ظ‚ط§ط¦ظٹظ‹ط§. ط§ظ„طھط®ط²ظٹظ† ط§ظ„ظ…ط­ظ„ظٹ ظٹظ‚طھطµط± ط¹ظ„ظ‰ ط¢ط®ط± ظ…ظˆظ‚ط¹ ظ…ط¹ط±ظˆظپ ظ„طھط¬ط±ط¨ط© ط£ظپط¶ظ„ ط¹ظ†ط¯ ط¶ط¹ظپ/ط§ظ†ظ‚ط·ط§ط¹ ط§ظ„ط´ط¨ظƒط©.

import 'dart:async';
import 'dart:io';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const _latKey = 'location.last_latitude';
  static const _lngKey = 'location.last_longitude';
  static const _timeKey = 'location.last_timestamp_ms';

  Future<LocationResult> getCurrentLocation({bool allowCached = true}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final cached = allowCached ? await getCachedLocation() : null;
        return cached ?? LocationResult.failure(LocationError.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        final cached = allowCached ? await getCachedLocation() : null;
        return cached ?? LocationResult.failure(LocationError.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        final cached = allowCached ? await getCachedLocation() : null;
        return cached ?? LocationResult.failure(LocationError.permissionDeniedForever);
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).timeout(const Duration(seconds: 12));
        await _cache(position);
        return LocationResult.success(position, source: LocationSource.gps);
      } on TimeoutException {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          await _cache(lastKnown);
          return LocationResult.success(lastKnown, source: LocationSource.lastKnown);
        }
        final cached = allowCached ? await getCachedLocation() : null;
        return cached ?? LocationResult.failure(LocationError.unavailable);
      }
    } catch (_) {
      final cached = allowCached ? await getCachedLocation() : null;
      return cached ?? LocationResult.failure(LocationError.unavailable);
    }
  }

  Stream<Position> watchPosition({int distanceFilterMeters = 20}) async* {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return;
    }

    yield* Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).asyncMap((position) async {
      await _cache(position);
      return position;
    });
  }

  Future<LocationResult?> getCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    final ms = prefs.getInt(_timeKey);
    if (lat == null || lng == null) return null;

    final position = Position(
      longitude: lng,
      latitude: lat,
      timestamp: ms == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(ms),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    return LocationResult.success(position, source: LocationSource.cached);
  }

  Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<CoordinatesResult> coordinatesFromAddress(String address) async {
    if (address.trim().isEmpty) return CoordinatesResult.failure();
    try {
      final marks = await locationFromAddress(address.trim());
      if (marks.isEmpty) return CoordinatesResult.failure();
      final mark = marks.first;
      return CoordinatesResult.success(mark.latitude, mark.longitude);
    } catch (_) {
      return CoordinatesResult.failure();
    }
  }

  Future<AddressResult> addressFromCoordinates(double latitude, double longitude) async {
    try {
      final marks = await placemarkFromCoordinates(latitude, longitude);
      if (marks.isEmpty) return AddressResult.failure();
      final mark = marks.first;
      final parts = <String?>[
        mark.street,
        mark.subLocality,
        mark.locality,
        mark.administrativeArea,
        mark.country,
      ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      return AddressResult.success(parts.join('طŒ '));
    } catch (_) {
      return AddressResult.failure();
    }
  }

  double distanceInKm({
    required double userLat,
    required double userLng,
    required double placeLat,
    required double placeLng,
  }) => Geolocator.distanceBetween(userLat, userLng, placeLat, placeLng) / 1000;

  Future<void> _cache(Position position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, position.latitude);
    await prefs.setDouble(_lngKey, position.longitude);
    await prefs.setInt(_timeKey, position.timestamp.millisecondsSinceEpoch);
  }
}

enum LocationSource { gps, lastKnown, cached }

enum LocationError { serviceDisabled, permissionDenied, permissionDeniedForever, unavailable }

class LocationResult {
  final bool isSuccess;
  final Position? position;
  final LocationSource? source;
  final LocationError? error;

  const LocationResult._({required this.isSuccess, this.position, this.source, this.error});
  factory LocationResult.success(Position position, {required LocationSource source}) =>
      LocationResult._(isSuccess: true, position: position, source: source);
  factory LocationResult.failure(LocationError error) =>
      LocationResult._(isSuccess: false, error: error);
}

class CoordinatesResult {
  final bool isSuccess;
  final double? latitude;
  final double? longitude;
  const CoordinatesResult._(this.isSuccess, this.latitude, this.longitude);
  factory CoordinatesResult.success(double lat, double lng) => CoordinatesResult._(true, lat, lng);
  factory CoordinatesResult.failure() => const CoordinatesResult._(false, null, null);
}

class AddressResult {
  final bool isSuccess;
  final String? address;
  const AddressResult._(this.isSuccess, this.address);
  factory AddressResult.success(String address) => AddressResult._(true, address);
  factory AddressResult.failure() => const AddressResult._(false, null);
}


