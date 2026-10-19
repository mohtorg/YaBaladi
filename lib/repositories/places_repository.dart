// lib/repositories/places_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/place.dart';

class PlacesRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Place>> getTrending({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get(const GetOptions(source: Source.server));
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
          .get(const GetOptions(source: Source.server));
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

      final snapshot = await query.get(const GetOptions(source: Source.server));
      final places =
          snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
      final newLastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return (places: places, lastDoc: newLastDoc);
    } catch (e) {
      debugPrint('❌ fetchPlaces error: $e');
      return (places: <Place>[], lastDoc: null);
    }
  }

  // ✅ استعادة الدالة القديمة
  Future<List<Place>> getAllPlaces() async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .limit(50)
          .get(const GetOptions(source: Source.server));
      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ getAllPlaces error: $e');
      return [];
    }
  }

  // ✅ استعادة الدالة القديمة
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
          .get(const GetOptions(source: Source.server));
      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ search error: $e');
      return [];
    }
  }
}
