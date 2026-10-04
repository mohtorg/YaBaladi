// repositories/places_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/place.dart';

class PlacesRepository {
  PlacesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'places';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  Stream<List<Place>> watchApproved({int limit = 50}) => _ref
      .where('isApproved', isEqualTo: true)
      .where('isActive', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map((d) => Place.fromMap(d.id, d.data())).toList());

  Stream<List<Place>> watchByCategory(String categoryId, {int limit = 50}) =>
      _ref
          .where('categoryId', isEqualTo: categoryId)
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => Place.fromMap(d.id, d.data())).toList());

  Future<Place?> getById(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? Place.fromMap(doc.id, doc.data()!) : null;
  }

  Future<String> create(Place place) async {
    final doc = await _ref.add(place.toMap());
    return doc.id;
  }

  Future<void> update(Place place) =>
      _ref.doc(place.id).update(place.toMap());

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
}