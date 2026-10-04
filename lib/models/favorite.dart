// models/favorite.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Favorite {
  final String id;      // userId_placeId (unique)
  final String userId;
  final String placeId;
  final DateTime? createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    required this.placeId,
    this.createdAt,
  });

  /// docId موحّد لمنع التكرار
  static String buildId(String userId, String placeId) => '${userId}_$placeId';

  factory Favorite.fromMap(String id, Map<String, dynamic> map) {
    return Favorite(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      placeId: (map['placeId'] as String?) ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'placeId': placeId,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
      };

  @override
  String toString() => 'Favorite($id, user=$userId, place=$placeId)';
}