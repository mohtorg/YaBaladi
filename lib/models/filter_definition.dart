// lib/models/filter_definition.dart
//
// [Wave 11 — Filters System] — 2026-10-25
// نموذج تعريف الفلتر — Firestore-backed.
//
// يدعم 5 أنواع: single_choice, multi_choice, range, boolean, sort.
// كل فلتر مرتبط بحقل في Place عبر fieldKey.
//
// ✅ Dynamic — يُدار من Admin Dashboard.
// ✅ Role-aware — rolesAllowed يحدد من يرى الفلتر.

import 'package:cloud_firestore/cloud_firestore.dart';

enum FilterType {
  singleChoice, // اختيار واحد (price: 1,2,3)
  multiChoice, // اختيار متعدد (features: family, halal)
  range, // نطاق (rating: >= 4)
  boolean, // تبديل (hasWifi: true/false)
  sort, // ترتيب (order: recommended, newest)
}

class FilterOption {
  final String value; // slug: 'wifi', 'parking'
  final String labelAr;
  final String labelEn;
  final String? icon; // iconName من Category.availableIcons

  const FilterOption({
    required this.value,
    required this.labelAr,
    required this.labelEn,
    this.icon,
  });

  factory FilterOption.fromMap(Map<String, dynamic> map) {
    return FilterOption(
      value: (map['value'] ?? '').toString(),
      labelAr: (map['labelAr'] ?? map['label'] ?? '').toString(),
      labelEn: (map['labelEn'] ?? map['label'] ?? '').toString(),
      icon: map['icon']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'value': value,
        'labelAr': labelAr,
        'labelEn': labelEn,
        if (icon != null) 'icon': icon,
      };
}

class FilterDefinition {
  final String id; // slug: 'amenities', 'price'
  final String nameAr;
  final String nameEn;
  final FilterType type;
  final String fieldKey; // 'hasWifi', 'priceLevel', 'averageRating'
  final String? icon;
  final int order;
  final bool isActive;
  final bool isRequired;
  final List<String> rolesAllowed; // ['user','merchant','moderator','admin']
  final List<FilterOption> options;
  final String matchMode; // 'exact', 'contains', 'gte', 'lte'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FilterDefinition({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.type,
    required this.fieldKey,
    this.icon,
    this.order = 100,
    this.isActive = true,
    this.isRequired = false,
    this.rolesAllowed = const ['user', 'merchant', 'moderator', 'admin'],
    this.options = const [],
    this.matchMode = 'exact',
    this.createdAt,
    this.updatedAt,
  });

  // ─── Firestore ───

  factory FilterDefinition.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return FilterDefinition.fromMap(map, id: doc.id);
  }

  factory FilterDefinition.fromMap(Map<String, dynamic> map, {String? id}) {
    return FilterDefinition(
      id: id ?? (map['id'] ?? '').toString(),
      nameAr: (map['nameAr'] ?? '').toString(),
      nameEn: (map['nameEn'] ?? '').toString(),
      type: _parseType(map['type']),
      fieldKey: (map['fieldKey'] ?? '').toString(),
      icon: map['icon']?.toString(),
      order: (map['order'] as num?)?.toInt() ?? 100,
      isActive: map['isActive'] == true,
      isRequired: map['isRequired'] == true,
      rolesAllowed:
          (map['rolesAllowed'] as List?)?.map((e) => e.toString()).toList() ??
              const ['user', 'merchant', 'moderator', 'admin'],
      options: (map['options'] as List?)
              ?.map((e) => FilterOption.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      matchMode: (map['matchMode'] ?? 'exact').toString(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'type': _typeToString(type),
        'fieldKey': fieldKey,
        if (icon != null) 'icon': icon,
        'order': order,
        'isActive': isActive,
        'isRequired': isRequired,
        'rolesAllowed': rolesAllowed,
        'options': options.map((o) => o.toMap()).toList(),
        'matchMode': matchMode,
      };

  FilterDefinition copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    FilterType? type,
    String? fieldKey,
    String? icon,
    int? order,
    bool? isActive,
    bool? isRequired,
    List<String>? rolesAllowed,
    List<FilterOption>? options,
    String? matchMode,
  }) {
    return FilterDefinition(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      type: type ?? this.type,
      fieldKey: fieldKey ?? this.fieldKey,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      isRequired: isRequired ?? this.isRequired,
      rolesAllowed: rolesAllowed ?? this.rolesAllowed,
      options: options ?? this.options,
      matchMode: matchMode ?? this.matchMode,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ─── Helpers ───

  static FilterType _parseType(dynamic raw) {
    switch ((raw ?? '').toString()) {
      case 'multi_choice':
        return FilterType.multiChoice;
      case 'range':
        return FilterType.range;
      case 'boolean':
        return FilterType.boolean;
      case 'sort':
        return FilterType.sort;
      case 'single_choice':
      default:
        return FilterType.singleChoice;
    }
  }

  static String _typeToString(FilterType t) {
    switch (t) {
      case FilterType.singleChoice:
        return 'single_choice';
      case FilterType.multiChoice:
        return 'multi_choice';
      case FilterType.range:
        return 'range';
      case FilterType.boolean:
        return 'boolean';
      case FilterType.sort:
        return 'sort';
    }
  }
}

/// نتيجة اختيار المستخدم لفلتر واحد.
class FilterSelection {
  final Set<String> values; // ['wifi', 'parking'] أو ['4']

  const FilterSelection(this.values);

  bool get isEmpty => values.isEmpty;
  bool get isNotEmpty => values.isNotEmpty;

  static const FilterSelection empty = FilterSelection({});
}
