// lib/repositories/geo_zones_repository.dart
// [v1.3.1 — 2026-11-15] — LINTER FIX: Converted districtName and govName to final.
// [v1.3 — 2026-11-15] — RELATIONAL LINKING: Added `getFullLocationName`.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../models/geo_zone.dart';

class GeoZonesRepository {
  GeoZonesRepository._();
  static final GeoZonesRepository instance = GeoZonesRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _zonesRef =>
      _db.collection('geo_zones');

  /// جلب جميع المناطق (مرة واحدة) — العدد ~80 فقط، لا يؤثر على الأداء.
  Future<List<GeoZone>> getAllZones() async {
    final snap = await _zonesRef.get();
    return snap.docs.map((d) => GeoZone.fromMap(d.id, d.data())).toList();
  }

  /// اكتشاف منطقة المستخدم بناءً على إحداثياته.
  Future<GeoZone?> findZoneForPoint(double lat, double lng) async {
    final zones = await getAllZones();

    // 1. فصل المناطق التي تحتوي بالفعل على موقع المستخدم
    final matchingZones =
        zones.where((zone) => zone.containsPoint(lat, lng)).toList();

    if (matchingZones.isEmpty) return null;

    // 2. ترتيب هذه المناطق المطابقة من الأصغر مساحة إلى الأكبر
    matchingZones.sort((a, b) {
      final areaA = (a.north - a.south) * (a.east - a.west);
      final areaB = (b.north - b.south) * (b.east - b.west);
      return areaA.compareTo(areaB);
    });

    return matchingZones.first;
  }

  /// ✅ v1.3: ربط المنطقة بالحي والمحافظة وإرجاع العنوان كاملاً
  Future<String?> getFullLocationName(double lat, double lng) async {
    final zone = await findZoneForPoint(lat, lng);
    if (zone == null) return null;

    // نقرأ البيانات الخام للحصول على المفاتيح الأجنبية (IDs)
    final zoneDoc = await _zonesRef.doc(zone.id).get();
    final zoneData = zoneDoc.data() ?? {};

    final districtId = zoneData['districtId'] as String?;
    final govId = zoneData['governorateId'] as String?;

    // ✅ Linter Fix: استخدام final مع التعيين الشرطي
    final String? districtName = districtId == null
        ? null
        : (await _db.collection('districts').doc(districtId).get())
            .data()?['nameAr'] as String?;

    final String? govName = govId == null
        ? null
        : (await _db.collection('governorates').doc(govId).get())
            .data()?['nameAr'] as String?;

    final parts = <String>[];
    if (zone.nameAr.isNotEmpty) parts.add(zone.nameAr);

    // تجنب التكرار (إذا كان اسم الحي هو نفسه اسم المنطقة)
    if (districtName != null &&
        districtName.isNotEmpty &&
        districtName != zone.nameAr) {
      parts.add(districtName);
    }
    if (govName != null && govName.isNotEmpty && govName != districtName) {
      parts.add(govName);
    }

    return parts.join(' - ');
  }

  /// استيراد البيانات من ملف GeoJSON إلى Firestore.
  Future<Map<String, int>> importFromGeoJson() async {
    final raw =
        await rootBundle.loadString('assets/data/port_said_zones.geojson');
    final geo = jsonDecode(raw) as Map<String, dynamic>;
    final features = geo['features'] as List;

    int imported = 0, skipped = 0, failed = 0;
    final batch = _db.batch();
    int batchCount = 0;

    for (final f in features) {
      try {
        final geom = f['geometry'] as Map<String, dynamic>;
        if (geom['type'] != 'Polygon') {
          skipped++;
          continue;
        }

        final coords = (geom['coordinates'] as List).first as List;
        final points = coords
            .map((c) => GeoPoint(
                  (c[1] as num).toDouble(),
                  (c[0] as num).toDouble(),
                ))
            .toList();

        if (points.length < 4) {
          skipped++;
          continue;
        }

        double south = 90, north = -90, west = 180, east = -180;
        for (final p in points) {
          if (p.latitude < south) south = p.latitude;
          if (p.latitude > north) north = p.latitude;
          if (p.longitude < west) west = p.longitude;
          if (p.longitude > east) east = p.longitude;
        }
        final center = GeoPoint((south + north) / 2, (west + east) / 2);

        final props = f['properties'] as Map<String, dynamic>;
        final nameAr = props['name:ar']?.toString() ??
            props['name']?.toString() ??
            'منطقة غير مسماة';
        final nameEn = props['name:en']?.toString() ?? '';
        final osmId =
            props['@id']?.toString() ?? DateTime.now().toIso8601String();
        final docId = osmId.replaceAll('/', '_');

        final zone = GeoZone(
          id: docId,
          nameAr: nameAr,
          nameEn: nameEn,
          center: center,
          polygon: points,
          south: south,
          west: west,
          north: north,
          east: east,
        );

        batch.set(_zonesRef.doc(docId), zone.toMap());
        imported++;
        batchCount++;

        if (batchCount >= 499) {
          await batch.commit();
          batchCount = 0;
        }
      } catch (e) {
        failed++;
      }
    }

    if (batchCount > 0) {
      await batch.commit();
    }

    return {'imported': imported, 'skipped': skipped, 'failed': failed};
  }
}
