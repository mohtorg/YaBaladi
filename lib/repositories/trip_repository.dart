// lib/repositories/trip_repository.dart
//
// [v1.2 — 2026-10-18] — Cold-start robustness (source.server + timeout)
//   - FIX: getById uses Source.server (cold-start accuracy, FlutLab)
//          → بدونها، بعد Hot Restart، /trips/detailed/{id} قد يعرض
//            "الرحلة غير موجودة" رغم وجودها (cache فارغ)
//   - NEW: timeout 15s في getById — يمنع تعليق UI
//   - NEW: catch TimeoutException صراحةً
//   - NEW: debugPrint للتشخيص
//   - KEPT: buildUpdateMap (R1 fix) — createdAt محفوظ
//
// [v1.1 — 2026-10-16] — G6.7 Wave 1a: R1 fix
//   - FIX: update() كان يستبدل createdAt عند كل تحديث
//   - NEW: buildUpdateMap() static — قابلة للاختبار بدون Firestore
//   - FIX: getById catch → on FirebaseException (تنظيف lint)
//
// [v1.0 — 2026-10-15] — G6.7: Trip Repository

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/trip_plan.dart';

class TripRepository {
  TripRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'trip_plans';

  /// مهلة قراءة الرحلة الواحدة — يغطي cold start في FlutLab.
  static const Duration _timeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  // ═══════════════════════════════════════════════════════════════
  // WATCH — streams للمستخدم
  // ═══════════════════════════════════════════════════════════════

  /// Stream بكل رحلات المستخدم — client-side sort بـ createdAt DESC.
  Stream<List<TripPlan>> watchByUser(String userId) {
    return _ref.where('userId', isEqualTo: userId).snapshots().map((s) {
      final list = s.docs.map((d) => TripPlan.fromMap(d.id, d.data())).toList();
      _sortNewestFirst(list);
      return list;
    });
  }

  /// Stream برحلات المستخدم في حالة معينة.
  Stream<List<TripPlan>> watchByUserAndStatus(
    String userId,
    TripStatus status,
  ) {
    return _ref
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.code)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => TripPlan.fromMap(d.id, d.data())).toList();
      _sortNewestFirst(list);
      return list;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // GET — one-shot
  // ═══════════════════════════════════════════════════════════════

  /// يحمّل كل رحلات المستخدم مرة واحدة.
  Future<List<TripPlan>> getByUser(String userId) async {
    final snap = await _ref.where('userId', isEqualTo: userId).get();
    final list =
        snap.docs.map((d) => TripPlan.fromMap(d.id, d.data())).toList();
    _sortNewestFirst(list);
    return list;
  }

  /// يجلب رحلة واحدة بمعرّفها.
  ///
  /// **✅ التصويب (v1.2):** `Source.server` + timeout + catch TimeoutException.
  ///
  /// **لماذا `Source.server`؟**
  ///   على FlutLab Web، بعد Hot Restart، الكاش فارغ. بدون `Source.server`،
  ///   `.get()` يستخدم `serverAndCache` افتراضياً → يُعيد null عند cold start
  ///   → `TripDetailedScreen` يعرض "الرحلة غير موجودة" رغم وجودها.
  ///   نفس المشكلة حُلَّت في `PlacesRepository` v2.1.
  Future<TripPlan?> getById(String id) async {
    if (id.isEmpty) return null;

    try {
      final doc = await _ref
          .doc(id)
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);

      if (!doc.exists) return null;
      return TripPlan.fromMap(doc.id, doc.data()!);
    } on TimeoutException {
      debugPrint('⏱️ TripRepository.getById timeout: $id');
      return null;
    } on FirebaseException catch (e) {
      debugPrint('❌ TripRepository.getById error: $e');
      return null;
    } on ArgumentError catch (e) {
      // بيانات firestore مشوهة → fromMap throws ArgumentError
      debugPrint('❌ TripRepository.getById data error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE / UPDATE / DELETE
  // ═══════════════════════════════════════════════════════════════

  /// يُنشئ رحلة جديدة. يُعيد الـ id.
  Future<String> create(TripPlan trip) async {
    final doc = await _ref.add(trip.toMap());
    return doc.id;
  }

  /// يُحدِّث رحلة قائمة.
  ///
  /// [v1.1 — R1 FIX] نستخدم `buildUpdateMap` بدل `toMap()` مباشرة
  /// لأن `toMap()` يُنتج `createdAt` (بقيمة `FieldValue.serverTimestamp()`
  /// أو `Timestamp.fromDate`) — وكلاهما يُستبدل عند كل تحديث.
  ///
  /// الحل: نحذف `createdAt` من data قبل الحفظ — يبقى كما هو في Firestore.
  Future<void> update(TripPlan trip) async {
    if (trip.id.isEmpty) {
      throw ArgumentError('Cannot update trip with empty id');
    }
    await _ref.doc(trip.id).update(buildUpdateMap(trip));
  }

  /// يحذف رحلة.
  Future<void> delete(String id) => _ref.doc(id).delete();

  /// يُحدِّث حالة الرحلة فقط.
  Future<void> updateStatus(String id, TripStatus status) async {
    await _ref.doc(id).update({
      'status': status.code,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS — [v1.1] قابلة للاختبار بدون Firestore
  // ═══════════════════════════════════════════════════════════════

  /// يبني الـ data للتحديث.
  ///
  /// **لماذا دالة منفصلة؟**
  ///   - يمكن اختبارها بدون Firestore (بدون mocks).
  ///   - توثيق صريح للفرق بين `toMap()` و update-map.
  ///
  /// **القواعد:**
  ///   - `createdAt` محذوف — يبقى كما هو في Firestore.
  ///   - `updatedAt` = `FieldValue.serverTimestamp()` — يُعيَّن تلقائياً.
  ///   - كل الحقول الأخرى تُمرَّر كما هي.
  static Map<String, dynamic> buildUpdateMap(TripPlan trip) {
    final data = Map<String, dynamic>.from(trip.toMap());
    data.remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    return data;
  }

  /// الأحدث أولاً.
  void _sortNewestFirst(List<TripPlan> list) {
    list.sort((a, b) {
      final da = a.createdAt ?? DateTime(2000);
      final db = b.createdAt ?? DateTime(2000);
      return db.compareTo(da);
    });
  }
}
