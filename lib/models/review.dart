// models/review.dart
//
// [v1.1.2 — 2026-10-18] — FIX: Strict cast for imageUrls + Logic fix in copyWith
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String placeId;
  final String userId;
  final String userName;
  final String userPhotoUrl;
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final DateTime? createdAt;
  final bool isVerified;
  final String? visitId;
  final DateTime? verifiedAt;

  const Review({
    required this.id,
    required this.placeId,
    required this.userId,
    this.userName = '',
    this.userPhotoUrl = '',
    required this.rating,
    this.comment = '',
    this.imageUrls = const [],
    this.createdAt,
    this.isVerified = false,
    this.visitId,
    this.verifiedAt,
  });

  factory Review.fromMap(String id, Map<String, dynamic> map) {
    return Review(
      id: id,
      placeId: (map['placeId'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      userName: (map['userName'] as String?) ?? '',
      userPhotoUrl: (map['userPhotoUrl'] as String?) ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      comment: (map['comment'] as String?) ?? '',
      // ✅ التصويب: تحويل صريح إلى List? لتجنب خطأ dynamic مع strict-casts
      imageUrls: List<String>.from(map['imageUrls'] as List? ?? const []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      isVerified: (map['isVerified'] as bool?) ?? false,
      visitId: map['visitId'] as String?,
      verifiedAt: (map['verifiedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'placeId': placeId,
        'userId': userId,
        'userName': userName,
        'userPhotoUrl': userPhotoUrl,
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'isVerified': isVerified,
        // إضافة القيم فقط إذا كانت موجودة لتجنب تخزين null
        if (visitId != null) 'visitId': visitId,
        if (verifiedAt != null) 'verifiedAt': Timestamp.fromDate(verifiedAt!),
      };

  Review copyWith({
    String? id,
    String? placeId,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    double? rating,
    String? comment,
    List<String>? imageUrls,
    DateTime? createdAt,
    bool? isVerified,
    String? visitId,
    DateTime? verifiedAt,
  }) =>
      Review(
        id: id ?? this.id,
        placeId: placeId ?? this.placeId,
        userId: userId ?? this.userId,
        userName: userName ?? this.userName,
        userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        imageUrls: imageUrls ?? this.imageUrls,
        createdAt: createdAt ?? this.createdAt,
        isVerified: isVerified ?? this.isVerified,
        // ✅ التصويب المنطقي: السماح بمسح القيمة (تعيينها null) إذا لزم الأمر
        visitId: visitId,
        verifiedAt: verifiedAt,
      );

  @override
  String toString() =>
      'Review($id, place=$placeId, rating=$rating, verified=$isVerified)';
}
