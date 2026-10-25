// lib/services/seed_service.dart
//
// [v2.0 — 2026-10-24] — Category v2.0 schema alignment
//   - REPLACED: iconKey (old v1 field) → iconName (v2.0 required field)
//   - iconName values are English slug keys matching Category.availableIcons
//   - All Category() const constructors now provide iconName, so
//     "Null can't be assigned to String" no longer occurs.
//   - REMOVED: 'مطاعم' etc. as iconKey values (were Arabic, v1 legacy)
//   - KEPT: seedPlaces unchanged (no errors were reported on them)
//   - KEPT: public API — seedCategories, seedPlaces, seedAll*, clearAll
//
// [v1.2 — 2026-10-18] — static const for seedPlaces
// [v1.1 — 2026-10-16] — merge:true on writes
// [v1.0] — initial seed service

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../models/category.dart';
import '../models/place.dart';

class SeedService {
  SeedService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  static const String categoriesCol = 'categories';
  static const String placesCol = 'places';

  // ═══════════════════════════════════════════════════════════════
  // 9 categories — v2.0 schema (iconName is a required String key)
  // ═══════════════════════════════════════════════════════════════
  static const List<Category> seedCategories = [
    Category(
      id: 'restaurants',
      nameAr: 'مطاعم',
      nameEn: 'Restaurants',
      iconName: 'restaurant',
      order: 1,
    ),
    Category(
      id: 'cafes',
      nameAr: 'مقاهي',
      nameEn: 'Cafes',
      iconName: 'coffee',
      order: 2,
    ),
    Category(
      id: 'beaches',
      nameAr: 'شواطئ وساحل',
      nameEn: 'Beaches',
      iconName: 'beach_access',
      order: 3,
    ),
    Category(
      id: 'hotels',
      nameAr: 'فنادق ومنتجعات',
      nameEn: 'Hotels & Resorts',
      iconName: 'hotel',
      order: 4,
    ),
    Category(
      id: 'family',
      nameAr: 'ترفيه وعائلات',
      nameEn: 'Family & Entertainment',
      iconName: 'family_restroom',
      order: 5,
    ),
    Category(
      id: 'landmarks',
      nameAr: 'معالم تاريخية',
      nameEn: 'Historical Landmarks',
      iconName: 'account_balance',
      order: 6,
    ),
    Category(
      id: 'shopping',
      nameAr: 'تسوق',
      nameEn: 'Shopping',
      iconName: 'shopping_bag',
      order: 7,
    ),
    Category(
      id: 'parks',
      nameAr: 'حدائق عامة',
      nameEn: 'Parks',
      iconName: 'park',
      order: 8,
    ),
    Category(
      id: 'events',
      nameAr: 'فعاليات',
      nameEn: 'Events',
      iconName: 'event',
      order: 9,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // Seed places (unchanged from v1.2 — no errors were reported)
  // ═══════════════════════════════════════════════════════════════
  static const List<Place> seedPlaces = [
    Place(
      id: 'abu_tarek',
      nameAr: 'مطعم أبو طارق',
      nameEn: 'Abu Tarek Restaurant',
      description: 'أشهر مطاعم فسيخ في بورسعيد',
      categoryId: 'restaurants',
      ownerId: 'seed',
      location: GeoPoint(30.0589, 31.2436),
      address: '27 شارع بورسعيد، وسط البلد',
      city: 'بورسعيد',
      governorate: 'بورسعيد',
      phone: '+20 100 000 0001',
      averageRating: 4.7,
      reviewCount: 312,
      priceLevel: 1,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'fish_market',
      nameAr: 'مطعم فيش ماركت',
      nameEn: 'Fish Market',
      description: 'مأكولات بحرية طازجة',
      categoryId: 'restaurants',
      ownerId: 'seed',
      location: GeoPoint(31.2001, 29.9187),
      address: 'سوق السمك، الإسكندرية',
      city: 'الإسكندرية',
      governorate: 'الإسكندرية',
      phone: '+20 100 000 0002',
      averageRating: 4.5,
      reviewCount: 180,
      priceLevel: 3,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'cafe_celine',
      nameAr: 'كافيه سيلين',
      nameEn: 'Cafe Celine',
      description: 'كافيه هادئ بإطلالة',
      categoryId: 'cafes',
      ownerId: 'seed',
      location: GeoPoint(27.2579, 33.8116),
      address: 'كورنيش الغردقة',
      city: 'الغردقة',
      governorate: 'البحر الأحمر',
      phone: '+20 100 000 0003',
      averageRating: 4.6,
      reviewCount: 95,
      priceLevel: 2,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'beit_elqahwa',
      nameAr: 'بيت القهوة',
      nameEn: 'Beit El Qahwa',
      description: 'قهوة مختصة في وسط البلد',
      categoryId: 'cafes',
      ownerId: 'seed',
      location: GeoPoint(30.0459, 31.2621),
      address: 'شارع المعز',
      city: 'القاهرة',
      governorate: 'القاهرة',
      phone: '+20 100 000 0004',
      averageRating: 4.8,
      reviewCount: 210,
      priceLevel: 1,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'marriott_beach',
      nameAr: 'شاطئ ماريوت',
      nameEn: 'Marriott Beach',
      description: 'شاطئ خاص بمنتجع',
      categoryId: 'beaches',
      ownerId: 'seed',
      location: GeoPoint(27.2311, 33.8399),
      address: 'الغردقة',
      city: 'الغردقة',
      governorate: 'البحر الأحمر',
      phone: '+20 100 000 0005',
      averageRating: 4.9,
      reviewCount: 420,
      priceLevel: 4,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'san_stefano_beach',
      nameAr: 'شاطئ سان ستيفانو',
      nameEn: 'San Stefano Beach',
      description: 'شاطئ عائلي في الإسكندرية',
      categoryId: 'beaches',
      ownerId: 'seed',
      location: GeoPoint(31.2411, 29.9621),
      address: 'سان ستيفانو',
      city: 'الإسكندرية',
      governorate: 'الإسكندرية',
      phone: '+20 100 000 0006',
      averageRating: 4.3,
      reviewCount: 165,
      priceLevel: 1,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'hilton_plaza',
      nameAr: 'فندق هيلتون بلازا',
      nameEn: 'Hilton Plaza Hotel',
      description: 'فندق 5 نجوم في بورسعيد',
      categoryId: 'hotels',
      ownerId: 'seed',
      location: GeoPoint(30.0561, 31.2262),
      address: 'شارع الجمهورية',
      city: 'بورسعيد',
      governorate: 'بورسعيد',
      phone: '+20 100 000 0007',
      averageRating: 4.6,
      reviewCount: 530,
      priceLevel: 4,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'rixos_sharm',
      nameAr: 'فندق ريكسوس شرم',
      nameEn: 'Rixos Sharm',
      description: 'منتجع فاخر في شرم الشيخ',
      categoryId: 'hotels',
      ownerId: 'seed',
      location: GeoPoint(27.9158, 34.3299),
      address: 'خليج نعمة',
      city: 'شرم الشيخ',
      governorate: 'جنوب سيناء',
      phone: '+20 100 000 0008',
      averageRating: 4.8,
      reviewCount: 780,
      priceLevel: 4,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'dream_park',
      nameAr: 'دريم بارك',
      nameEn: 'Dream Park',
      description: 'مدينة ملاهي في 6 أكتوبر',
      categoryId: 'family',
      ownerId: 'seed',
      location: GeoPoint(30.0331, 31.0171),
      address: '6 أكتوبر',
      city: 'الجيزة',
      governorate: 'الجيزة',
      phone: '+20 100 000 0009',
      averageRating: 4.4,
      reviewCount: 620,
      priceLevel: 2,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'kidzania',
      nameAr: 'كيدزانيا',
      nameEn: 'KidZania',
      description: 'مدينة تعليمية للأطفال',
      categoryId: 'family',
      ownerId: 'seed',
      location: GeoPoint(30.0263, 31.4925),
      address: 'مول كايرو فستيفال سيتي',
      city: 'القاهرة',
      governorate: 'القاهرة',
      phone: '+20 100 000 0010',
      averageRating: 4.5,
      reviewCount: 290,
      priceLevel: 3,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'giza_pyramids',
      nameAr: 'أهرامات الجيزة',
      nameEn: 'Giza Pyramids',
      description: 'أحد عجائب الدنيا السبع',
      categoryId: 'landmarks',
      ownerId: 'seed',
      location: GeoPoint(29.9792, 31.1342),
      address: 'الجيزة',
      city: 'الجيزة',
      governorate: 'الجيزة',
      phone: '+20 100 000 0011',
      averageRating: 4.9,
      reviewCount: 1540,
      priceLevel: 2,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'city_stars',
      nameAr: 'كايرو فستيفال سيتي مول',
      nameEn: 'City Stars Mall',
      description: 'أحد أكبر مولات مصر',
      categoryId: 'shopping',
      ownerId: 'seed',
      location: GeoPoint(30.0729, 31.3456),
      address: 'مدينة نصر',
      city: 'القاهرة',
      governorate: 'القاهرة',
      phone: '+20 100 000 0012',
      averageRating: 4.6,
      reviewCount: 890,
      priceLevel: 3,
      isApproved: true,
      isActive: true,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════
  // Seed operations
  // ═══════════════════════════════════════════════════════════════

  Future<int> seedAllCategories() async {
    final batch = _db.batch();
    for (final cat in seedCategories) {
      batch.set(
        _db.collection(categoriesCol).doc(cat.id),
        cat.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    debugPrint('✅ Seeded ${seedCategories.length} categories');
    return seedCategories.length;
  }

  Future<int> seedAllPlaces() async {
    final batch = _db.batch();
    for (final place in seedPlaces) {
      batch.set(
        _db.collection(placesCol).doc(place.id),
        place.toMap(),
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    debugPrint('✅ Seeded ${seedPlaces.length} places');
    return seedPlaces.length;
  }

  Future<Map<String, int>> seedAll() async {
    final cats = await seedAllCategories();
    final places = await seedAllPlaces();
    return {'categories': cats, 'places': places};
  }

  Future<void> clearAll() async {
    final cats = await _db.collection(categoriesCol).get();
    final places = await _db.collection(placesCol).get();
    final batch = _db.batch();
    for (final d in cats.docs) {
      batch.delete(d.reference);
    }
    for (final d in places.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
    debugPrint(
      '🗑️ Cleared ${cats.docs.length} cats + ${places.docs.length} places',
    );
  }
}
