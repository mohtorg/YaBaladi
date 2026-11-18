// lib/core/services/zone_service.dart
//
// [v2.0 — REBUILT] — Fresh clean rebuild, functionally identical to v1.1.
//   No logic changes, only formatting and clarity improvements.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geobase/geobase.dart';

/// خدمة تحدد اسم المنطقة (الحي) بناءً على إحداثيات GPS.
///
/// - Singleton: تحميل ملفات GeoJSON مرة واحدة فقط.
/// - Thread-safe: يستخدم Future cache لمنع التحميل المزدوج.
/// - Accurate: يدعم Polygon holes و MultiPolygon و degenerate rings.
class ZoneService {
  // ─── Singleton ───
  static final ZoneService _instance = ZoneService._internal();
  factory ZoneService() => _instance;
  ZoneService._internal();

  // ─── Config ───
  static const List<String> _governoratesFiles = [
    'assets/data/port_said_zones.geojson',
  ];

  // ─── State ───
  final List<FeatureCollection> _featureCollections = [];
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  // ═══════════════════════════════════════════════════════════════
  // Public API
  // ═══════════════════════════════════════════════════════════════

  /// يُرجع اسم المنطقة/الحي، أو:
  /// - `null` إذا لم يتم تحميل بيانات GeoJSON (فشل تحميل)
  /// - `'منطقة غير معروفة'` إذا كانت النقطة خارج كل المضلعات
  Future<String?> getZoneName(double latitude, double longitude) async {
    await _ensureLoaded();
    if (_featureCollections.isEmpty) return null;

    final userPosition = Geographic(lon: longitude, lat: latitude);
    String? exactNeighborhood;
    String? generalArea;

    for (final collection in _featureCollections) {
      for (final feature in collection.features) {
        final geometry = feature.geometry;
        if (geometry == null) continue;
        if (geometry is! Polygon && geometry is! MultiPolygon) continue;
        if (!_containsPoint(userPosition, geometry)) continue;

        final props = feature.properties;
        final placeType = props['place']?.toString();
        final adminLevel = props['admin_level']?.toString();
        final zoneName =
            props['name']?.toString() ?? props['name:ar']?.toString();

        if (zoneName == null) continue;

        if (placeType == 'neighbourhood') {
          exactNeighborhood = zoneName;
          break;
        }

        if (adminLevel != '4') {
          generalArea ??= zoneName;
        }
      }
      if (exactNeighborhood != null) break;
    }

    return exactNeighborhood ?? generalArea ?? 'منطقة غير معروفة';
  }

  // ═══════════════════════════════════════════════════════════════
  // Loading
  // ═══════════════════════════════════════════════════════════════

  Future<void> _ensureLoaded() {
    if (_isLoaded) return Future.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      for (final path in _governoratesFiles) {
        final jsonString = await rootBundle.loadString(path);
        final collection = FeatureCollection.parse(
          jsonString,
          format: GeoJSON.feature,
        );
        _featureCollections.add(collection);
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ ZoneService: خطأ في تحميل GeoJSON: $e');
      _featureCollections.clear();
      _isLoaded = false;
      _loadFuture = null; // السماح بإعادة المحاولة
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Geometry
  // ═══════════════════════════════════════════════════════════════

  bool _containsPoint(Position p, Geometry g) {
    if (g is Polygon) return _containsInPolygon(p, g);
    if (g is MultiPolygon) {
      for (final poly in g.polygons) {
        if (_containsInPolygon(p, poly)) return true;
      }
    }
    return false;
  }

  bool _containsInPolygon(Position p, Polygon poly) {
    if (poly.rings.isEmpty) return false;
    // النقطة يجب أن تكون داخل الحلقة الخارجية
    if (!_containsInRing(p, poly.rings.first)) return false;
    // ويجب ألا تكون داخل أي "ثقب" (حلقة داخلية)
    for (int i = 1; i < poly.rings.length; i++) {
      if (_containsInRing(p, poly.rings[i])) return false;
    }
    return true;
  }

  /// Ray-casting algorithm (يتحمل الحلقات المشوهة)
  bool _containsInRing(Position p, PositionSeries ring) {
    final n = ring.positionCount;
    if (n < 3) return false; // حلقة صحيحة تحتاج 3 نقاط على الأقل

    bool inside = false;
    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = ring.x(i), yi = ring.y(i);
      final xj = ring.x(j), yj = ring.y(j);

      final crosses = ((yi > p.y) != (yj > p.y)) &&
          (p.x < (xj - xi) * (p.y - yi) / (yj - yi) + xi);
      if (crosses) inside = !inside;
    }
    return inside;
  }
}
