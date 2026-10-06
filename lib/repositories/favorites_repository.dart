// repositories/favorites_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/favorite.dart';

/// Repository للمفضلة — يستخدم Subcollection:
/// `users/{uid}/favorites/{placeId}`
///
/// مطابق لـ Master Plan v1.0:
///   users/{uid}/favorites/{pid}   ← المفضلة
class FavoritesRepository {
  FavoritesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String usersCollection = 'users';
  static const String favoritesCollection = 'favorites';

  /// مرجع Subcollection: users/{userId}/favorites
  CollectionReference<Map<String, dynamic>> _favoritesRef(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(favoritesCollection);
  }

  /// Stream لكل مفضلات المستخدم (مرتّبة بالأحدث).
  Stream<List<Favorite>> watchByUser(String userId) {
    return _favoritesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => Favorite.fromMap(userId, d.id, d.data()))
              .toList(),
        );
  }

  /// هل المكان مفضّل؟
  Future<bool> isFavorite(String userId, String placeId) async {
    final doc = await _favoritesRef(userId).doc(placeId).get();
    return doc.exists;
  }

  /// إضافة للمفضلة.
  Future<void> add(String userId, String placeId) {
    return _favoritesRef(userId).doc(placeId).set({
      'placeId': placeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// إزالة من المفضلة.
  Future<void> remove(String userId, String placeId) {
    return _favoritesRef(userId).doc(placeId).delete();
  }

  /// Toggle — يعيد الحالة الجديدة.
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