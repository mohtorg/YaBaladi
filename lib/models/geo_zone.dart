// lib/models/geo_zone.dart
// [v1.0 — 2026-10-29] — Wave 18: المناطق الجغرافية الدقيقة من OSM

import 'package:cloud_firestore/cloud_firestore.dart';

class GeoZone {
  final String id;
  final String nameAr;
  final String nameEn;
  final GeoPoint center;
  final List<GeoPoint> polygon;
  final double south, west, north, east;

  const GeoZone({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.center,
    required this.polygon,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  factory GeoZone.fromMap(String id, Map<String, dynamic> d) {
    return GeoZone(
      id: id,
      nameAr: d['nameAr']?.toString() ?? '',
      nameEn: d['nameEn']?.toString() ?? '',
      center: d['center'] as GeoPoint,
      polygon: (d['polygon'] as List).cast<GeoPoint>(),
      south: (d['south'] as num).toDouble(),
      west: (d['west'] as num).toDouble(),
      north: (d['north'] as num).toDouble(),
      east: (d['east'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'center': center,
      'polygon': polygon,
      'south': south,
      'west': west,
      'north': north,
      'east': east,
    };
  }

  /// فحص سريع جداً: هل النقطة داخل المستطيل المحيط بالمنطقة؟
  bool containsInBBox(double lat, double lng) {
    return lat >= south && lat <= north && lng >= west && lng <= east;
  }

  /// فحص دقيق (Ray Casting): هل النقطة داخل المضلع الفعلي؟
  bool containsPoint(double lat, double lng) {
    if (!containsInBBox(lat, lng)) return false;
    int crossings = 0;
    for (var i = 0; i < polygon.length; i++) {
      final a = polygon[i];
      final b = polygon[(i + 1) % polygon.length];
      if ((a.latitude <= lat && b.latitude > lat) ||
          (b.latitude <= lat && a.latitude > lat)) {
        final t = (lat - a.latitude) / (b.latitude - a.latitude);
        final x = a.longitude + t * (b.longitude - a.longitude);
        if (lng < x) crossings++;
      }
    }
    return crossings.isOdd;
  }
}
