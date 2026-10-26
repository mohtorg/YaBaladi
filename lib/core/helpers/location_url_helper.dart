// lib/core/helpers/location_url_helper.dart
//
// [v2.1 — 2026-10-26] — BUILD FIX: Strict Raw Strings for RegExp (No deprecation warnings)

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationUrlHelper {
  LocationUrlHelper._();

  // ═══════════════════════════════════════════════════════════════
  // URL Generators (تعمل بشكل كامل)
  // ═══════════════════════════════════════════════════════════════

  static String? mapUrl({
    double? lat,
    double? lng,
    GeoPoint? location,
  }) {
    final finalLat = lat ?? location?.latitude;
    final finalLng = lng ?? location?.longitude;
    if (finalLat == null || finalLng == null) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$finalLat,$finalLng';
  }

  static String? directionsUrl({
    double? lat,
    double? lng,
    GeoPoint? location,
  }) {
    final finalLat = lat ?? location?.latitude;
    final finalLng = lng ?? location?.longitude;
    if (finalLat == null || finalLng == null) return null;
    return 'https://www.google.com/maps/dir/?api=1&destination=$finalLat,$finalLng';
  }

  // ═══════════════════════════════════════════════════════════════
  // Coordinate Extraction
  // ═══════════════════════════════════════════════════════════════

  static const String _num = r'(-?\d+(?:\.\d+)?)';

  // ✅ [FIX] استخدام r'...' لتجنب تحذيرات RegExp المهجورة
  static final List<RegExp> _coordinatePatterns = [
    RegExp(r'!3d' + _num + r'!4d' + _num),
    RegExp(
      r'[?&](?:q|query|ll|destination)=' + _num + r'(?:,|%2C)\s*\+?' + _num,
      caseSensitive: false,
    ),
    RegExp(r'@' + _num + r',' + _num),
    RegExp(r'place/' + _num + r',\+?' + _num),
    RegExp(r'^\s*' + _num + r'\s*[,;]\s*' + _num + r'\s*$'),
  ];

  static ({double lat, double lng})? extractCoordinates(String url) {
    final input = url.trim();
    if (input.isEmpty) return null;

    for (final pattern in _coordinatePatterns) {
      final match = pattern.firstMatch(input);
      if (match == null) continue;

      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null && _isValidCoordinate(lat, lng)) {
        return (lat: lat, lng: lng);
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // External Actions (Graceful Degradation — بدون Crash)
  // ═══════════════════════════════════════════════════════════════

  static Future<bool> open(String? url) async {
    if (url == null || url.trim().isEmpty) return false;
    debugPrint(
      'LocationUrlHelper.open: "$url" — url_launcher not available in FlutterLab',
    );
    return false;
  }

  static Future<bool> call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return false;

    final trimmed = phone.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return false;

    final cleaned = trimmed.startsWith('+') ? '+$digits' : digits;
    return open('tel:$cleaned');
  }

  static Future<bool> openWhatsApp(
    String? phone, {
    String? defaultCountryCode,
  }) async {
    if (phone == null || phone.trim().isEmpty) return false;

    var cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return false;

    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    } else if (defaultCountryCode != null && cleaned.startsWith('0')) {
      cleaned = '$defaultCountryCode${cleaned.substring(1)}';
    }

    return open('https://wa.me/$cleaned');
  }

  // ═══════════════════════════════════════════════════════════════
  // Validation
  // ═══════════════════════════════════════════════════════════════

  static bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}
