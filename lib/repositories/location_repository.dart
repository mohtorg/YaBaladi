// lib/repositories/location_repository.dart
// [v1.5] — ADDED: updateZoneNotes function to support admin notes on zones.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/location_hierarchy_models.dart';

class LocationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ═══════════════════════════════════════════════════════════════
  // 1. جلب الأحياء التابعة لمحافظة معينة (للقوائم المنسدلة - النشطة فقط)
  // ═══════════════════════════════════════════════════════════════
  Future<List<DistrictModel>> getDistricts(String governorateId) async {
    try {
      final snapshot = await _firestore
          .collection('districts')
          .where('governorateId', isEqualTo: governorateId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => DistrictModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 2. جلب المناطق التابعة لحي معين (للقوائم المنسدلة - النشطة فقط)
  // ═══════════════════════════════════════════════════════════════
  Future<List<ZoneModel>> getZones(String districtId) async {
    try {
      final snapshot = await _firestore
          .collection('zones')
          .where('districtId', isEqualTo: districtId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => ZoneModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 3. جلب الحدود الجغرافية المتاحة (GeoZones) لربطها
  // ═══════════════════════════════════════════════════════════════
  Future<List<Map<String, String>>> getGeoZones() async {
    try {
      final snap = await _firestore.collection('geo_zones').get();
      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'nameAr': data['nameAr']?.toString() ?? doc.id,
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 4. إضافة منطقة جديدة مع إمكانية ربطها بحدود جغرافية (GeoZone)
  // ═══════════════════════════════════════════════════════════════
  Future<void> addZoneWithGeoData({
    required String id,
    required String nameAr,
    required String nameEn,
    required String districtId,
    String? geoZoneId,
  }) async {
    await _firestore.collection('zones').doc(id).set({
      'nameAr': nameAr,
      'nameEn': nameEn,
      'districtId': districtId,
      'isActive': true,
      if (geoZoneId != null && geoZoneId.isNotEmpty) 'geoZoneId': geoZoneId,
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // 5. جلب كل الأحياء (بدون فلترة isActive) - لشاشة الأدمن
  // ═══════════════════════════════════════════════════════════════
  Future<List<DistrictModel>> getAllDistricts(String govId) async {
    try {
      final snap = await _firestore
          .collection('districts')
          .where('governorateId', isEqualTo: govId)
          .get();
      return snap.docs.map((d) => DistrictModel.fromFirestore(d)).toList();
    } catch (e) {
      return []; // ✅ إرجاع قائمة فارغة عند الخطأ لمنع انهيار الشاشة
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 6. جلب كل المناطق (بدون فلترة isActive) - لشاشة الأدمن
  // ═══════════════════════════════════════════════════════════════
  Future<List<ZoneModel>> getAllZones(String distId) async {
    try {
      final snap = await _firestore
          .collection('zones')
          .where('districtId', isEqualTo: distId)
          .get();
      return snap.docs.map((d) => ZoneModel.fromFirestore(d)).toList();
    } catch (e) {
      return []; // ✅ إرجاع قائمة فارغة عند الخطأ لمنع انهيار الشاشة
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // 7. تفعيل / تعطيل أي عنصر (محافظة، حي، منطقة)
  // ═══════════════════════════════════════════════════════════════
  Future<void> toggleStatus(String collection, String id, bool isActive) async {
    await _firestore
        .collection(collection)
        .doc(id)
        .update({'isActive': isActive});
  }

  // ═══════════════════════════════════════════════════════════════
  // 8. ربط أي عنصر بحدود جغرافية
  // ═══════════════════════════════════════════════════════════════
  Future<void> linkGeoZone(
      String collection, String id, String? geoZoneId) async {
    await _firestore
        .collection(collection)
        .doc(id)
        .update({'geoZoneId': geoZoneId});
  }

  // ═══════════════════════════════════════════════════════════════
  // 9. تحديث ملاحظات المنطقة (جديد)
  // ═══════════════════════════════════════════════════════════════
  Future<void> updateZoneNotes(String zoneId, String? notes) async {
    await _firestore.collection('zones').doc(zoneId).update({
      'notes': notes,
    });
  }
}
