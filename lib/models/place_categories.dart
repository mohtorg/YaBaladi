// models/place_categories.dart
//
// [v2.1 — 2026-10-18] — Alias Normalization + Defensive Lookups
//   - FIX (CRITICAL): byId normalizes singular/plural
//     ('beach' → 'beaches', 'restaurant' → 'restaurants', إلخ)
//     → يحل مشكلة البيانات المزروعة بـ 'beach' (singular)
//   - FIX: byLabelEn case-insensitive (trim + toLowerCase)
//   - FIX: byLabelAr trim
//   - NEW: byAnyId() — fallback chain (id → labelAr → labelEn)
//     مفيد لـ Category.icon
//   - NEW: normalizeId() — exposure للاستخدام الخارجي
//   - NEW: ids() returns unmodifiable list
//   - NEW: sorted() returns unmodifiable list
//
// [v2.0 — 2026-10-18] — CRITICAL: Align IDs with Firestore
// [v1.0 — الأصل]

import 'package:flutter/material.dart';

class PlaceCategory {
  final String id; // English ID — مطابق لـ Firestore
  final String labelAr; // اسم عربي للعرض
  final String labelEn; // اسم إنجليزي للعرض
  final IconData icon;
  final int order; // ترتيب في الواجهة

  const PlaceCategory({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    this.order = 99,
  });
}

class PlaceCategories {
  PlaceCategories._(); // منع الإنشاء

  // ═══════════════════════════════════════════════════════════════
  // ALIASES — singular ↔ plural + common alternatives
  // ═══════════════════════════════════════════════════════════════

  /// خريطة aliases — يُستخدم في `byId` لتوحيد الصيغ.
  ///
  /// **المشكلة المحلولة:** البيانات المزروعة في Firestore (Wave 2.1)
  /// تستخدم صيغة مفردة (`'beach'`)، والتصنيفات في هذه القائمة
  /// تستخدم صيغة جمع (`'beaches'`). بدلاً من تعديل Firestore
  /// (يتطلب re-seed)، نعتمد matching ذكي.
  ///
  /// **مفتاح:** قيمة Firestore (lowercase)
  /// **قيمة:** الـ canonical id في هذه القائمة
  static const Map<String, String> _aliases = {
    // singular → plural
    'beach': 'beaches',
    'restaurant': 'restaurants',
    'cafe': 'cafes',
    'park': 'parks',
    'hotel': 'hotels',
    'museum': 'museums',
    'event': 'events',
    'landmark': 'landmarks',
    'service': 'services',
    'activity': 'activities',

    // variants → canonical
    'kids_activities': 'kids',
    'children': 'kids',
    'wellness': 'health',
    'gym': 'clubs_gyms',
    'club': 'clubs_gyms',
    'tourist_area': 'tourist_areas',
    'tourist_village': 'tourist_villages',
    'beauty_center': 'beauty_centers',
    'women_salon': 'women_salons',
    'men_salon': 'men_salons',
    'historical': 'history',
    'water_activity': 'water_activities',
    'outing': 'trips',
  };

  // ═══════════════════════════════════════════════════════════════
  // DATA
  // ═══════════════════════════════════════════════════════════════

  static const all = <PlaceCategory>[
    // ─── الطعام والشراب ───
    PlaceCategory(
      id: 'restaurants',
      labelAr: 'مطاعم',
      labelEn: 'Restaurants',
      icon: Icons.restaurant,
      order: 1,
    ),
    PlaceCategory(
      id: 'cafes',
      labelAr: 'كافيهات',
      labelEn: 'Cafes',
      icon: Icons.coffee,
      order: 2,
    ),
    PlaceCategory(
      id: 'food',
      labelAr: 'أطعمة',
      labelEn: 'Food',
      icon: Icons.fastfood,
      order: 3,
    ),

    // ─── الطبيعة والشواطئ ───
    PlaceCategory(
      id: 'beaches',
      labelAr: 'شواطئ وبلاجات',
      labelEn: 'Beaches',
      icon: Icons.beach_access,
      order: 4,
    ),
    PlaceCategory(
      id: 'nature',
      labelAr: 'طبيعة',
      labelEn: 'Nature',
      icon: Icons.landscape,
      order: 5,
    ),
    PlaceCategory(
      id: 'parks',
      labelAr: 'حدائق ومتنزهات',
      labelEn: 'Parks',
      icon: Icons.park,
      order: 6,
    ),

    // ─── الثقافة والتاريخ ───
    PlaceCategory(
      id: 'landmarks',
      labelAr: 'معالم تاريخية',
      labelEn: 'Historical Landmarks',
      icon: Icons.account_balance,
      order: 7,
    ),
    PlaceCategory(
      id: 'history',
      labelAr: 'تاريخ',
      labelEn: 'History',
      icon: Icons.museum,
      order: 8,
    ),
    PlaceCategory(
      id: 'museums',
      labelAr: 'متاحف',
      labelEn: 'Museums',
      icon: Icons.museum_outlined,
      order: 9,
    ),
    PlaceCategory(
      id: 'culture',
      labelAr: 'ثقافة وفنون',
      labelEn: 'Culture & Arts',
      icon: Icons.theater_comedy,
      order: 10,
    ),

    // ─── العائلة والأطفال ───
    PlaceCategory(
      id: 'family',
      labelAr: 'ترفيه أسري',
      labelEn: 'Family & Entertainment',
      icon: Icons.family_restroom,
      order: 11,
    ),
    PlaceCategory(
      id: 'kids',
      labelAr: 'أنشطة وأماكن للأطفال',
      labelEn: 'Kids Activities & Places',
      icon: Icons.child_care,
      order: 12,
    ),

    // ─── التسوق والترفيه ───
    PlaceCategory(
      id: 'shopping',
      labelAr: 'تسوق',
      labelEn: 'Shopping',
      icon: Icons.shopping_bag,
      order: 13,
    ),
    PlaceCategory(
      id: 'events',
      labelAr: 'فعاليات',
      labelEn: 'Events',
      icon: Icons.celebration,
      order: 14,
    ),
    PlaceCategory(
      id: 'nightlife',
      labelAr: 'حياة ليلية',
      labelEn: 'Nightlife',
      icon: Icons.nightlife,
      order: 15,
    ),
    PlaceCategory(
      id: 'entertainment',
      labelAr: 'ألعاب وترفيه',
      labelEn: 'Games & Entertainment',
      icon: Icons.sports_esports,
      order: 16,
    ),

    // ─── الأنشطة ───
    PlaceCategory(
      id: 'water_activities',
      labelAr: 'أنشطة بحرية',
      labelEn: 'Water Activities',
      icon: Icons.sailing,
      order: 17,
    ),
    PlaceCategory(
      id: 'trips',
      labelAr: 'رحلات وخروجات',
      labelEn: 'Trips & Outings',
      icon: Icons.hiking,
      order: 18,
    ),

    // ─── الإقامة ───
    PlaceCategory(
      id: 'hotels',
      labelAr: 'فنادق ومنتجعات',
      labelEn: 'Hotels & Resorts',
      icon: Icons.hotel,
      order: 19,
    ),
    PlaceCategory(
      id: 'tourist_villages',
      labelAr: 'قرى سياحية',
      labelEn: 'Tourist Villages',
      icon: Icons.villa,
      order: 20,
    ),

    // ─── الخدمات ───
    PlaceCategory(
      id: 'beauty_centers',
      labelAr: 'بيوتي سنتر',
      labelEn: 'Beauty Centers',
      icon: Icons.spa,
      order: 21,
    ),
    PlaceCategory(
      id: 'women_salons',
      labelAr: 'كوافير حريمي',
      labelEn: 'Women Salons',
      icon: Icons.face_retouching_natural,
      order: 22,
    ),
    PlaceCategory(
      id: 'men_salons',
      labelAr: 'كوافير رجالي',
      labelEn: 'Men Salons',
      icon: Icons.cut,
      order: 23,
    ),
    PlaceCategory(
      id: 'clubs_gyms',
      labelAr: 'نوادي وصالات جيم',
      labelEn: 'Clubs & Gyms',
      icon: Icons.fitness_center,
      order: 24,
    ),
    PlaceCategory(
      id: 'health',
      labelAr: 'صحة وعناية',
      labelEn: 'Health & Care',
      icon: Icons.health_and_safety,
      order: 25,
    ),
    PlaceCategory(
      id: 'education',
      labelAr: 'تعليم وتدريب',
      labelEn: 'Education & Training',
      icon: Icons.school,
      order: 26,
    ),
    PlaceCategory(
      id: 'tourism_services',
      labelAr: 'خدمات سياحية',
      labelEn: 'Tourism Services',
      icon: Icons.travel_explore,
      order: 27,
    ),
    PlaceCategory(
      id: 'services',
      labelAr: 'خدمات',
      labelEn: 'Services',
      icon: Icons.build,
      order: 28,
    ),
    PlaceCategory(
      id: 'tourist_areas',
      labelAr: 'مناطق سياحية',
      labelEn: 'Tourist Areas',
      icon: Icons.landscape_outlined,
      order: 29,
    ),

    // ─── أخرى ───
    PlaceCategory(
      id: 'other',
      labelAr: 'أخرى',
      labelEn: 'Other',
      icon: Icons.more_horiz,
      order: 99,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // NORMALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// يوحّد الـ id: trim + lowercase + alias resolution.
  ///
  /// **مثال:**
  /// ```dart
  /// PlaceCategories.normalizeId('Beach')    // → 'beaches'
  /// PlaceCategories.normalizeId('beach')    // → 'beaches'
  /// PlaceCategories.normalizeId('RESTAURANTS') // → 'restaurants'
  /// PlaceCategories.normalizeId('unknown')  // → 'unknown'
  /// ```
  static String normalizeId(String raw) {
    final lower = raw.trim().toLowerCase();
    return _aliases[lower] ?? lower;
  }

  // ═══════════════════════════════════════════════════════════════
  // LOOKUPS
  // ═══════════════════════════════════════════════════════════════

  /// البحث بالـ ID (English) — مع alias normalization.
  ///
  /// ✅ يدعم:
  /// - Exact match: `'restaurants'`
  /// - Case-insensitive: `'Restaurants'`
  /// - Singular aliases: `'restaurant'`
  /// - Legacy variants: `'beach'` → `'beaches'`
  static PlaceCategory? byId(String id) {
    final normalized = normalizeId(id);
    for (final item in all) {
      if (item.id.toLowerCase() == normalized) return item;
    }
    return null;
  }

  /// البحث بالاسم العربي — trim only.
  static PlaceCategory? byLabelAr(String labelAr) {
    final target = labelAr.trim();
    for (final item in all) {
      if (item.labelAr == target) return item;
    }
    return null;
  }

  /// البحث بالاسم الإنجليزي — trim + case-insensitive.
  static PlaceCategory? byLabelEn(String labelEn) {
    final target = labelEn.trim().toLowerCase();
    for (final item in all) {
      if (item.labelEn.toLowerCase() == target) return item;
    }
    return null;
  }

  /// Fallback chain — يجرب كل الطرق.
  ///
  /// **الاستخدام المفضل لـ `Category.icon`** — يعمل مع أي صيغة مخزنة:
  /// - `'restaurants'` → byId
  /// - `'مطاعم'` → byLabelAr
  /// - `'Restaurants'` → byLabelEn
  /// - `'beach'` → byId (بعد alias) ✅
  static PlaceCategory? byAnyId(String raw) {
    return byId(raw) ?? byLabelAr(raw) ?? byLabelEn(raw);
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// قائمة الـ IDs (English) — immutable.
  ///
  /// مثال:
  /// ```dart
  /// final ids = PlaceCategories.ids();
  /// firestore.collection('places').where('categoryId', whereIn: ids.take(10))
  /// ```
  static List<String> ids() => List<String>.unmodifiable(all.map((c) => c.id));

  /// التصنيفات مرتبة حسب `order` (immutable).
  static List<PlaceCategory> sorted() {
    final list = List<PlaceCategory>.from(all);
    list.sort((a, b) => a.order.compareTo(b.order));
    return List<PlaceCategory>.unmodifiable(list);
  }

  /// هل الـ ID موجود؟ (يدعم aliases)
  static bool exists(String id) => byId(id) != null;
}
