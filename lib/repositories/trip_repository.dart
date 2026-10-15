// lib/repositories/trip_repository.dart
//
// [v1.0 — 2026-10-15] — G6.7: Trip Repository
//   - Firestore CRUD لـ trip_plans/{id}.
//   - يستخدم client-side sorting (تفادي composite indexes).
//   - Stream-based watch — يعمل في كل البيئات.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/trip_plan.dart';

class TripRepository {
  TripRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'trip_plans';

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
  Future<TripPlan?> getById(String id) async {
    try {
      final doc = await _ref.doc(id).get();
      if (!doc.exists) return null;
      return TripPlan.fromMap(doc.id, doc.data()!);
    } catch (_) {
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
  Future<void> update(TripPlan trip) async {
    if (trip.id.isEmpty) {
      throw ArgumentError('Cannot update trip with empty id');
    }
    await _ref.doc(trip.id).update(trip.toMap());
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
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// الأحدث أولاً.
  void _sortNewestFirst(List<TripPlan> list) {
    list.sort((a, b) {
      final da = a.createdAt ?? DateTime(2000);
      final db = b.createdAt ?? DateTime(2000);
      return db.compareTo(da);
    });
  }
}
