// repositories/favorites_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/favorite.dart';

class FavoritesRepository {
  FavoritesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'favorites';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  Stream<List<Favorite>> watchByUser(String userId) => _ref
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Favorite.fromMap(d.id, d.data())).toList());

  Future<bool> isFavorite(String userId, String placeId) async {
    final doc = await _ref.doc(Favorite.buildId(userId, placeId)).get();
    return doc.exists;
  }

  Future<void> add(String userId, String placeId) =>
      _ref.doc(Favorite.buildId(userId, placeId)).set({
        'userId': userId,
        'placeId': placeId,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> remove(String userId, String placeId) =>
      _ref.doc(Favorite.buildId(userId, placeId)).delete();

  /// يعيد الحالة الجديدة
  Future<bool> toggle(String userId, String placeId) async {
    final current = await isFavorite(userId, placeId);
    if (current) {
      await remove(userId, placeId);
      return false;
    }
    await add(userId, placeId);
    return true;
  }
}