// lib/core/helpers/location_url_helper.dart
//
// [v1.2 — 2026-10-22] — Wave 2: Compile fix + hardening
//   - FIX (compile): v1.1 declared List<Pattern> then called .firstMatch(),
//     which does not exist on Pattern. Restored List<RegExp>.
//   - FIX: extraction now supports query=, ll=, destination=, %2C and
//     ", +" separators (the app's own mapUrl/directionsUrl output included).
//   - FIX: coordinates without decimals ("31, 32") are accepted.
//   - FIX: call() keeps "+" only at the start; 00 prefix handled for WhatsApp.
//   - KEPT: all URL generators and external actions (same public API).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  static const String _num = r'(-?\d+(?:\.\d+)?)';

  /// الأنماط تُبنى مرة واحدة. الترتيب مهم: الأدق أولاً.
  /// ملاحظة: النوع RegExp (وليس Pattern) لأن firstMatch غير معرّفة في Pattern.
  static final List<RegExp> _coordinatePatterns = [
    // !3d..!4d.. — إحداثيات المكان الفعلية (أدق من @ لأن @ مركز العرض)
    RegExp('!3d$_num!4d$_num'),
    // q= / query= / ll= / destination=  (يدعم %2C وفاصلة + مسافة)
    RegExp(
      '[?&](?:q|query|ll|destination)=$_num(?:,|%2C)\\s*\\+?$_num',
      caseSensitive: false,
    ),
    // @lat,lng
    RegExp('@$_num,$_num'),
    // place/lat,lng
    RegExp('place/$_num,\\+?$_num'),
    // "lat,lng" مجردة — النص كله إحداثيات فقط
    RegExp('^\\s*$_num\\s*[,;]\\s*$_num\\s*\$'),
  ];

  /// استخراج الإحداثيات من رابط Google Maps ملصوق
  /// ⚠️ الروابط المختصرة (goo.gl / maps.app) تُرجع null
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
  // External Actions
  // ═══════════════════════════════════════════════════════════════

  /// فتح رابط خارجي بأمان
  static Future<bool> open(String? url) async {
    if (url == null || url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url.trim());
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('LocationUrlHelper.open failed for "$url": $e');
    }
    return false;
  }

  /// فتح تطبيق الاتصال
  static Future<bool> call(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return false;

    final trimmed = phone.trim();
    final digits = trimmed.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return false;

    // "+" مسموح في البداية فقط
    final cleaned = trimmed.startsWith('+') ? '+$digits' : digits;
    return open('tel:$cleaned');
  }

  /// فتح واتساب
  /// [defaultCountryCode] — مفتاح الدولة بدون + (مثال: '20' لمصر)
  ///   إذا كان الرقم يبدأ بـ 0 محلياً، سيُستبدل هذا الصفر بالمفتاح.
  ///   وإذا بدأ بـ 00 (صيغة دولية) تُحذف الصفران.
  static Future<bool> openWhatsApp(
    String? phone, {
    String? defaultCountryCode,
  }) async {
    if (phone == null || phone.trim().isEmpty) return false;

    var cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.isEmpty) return false;

    if (cleaned.startsWith('00')) {
      // 0020100... → 20100...
      cleaned = cleaned.substring(2);
    } else if (defaultCountryCode != null && cleaned.startsWith('0')) {
      // 0100... → 20100...
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
