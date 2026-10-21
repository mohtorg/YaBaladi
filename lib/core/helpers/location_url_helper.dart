// lib/core/helpers/location_url_helper.dart
//
// [v1.0 — 2026-10-21] — Central Location URL Helper
//   - Generates Google Maps URLs from coordinates
//   - Extracts coordinates from pasted URLs (q=, @, place/)
//   - Opens external links safely
//   - Handles phone calls and WhatsApp
//   - Will be reused by Merchant Registration in future waves

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationUrlHelper {
  LocationUrlHelper._();

  // ═══════════════════════════════════════════════════════════════
  // URL Generators
  // ═══════════════════════════════════════════════════════════════

  /// توليد رابط "عرض على الخريطة"
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

  /// توليد رابط "الاتجاهات"
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
  // Coordinate Extraction (from pasted URLs)
  // ═══════════════════════════════════════════════════════════════

  /// استخراج الإحداثيات من رابط Google Maps ملصوق
  /// الصيغ المدعومة:
  ///   - https://maps.google.com/?q=31.26,32.29
  ///   - https://www.google.com/maps/@31.26,32.29,15z
  ///   - https://www.google.com/maps/place/31.26,32.29
  ///   - 31.26, 32.29 (بدون رابط)
  static ({double lat, double lng})? extractCoordinates(String url) {
    if (url.trim().isEmpty) return null;

    final patterns = [
      // q=31.26,32.29
      RegExp(r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)'),
      // @31.26,32.29
      RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)'),
      // place/31.26,32.29
      RegExp(r'place/(-?\d+\.\d+),(-?\d+\.\d+)'),
      // أي "lat,lng" عام
      RegExp(r'(-?\d+\.\d+),\s*(-?\d+\.\d+)'),
    ];

    for (final regex in patterns) {
      final match = regex.firstMatch(url);
      if (match != null) {
        final lat = double.tryParse(match.group(1)!);
        final lng = double.tryParse(match.group(2)!);
        if (lat != null && lng != null && _isValidCoordinate(lat, lng)) {
          return (lat: lat, lng: lng);
        }
      }
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // External Actions
  // ═══════════════════════════════════════════════════════════════

  /// فتح رابط خارجي بأمان
  static Future<bool> open(String? url) async {
    if (url == null || url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  /// فتح تطبيق الاتصال
  static Future<bool> call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return false;
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return false;
    return open('tel:$cleaned');
  }

  /// فتح واتساب
  static Future<bool> openWhatsApp(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return false;
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return false;
    return open('https://wa.me/$cleaned');
  }

  // ═══════════════════════════════════════════════════════════════
  // Validation
  // ═══════════════════════════════════════════════════════════════

  static bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}
