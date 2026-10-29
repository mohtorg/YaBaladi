// lib/core/helpers/location_url_helper.dart
//
// [v2.2 — 2026-10-29] — BUILD FIX: إزالة RegExp كلياً (تحذيرات الإهمال)
//   - استُبدل استخراج الإحداثيات بماسح نصي يدوي يطابق سلوك الأنماط الخمسة السابقة
//     وبالترتيب نفسه (النمط الأول المطابق ثم التحقق من الصلاحية، وإلا الانتقال للتالي).
//   - استُبدل تنقية الأرقام ([^\d]) بدالة _digitsOnly.
//   - KEPT: جميع الواجهات العامة وتواقيعها دون تغيير.
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

  /// الأنماط المدعومة (بالترتيب):
  ///  1. ...!3d<lat>!4d<lng>
  ///  2. ?q= | &query= | &ll= | &destination=  <lat> (, أو %2C) [مسافات] [+] <lng>
  ///  3. @<lat>,<lng>
  ///  4. place/<lat>,[+]<lng>
  ///  5. "<lat>, <lng>" أو "<lat>; <lng>" (النص كله)
  static ({double lat, double lng})? extractCoordinates(String url) {
    final input = url.trim();
    if (input.isEmpty) return null;

    final matchers = <(String, String)? Function(String)>[
      _matchDataParams,
      _matchQueryParam,
      _matchAtSign,
      _matchPlacePath,
      _matchPlainPair,
    ];

    for (final matcher in matchers) {
      final match = matcher(input);
      if (match == null) continue;

      final lat = double.tryParse(match.$1);
      final lng = double.tryParse(match.$2);
      if (lat != null && lng != null && _isValidCoordinate(lat, lng)) {
        return (lat: lat, lng: lng);
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

  // ── 2) [?&](q|query|ll|destination)=<lat>(,|%2C)\s*\+?<lng> ──
  static (String, String)? _matchQueryParam(String s) {
    const keys = ['q', 'query', 'll', 'destination'];
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c != 63 && c != 38) continue; // '?' أو '&'

      for (final key in keys) {
        var p = i + 1;
        if (!_matchesIgnoreCase(s, p, key)) continue;
        p += key.length;
        if (p >= s.length || s.codeUnitAt(p) != 61) continue; // '='
        p++;

        final a = _scanNumber(s, p);
        if (a == null) continue;
        p = a.end;

        if (p < s.length && s.codeUnitAt(p) == 44) {
          p++; // ','
        } else if (_matchesIgnoreCase(s, p, '%2c')) {
          p += 3;
        } else {
          continue;
        }

        while (p < s.length && _isSpace(s.codeUnitAt(p))) {
          p++;
        }
        if (p < s.length && s.codeUnitAt(p) == 43) p++; // '+'

        final b = _scanNumber(s, p);
        if (b == null) continue;
        return (a.text, b.text);
      }
    }
    return null;
  }

  // ── 3) @<lat>,<lng> ──
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

  // ── 4) place/<lat>,\+?<lng> ──
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

  // ── 5) ^\s*<lat>\s*[,;]\s*<lng>\s*$ ──
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

  // ── أدوات الماسح النصي ──

  /// يقرأ رقماً بالصيغة: -?\d+(\.\d+)? ابتداءً من [start].
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

  /// يطابق [lowerKey] (بحروف صغيرة) عند [pos] دون اعتبار حالة الأحرف اللاتينية.
  static bool _matchesIgnoreCase(String s, int pos, String lowerKey) {
    if (pos < 0 || pos + lowerKey.length > s.length) return false;
    for (var k = 0; k < lowerKey.length; k++) {
      var c = s.codeUnitAt(pos + k);
      if (c >= 65 && c <= 90) c += 32; // A-Z → a-z
      if (c != lowerKey.codeUnitAt(k)) return false;
    }
    return true;
  }

  static bool _isDigit(int c) => c >= 48 && c <= 57;

  /// مكافئ \s في Dart: مسافات ASCII وفراغات يونيكود المعتادة.
  static bool _isSpace(int c) {
    return (c >= 9 && c <= 13) || // \t \n \v \f \r
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

  /// يُبقي الأرقام 0-9 فقط (مكافئ replaceAll([^\d], '')).
  static String _digitsOnly(String s) {
    final buf = StringBuffer();
    for (final c in s.codeUnits) {
      if (_isDigit(c)) buf.writeCharCode(c);
    }
    return buf.toString();
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
    final digits = _digitsOnly(trimmed);
    if (digits.isEmpty) return false;

    final cleaned = trimmed.startsWith('+') ? '+$digits' : digits;
    return open('tel:$cleaned');
  }

  static Future<bool> openWhatsApp(
    String? phone, {
    String? defaultCountryCode,
  }) async {
    if (phone == null || phone.trim().isEmpty) return false;

    var cleaned = _digitsOnly(phone);
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
