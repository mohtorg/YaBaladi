// lib/models/review_criterion_model.dart
// [v1.1 — 2026-11-12] — LEGACY SAFETY:
//   - If `isGeneral` is missing (legacy data), infer from `categoryId`:
//       * null/empty → treat as general (true).
//       * present    → treat as specific (false).
//   - Prevents old criteria (created before `isGeneral` existed) from
//     disappearing from both the "General" and "Specific" admin tabs.
//   - Also normalizes `categoryId`: treats empty strings as null.

import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewCriterionModel {
  final String id;
  final String? categoryId;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String fieldKey;
  final double weight;
  final int order;
  final bool isActive;
  final bool isRequired;
  final bool isGeneral;

  const ReviewCriterionModel({
    required this.id,
    this.categoryId,
    required this.nameAr,
    required this.nameEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.fieldKey,
    required this.weight,
    required this.order,
    required this.isActive,
    required this.isRequired,
    required this.isGeneral,
  });

  factory ReviewCriterionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 1. تطبيع categoryId: يقبل null / نص فارغ / نص عادي
    final dynamic rawCat = data['categoryId'];
    final String? normalizedCategoryId =
        (rawCat == null || rawCat.toString().isEmpty)
            ? null
            : rawCat.toString();

    // 2. استنتاج isGeneral إذا كان مفقوداً (بيانات قديمة)
    //    القاعدة: لا يوجد categoryId → معيار عام.
    final bool normalizedIsGeneral =
        (data['isGeneral'] as bool?) ?? (normalizedCategoryId == null);

    return ReviewCriterionModel(
      id: doc.id,
      categoryId: normalizedCategoryId,
      nameAr: data['nameAr'] as String? ?? '',
      nameEn: data['nameEn'] as String? ?? '',
      descriptionAr: data['descriptionAr'] as String?,
      descriptionEn: data['descriptionEn'] as String?,
      fieldKey: data['fieldKey'] as String? ?? '',
      weight: (data['weight'] as num?)?.toDouble() ?? 1.0,
      order: (data['order'] as num?)?.toInt() ?? 1,
      isActive: data['isActive'] as bool? ?? true,
      isRequired: data['isRequired'] as bool? ?? true,
      isGeneral: normalizedIsGeneral,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'descriptionAr': descriptionAr,
      'descriptionEn': descriptionEn,
      'fieldKey': fieldKey,
      'weight': weight,
      'order': order,
      'isActive': isActive,
      'isRequired': isRequired,
      'isGeneral': isGeneral,
    };
  }
}
