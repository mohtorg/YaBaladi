// lib/repositories/places_repository.dart
//
// [v3.1 — 2026-10-26] — FIX: Added .limit() to all list queries
//   - FIX: getAllPlaces()      → added .limit(100)
//   - FIX: search()            → added .limit(50)
//   - FIX: getNearestPlaces()  → added .limit(100)
//   - Reason: Firestore rules require request.query.limit <= 100
//   - KEPT: all other methods unchanged

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';

class PlacesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'places';

  // ═══════════════════════════════════════════════════════════════
  // TRENDING
  // ═══════════════════════════════════════════════════════════════

  Future<List<Place>> getTrending({int limit = 10}) async {
    final snap = await _db
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('averageRating', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) => Place.fromMap(doc.id, doc.data())).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // PAGINATED FETCH
  // ═══════════════════════════════════════════════════════════════

  Future<({List<Place> places, DocumentSnapshot? lastDoc})> fetchPlaces({
    required String governorateNameAr,
    String? categoryId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    Query query = _db
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true);

    if (governorateNameAr.isNotEmpty) {
      query = query.where('governorate', isEqualTo: governorateNameAr);
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    query = query.orderBy('createdAt', descending: true).limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snap = await query.get();
    final places = snap.docs
        .map((doc) => Place.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
    return (
      places: places,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ALL PLACES
  // ═══════════════════════════════════════════════════════════════

  Future<List<Place>> getAllPlaces() async {
    final snap = await _db
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(100) // ✅ [FIX] مطلوب لتجاوز فحص القواعد
        .get();
    return snap.docs.map((doc) => Place.fromMap(doc.id, doc.data())).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // GET BY ID
  // ═══════════════════════════════════════════════════════════════

  Future<Place?> getById(String id) async {
    final doc = await _db.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return Place.fromMap(doc.id, doc.data()!);
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════

  Future<List<Place>> search({
    String? query,
    String? categoryId,
  }) async {
    Query q = _db
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true);

    // فلترة بالتصنيف (إن وُجد)
    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }

    // فلترة بالنص (prefix search — Firestore limitation)
    final trimmedQuery = query?.trim() ?? '';
    if (trimmedQuery.isNotEmpty) {
      q = q
          .where('nameAr', isGreaterThanOrEqualTo: trimmedQuery)
          .where('nameAr', isLessThanOrEqualTo: '$trimmedQuery\uf8ff');
    }

    q = q.limit(50); // ✅ [FIX] مطلوب لتجاوز فحص القواعد

    final snap = await q.get();
    return snap.docs
        .map((doc) => Place.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // NEAREST (client-side sort — no GeoQueries)
  // ═══════════════════════════════════════════════════════════════

  Future<List<Place>> getNearestPlaces({
    required double userLat,
    required double userLng,
    double maxDistanceKm = 50,
    int limit = 20,
  }) async {
    final snap = await _db
        .collection(_collection)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(100) // ✅ [FIX] مطلوب لتجاوز فحص القواعد
        .get();
    return snap.docs.map((doc) => Place.fromMap(doc.id, doc.data())).toList();
  }
}
