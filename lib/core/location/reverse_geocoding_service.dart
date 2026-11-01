// lib/core/location/reverse_geocoding_service.dart
//
// [v1.1 — 2026-10-25] — FIX: Web User-Agent exception + Math domain error
//   - FIXED: User-Agent header is now conditionally added only on non-web
//     platforms (browsers forbid setting it, which throws a ClientException).
//   - FIXED: haversineKm now uses clamp(0.0, 1.0) to prevent math.sqrt(negative).
//   - KEPT: all logic, caching, and timeouts identical.

import 'dart:async'; // لضمان توفر TimeoutException
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../models/address_info.dart';

class ReverseGeocodingService {
  ReverseGeocodingService._();

  static const String _baseUrl = 'https://nominatim.openstreetmap.org/reverse';
  static const Duration _cacheDuration = Duration(minutes: 30);
  static const Duration _timeout = Duration(seconds: 5);

  /// User-Agent مطلوب من Nominatim (سياسة استخدامهم).
  static const String _userAgent = 'YaBaladi/1.0 (ya-baladi.app)';

  /// Cache: key = "lat3_lng3" → (AddressInfo, timestamp).
  static final Map<String, _CacheEntry> _cache = {};

  /// يُترجم إحداثيات إلى AddressInfo.
  ///
  /// - يُعيد `null` عند:
  ///   * فشل الشبكة
  ///   * timeout
  ///   * رد غير صحيح
  /// - يستخدم cache لمدة 30 دقيقة (توفير طلبات).
  static Future<AddressInfo?> resolve(double lat, double lng) async {
    // Round لـ 3 decimals ≈ 111 متر — كافٍ للحي
    final key = '${lat.toStringAsFixed(3)}_${lng.toStringAsFixed(3)}';

    // Cache hit
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return cached.value;
    }

    try {
      final uri = Uri.parse(
        '$_baseUrl'
        '?lat=$lat'
        '&lon=$lng'
        '&format=json'
        '&accept-language=ar'
        '&zoom=14'
        '&addressdetails=1',
      );

      // [FIX] المتصفحات تمنع إرسال User-Agent برمجياً (CORS)
      final headers = <String, String>{};
      if (!kIsWeb) {
        headers['User-Agent'] = _userAgent;
      }

      final response = await http
          .get(
            uri,
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        debugPrint(
          'Nominatim non-200: ${response.statusCode} for ($lat, $lng)',
        );
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final info = AddressInfo.fromNominatim(json, lat: lat, lng: lng);

      _cache[key] = _CacheEntry(info, DateTime.now());
      return info;
    } catch (e) {
      debugPrint('ReverseGeocodingService.resolve error: $e');
      return null;
    }
  }

  /// يمسح الـ cache — استخدمه عند forceRefresh.
  static void clearCache() => _cache.clear();

  /// عدد الطلبات المُخزَّنة — للتشخيص.
  static int get cacheSize => _cache.length;

  /// Haversine للمسافات — مساعد.
  static double haversineKm(
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

    // [FIX] استخدام clamp لتجنب NaN في حال كانت a أكبر من 1 قليلاً
    final c = 2 *
        math.atan2(
          math.sqrt(a.clamp(0.0, 1.0)),
          math.sqrt((1 - a).clamp(0.0, 1.0)),
        );
    return 6371.0 * c;
  }
}

class _CacheEntry {
  _CacheEntry(this.value, this.timestamp);

  final AddressInfo value;
  final DateTime timestamp;

  bool get isExpired =>
      DateTime.now().difference(timestamp) >
      ReverseGeocodingService._cacheDuration;
}
