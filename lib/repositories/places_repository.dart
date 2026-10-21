// lib/repositories/places_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';

class PlacesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Place>> getTrending({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ تعديل
      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ getTrending error: $e');
      return [];
    }
  }

  Future<Place?> getById(String id) async {
    try {
      final doc = await _firestore
          .collection('places')
          .doc(id)
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ تعديل
      return doc.exists ? Place.fromFirestore(doc) : null;
    } catch (e) {
      debugPrint('❌ getById error: $e');
      return null;
    }
  }

  Future<({List<Place> places, DocumentSnapshot? lastDoc})> fetchPlaces({
    required String governorateNameAr,
    String? categoryId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore
          .collection('places')
          .where('governorate', isEqualTo: governorateNameAr)
          .orderBy(FieldPath.documentId)
          .limit(limit);

      if (categoryId != null && categoryId.trim().isNotEmpty) {
        query = query.where('categoryId', isEqualTo: categoryId.trim());
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ تعديل
      final places =
          snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
      final newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return (places: places, lastDoc: newLastDoc);
    } catch (e) {
      debugPrint('❌ fetchPlaces error: $e');
      return (places: <Place>[], lastDoc: null);
    }
  }

  Future<List<Place>> getAllPlaces() async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ تعديل
      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ getAllPlaces error: $e');
      return [];
    }
  }

  Future<List<Place>> search({
    String? query,
    String? categoryId,
    String? governorate,
    int limit = 20,
  }) async {
    try {
      Query firestoreQuery = _firestore.collection('places');
      if (governorate != null && governorate.trim().isNotEmpty) {
        firestoreQuery =
            firestoreQuery.where('governorate', isEqualTo: governorate.trim());
      }
      if (categoryId != null && categoryId.trim().isNotEmpty) {
        firestoreQuery =
            firestoreQuery.where('categoryId', isEqualTo: categoryId.trim());
      }
      final q = query?.trim() ?? '';
      if (q.isNotEmpty) {
        firestoreQuery = firestoreQuery
            .where('nameAr', isGreaterThanOrEqualTo: q)
            .where('nameAr', isLessThan: '${q}z');
      }
      final snapshot = await firestoreQuery
          .limit(limit)
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ تعديل
      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ search error: $e');
      return [];
    }
  }

  // ✅ ميزة "الأقرب إليك" (Nearest Places) باستخدام Geohash مدمج
  Future<List<Place>> getNearestPlaces({
    required double userLat,
    required double userLng,
    String? governorateNameAr,
    int limit = 50,
  }) async {
    try {
      final userHash = _encodeGeohash(userLat, userLng, precision: 5);
      final prefix = userHash.substring(0, 4);

      Query query = _firestore
          .collection('places')
          .where('geohash', isGreaterThanOrEqualTo: prefix)
          .where('geohash', isLessThan: '$prefix~')
          .limit(limit);

      if (governorateNameAr != null && governorateNameAr.isNotEmpty) {
        query = query.where('governorate', isEqualTo: governorateNameAr);
      }

      final snapshot = await query
          .get(const GetOptions(source: Source.serverAndCache)); // ✅ تعديل
      final places =
          snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();

      places.sort((a, b) {
        if (a.location == null) return 1;
        if (b.location == null) return -1;

        final distA = Geolocator.distanceBetween(
          userLat,
          userLng,
          a.location!.latitude,
          a.location!.longitude,
        );
        final distB = Geolocator.distanceBetween(
          userLat,
          userLng,
          b.location!.latitude,
          b.location!.longitude,
        );

        return distA.compareTo(distB);
      });

      return places;
    } catch (e) {
      debugPrint('❌ getNearestPlaces error: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // دالة مدمجة لحساب Geohash
  // ═══════════════════════════════════════════════════════════════
  String _encodeGeohash(double latitude, double longitude,
      {int precision = 9}) {
    const base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
    var isEven = true;
    var bit = 0;
    var ch = 0;
    final geohash = StringBuffer();
    var latMin = -90.0;
    var latMax = 90.0;
    var lonMin = -180.0;
    var lonMax = 180.0;

    while (geohash.length < precision) {
      if (isEven) {
        final mid = (lonMin + lonMax) / 2;
        if (longitude > mid) {
          ch |= 1 << (4 - bit);
          lonMin = mid;
        } else {
          lonMax = mid;
        }
      } else {
        final mid = (latMin + latMax) / 2;
        if (latitude > mid) {
          ch |= 1 << (4 - bit);
          latMin = mid;
        } else {
          latMax = mid;
        }
      }

      isEven = !isEven;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(base32[ch]);
        bit = 0;
        ch = 0;
      }
    }
    return geohash.toString();
  }
}
