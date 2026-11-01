// lib/models/district.dart
// [v1.0 — 2026-10-29] — جديد كلياً
// نموذج الحي (subcollection من المحافظة)
//
// ⚠️ ملاحظة: حقل `governorateId` غير مُضمَّن في toMap() لأنه مُضمَّن
//    ضمن مسار Firestore: governorates/{govId}/districts/{districtId}.
//    إضافته ستكون تكراراً غير ضروري.
//
// ⚠️ ملاحظة: يستخدم `Timestamp` (من cloud_firestore) وليس `DateTime`
//    لتفادي التحويلات اليدوية في كل مكان.

import 'package:cloud_firestore/cloud_firestore.dart';

class District {
  final String id;
  final String governorateId;
  final String nameAr;
  final String nameEn;
  final bool isActive;
  final int displayOrder;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const District({
    required this.id,
    required this.governorateId,
    required this.nameAr,
    required this.nameEn,
    required this.isActive,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });

  // ─── Firestore → Model ───
  factory District.fromMap(
    String id,
    String governorateId,
    Map<String, dynamic> data,
  ) {
    return District(
      id: id,
      governorateId: governorateId,
      nameAr: (data['nameAr'] as String?)?.trim() ?? '',
      nameEn: (data['nameEn'] as String?)?.trim() ?? '',
      isActive: data['isActive'] == true,
      displayOrder: (data['displayOrder'] as num?)?.toInt() ?? 999,
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
      'displayOrder': displayOrder,
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ─── Immutable update ───
  District copyWith({
    String? nameAr,
    String? nameEn,
    bool? isActive,
    int? displayOrder,
  }) {
    return District(
      id: id,
      governorateId: governorateId,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      isActive: isActive ?? this.isActive,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Display helper ───
  String get displayName => nameAr.isNotEmpty ? nameAr : nameEn;

  // ─── Equality ───
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is District &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          governorateId == other.governorateId &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(id, governorateId, isActive);

  @override
  String toString() => 'District($id, $nameAr, active=$isActive)';
}
