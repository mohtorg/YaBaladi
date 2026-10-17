// lib/repositories/places_repository.dart
//
// [v2.0 — 2026-10-16] — RIGOROUS: Fix cold-start empty results
//   - FIX: جميع القراءات تستخدم Source.server (يمنع cache-fallback)
//   - NEW: _getWithRetry() — retry with backoff (cold start ~40s)
//   - NEW: Timeout 30s per attempt, 3 attempts max
//   - السبب: Source.serverAndCache يُرجع cache فارغ عند cold start
//           في FlutLab Web (WebChannel بطيء أول 40s).
//
// [v1.0] — Initial repository

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/place.dart';

class PlacesRepository {
  PlacesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'places';

  /// مهلة القراءة الواحدة — يغطي cold start في FlutLab.
  static const Duration _timeout = Duration(seconds: 30);

  /// عدد محاولات إعادة القراءة.
  static const int _maxRetries = 3;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  // ═══════════════════════════════════════════════════════════════
  // CORE — retry wrapper
  // ═══════════════════════════════════════════════════════════════

  /// ينفّذ قراءة Firestore مع:
  ///   1. Source.server (بدون cache fallback)
  ///   2. Timeout 30s
  ///   3. Retry تلقائي (3 محاولات، backoff).
  ///
  /// **لماذا `Source.server`؟**
  ///   Cold start في FlutLab Web: الاتصال يستغرق ~40s.
  ///   `Source.serverAndCache` يرمي cache فارغ بعد 30s → [] فارغ.
  ///   `Source.server` ينتظر السيرفر حتى النهاية → نتائج صحيحة.
  Future<QuerySnapshot<Map<String, dynamic>>> _getWithRetry(
    Query<Map<String, dynamic>> query,
  ) async {
    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        debugPrint(
          '🔍 PlacesRepository: attempt $attempt/$_maxRetries '
          '(Source.server)...',
        );
        final start = DateTime.now();
        final snap = await query
            .get(const GetOptions(source: Source.server))
            .timeout(_timeout);
        final elapsed = DateTime.now().difference(start);
        debugPrint(
          '✅ PlacesRepository: attempt $attempt OK '
          '(${elapsed.inMilliseconds}ms, ${snap.docs.length} docs)',
        );
        return snap;
      } on TimeoutException {
        debugPrint('⏱️ PlacesRepository: timeout on attempt $attempt');
        if (attempt == _maxRetries) rethrow;
      } catch (e) {
        debugPrint('❌ PlacesRepository: error on attempt $attempt — $e');
        if (attempt == _maxRetries) rethrow;
      }

      // Backoff: 2s, 4s, 6s...
      final wait = Duration(seconds: 2 * attempt);
      debugPrint('⏳ PlacesRepository: waiting ${wait.inSeconds}s...');
      await Future.delayed(wait);
    }

    // لن يصل هنا (rethrow في آخر محاولة)
    throw StateError('Unreachable: _getWithRetry exhausted');
  }

  // ═══════════════════════════════════════════════════════════════
  // WATCHERS (legacy — stream-based)
  // ═══════════════════════════════════════════════════════════════

  Stream<List<Place>> watchApproved({int limit = 50}) {
    return _ref
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Place.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Place>> watchByCategory(String categoryId, {int limit = 50}) {
    return _ref
        .where('categoryId', isEqualTo: categoryId)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('averageRating', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Place.fromMap(d.id, d.data())).toList());
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD (One-shot)
  // ═══════════════════════════════════════════════════════════════

  /// [v2.0] Source.server + retry.
  Future<List<Place>> loadAll({int limit = 500}) async {
    final query = _ref
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(limit);

    final snap = await _getWithRetry(query);
    return snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();
  }

  /// [v2.0] Source.server + retry.
  Future<List<Place>> loadByCategory(
    String categoryId, {
    int limit = 500,
  }) async {
    final query = _ref
        .where('categoryId', isEqualTo: categoryId)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(limit);

    final snap = await _getWithRetry(query);
    return snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // GET BY ID
  // ═══════════════════════════════════════════════════════════════

  /// [v2.0] Source.server.
  Future<Place?> getById(String id) async {
    try {
      final doc = await _ref
          .doc(id)
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);
      return doc.exists ? Place.fromMap(doc.id, doc.data()!) : null;
    } on TimeoutException {
      debugPrint('⏱️ PlacesRepository.getById timeout: $id');
      return null;
    } on FirebaseException catch (e) {
      debugPrint('❌ PlacesRepository.getById error: $e');
      return null;
    }
  }

  /// [v2.0] Source.server + retry.
  Future<List<Place>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final result = <Place>[];

    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
      final query = _ref.where(FieldPath.documentId, whereIn: chunk);
      final snap = await _getWithRetry(query);
      result.addAll(snap.docs.map((d) => Place.fromMap(d.id, d.data())));
    }

    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // TRENDING
  // ═══════════════════════════════════════════════════════════════

  /// [v2.0] Source.server + retry.
  Future<List<Place>> getTrending({int limit = 5}) async {
    try {
      final query = _ref
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(200);

      final snap = await _getWithRetry(query);
      final places =
          snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();
      places.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      return places.take(limit).toList();
    } catch (e) {
      debugPrint('❌ PlacesRepository.getTrending error: $e');
      return const [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<String> create(Place place) async {
    final doc = await _ref.add(place.toMap());
    return doc.id;
  }

  Future<void> update(Place place) => _ref.doc(place.id).update(place.toMap());

  Future<void> delete(String id) => _ref.doc(id).delete();

  Future<void> updateRating({
    required String placeId,
    required double average,
    required int count,
  }) =>
      _ref.doc(placeId).update({
        'averageRating': average,
        'reviewCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ═══════════════════════════════════════════════════════════════
  // SEARCH (legacy — client-side)
  // ═══════════════════════════════════════════════════════════════

  Future<List<Place>> search({
    required String query,
    String? categoryId,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> q = _ref
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }

    q = q.limit(limit);

    final snap = await _getWithRetry(q);
    final all = snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();

    final q2 = query.trim().toLowerCase();
    if (q2.isEmpty) return all;

    return all.where((p) {
      return p.nameAr.toLowerCase().contains(q2) ||
          p.nameEn.toLowerCase().contains(q2) ||
          p.description.toLowerCase().contains(q2);
    }).toList();
  }
}
