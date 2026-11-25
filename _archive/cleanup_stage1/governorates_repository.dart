// lib/repositories/governorates_repository.dart
// [v1.0 — 2026-10-29] — جديد كلياً
// طبقة وصول موحدة لبيانات المحافظات والأحياء.
//
// ⚠️ ملاحظة: watchActiveGovernorates() / watchActiveDistricts()
//    تُصفّي في العميل (بعد الاستماع لكل الوثائق) بدلاً من الاستعلام
//    مع where() — لأن where + orderBy يتطلب Compound Index في
//    Firestore. المجموعة صغيرة (27 محافظة × ~5 أحياء)، فالتصفية
//    في العميل أسرع وأبسط ولا تتطلب إعدادات إضافية.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/location/egypt_governorates.dart';
import '../models/district.dart';
import '../models/governorate_config.dart';

class GovernoratesRepository {
  GovernoratesRepository._();
  static final GovernoratesRepository instance = GovernoratesRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── References ───
  CollectionReference<Map<String, dynamic>> get _govRef =>
      _db.collection('governorates');

  CollectionReference<Map<String, dynamic>> _districtsRef(String govId) =>
      _govRef.doc(govId).collection('districts');

  // ═══════════════════════════════════════════════════════════════
  // GOVERNORATES
  // ═══════════════════════════════════════════════════════════════

  /// مراقبة كل المحافظات (مفعّلة + غير مفعّلة) مرتبة بـ order.
  Stream<List<GovernorateConfig>> watchAllGovernorates() {
    return _govRef.orderBy('order').snapshots().map((snap) {
      return snap.docs
          .map((d) => GovernorateConfig.fromMap(d.id, d.data()))
          .toList();
    });
  }

  /// مراقبة المحافظات المفعّلة فقط (للـ Dropdown في شاشة التاجر).
  /// التصفية في العميل لتجنب Compound Index.
  Stream<List<GovernorateConfig>> watchActiveGovernorates() {
    return _govRef.orderBy('order').snapshots().map((snap) {
      return snap.docs
          .map((d) => GovernorateConfig.fromMap(d.id, d.data()))
          .where((g) => g.isActive)
          .toList();
    });
  }

  /// قراءة محافظة واحدة بالـ docId.
  Future<GovernorateConfig?> getGovernorate(String docId) async {
    if (docId.trim().isEmpty) return null;
    final doc = await _govRef.doc(docId).get();
    if (!doc.exists) return null;
    return GovernorateConfig.fromMap(doc.id, doc.data() ?? {});
  }

  /// البحث عن محافظة بالاسم العربي (للمطابقة مع place.governorate).
  Future<GovernorateConfig?> getGovernorateByNameAr(String nameAr) async {
    final clean = nameAr.trim();
    if (clean.isEmpty) return null;
    final snap = await _govRef.where('nameAr', isEqualTo: clean).limit(1).get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return GovernorateConfig.fromMap(doc.id, doc.data());
  }

  /// تفعيل/إيقاف محافظة.
  Future<void> setGovernorateActive(String docId, bool isActive) async {
    if (docId.trim().isEmpty) return;
    await _govRef.doc(docId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تفعيل/إيقاف التوصيل في محافظة.
  Future<void> setDeliveryEnabled(String docId, bool enabled) async {
    if (docId.trim().isEmpty) return;
    await _govRef.doc(docId).update({
      'deliveryEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تفعيل/إيقاف الرحلات في محافظة.
  Future<void> setTripsEnabled(String docId, bool enabled) async {
    if (docId.trim().isEmpty) return;
    await _govRef.doc(docId).update({
      'tripsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// تهيئة الـ27 محافظة (يُنشئ الوثائق الناقصة فقط).
  /// آمن: يتحقق أولاً بـ nameAr (وليس docId) لتجنب التكرار إذا
  /// كانت وثائق موجودة بمعرّفات مختلفة (مثل 'portsaid' بدل 'port_said').
  ///
  /// القيمة الافتراضية: isActive = false, deliveryEnabled = false,
  /// tripsEnabled = false — حتى يُفعّلها الأدمن يدوياً.
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

  /// مراقبة كل الأحياء داخل محافظة (مرتبة بـ displayOrder).
  Stream<List<District>> watchDistricts(String govId) {
    if (govId.trim().isEmpty) return Stream.value(const []);
    return _districtsRef(govId).orderBy('displayOrder').snapshots().map((snap) {
      return snap.docs
          .map((d) => District.fromMap(d.id, govId, d.data()))
          .toList();
    });
  }

  /// مراقبة الأحياء المفعّلة فقط (للـ Dropdown في شاشة التاجر).
  /// التصفية في العميل لتجنب Compound Index.
  Stream<List<District>> watchActiveDistricts(String govId) {
    if (govId.trim().isEmpty) return Stream.value(const []);
    return _districtsRef(govId).orderBy('displayOrder').snapshots().map((snap) {
      return snap.docs
          .map((d) => District.fromMap(d.id, govId, d.data()))
          .where((d) => d.isActive)
          .toList();
    });
  }

  /// قراءة حي واحد.
  Future<District?> getDistrict(String govId, String districtId) async {
    if (govId.trim().isEmpty || districtId.trim().isEmpty) return null;
    final doc = await _districtsRef(govId).doc(districtId).get();
    if (!doc.exists) return null;
    return District.fromMap(doc.id, govId, doc.data() ?? {});
  }

  /// إضافة حي جديد (id تلقائي من Firestore).
  /// يُرجع معرّف الحي المُنشأ.
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

  /// تحديث بيانات حي (حقول اختيارية).
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

  /// تفعيل/إيقاف حي.
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

  /// حذف حي.
  /// ⚠️ لا يتحقق من وجود أماكن مرتبطة. الشاشة يجب أن تُحذّر
  ///    الأدمن في الواجهة قبل الحذف.
  Future<void> deleteDistrict({
    required String govId,
    required String districtId,
  }) async {
    if (govId.trim().isEmpty || districtId.trim().isEmpty) return;
    await _districtsRef(govId).doc(districtId).delete();
  }

  /// عدد الأحياء داخل محافظة (اختياري: المفعّلة فقط).
  /// يستخدم Aggregation Query (سريع، تكلفته قراءة واحدة).
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
