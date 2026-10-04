// models/category.dart
// Firestore-backed Category model (مختلف عن PlaceCategory المرجعي للأيقونات).
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'place_categories.dart';

class Category {
  final String id;
  final String nameAr;
  final String nameEn;
  final String iconKey;   // يطابق PlaceCategory.id للحصول على الأيقونة
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

  /// الأيقونة من المرجع المحلي (PlaceCategories)
  IconData get icon =>
      PlaceCategories.byId(iconKey)?.icon ?? Icons.category;

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      nameAr: (map['nameAr'] as String?) ?? '',
      nameEn: (map['nameEn'] as String?) ?? '',
      iconKey: (map['iconKey'] as String?) ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
      isActive: (map['isActive'] as bool?) ?? true,
      placeCount: (map['placeCount'] as num?)?.toInt() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

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

  @override
  String toString() => 'Category($id, $nameAr / $nameEn)';
}