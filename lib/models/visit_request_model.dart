// models/visit_request_model.dart
// ملاحظة التعديل: دعم Timestamp في التواريخ، مع الاحتفاظ بتوافق القراءة مع
// السجلات القديمة التي خزنت التاريخ كنص ISO-8601.
// "طلب زيارة" مؤقت - بيتولّد لحظة ما المستخدم يفتح شاشة QR
// التاجر لما يمسح الكود، بيأكد الطلب ده ويتحول لـ Visit دائم
// الفصل بين "الطلب" و"الزيارة المؤكدة" مهم أمنيًا: أي حد يقدر يولّد كود،
// لكن بس التاجر الحقيقي (مالك المكان) اللي يقدر يأكده

import 'package:cloud_firestore/cloud_firestore.dart';

class VisitRequest {
  final String id;
  final String placeId;
  final String userId;
  final String status; // "pending" | "confirmed" | "expired"
  final DateTime createdAt;
  final DateTime expiresAt; // صالح لمدة 10 دقائق بس من التوليد

  VisitRequest({
    required this.id,
    required this.placeId,
    required this.userId,
    this.status = 'pending',
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isValid =>
      status == 'pending' && DateTime.now().isBefore(expiresAt);

  factory VisitRequest.fromMap(String id, Map<String, dynamic> map) {
    return VisitRequest(
      id: id,
      placeId: map['placeId'] ?? '',
      userId: map['userId'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: _readDate(map['createdAt']),
      expiresAt: _readDate(map['expiresAt']),
    );
  }

  static DateTime _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.parse(value.toString());
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'userId': userId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
