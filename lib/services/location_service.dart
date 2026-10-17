// lib/services/location_service.dart
//
// [v1.1 — 2026-10-16] — Wave 1a DUPLICATE-1 fix
//   - FIX: حذف _Gov + _governorates (27 محافظة مكررة)
//   - CHANGE: استخدام `nearestGovernorate` من egypt_governorates.dart
//   - REMOVED: _haversine + _rad (مكرران في egypt_governorates)
//   - النتيجة: مصدر وحيد للمحافظات — لا drift محتمل
//
// [v1.0 — 2026-10-14] — LocationService: صلاحيات + cache + محافظة

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/location/egypt_governorates.dart';

/// نتيجة تحديد الموقع.
class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.governorateAr,
    required this.governorateEn,
  });

  final double latitude;
  final double longitude;
  final String governorateAr;
  final String governorateEn;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lat': latitude,
        'lng': longitude,
        'ar': governorateAr,
        'en': governorateEn,
      };

  static LocationData? fromJson(Map<String, dynamic> json) {
    try {
      return LocationData(
        latitude: (json['lat'] as num).toDouble(),
        longitude: (json['lng'] as num).toDouble(),
        governorateAr: json['ar'] as String? ?? '',
        governorateEn: json['en'] as String? ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}

/// خدمة الموقع: صلاحيات + جلب الإحداثيات + تحديد المحافظة + cache.
///
/// [v1.1] يعتمد على `egypt_governorates.dart` كمصدر وحيد للمحافظات.
class LocationService {
  LocationService._();

  // ═══════════════════════════════════════════════════════════════
  // CACHE (30 دقيقة)
  // ═══════════════════════════════════════════════════════════════
  static const String _cacheKey = 'last_location_data';
  static const String _cacheTimeKey = 'last_location_time';
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// يجلب آخر عنوان محفوظ (لو مش قديم).
  static Future<LocationData?> getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timeStr = prefs.getInt(_cacheTimeKey);
      if (timeStr == null) return null;

      final savedTime = DateTime.fromMillisecondsSinceEpoch(timeStr);
      if (DateTime.now().difference(savedTime) > _cacheDuration) {
        return null;
      }

      final jsonStr = prefs.getString(_cacheKey);
      if (jsonStr == null) return null;

      return LocationData.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('LocationService.getCachedLocation: $e');
      return null;
    }
  }

  static Future<void> _saveToCache(LocationData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data.toJson()));
      await prefs.setInt(
        _cacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('LocationService._saveToCache: $e');
    }
  }

  /// يمسح الـ cache (عند force refresh).
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      await prefs.remove(_cacheTimeKey);
    } catch (e) {
      debugPrint('LocationService.clearCache: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // PERMISSIONS
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> isServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  static Future<bool> requestPermission() async {
    var perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  // ═══════════════════════════════════════════════════════════════
  // MAIN
  // ═══════════════════════════════════════════════════════════════

  /// يجلب الموقع الحالي ويحدّد المحافظة.
  ///
  /// [v1.1] يستخدم `nearestGovernorate` من `egypt_governorates.dart`
  /// (بدل النسخة المكررة السابقة).
  ///
  /// - [forceRefresh]: تجاهل الـ cache.
  /// - يعيد `null` لو الخدمة معطّلة أو الصلاحية مرفوضة.
  static Future<LocationData?> getCurrentLocation({
    bool forceRefresh = false,
  }) async {
    // 1. حاول من الـ cache
    if (!forceRefresh) {
      final cached = await getCachedLocation();
      if (cached != null) {
        debugPrint('LocationService: from cache');
        return cached;
      }
    }

    try {
      // 2. تأكد إن خدمة الموقع مفعّلة
      if (!await isServiceEnabled()) {
        debugPrint('LocationService: services disabled');
        return null;
      }

      // 3. اطلب الصلاحية
      if (!await requestPermission()) {
        debugPrint('LocationService: permission denied');
        return null;
      }

      // 4. اجلب الموقع
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 5. حدّد المحافظة الأقرب — من المصدر الوحيد
      final gov = nearestGovernorate(pos.latitude, pos.longitude);

      final data = LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        governorateAr: gov.nameAr,
        governorateEn: gov.nameEn,
      );

      // 6. احفظ في الـ cache
      await _saveToCache(data);

      return data;
    } catch (e) {
      debugPrint('LocationService: error $e');
      return null;
    }
  }
}
