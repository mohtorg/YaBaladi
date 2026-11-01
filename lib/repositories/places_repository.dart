// lib/repositories/places_repository.dart
//
// [v4.2 — 2026-10-29] — FIX: removed unsupported 'limit' param from fetchWithin
//   - geoflutterfire_plus v0.0.19's fetchWithin() does not accept `limit`.
//   - Results are limited in-memory via `places.take(limit).toList()`.
//   - KEPT: all v4.1 API compatibility fixes and v4.0 features.
// [v4.1 — 2026-10-29] — FIX: geoflutterfire_plus v0.0.19 API compatibility

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../models/geo_zone.dart';
import 'geo_zones_repository.dart';

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
        .limit(100)
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

    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }

    final trimmedQuery = query?.trim() ?? '';
    if (trimmedQuery.isNotEmpty) {
      q = q
          .where('nameAr', isGreaterThanOrEqualTo: trimmedQuery)
          .where('nameAr', isLessThanOrEqualTo: '$trimmedQuery\uf8ff');
    }

    q = q.limit(50);

    final snap = await q.get();
    return snap.docs
        .map((doc) => Place.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // NEAREST PLACES (Wave 18)
  // ═══════════════════════════════════════════════════════════════

  Future<List<Place>> getNearestPlaces({
    required double userLat,
    required double userLng,
    double maxDistanceKm = 50,
    int limit = 20,
  }) async {
    List<Place> places = [];

    try {
      // GeoCollectionReference يتطلب CollectionReference وليس Query
      final geoRef = GeoCollectionReference(_db.collection(_collection));

      final snapshots = await geoRef.fetchWithin(
        center: GeoFirePoint(GeoPoint(userLat, userLng)),
        radiusInKm: maxDistanceKm,
        field: 'geo',
        // دالة استخراج الإحداثيات من الوثيقة
        geopointFrom: (data) {
          final geoData = data['geo'];
          if (geoData is Map && geoData['geopoint'] is GeoPoint) {
            return geoData['geopoint'] as GeoPoint;
          }
          // خطة احتياطية إذا لم يكن حقل geo موجوداً
          if (data['location'] is GeoPoint) {
            return data['location'] as GeoPoint;
          }
          return const GeoPoint(0, 0);
        },
      );

      if (snapshots.isNotEmpty) {
        // الفلترة في الذاكرة (لأن GeoCollectionReference لا يقبل Query)
        places = snapshots
            .map((s) => Place.fromMap(s.id, s.data()!))
            .where((p) => p.isApproved && p.isActive)
            .toList();
      }
    } catch (e) {
      debugPrint('⚠️ GeoQuery failed, using fallback: $e');
    }

    // خطة احتياطية: إذا لم نجد نتائج أو فشل البحث الجغرافي
    if (places.isEmpty) {
      final snap = await _db
          .collection(_collection)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(100)
          .get();
      places =
          snap.docs.map((doc) => Place.fromMap(doc.id, doc.data())).toList();
    }

    _sortPlacesByDistance(places, userLat, userLng);

    return places.take(limit).toList();
  }

  /// Wave 18: اكتشاف المنطقة والأماكن القريبة.
  Future<({GeoZone? zone, List<Place> places})> getNearestPlacesWithZone({
    required double userLat,
    required double userLng,
    double maxDistanceKm = 5.0,
    int limit = 20,
  }) async {
    GeoZone? myZone;
    try {
      myZone =
          await GeoZonesRepository.instance.findZoneForPoint(userLat, userLng);
    } catch (e) {
      debugPrint('⚠️ Zone detection failed: $e');
    }

    final places = await getNearestPlaces(
      userLat: userLat,
      userLng: userLng,
      maxDistanceKm: maxDistanceKm,
      limit: limit,
    );

    return (zone: myZone, places: places);
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  void _sortPlacesByDistance(
      List<Place> places, double userLat, double userLng) {
    places.sort((a, b) {
      final locA = a.location;
      final locB = b.location;

      if (locA == null && locB == null) return 0;
      if (locA == null) return 1;
      if (locB == null) return -1;

      final distA = Geolocator.distanceBetween(
          userLat, userLng, locA.latitude, locA.longitude);
      final distB = Geolocator.distanceBetween(
          userLat, userLng, locB.latitude, locB.longitude);

      return distA.compareTo(distB);
    });
  }
}
