// lib/models/category.dart
//
// [v1.1 — 2026-10-18] — Robust icon lookup + Defensive Casting
//   - FIX (CRITICAL): icon uses fallback chain
//     byId → byLabelAr → byLabelEn → Icons.category
//     → يعمل سواء كان iconKey في Firestore = 'مطعم' (قديم)
//       أو 'restaurants' (جديد) أو 'Restaurants' (label)
//   - FIX: createdAt/updatedAt defensive cast (is Timestamp)
//   - NEW: ==, hashCode — للمقارنة في Sets/اختبارات
//   - NEW: isVisible getter (isActive && placeCount > 0)
//   - NOTE: يعتمد على PlaceCategories.byId + byLabelAr + byLabelEn
//     → تأكد أن place_categories.dart يحتوي هذه الدوال
//
// [v1.0 — الأصل] — Firestore-backed Category model

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'place_categories.dart';

class Category {
  final String id;
  final String nameAr;
  final String nameEn;

  /// يطابق إما `PlaceCategory.id` (English) أو `PlaceCategory.labelAr`
  /// (Arabic) أو `PlaceCategory.labelEn` (English) — حسب ما تم تخزينه.
  final String iconKey;

  final int order;
  final bool isActive;
  final int placeCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.iconKey,
    this.order = 0,
    this.isActive = true,
    this.placeCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  // ═══════════════════════════════════════════════════════════════
  // ICON — fallback chain (defensive)
  // ═══════════════════════════════════════════════════════════════

  /// الأيقونة من المرجع المحلي (`PlaceCategories`).
  ///
  /// **fallback chain:**
  /// 1. `byId(iconKey)` — للـ English IDs الجديدة (`'restaurants'`).
  /// 2. `byLabelAr(iconKey)` — للبيانات القديمة المخزّنة بالعربي (`'مطعم'` = labelAr قديم، أو `'مطاعم'` = labelAr جديد).
  /// 3. `byLabelEn(iconKey)` — إذا كان iconKey = `'Restaurants'`.
  /// 4. `Icons.category` — fallback أخير.
  ///
  /// **لماذا؟** لتفادي فقدان الأيقونات عند تغيير `PlaceCategories`
  /// من Arabic IDs إلى English IDs (v1.0 → v2.0).
  IconData get icon {
    final byId = PlaceCategories.byId(iconKey);
    if (byId != null) return byId.icon;

    final byAr = PlaceCategories.byLabelAr(iconKey);
    if (byAr != null) return byAr.icon;

    final byEn = PlaceCategories.byLabelEn(iconKey);
    if (byEn != null) return byEn.icon;

    return Icons.category;
  }

  // ═══════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════

  /// هل التصنيف ظاهر للجمهور؟ (نشط + يحتوي أماكن).
  bool get isVisible => isActive && placeCount > 0;

  // ═══════════════════════════════════════════════════════════════
  // PARSING
  // ═══════════════════════════════════════════════════════════════

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    // defensive: createdAt/updatedAt
    final rawCreated = map['createdAt'];
    final rawUpdated = map['updatedAt'];

    return Category(
      id: id,
      nameAr: (map['nameAr'] as String?) ?? '',
      nameEn: (map['nameEn'] as String?) ?? '',
      iconKey: (map['iconKey'] as String?) ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      isActive: (map['isActive'] as bool?) ?? true,
      placeCount: (map['placeCount'] as num?)?.toInt() ?? 0,
      createdAt: rawCreated is Timestamp ? rawCreated.toDate() : null,
      updatedAt: rawUpdated is Timestamp ? rawUpdated.toDate() : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SERIALIZATION
  // ═══════════════════════════════════════════════════════════════

  Map<String, dynamic> toMap() => {
        'nameAr': nameAr,
        'nameEn': nameEn,
        'iconKey': iconKey,
        'order': order,
        'isActive': isActive,
        'placeCount': placeCount,
        'createdAt': createdAt != null
            ? Timestamp.fromDate(createdAt!)
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // ═══════════════════════════════════════════════════════════════
  // COPY WITH
  // ═══════════════════════════════════════════════════════════════

  Category copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? iconKey,
    int? order,
    bool? isActive,
    int? placeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Category(
        id: id ?? this.id,
        nameAr: nameAr ?? this.nameAr,
        nameEn: nameEn ?? this.nameEn,
        iconKey: iconKey ?? this.iconKey,
        order: order ?? this.order,
        isActive: isActive ?? this.isActive,
        placeCount: placeCount ?? this.placeCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  // ═══════════════════════════════════════════════════════════════
  // EQUALITY
  // ═══════════════════════════════════════════════════════════════

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          other.id == id &&
          other.nameAr == nameAr &&
          other.nameEn == nameEn &&
          other.iconKey == iconKey &&
          other.order == order &&
          other.isActive == isActive &&
          other.placeCount == placeCount;

  @override
  int get hashCode => Object.hash(
        id,
        nameAr,
        nameEn,
        iconKey,
        order,
        isActive,
        placeCount,
      );

  @override
  String toString() => 'Category($id, $nameAr / $nameEn)';
}
