// models/coupon_model.dart
// ملاحظة التعديل: دعم قراءة تواريخ Firestore من Timestamp مع الإبقاء على دعم
// النصوص القديمة، حتى لا تتعطل البيانات الموجودة قبل تطبيق التحديث.
//
// ============================================================
// الفكرة العامة من الملف ده:
// كوبون بسيط بيتولّد تلقائيًا لما المستخدم يقيّم زيارة موثّقة.
// النموذج المعتمد هنا هو "خصم على الفاتورة يدويًا" (مش تحويل فلوس فعلي) -
// يعني الكوبون ده مجرد "كود" التاجر بيتأكد منه ويطبّق الخصم بنفسه وقت الدفع.
// ده أبسط بكتير من ربط محافظ إلكترونية أو Payout APIs، ومناسب جدًا للمرحلة الحالية.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id;
  final String code; // كود قصير يقوله المستخدم للتاجر (مثال: YB-4821)
  final String userId;
  final String ratingId; // التقييم الموثق الذي أنشأ هذا الكوبون
  final String placeId;
  final String discountLabel; // نص وصفي بسيط، مثال: "خصم 10%"
  final bool isUsed;
  final DateTime createdAt;
  final DateTime expiresAt; // صالح لمدة 7 أيام من تاريخ التوليد

  Coupon({
    required this.id,
    required this.code,
    required this.userId,
    required this.ratingId,
    required this.placeId,
    required this.discountLabel,
    this.isUsed = false,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isValid => !isUsed && DateTime.now().isBefore(expiresAt);

  factory Coupon.fromMap(String id, Map<String, dynamic> map) {
    return Coupon(
      id: id,
      code: map['code'] ?? '',
      userId: map['userId'] ?? '',
      ratingId: map['ratingId'] ?? id,
      placeId: map['placeId'] ?? '',
      discountLabel: map['discountLabel'] ?? '',
      isUsed: map['isUsed'] ?? false,
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
      'code': code,
      'userId': userId,
      'ratingId': ratingId,
      'placeId': placeId,
      'discountLabel': discountLabel,
      'isUsed': isUsed,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
    };
  }
}
