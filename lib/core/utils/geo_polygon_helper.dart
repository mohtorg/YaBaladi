// lib/core/utils/geo_polygon_helper.dart
// [v1.2 — 2026-11-12] — REGEXP REMOVAL.
//   - Removed the only `RegExp` usage in the file (was in `_parseStringPoint`).
//     Newer Dart SDK analyzers warn that `RegExp` is slated to become `final`,
//     producing a `deprecated_member_use` diagnostic even on the constructor
//     call. Replaced with an explicit character-by-character parser that:
//       * handles "31.26° N, 32.28° E", "31.26N, 32.28E", "31.26 N 32.28 E"
//       * treats N/S/E/W as sign: N/E → positive, S/W → negative
//       * ignores degree symbols, whitespace, and commas
//   - Public API unchanged: isPointInPolygon, parsePolygon, haversineMeters.
//   - v1.1 change (GeoJSON ambiguity fix) remains in effect.
//
// [v1.1 — 2026-11-12] — GEOJSON AMBIGUITY FIX.
//   - GeoJSON wrapper `{type:"Polygon", coordinates:[[[lng,lat], ...]]}` is now
//     parsed EXPLICITLY as [lng, lat] (no >90 heuristic). The old heuristic
//     failed for coordinates inside Egypt (~31°N, ~32°E) where both lat and lng
//     are < 90, causing inverted latitude/longitude and silently breaking zone
//     validation.
//   - MultiPolygon is supported: first polygon's outer ring is used.
//   - Bare arrays `[[lat, lng], ...]` (Firestore stored format) keep using the
//     heuristic — backwards compatible.

import 'dart:math' show atan2, cos, sin, sqrt, pi;

class GeoPolygonHelper {
  GeoPolygonHelper._();

  // ═══════════════════════════════════════════════════════════════
  // 1. Point-in-Polygon (Ray Casting Algorithm)
  // ═══════════════════════════════════════════════════════════════

  /// يتحقق هل النقطة (lat, lng) تقع داخل المضلع أم لا.
  /// المضلع يجب أن يكون قائمة نقاط [{lat, lng}, ...]
  static bool isPointInPolygon({
    required double lat,
    required double lng,
    required List<Map<String, double>> polygon,
  }) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final xi = polygon[i]['lng'];
      final yi = polygon[i]['lat'];
      final xj = polygon[j]['lng'];
      final yj = polygon[j]['lat'];

      if (xi == null || yi == null || xj == null || yj == null) {
        j = i;
        continue;
      }

      final intersect = ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
      j = i;
    }
    return inside;
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. Robust Polygon Parser
  // ═══════════════════════════════════════════════════════════════

  /// يحوّل أي صيغة polygons إلى قائمة موحدة [{lat, lng}, ...].
  ///
  /// الصيغ المدعومة:
  ///   - GeoJSON Polygon:    {type:"Polygon", coordinates:[[[lng,lat],...]]}
  ///   - GeoJSON MultiPolygon: {type:"MultiPolygon", coordinates:[[[[lng,lat],...]]]}
  ///                          → تُستخدم أول مضلع فقط.
  ///   - Bare array:         [[lat, lng], ...]  (صيغة التخزين في Firestore)
  ///   - Bare array:         [[lng, lat], ...]  (يُكتشف تلقائياً إن |lng|>90)
  ///   - Map points:         [{lat:..., lng:...}, ...]
  ///   - String points:      ["31.26° N, 32.28° E", ...]
  static List<Map<String, double>> parsePolygon(dynamic raw) {
    if (raw == null) return [];

    // GeoJSON wrapper — المسار صريح [lng, lat]
    if (raw is Map && raw['coordinates'] is List) {
      final coords = raw['coordinates'] as List;
      if (coords.isEmpty || coords[0] is! List) return [];

      final outerRingOrFirstPolygon = coords[0] as List;
      if (outerRingOrFirstPolygon.isEmpty ||
          outerRingOrFirstPolygon[0] is! List) {
        return [];
      }

      final firstPointOrRing = outerRingOrFirstPolygon[0] as List;
      if (firstPointOrRing.isEmpty) return [];

      // Polygon: coords[0] = outer ring = [[lng,lat], ...]
      //   ⇒ firstPointOrRing = [lng, lat] ⇒ firstPointOrRing[0] = num
      if (firstPointOrRing[0] is num) {
        return _parseListAsLngLat(outerRingOrFirstPolygon);
      }

      // MultiPolygon: coords[0][0] = outer ring = [[lng,lat], ...]
      //   ⇒ firstPointOrRing = [[lng,lat], ...] ⇒ firstPointOrRing[0] = List
      if (firstPointOrRing[0] is List) {
        return _parseListAsLngLat(firstPointOrRing);
      }

      return [];
    }

    if (raw is List) {
      return _parseList(raw);
    }

    return [];
  }

  static List<Map<String, double>> _parseList(List raw) {
    final points = <Map<String, double>>[];
    for (final point in raw) {
      final parsed = _parsePoint(point);
      if (parsed != null) points.add(parsed);
    }
    return points;
  }

  static List<Map<String, double>> _parseListAsLngLat(List raw) {
    final points = <Map<String, double>>[];
    for (final point in raw) {
      final parsed = _parsePointAsLngLat(point);
      if (parsed != null) points.add(parsed);
    }
    return points;
  }

  static Map<String, double>? _parsePoint(dynamic point) {
    // Format 1: [lat, lng] (default) أو [lng, lat] (إن |a|>90)
    if (point is List && point.length >= 2) {
      final a = _toDouble(point[0]);
      final b = _toDouble(point[1]);
      if (a == null || b == null) return null;

      // heuristic: longitude يتراوح بين -180..180، latitude بين -90..90.
      // إذا القيمة الأولى > 90 فهي قطعاً longitude.
      // إذا كلاهما < 90 (مصر) نفترض [lat, lng] — وهو صيغة Firestore.
      if (a.abs() > 90 && b.abs() <= 90) {
        return {'lat': b, 'lng': a};
      }
      return {'lat': a, 'lng': b};
    }

    // Format 2: Map
    if (point is Map) {
      final lat = _toDouble(point['lat'] ?? point['latitude']);
      final lng = _toDouble(point['lng'] ?? point['lon'] ?? point['longitude']);
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
    }

    // Format 3: String "31.26° N, 32.28° E"
    if (point is String) {
      return _parseStringPoint(point);
    }

    return null;
  }

  static Map<String, double>? _parsePointAsLngLat(dynamic point) {
    if (point is List && point.length >= 2) {
      final lng = _toDouble(point[0]);
      final lat = _toDouble(point[1]);
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
    }
    if (point is Map) {
      final lat = _toDouble(point['lat'] ?? point['latitude']);
      final lng = _toDouble(point['lng'] ?? point['lon'] ?? point['longitude']);
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
    }
    return null;
  }

  /// محلل يدوي بدون RegExp.
  ///
  /// يستقبل صيغة مثل "31.26° N, 32.28° E" ويستخرج (lat, lng).
  ///
  /// القواعد:
  ///   - الأرقام (مع - و .) تُجمَّع في buffer.
  ///   - عند رؤية N/S/E/W: يُسند buffer للاتجاه المقابل ثم يُفرَّغ.
  ///     * N/E → قيمة مطلقة موجبة.
  ///     * S/W → قيمة مطلقة سالبة.
  ///   - أي حرف آخر (مسافة، فاصلة، °) يُتجاهَل بدون تفريغ buffer —
  ///     حتى يبقى الرقم صالحاً عبر "31.26 ° N" أو "31.26 N".
  static Map<String, double>? _parseStringPoint(String s) {
    double? lat;
    double? lng;
    final digits = StringBuffer();

    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      final lower = ch.toLowerCase();
      final code = ch.codeUnitAt(0);
      final isDigitChar = ch == '-' || ch == '.' || (code >= 48 && code <= 57);

      if (isDigitChar) {
        digits.write(ch);
        continue;
      }

      if (lower == 'n' || lower == 's' || lower == 'e' || lower == 'w') {
        if (digits.isNotEmpty) {
          final value = double.tryParse(digits.toString());
          digits.clear();
          if (value != null) {
            switch (lower) {
              case 'n':
                lat = value.abs();
                break;
              case 's':
                lat = -value.abs();
                break;
              case 'e':
                lng = value.abs();
                break;
              case 'w':
                lng = -value.abs();
                break;
            }
          }
        }
        continue;
      }
      // أي حرف آخر (مسافة، فاصلة، °، حرف غير معروف) → يُتجاهَل.
    }

    if (lat != null && lng != null) {
      return {'lat': lat, 'lng': lng};
    }
    return null;
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. Haversine (مسافة بين نقطتين — للاستخدام الداخلي)
  // ═══════════════════════════════════════════════════════════════

  static double haversineMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
