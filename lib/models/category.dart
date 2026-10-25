// lib/models/category.dart
//
// [v2.0 — 2026-10-23] — Firestore-backed Category
//   - ADDED: iconName, colorHex, isActive, isFeatured, parentId,
//            aliases, placesCount, searchKeywords, createdAt, updatedAt.
//   - icon/color now getters (Firestore can't store IconData/Color).
//   - Defensive fromMap (backwards-compatible with old data).
//   - Full copyWith.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id; // slug: 'restaurants', 'cafes', 'landmarks'
  final String nameAr;
  final String nameEn;
  final String iconName; // stored in Firestore
  final String colorHex; // '#0D6EFD'
  final int order;
  final bool isActive;
  final bool isFeatured;
  final String? parentId; // for hierarchy (null = root)
  final List<String> aliases; // OSM tags: ['restaurant', 'fast_food']
  final int placesCount; // denormalized counter
  final List<String> searchKeywords;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.iconName,
    this.colorHex = '#0D6EFD',
    this.order = 99,
    this.isActive = true,
    this.isFeatured = false,
    this.parentId,
    this.aliases = const [],
    this.placesCount = 0,
    this.searchKeywords = const [],
    this.createdAt,
    this.updatedAt,
  });

  // ═══════════════════════════════════════════════════════════════
  // UI Getters (translation from stored strings)
  // ═══════════════════════════════════════════════════════════════

  /// يحوّل iconName إلى IconData للاستخدام في الواجهة.
  IconData get icon => _iconFromName(iconName);

  /// يحوّل colorHex إلى Color.
  Color get color => _colorFromHex(colorHex);

  // ═══════════════════════════════════════════════════════════════
  // Firestore serialization
  // ═══════════════════════════════════════════════════════════════

  factory Category.fromMap(String id, Map<String, dynamic> map) {
    return Category(
      id: id,
      nameAr: _str(map['nameAr'] ?? map['labelAr'] ?? id),
      nameEn: _str(map['nameEn'] ?? map['labelEn'] ?? id),
      iconName: _str(map['iconName'] ?? map['icon'] ?? 'category'),
      colorHex: _str(map['colorHex'] ?? map['color'] ?? '#0D6EFD'),
      order: _int(map['order'], 99),
      isActive: _bool(map['isActive'], true),
      isFeatured: _bool(map['isFeatured'], false),
      parentId: map['parentId'] as String?,
      aliases: _strList(map['aliases']),
      placesCount: _int(map['placesCount'], 0),
      searchKeywords: _strList(map['searchKeywords']),
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
    );
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Category.fromMap(doc.id, data);
  }

  Map<String, dynamic> toMap() {
    return {
      'nameAr': nameAr,
      'nameEn': nameEn,
      'iconName': iconName,
      'colorHex': colorHex,
      'order': order,
      'isActive': isActive,
      'isFeatured': isFeatured,
      if (parentId != null) 'parentId': parentId,
      'aliases': aliases,
      'placesCount': placesCount,
      'searchKeywords': searchKeywords,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Category copyWith({
    String? id,
    String? nameAr,
    String? nameEn,
    String? iconName,
    String? colorHex,
    int? order,
    bool? isActive,
    bool? isFeatured,
    String? parentId,
    List<String>? aliases,
    int? placesCount,
    List<String>? searchKeywords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      parentId: parentId ?? this.parentId,
      aliases: aliases ?? this.aliases,
      placesCount: placesCount ?? this.placesCount,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Static helpers (icon/color conversions)
  // ═══════════════════════════════════════════════════════════════

  /// قائمة الأيقونات المدعومة — يمكن توسيعها بحرية.
  static const Map<String, IconData> availableIcons = {
    'restaurant': Icons.restaurant,
    'coffee': Icons.coffee,
    'fastfood': Icons.fastfood,
    'beach_access': Icons.beach_access,
    'landscape': Icons.landscape,
    'park': Icons.park,
    'account_balance': Icons.account_balance,
    'museum': Icons.museum,
    'museum_outlined': Icons.museum_outlined,
    'theater_comedy': Icons.theater_comedy,
    'family_restroom': Icons.family_restroom,
    'child_care': Icons.child_care,
    'shopping_bag': Icons.shopping_bag,
    'celebration': Icons.celebration,
    'nightlife': Icons.nightlife,
    'sports_esports': Icons.sports_esports,
    'sailing': Icons.sailing,
    'hiking': Icons.hiking,
    'hotel': Icons.hotel,
    'villa': Icons.villa,
    'spa': Icons.spa,
    'face_retouching_natural': Icons.face_retouching_natural,
    'cut': Icons.cut,
    'fitness_center': Icons.fitness_center,
    'health_and_safety': Icons.health_and_safety,
    'school': Icons.school,
    'travel_explore': Icons.travel_explore,
    'build': Icons.build,
    'landscape_outlined': Icons.landscape_outlined,
    'more_horiz': Icons.more_horiz,
    'category': Icons.category,
    'local_cafe': Icons.local_cafe,
    'local_bar': Icons.local_bar,
    'storefront': Icons.storefront,
    'local_mall': Icons.local_mall,
    'church': Icons.church,
    'mosque': Icons.mosque,
    'temple_buddhist': Icons.temple_buddhist,
    'stadium': Icons.stadium,
    'pool': Icons.pool,
    'camera_alt': Icons.camera_alt,
    'music_note': Icons.music_note,
    'palette': Icons.palette,
    'spa_outlined': Icons.spa_outlined,
    'location_city': Icons.location_city,
    'apartment': Icons.apartment,
    'house': Icons.house,
  };

  static IconData _iconFromName(String name) {
    return availableIcons[name] ?? Icons.category;
  }

  static Color _colorFromHex(String hex) {
    var h = hex.trim().replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    final value = int.tryParse(h, radix: 16) ?? 0xFF0D6EFD;
    return Color(value);
  }

  static String colorToHex(Color c) {
    return '#${c.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  // ═══════════════════════════════════════════════════════════════
  // Defensive parsing helpers
  // ═══════════════════════════════════════════════════════════════

  static String _str(dynamic v) => v?.toString() ?? '';
  static int _int(dynamic v, int fallback) =>
      v is num ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? fallback);
  static bool _bool(dynamic v, bool fallback) => v is bool
      ? v
      : (v?.toString() == 'true'
          ? true
          : (v?.toString() == 'false' ? false : fallback));
  static List<String> _strList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    if (v is String && v.isNotEmpty)
      return v.split(',').map((e) => e.trim()).toList();
    return const [];
  }

  static DateTime? _date(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  String toString() => 'Category($id, $nameAr / $nameEn)';
}
