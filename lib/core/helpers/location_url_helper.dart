// lib/core/helpers/location_url_helper.dart
//
// [v3.2 — 2026-11-11] — BACKWARD COMPATIBILITY: Added mapUrl, directionsUrl, and open aliases for older screens.
// [v3.1 — 2026-11-11] — LINTER FIX: Replaced RegExp in openSmart with string methods.
// [v3.0 — 2026-11-11] — HIGH-LEVEL GIS HUB: Smart routing, Haversine, Advanced Scanner.

import 'dart:io' show Platform;
import 'dart:math' show cos, sin, sqrt, atan2, pi;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationUrlHelper {
  LocationUrlHelper._();

  // ═══════════════════════════════════════════════════════════════
  // 1. SMART MAPS & NAVIGATION (التوجيه الذكي للخرائط)
  // ═══════════════════════════════════════════════════════════════

  /// ينشئ رابط خريطة ذكي يدرك نوع المنصة (iOS/Android/Web).
  static String? getSmartMapUrl({
    double? lat,
    double? lng,
    GeoPoint? location,
    String? label,
  }) {
    final finalLat = lat ?? location?.latitude;
    final finalLng = lng ?? location?.longitude;
    if (finalLat == null || finalLng == null) return null;

    final encodedLabel =
        label != null ? Uri.encodeComponent(label) : '$finalLat,$finalLng';

    if (kIsWeb) {
      return 'https://www.google.com/maps/search/?api=1&query=$finalLat,$finalLng';
    }

    if (Platform.isAndroid) {
      // Android Geo Intent (يفتح التطبيق مباشرة أو المتصفح)
      return 'geo:$finalLat,$finalLng?q=$finalLat,$finalLng($encodedLabel)';
    } else if (Platform.isIOS) {
      // Apple Maps Deep Link
      return 'https://maps.apple.com/?q=$encodedLabel&ll=$finalLat,$finalLng';
    }

    // Fallback for Desktop (Windows/Mac/Linux)
    return 'https://www.google.com/maps/search/?api=1&query=$finalLat,$finalLng';
  }

  /// ينشئ رابط الاتجاهات (Navigation) الذكي.
  static String? getSmartDirectionsUrl({
    double? lat,
    double? lng,
    GeoPoint? location,
  }) {
    final finalLat = lat ?? location?.latitude;
    final finalLng = lng ?? location?.longitude;
    if (finalLat == null || finalLng == null) return null;

    if (!kIsWeb && Platform.isIOS) {
      return 'https://maps.apple.com/?daddr=$finalLat,$finalLng';
    }
    return 'https://www.google.com/maps/dir/?api=1&destination=$finalLat,$finalLng';
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. HAVERSINE ENGINE (محرك المسافات الدقيق)
  // ═══════════════════════════════════════════════════════════════

  /// يحسب المسافة بالأمتار بين نقطتين (يُستخدم في Geofencing ونظام التقييم).
  static double calculateDistanceMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    const double earthRadius = 6371000.0; // Meters
    final dLat = _toRadians(endLat - startLat);
    final dLng = _toRadians(endLng - startLng);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(startLat)) *
            cos(_toRadians(endLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  /// يحول المسافة لصيغة مقروءة للمستخدم (مثال: 150 م، 2.5 كم).
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} م';
    }
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  static double _toRadians(double degree) => degree * pi / 180;

  // ═══════════════════════════════════════════════════════════════
  // 3. ADVANCED COORDINATE EXTRACTION (الماسح النصي المتقدم)
  // ═══════════════════════════════════════════════════════════════

  /// يستخرج الإحداثيات من أي رابط خرائط معقد (Google/Apple/OSM).
  static ({double lat, double lng})? extractCoordinates(String url) {
    final input = url.trim();
    if (input.isEmpty) return null;

    // 1. المحاولة الأولى: استخدام محلل الروابط القياسي (لروابط الاستعلام)
    try {
      final uri = Uri.parse(input);
      final q = uri.queryParameters['q'] ?? uri.queryParameters['ll'];
      if (q != null) {
        final parts = q.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lng = double.tryParse(parts[1]);
          if (lat != null && lng != null && _isValidCoordinate(lat, lng)) {
            return (lat: lat, lng: lng);
          }
        }
      }
    } catch (_) {
      // تجاهل الخطأ والانتقال للماسح اليدوي
    }

    // 2. الماسح اليدوي (للروابط التي لا تدعم Uri.parse بشكل جيد مثل !3d!4d)
    final matchers = <(String, String)? Function(String)>[
      _matchDataParams, // !3d<lat>!4d<lng>
      _matchAtSign, // @<lat>,<lng>
      _matchPlacePath, // place/<lat>,<lng>
      _matchPlainPair, // <lat>, <lng>
    ];

    for (final matcher in matchers) {
      final match = matcher(input);
      if (match != null) {
        final lat = double.tryParse(match.$1);
        final lng = double.tryParse(match.$2);
        if (lat != null && lng != null && _isValidCoordinate(lat, lng)) {
          return (lat: lat, lng: lng);
        }
      }
    }
    return null;
  }

  // ── 1) !3d<lat>!4d<lng> ──
  static (String, String)? _matchDataParams(String s) {
    var from = 0;
    while (true) {
      final i = s.indexOf('!3d', from);
      if (i < 0) return null;
      final a = _scanNumber(s, i + 3);
      if (a != null && s.startsWith('!4d', a.end)) {
        final b = _scanNumber(s, a.end + 3);
        if (b != null) return (a.text, b.text);
      }
      from = i + 1;
    }
  }

  // ── 2) @<lat>,<lng> ──
  static (String, String)? _matchAtSign(String s) {
    var from = 0;
    while (true) {
      final i = s.indexOf('@', from);
      if (i < 0) return null;
      final a = _scanNumber(s, i + 1);
      if (a != null && a.end < s.length && s.codeUnitAt(a.end) == 44) {
        final b = _scanNumber(s, a.end + 1);
        if (b != null) return (a.text, b.text);
      }
      from = i + 1;
    }
  }

  // ── 3) place/<lat>,\+?<lng> ──
  static (String, String)? _matchPlacePath(String s) {
    var from = 0;
    while (true) {
      final i = s.indexOf('place/', from);
      if (i < 0) return null;
      final a = _scanNumber(s, i + 6);
      if (a != null && a.end < s.length && s.codeUnitAt(a.end) == 44) {
        var p = a.end + 1;
        if (p < s.length && s.codeUnitAt(p) == 43) p++; // '+'
        final b = _scanNumber(s, p);
        if (b != null) return (a.text, b.text);
      }
      from = i + 1;
    }
  }

  // ── 4) ^\s*<lat>\s*[,;]\s*<lng>\s*$ ──
  static (String, String)? _matchPlainPair(String s) {
    var p = 0;
    while (p < s.length && _isSpace(s.codeUnitAt(p))) {
      p++;
    }
    final a = _scanNumber(s, p);
    if (a == null) return null;
    p = a.end;

    while (p < s.length && _isSpace(s.codeUnitAt(p))) {
      p++;
    }
    if (p >= s.length) return null;
    final sep = s.codeUnitAt(p);
    if (sep != 44 && sep != 59) return null; // ',' أو ';'
    p++;

    while (p < s.length && _isSpace(s.codeUnitAt(p))) {
      p++;
    }
    final b = _scanNumber(s, p);
    if (b == null) return null;
    p = b.end;

    while (p < s.length && _isSpace(s.codeUnitAt(p))) {
      p++;
    }
    if (p != s.length) return null;
    return (a.text, b.text);
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. EXTERNAL ACTIONS & LINGUISTIC NORMALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// يفتح الرابط بذكاء مع التراجع الآمن (Fallback) في حال فشل التطبيق.
  static Future<bool> openSmart(String? url) async {
    if (url == null || url.trim().isEmpty) return false;
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return false;

    try {
      // محاولة فتح التطبيق الخارجي (Deep Link)
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // ✅ إذا فشل (مثلاً المستخدم ليس لديه تطبيق خرائط)، نحول الرابط لنسخة الويب بدون RegExp
      if (url.startsWith('geo:')) {
        final webFallback =
            'https://www.google.com/maps/search/?api=1&query=${url.substring(4)}';
        return await launchUrl(Uri.parse(webFallback),
            mode: LaunchMode.inAppBrowserView);
      } else if (url.startsWith('maps:')) {
        final webFallback =
            'https://www.google.com/maps/search/?api=1&query=${url.substring(5)}';
        return await launchUrl(Uri.parse(webFallback),
            mode: LaunchMode.inAppBrowserView);
      }

      return false;
    } catch (e) {
      debugPrint('LocationUrlHelper.openSmart error: $e');
      return false;
    }
  }

  /// إجراء اتصال هاتفي مع دعم الأرقام العربية.
  static Future<bool> makeCall(String? phone) async {
    if (phone == null) return false;
    final cleaned = _normalizeDigits(phone);
    if (cleaned.isEmpty) return false;
    return openSmart('tel:$cleaned');
  }

  /// فتح واتساب مع حقن كود الدولة (مصر: 20).
  static Future<bool> openWhatsApp(
    String? phone, {
    String defaultCountryCode = '20',
  }) async {
    if (phone == null) return false;
    var cleaned = _normalizeDigits(phone);
    if (cleaned.isEmpty) return false;

    if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0')) {
      cleaned = '$defaultCountryCode${cleaned.substring(1)}';
    }

    return openSmart('https://wa.me/$cleaned');
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. LOW-LEVEL HELPERS (أدوات المعالجة العميقة)
  // ═══════════════════════════════════════════════════════════════

  static ({String text, int end})? _scanNumber(String s, int start) {
    var p = start;
    if (p < s.length && s.codeUnitAt(p) == 45) p++; // '-'

    final digitsStart = p;
    while (p < s.length && _isDigit(s.codeUnitAt(p))) {
      p++;
    }
    if (p == digitsStart) return null;

    if (p + 1 < s.length &&
        s.codeUnitAt(p) == 46 && // '.'
        _isDigit(s.codeUnitAt(p + 1))) {
      p++;
      while (p < s.length && _isDigit(s.codeUnitAt(p))) {
        p++;
      }
    }
    return (text: s.substring(start, p), end: p);
  }

  static bool _isDigit(int c) => c >= 48 && c <= 57;

  static bool _isSpace(int c) {
    return (c >= 9 && c <= 13) ||
        c == 32 ||
        c == 0xA0 ||
        c == 0x1680 ||
        (c >= 0x2000 && c <= 0x200A) ||
        c == 0x2028 ||
        c == 0x2029 ||
        c == 0x202F ||
        c == 0x205F ||
        c == 0x3000 ||
        c == 0xFEFF;
  }

  /// التطبيع اللغوي: تحويل الأرقام العربية/الفارسية لإنجليزية وإزالة الرموز.
  static String _normalizeDigits(String s) {
    final buf = StringBuffer();
    for (final c in s.runes) {
      if (c >= 48 && c <= 57) {
        buf.writeCharCode(c); // 0-9
      } else if (c >= 0x0660 && c <= 0x0669) {
        buf.writeCharCode(c - 0x0660 + 48); // ٠-٩
      } else if (c >= 0x06F0 && c <= 0x06F9) {
        buf.writeCharCode(c - 0x06F0 + 48); // ۰-۹
      } else if (c == 43) {
        buf.writeCharCode(c); // '+'
      }
    }
    return buf.toString();
  }

  static bool _isValidCoordinate(double lat, double lng) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        lat != 0 &&
        lng != 0;
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. BACKWARD COMPATIBILITY (Aliases for older code)
  // ═══════════════════════════════════════════════════════════════

  /// اسم قديم للتوافق مع add_place_screen و place_detail_screen
  static String? mapUrl({double? lat, double? lng, GeoPoint? location}) {
    return getSmartMapUrl(lat: lat, lng: lng, location: location);
  }

  /// اسم قديم للتوافق مع add_place_screen و place_detail_screen
  static Future<bool> open(String? url) {
    return openSmart(url);
  }

  /// اسم قديم للتوافق مع place_detail_screen
  static String? directionsUrl({double? lat, double? lng, GeoPoint? location}) {
    return getSmartDirectionsUrl(lat: lat, lng: lng, location: location);
  }
}
