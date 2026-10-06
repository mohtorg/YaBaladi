// models/favorite.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// موديل المفضلة.
///
/// المسار في Firestore: users/{uid}/favorites/{placeId}
/// - `id` = placeId (الـ Document ID)
/// - `userId` = يأتي من الـ path (مش مخزّن في الوثيقة)
///
/// مطابق لـ Master Plan v1.0:
///   users/{uid}/favorites/{pid}   ← المفضلة
class Favorite {
  /// = placeId (الـ Document ID)
  final String id;

  /// يأتي من الـ path — مش مخزّن في الوثيقة
  final String userId;

  final String placeId;
  final DateTime? createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    required this.placeId,
    this.createdAt,
  });

  /// يحوّل من Firestore — `userId` يوصل من الـ path.
  factory Favorite.fromMap(
    String userId,
    String docId,
    Map<String, dynamic> map,
  ) {
    return Favorite(
      id: docId,
      userId: userId,
      placeId: (map['placeId'] as String?) ?? docId,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// للكتابة في Firestore — بدون `userId` (موجود في الـ path).
  Map<String, dynamic> toMap() => {
        'placeId': placeId,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  @override
  String toString() => 'Favorite(user=$userId, place=$placeId)';
}