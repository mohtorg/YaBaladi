// lib/models/governorate.dart
// [v1.0 — جديد] — نموذج المحافظة الكامل
// لا يُستبدل أي ملف قائم. يُضاف بجانبه.

import 'package:cloud_firestore/cloud_firestore.dart';

class Governorate {
  final String id;
  final String nameAr;
  final String nameEn;
  final bool isActive; // ← مرئية/مفعّلة في التطبيق
  final bool deliveryEnabled; // ← التوصيل يعمل داخل المحافظة
  final bool tripsEnabled; // ← ميزة مولد الرحلات تعمل
  final int displayOrder; // ← ترتيب العرض في القوائم
  final GeoPoint? center; // ← مركز المحافظة للخريطة
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Governorate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.isActive,
    required this.deliveryEnabled,
    required this.tripsEnabled,
    required this.displayOrder,
    this.center,
    this.createdAt,
    this.updatedAt,
  });

  // ─── Firestore → Model ───
  factory Governorate.fromMap(String id, Map<String, dynamic> data) {
    return Governorate(
      id: id,
      nameAr: (data['nameAr'] as String?)?.trim() ?? '',
      nameEn: (data['nameEn'] as String?)?.trim() ?? '',
      isActive: data['isActive'] == true,
      deliveryEnabled: data['deliveryEnabled'] == true,
      tripsEnabled: data['tripsEnabled'] == true,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 999,
      center: data['center'] is GeoPoint ? data['center'] as GeoPoint : null,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
    );
  }

  // ─── Model → Firestore ───
  Map<String, dynamic> toMap({bool forCreate = false}) {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'isActive': isActive,
      'deliveryEnabled': deliveryEnabled,
      'tripsEnabled': tripsEnabled,
      'displayOrder': displayOrder,
      if (center != null) 'center': center,
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ─── Immutable update ───
  Governorate copyWith({
    String? nameAr,
    String? nameEn,
    bool? isActive,
    bool? deliveryEnabled,
    bool? tripsEnabled,
    int? displayOrder,
    GeoPoint? center,
  }) {
    return Governorate(
      id: id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      isActive: isActive ?? this.isActive,
      deliveryEnabled: deliveryEnabled ?? this.deliveryEnabled,
      tripsEnabled: tripsEnabled ?? this.tripsEnabled,
      displayOrder: displayOrder ?? this.displayOrder,
      center: center ?? this.center,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Equality ───
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Governorate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isActive == other.isActive &&
          deliveryEnabled == other.deliveryEnabled &&
          tripsEnabled == other.tripsEnabled;

  @override
  int get hashCode => Object.hash(
        id,
        isActive,
        deliveryEnabled,
        tripsEnabled,
      );

  // ─── Display helper ───
  String get displayName => nameAr.isNotEmpty ? nameAr : nameEn;
}
