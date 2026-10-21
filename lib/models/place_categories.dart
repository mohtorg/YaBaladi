// models/place_categories.dart
//
// [v2.2 — 2026-10-20] — Added OSM aliases (attraction, fast_food) + full normalization.
// [v2.1 — 2026-10-18] — Alias Normalization + Defensive Lookups

import 'package:flutter/material.dart';

class PlaceCategory {
  final String id;
  final String labelAr;
  final String labelEn;
  final IconData icon;
  final int order;

  const PlaceCategory({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    this.order = 99,
  });
}

class PlaceCategories {
  PlaceCategories._();

  static const Map<String, String> _aliases = {
    // ✅ التصحيح لبيانات OpenStreetMap
    'restaurant': 'restaurants',
    'fast_food': 'restaurants',
    'cafe': 'cafes',
    'attraction': 'landmarks',
    'tourist_attraction': 'tourist_areas',
    'museum': 'museums',
    'park': 'parks',
    'hotel': 'hotels',
    'monument': 'landmarks',

    // variants → canonical
    'beach': 'beaches',
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

  static const all = <PlaceCategory>[
    PlaceCategory(
        id: 'restaurants',
        labelAr: 'مطاعم',
        labelEn: 'Restaurants',
        icon: Icons.restaurant,
        order: 1),
    PlaceCategory(
        id: 'cafes',
        labelAr: 'كافيهات',
        labelEn: 'Cafes',
        icon: Icons.coffee,
        order: 2),
    PlaceCategory(
        id: 'food',
        labelAr: 'أطعمة',
        labelEn: 'Food',
        icon: Icons.fastfood,
        order: 3),
    PlaceCategory(
        id: 'beaches',
        labelAr: 'شواطئ وبلاجات',
        labelEn: 'Beaches',
        icon: Icons.beach_access,
        order: 4),
    PlaceCategory(
        id: 'nature',
        labelAr: 'طبيعة',
        labelEn: 'Nature',
        icon: Icons.landscape,
        order: 5),
    PlaceCategory(
        id: 'parks',
        labelAr: 'حدائق ومتنزهات',
        labelEn: 'Parks',
        icon: Icons.park,
        order: 6),
    PlaceCategory(
        id: 'landmarks',
        labelAr: 'معالم تاريخية',
        labelEn: 'Historical Landmarks',
        icon: Icons.account_balance,
        order: 7),
    PlaceCategory(
        id: 'history',
        labelAr: 'تاريخ',
        labelEn: 'History',
        icon: Icons.museum,
        order: 8),
    PlaceCategory(
        id: 'museums',
        labelAr: 'متاحف',
        labelEn: 'Museums',
        icon: Icons.museum_outlined,
        order: 9),
    PlaceCategory(
        id: 'culture',
        labelAr: 'ثقافة وفنون',
        labelEn: 'Culture & Arts',
        icon: Icons.theater_comedy,
        order: 10),
    PlaceCategory(
        id: 'family',
        labelAr: 'ترفيه أسري',
        labelEn: 'Family & Entertainment',
        icon: Icons.family_restroom,
        order: 11),
    PlaceCategory(
        id: 'kids',
        labelAr: 'أنشطة وأماكن للأطفال',
        labelEn: 'Kids Activities & Places',
        icon: Icons.child_care,
        order: 12),
    PlaceCategory(
        id: 'shopping',
        labelAr: 'تسوق',
        labelEn: 'Shopping',
        icon: Icons.shopping_bag,
        order: 13),
    PlaceCategory(
        id: 'events',
        labelAr: 'فعاليات',
        labelEn: 'Events',
        icon: Icons.celebration,
        order: 14),
    PlaceCategory(
        id: 'nightlife',
        labelAr: 'حياة ليلية',
        labelEn: 'Nightlife',
        icon: Icons.nightlife,
        order: 15),
    PlaceCategory(
        id: 'entertainment',
        labelAr: 'ألعاب وترفيه',
        labelEn: 'Games & Entertainment',
        icon: Icons.sports_esports,
        order: 16),
    PlaceCategory(
        id: 'water_activities',
        labelAr: 'أنشطة بحرية',
        labelEn: 'Water Activities',
        icon: Icons.sailing,
        order: 17),
    PlaceCategory(
        id: 'trips',
        labelAr: 'رحلات وخروجات',
        labelEn: 'Trips & Outings',
        icon: Icons.hiking,
        order: 18),
    PlaceCategory(
        id: 'hotels',
        labelAr: 'فنادق ومنتجعات',
        labelEn: 'Hotels & Resorts',
        icon: Icons.hotel,
        order: 19),
    PlaceCategory(
        id: 'tourist_villages',
        labelAr: 'قرى سياحية',
        labelEn: 'Tourist Villages',
        icon: Icons.villa,
        order: 20),
    PlaceCategory(
        id: 'beauty_centers',
        labelAr: 'بيوتي سنتر',
        labelEn: 'Beauty Centers',
        icon: Icons.spa,
        order: 21),
    PlaceCategory(
        id: 'women_salons',
        labelAr: 'كوافير حريمي',
        labelEn: 'Women Salons',
        icon: Icons.face_retouching_natural,
        order: 22),
    PlaceCategory(
        id: 'men_salons',
        labelAr: 'كوافير رجالي',
        labelEn: 'Men Salons',
        icon: Icons.cut,
        order: 23),
    PlaceCategory(
        id: 'clubs_gyms',
        labelAr: 'نوادي وصالات جيم',
        labelEn: 'Clubs & Gyms',
        icon: Icons.fitness_center,
        order: 24),
    PlaceCategory(
        id: 'health',
        labelAr: 'صحة وعناية',
        labelEn: 'Health & Care',
        icon: Icons.health_and_safety,
        order: 25),
    PlaceCategory(
        id: 'education',
        labelAr: 'تعليم وتدريب',
        labelEn: 'Education & Training',
        icon: Icons.school,
        order: 26),
    PlaceCategory(
        id: 'tourism_services',
        labelAr: 'خدمات سياحية',
        labelEn: 'Tourism Services',
        icon: Icons.travel_explore,
        order: 27),
    PlaceCategory(
        id: 'services',
        labelAr: 'خدمات',
        labelEn: 'Services',
        icon: Icons.build,
        order: 28),
    PlaceCategory(
        id: 'tourist_areas',
        labelAr: 'مناطق سياحية',
        labelEn: 'Tourist Areas',
        icon: Icons.landscape_outlined,
        order: 29),
    PlaceCategory(
        id: 'other',
        labelAr: 'أخرى',
        labelEn: 'Other',
        icon: Icons.more_horiz,
        order: 99),
  ];

  static String normalizeId(String raw) {
    final lower = raw.trim().toLowerCase();
    return _aliases[lower] ?? lower;
  }

  static PlaceCategory? byId(String id) {
    final normalized = normalizeId(id);
    for (final item in all) {
      if (item.id.toLowerCase() == normalized) return item;
    }
    return null;
  }

  static PlaceCategory? byLabelAr(String labelAr) {
    final target = labelAr.trim();
    for (final item in all) {
      if (item.labelAr == target) return item;
    }
    return null;
  }

  static PlaceCategory? byLabelEn(String labelEn) {
    final target = labelEn.trim().toLowerCase();
    for (final item in all) {
      if (item.labelEn.toLowerCase() == target) return item;
    }
    return null;
  }

  static PlaceCategory? byAnyId(String raw) {
    return byId(raw) ?? byLabelAr(raw) ?? byLabelEn(raw);
  }

  static List<String> ids() => List<String>.unmodifiable(all.map((c) => c.id));

  static List<PlaceCategory> sorted() {
    final list = List<PlaceCategory>.from(all);
    list.sort((a, b) => a.order.compareTo(b.order));
    return List<PlaceCategory>.unmodifiable(list);
  }

  static bool exists(String id) => byId(id) != null;
}
