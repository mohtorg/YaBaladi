// models/rating_model.dart
// ملاحظة التعديل: دعم Timestamp من Firestore حتى تكون createdAt متوافقة مع
// وقت الخادم المستخدم عند إنشاء التقييم.
// التقييم - لازم يكون مرتبط بمعرّف زيارة موثّقة (visitId)
// التقييم من غير visitId صالح مرفوض من قواعد الحماية في Firestore
// محدّث ليشمل: إمكانية رد التاجر على التقييم

import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String visitId; // إثبات الزيارة الحقيقية - إجباري
  final String placeId;
  final String userId;
  final int stars; // من 1 إلى 5
  final String? comment;
  final String? merchantReply; // رد التاجر على التقييم، فاضي لحد ما يرد
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.visitId,
    required this.placeId,
    required this.userId,
    required this.stars,
    this.comment,
    this.merchantReply,
    required this.createdAt,
  });

  factory Rating.fromMap(String id, Map<String, dynamic> map) {
    return Rating(
      id: id,
      visitId: map['visitId'] ?? '',
      placeId: map['placeId'] ?? '',
      userId: map['userId'] ?? '',
      stars: (map['stars'] ?? 0).toInt(),
      comment: map['comment'],
      merchantReply: map['merchantReply'],
      createdAt: _readDate(map['createdAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.parse(value.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'visitId': visitId,
      'placeId': placeId,
      'userId': userId,
      'stars': stars,
      if (comment != null) 'comment': comment,
      if (merchantReply != null) 'merchantReply': merchantReply,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
