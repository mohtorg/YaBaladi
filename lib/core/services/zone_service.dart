// lib/core/services/zone_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geobase/geobase.dart';

class ZoneService {
  static final ZoneService _instance = ZoneService._internal();
  factory ZoneService() => _instance;
  ZoneService._internal();

  // ✅ قائمة بملفات المحافظات (أضف أي محافظة جديدة هنا مستقبلاً)
  static const List<String> _governoratesFiles = [
    'assets/data/port_said_zones.geojson', // ✅ تم تعديل الاسم ليطابق اسم الملف الفعلي
    // 'assets/data/cairo.geojson',       // مثال للمستقبل
    // 'assets/data/alexandria.geojson',  // مثال للمستقبل
  ];

  // قائمة لحفظ بيانات كل الملفات في الذاكرة
  final List<FeatureCollection> _featureCollections = [];
  bool _isLoaded = false;

  /// تحميل كل ملفات الـ GeoJSON من الـ Assets
  Future<void> _loadGeoJson() async {
    if (_isLoaded) return;

    try {
      for (final filePath in _governoratesFiles) {
        final jsonString = await rootBundle.loadString(filePath);
        // ✅ التصحيح: استخدام parse بدلاً من fromJson
        final collection = FeatureCollection.parse(
          jsonString,
          format: GeoJSON.feature,
        );
        _featureCollections.add(collection);
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('خطأ في تحميل ملفات GeoJSON: $e');
    }
  }

  /// جلب اسم المنطقة بناءً على خطوط الطول والعرض
  Future<String?> getZoneName(double latitude, double longitude) async {
    await _loadGeoJson();
    if (_featureCollections.isEmpty) return null;

    // ✅ التصحيح: استخدام Geographic بدلاً من Point
    final userPosition = Geographic(lon: longitude, lat: latitude);
    String? exactNeighborhood;
    String? generalArea;

    // نبحث في جميع الملفات المحملة
    for (final collection in _featureCollections) {
      for (final feature in collection.features) {
        final geometry = feature.geometry;
        if (geometry == null) continue;

        // نتأكد أننا نتعامل مع مضلع (Polygon) أو (MultiPolygon)
        if (geometry is Polygon || geometry is MultiPolygon) {
          if (_isPositionInGeometry(userPosition, geometry)) {
            // ✅ التصحيح: properties غير قابل لـ null، لذا أزلنا شرط الفحص
            final properties = feature.properties;
            final placeType = properties['place']?.toString();
            final adminLevel = properties['admin_level']?.toString();
            final zoneName = properties['name']?.toString() ??
                properties['name:ar']?.toString();

            if (zoneName != null) {
              // إذا كانت المنطقة "حي" أو "neighbourhood" نأخذها كأولوية قصوى
              if (placeType == 'neighbourhood') {
                exactNeighborhood = zoneName;
                break; // وجدنا الحي الدقيق، نوقف البحث داخل هذا الملف
              }
              // إذا كانت منطقة إدارية (لكن ليست المحافظة نفسها)
              else if (adminLevel != '4') {
                generalArea ??= zoneName; // نحفظها كخيار احتياطي
              }
            }
          }
        }
      }
      // إذا وجدنا الحي الدقيق في أحد الملفات، لا داعي للبحث في باقي المحافظات
      if (exactNeighborhood != null) break;
    }

    // نرجع اسم الحي الدقيق، وإذا لم نجد نرجع المنطقة العامة، وإذا لم نجد نرجع نص افتراضي
    return exactNeighborhood ?? generalArea ?? 'منطقة غير معروفة';
  }

  bool _isPositionInGeometry(Position position, Geometry geometry) {
    if (geometry is Polygon) {
      return _isPositionInPolygon(position, geometry);
    } else if (geometry is MultiPolygon) {
      for (final polygon in geometry.polygons) {
        if (_isPositionInPolygon(position, polygon)) return true;
      }
    }
    return false;
  }

  bool _isPositionInPolygon(Position position, Polygon polygon) {
    // ✅ التصحيح: التعامل مع PositionSeries بشكل صحيح
    final ring = polygon.rings.first;
    bool isInside = false;
    final positionCount = ring.positionCount;

    if (positionCount == 0) return false;

    for (int i = 0, j = positionCount - 1; i < positionCount; j = i++) {
      // ✅ التصحيح: استخدام x(i) و y(i) للحصول على الإحداثيات
      final xi = ring.x(i);
      final yi = ring.y(i);
      final xj = ring.x(j);
      final yj = ring.y(j);

      final intersect = ((yi > position.y) != (yj > position.y)) &&
          (position.x < (xj - xi) * (position.y - yi) / (yj - yi) + xi);
      if (intersect) isInside = !isInside;
    }
    return isInside;
  }
}
