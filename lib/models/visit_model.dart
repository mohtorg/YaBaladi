// models/visit_model.dart
// ملاحظة التعديل: دعم قراءة Timestamp من Firestore لأن وقت إنشاء الزيارة
// ونافذة التقييم أصبحت تُسجل بطريقة أكثر موثوقية.
// سجل الزيارة الموثّقة - بيتسجل لما التاجر يمسح كود الزبون
// وجود مستند هنا هو "الإثبات" إن الزيارة حصلت فعليًا

import 'package:cloud_firestore/cloud_firestore.dart';

class Visit {
  final String id;
  final String placeId;
  final String userId;
  final String merchantId;
  // الطلب الذي أنشأ هذه الزيارة الموثقة؛ لا نسمح بإنشاء Visit منفصلة عن Request.
  final String visitRequestId;
  final DateTime scannedAt;
  final DateTime ratingWindowExpiresAt; // scannedAt + 24 ساعة
  final bool ratingSubmitted;

  Visit({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.merchantId,
    required this.visitRequestId,
    required this.scannedAt,
    required this.ratingWindowExpiresAt,
    this.ratingSubmitted = false,
  });

  // هل لسه في وقت التقييم المسموح؟
  bool get canStillRate =>
      !ratingSubmitted && DateTime.now().isBefore(ratingWindowExpiresAt);

  factory Visit.fromMap(String id, Map<String, dynamic> map) {
    return Visit(
      id: id,
      placeId: map['placeId'] ?? '',
      userId: map['userId'] ?? '',
      merchantId: map['merchantId'] ?? '',
      visitRequestId: map['visitRequestId'] ?? '',
      scannedAt: _readDate(map['scannedAt']),
      ratingWindowExpiresAt: _readDate(map['ratingWindowExpiresAt']),
      ratingSubmitted: map['ratingSubmitted'] ?? false,
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
      'merchantId': merchantId,
      'visitRequestId': visitRequestId,
      'scannedAt': scannedAt.toIso8601String(),
      'ratingWindowExpiresAt': ratingWindowExpiresAt.toIso8601String(),
      'ratingSubmitted': ratingSubmitted,
    };
  }
}
