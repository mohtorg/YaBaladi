// models/reward_model.dart
// نموذج تعريف المكافأة داخل الكتالوج.
// مهم: هذا النموذج لا يحمل رصيد المستخدم؛ الرصيد يظل في مستند المستخدم/محفظته
// ويجب ألا يستطيع العميل تعديله مباشرة. هنا نخزن فقط شروط المكافأة ومحتواها.

import 'package:cloud_firestore/cloud_firestore.dart';

class Reward {
  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final int pointsCost;
  final String? couponCode;
  final String? placeId;
  final bool active;
  final DateTime? expiresAt;

  const Reward({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.pointsCost,
    this.couponCode,
    this.placeId,
    this.active = true,
    this.expiresAt,
  });

  String nameFor(String languageCode) => languageCode == 'en' ? nameEn : nameAr;
  String descriptionFor(String languageCode) => languageCode == 'en' ? descriptionEn : descriptionAr;

  factory Reward.fromMap(String id, Map<String, dynamic> map) {
    final rawExpires = map['expiresAt'];
    DateTime? expires;
    if (rawExpires is Timestamp) expires = rawExpires.toDate();
    if (rawExpires is String) expires = DateTime.tryParse(rawExpires);

    return Reward(
      id: id,
      nameAr: (map['nameAr'] ?? map['name_ar'] ?? '').toString(),
      nameEn: (map['nameEn'] ?? map['name_en'] ?? '').toString(),
      descriptionAr: (map['descriptionAr'] ?? map['description_ar'] ?? '').toString(),
      descriptionEn: (map['descriptionEn'] ?? map['description_en'] ?? '').toString(),
      pointsCost: ((map['pointsCost'] ?? map['points_cost'] ?? 0) as num).toInt(),
      couponCode: map['couponCode']?.toString(),
      placeId: map['placeId']?.toString(),
      active: map['active'] ?? true,
      expiresAt: expires,
    );
  }
}
