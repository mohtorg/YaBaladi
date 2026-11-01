// lib/repositories/governorates_repository.dart
// [v1.0 — 2026-10-29] — جديد كلياً
// طبقة وصول موحدة لبيانات المحافظات والأحياء.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/location/egypt_governorates.dart';
import '../models/district.dart';
import '../models/governorate_config.dart';

class GovernoratesRepository {
  GovernoratesRepository._();
  static final GovernoratesRepository instance = GovernoratesRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _govRef =>
      _db.collection('governorates');

  CollectionReference<Map<String, dynamic>> _districtsRef(String govId) =>
      _govRef.doc(govId).collection('districts');

  // ═══════════════════════════════════════════════════════════════
  // GOVERNORATES
  // ═══════════════════════════════════════════════════════════════

  Stream<List<GovernorateConfig>> watchAllGovernorates() {
    return _govRef.orderBy('order').snapshots().map((snap) {
      return snap.docs
          .map((d) => GovernorateConfig.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Stream<List<GovernorateConfig>> watchActiveGovernorates() {
    return _govRef.orderBy('order').snapshots().map((snap) {
      return snap.docs
          .map((d) => GovernorateConfig.fromMap(d.id, d.data()))
          .where((g) => g.isActive)
          .toList();
    });
  }

  Future<GovernorateConfig?> getGovernorate(String docId) async {
    if (docId.trim().isEmpty) return null;
    final doc = await _govRef.doc(docId).get();
    if (!doc.exists) return null;
    return GovernorateConfig.fromMap(doc.id, doc.data() ?? {});
  }

  Future<GovernorateConfig?> getGovernorateByNameAr(String nameAr) async {
    final clean = nameAr.trim();
    if (clean.isEmpty) return null;
    final snap = await _govRef.where('nameAr', isEqualTo: clean).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return GovernorateConfig.fromMap(doc.id, doc.data());
  }

  Future<void> setGovernorateActive(String docId, bool isActive) async {
    if (docId.trim().isEmpty) return;
    await _govRef.doc(docId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setDeliveryEnabled(String docId, bool enabled) async {
    if (docId.trim().isEmpty) return;
    await _govRef.doc(docId).update({
      'deliveryEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setTripsEnabled(String docId, bool enabled) async {
    if (docId.trim().isEmpty) return;
    await _govRef.doc(docId).update({
      'tripsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<int> seedAllGovernorates() async {
    int created = 0;
    for (final entry in kEgyptGovernorates.asMap().entries) {
      final index = entry.key;
      final geo = entry.value;

      final existing =
          await _govRef.where('nameAr', isEqualTo: geo.nameAr).limit(1).get();

      if (existing.docs.isEmpty) {
        await _govRef.doc(geo.id).set({
          'nameAr': geo.nameAr,
          'nameEn': geo.nameEn,
          'order': index + 1,
          'isActive': false,
          'deliveryEnabled': false,
          'tripsEnabled': false,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        created++;
      }
    }
    return created;
  }

  // ═══════════════════════════════════════════════════════════════
  // DISTRICTS
  // ═══════════════════════════════════════════════════════════════

  Stream<List<District>> watchDistricts(String govId) {
    if (govId.trim().isEmpty) return Stream.value(const []);
    return _districtsRef(govId).orderBy('displayOrder').snapshots().map((snap) {
      return snap.docs
          .map((d) => District.fromMap(d.id, govId, d.data()))
          .toList();
    });
  }

  Stream<List<District>> watchActiveDistricts(String govId) {
    if (govId.trim().isEmpty) return Stream.value(const []);
    return _districtsRef(govId).orderBy('displayOrder').snapshots().map((snap) {
      return snap.docs
          .map((d) => District.fromMap(d.id, govId, d.data()))
          .where((d) => d.isActive)
          .toList();
    });
  }

  Future<District?> getDistrict(String govId, String districtId) async {
    if (govId.trim().isEmpty || districtId.trim().isEmpty) return null;
    final doc = await _districtsRef(govId).doc(districtId).get();
    if (!doc.exists) return null;
    return District.fromMap(doc.id, govId, doc.data() ?? {});
  }

  Future<String> createDistrict({
    required String govId,
    required String nameAr,
    required String nameEn,
    int displayOrder = 999,
    bool isActive = true,
  }) async {
    if (govId.trim().isEmpty) {
      throw ArgumentError('govId must not be empty');
    }
    if (nameAr.trim().isEmpty) {
      throw ArgumentError('nameAr must not be empty');
    }
    final ref = await _districtsRef(govId).add({
      'nameAr': nameAr.trim(),
      'nameEn': nameEn.trim(),
      'isActive': isActive,
      'displayOrder': displayOrder,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> updateDistrict({
    required String govId,
    required String districtId,
    String? nameAr,
    String? nameEn,
    bool? isActive,
    int? displayOrder,
  }) async {
    if (govId.trim().isEmpty || districtId.trim().isEmpty) return;
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (nameAr != null) updates['nameAr'] = nameAr.trim();
    if (nameEn != null) updates['nameEn'] = nameEn.trim();
    if (isActive != null) updates['isActive'] = isActive;
    if (displayOrder != null) updates['displayOrder'] = displayOrder;

    await _districtsRef(govId).doc(districtId).update(updates);
  }

  Future<void> setDistrictActive({
    required String govId,
    required String districtId,
    required bool isActive,
  }) async {
    if (govId.trim().isEmpty || districtId.trim().isEmpty) return;
    await _districtsRef(govId).doc(districtId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDistrict({
    required String govId,
    required String districtId,
  }) async {
    if (govId.trim().isEmpty || districtId.trim().isEmpty) return;
    await _districtsRef(govId).doc(districtId).delete();
  }

  Future<int> countDistricts({
    required String govId,
    bool onlyActive = false,
  }) async {
    if (govId.trim().isEmpty) return 0;
    Query<Map<String, dynamic>> query = _districtsRef(govId);
    if (onlyActive) {
      query = query.where('isActive', isEqualTo: true);
    }
    final snap = await query.count().get();
    return snap.count ?? 0;
  }
}
