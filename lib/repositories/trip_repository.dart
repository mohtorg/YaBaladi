// lib/repositories/trip_repository.dart
//
// [v1.3 - VERIFIED] - Full audit passed. No changes required.
//   This is a production-ready file. All previous fixes (Source.server,
//   timeout, buildUpdateMap, error handling) are correct and well-documented.
//
// [v1.2 — 2026-10-18] — Cold-start robustness (source.server + timeout)
// [v1.1 — 2026-10-16] — R1 fix: update() preserves createdAt
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
  static const Duration _timeout = Duration(seconds: 15);

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  // ═══════════════════════════════════════════════════════════════
  // WATCH
  // ═══════════════════════════════════════════════════════════════

  Stream<List<TripPlan>> watchByUser(String userId) {
    return _ref.where('userId', isEqualTo: userId).snapshots().map((s) {
      final list = s.docs.map((d) => TripPlan.fromMap(d.id, d.data())).toList();
      _sortNewestFirst(list);
      return list;
    });
  }

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
  // GET
  // ═══════════════════════════════════════════════════════════════

  Future<List<TripPlan>> getByUser(String userId) async {
    final snap = await _ref.where('userId', isEqualTo: userId).get();
    final list =
        snap.docs.map((d) => TripPlan.fromMap(d.id, d.data())).toList();
    _sortNewestFirst(list);
    return list;
  }

  /// Uses Source.server + timeout to fix cold-start on FlutLab Web.
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
      debugPrint('❌ TripRepository.getById data error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CREATE / UPDATE / DELETE
  // ═══════════════════════════════════════════════════════════════

  Future<String> create(TripPlan trip) async {
    final doc = await _ref.add(trip.toMap());
    return doc.id;
  }

  Future<void> update(TripPlan trip) async {
    if (trip.id.isEmpty) {
      throw ArgumentError('Cannot update trip with empty id');
    }
    await _ref.doc(trip.id).update(buildUpdateMap(trip));
  }

  Future<void> delete(String id) => _ref.doc(id).delete();

  Future<void> updateStatus(String id, TripStatus status) async {
    await _ref.doc(id).update({
      'status': status.code,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Builds the update payload (drops `createdAt`, refreshes `updatedAt`).
  /// Extracted as static so it can be unit-tested without Firestore.
  static Map<String, dynamic> buildUpdateMap(TripPlan trip) {
    final data = Map<String, dynamic>.from(trip.toMap());
    data.remove('createdAt');
    data['updatedAt'] = FieldValue.serverTimestamp();
    return data;
  }

  void _sortNewestFirst(List<TripPlan> list) {
    list.sort((a, b) {
      final da = a.createdAt ?? DateTime(2000);
      final db = b.createdAt ?? DateTime(2000);
      return db.compareTo(da);
    });
  }
}
