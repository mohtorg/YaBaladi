// repositories/reviews_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review.dart';

class ReviewsRepository {
  ReviewsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'reviews';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  Stream<List<Review>> watchByPlace(String placeId) => _ref
      .where('placeId', isEqualTo: placeId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Review.fromMap(d.id, d.data())).toList());

  Future<List<Review>> getByPlace(String placeId) async {
    final snap = await _ref
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
  }

  Future<String> create(Review review) async {
    final doc = await _ref.add(review.toMap());
    return doc.id;
  }

  Future<void> delete(String id) => _ref.doc(id).delete();
}