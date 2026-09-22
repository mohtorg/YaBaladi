// services/favorites_service.dart
//
// ============================================================
// الفكرة العامة من الملف ده:
// إدارة قائمة "المفضلة" بتاعة المستخدم - بنخزنها كـ Array بسيط
// جوه مستند المستخدم نفسه في users/{uid}، مش Collection منفصلة،
// لأن العدد المتوقع صغير (عشرات الأماكن مش آلاف) فمفيش داعي للتعقيد
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // إضافة مكان للمفضلة - arrayUnion بتتجنب التكرار تلقائيًا
  Future<void> addToFavorites(String userId, String placeId) async {
    await _db.collection('users').doc(userId).update({
      'favoritePlaceIds': FieldValue.arrayUnion([placeId]),
    });
  }

  // إزالة مكان من المفضلة
  Future<void> removeFromFavorites(String userId, String placeId) async {
    await _db.collection('users').doc(userId).update({
      'favoritePlaceIds': FieldValue.arrayRemove([placeId]),
    });
  }

  // متابعة لحظية لقائمة معرّفات المفضلة (مش الأماكن نفسها، بس المعرّفات)
  // الشاشة اللي هتستخدمها هي اللي هتجيب تفاصيل كل مكان بمعرّفه
  Stream<List<String>> favoriteIdsStream(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return [];
      return List<String>.from(doc.data()?['favoritePlaceIds'] ?? []);
    });
  }
}
