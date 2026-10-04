// services/seed_service.dart
// يزرع Firestore ببيانات أولية (9 تصنيفات + 12 مكان تجريبي) للـ MVP.
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

  // ════════════════════════════════════════════════════════════
  // 9 تصنيفات MVP — iconKey يطابق PlaceCategories.byId() الموجود
  // ════════════════════════════════════════════════════════════
  static const List<Category> seedCategories = [
    Category(id: 'restaurants', nameAr: 'مطاعم', nameEn: 'Restaurants', iconKey: 'مطعم', order: 1),
    Category(id: 'cafes', nameAr: 'كافيهات', nameEn: 'Cafes', iconKey: 'كافيه', order: 2),
    Category(id: 'beaches', nameAr: 'شواطئ وبلاجات', nameEn: 'Beaches', iconKey: 'بلاج', order: 3),
    Category(id: 'hotels', nameAr: 'فنادق ومنتجعات', nameEn: 'Hotels & Resorts', iconKey: 'فندق ومنتجع', order: 4),
    Category(id: 'family', nameAr: 'ترفيه أسري', nameEn: 'Family & Entertainment', iconKey: 'ترفيه أسري', order: 5),
    Category(id: 'landmarks', nameAr: 'معالم تاريخية', nameEn: 'Historical Landmarks', iconKey: 'معلم تاريخي', order: 6),
    Category(id: 'shopping', nameAr: 'تسوق', nameEn: 'Shopping', iconKey: 'تسوق', order: 7),
    Category(id: 'parks', nameAr: 'حدائق ومتنزهات', nameEn: 'Parks', iconKey: 'حديقة', order: 8),
    Category(id: 'events', nameAr: 'فعاليات', nameEn: 'Events', iconKey: 'فعالية', order: 9),
  ];

  // ════════════════════════════════════════════════════════════
  // 12 مكان تجريبي — موزّعين على التصنيفات
  // ════════════════════════════════════════════════════════════
  static final List<Place> seedPlaces = [
    Place(
      id: 'abu_tarek',
      nameAr: 'مطعم أبو طارق',
      nameEn: 'Abu Tarek Restaurant',
      description: 'أشهر مطعم كشري في القاهرة',
      categoryId: 'restaurants',
      ownerId: 'seed',
      location: const GeoPoint(30.0589, 31.2436),
      address: '27 شارع شريف، وسط البلد',
      city: 'القاهرة',
      governorate: 'القاهرة',
      phone: '+20 100 000 0001',
      averageRating: 4.7,
      reviewCount: 312,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'fish_market',
      nameAr: 'مطعم فيش ماركت',
      nameEn: 'Fish Market',
      description: 'أسماك طازة على البحر المتوسط',
      categoryId: 'restaurants',
      ownerId: 'seed',
      location: const GeoPoint(31.2001, 29.9187),
      address: 'كورنيش الإسكندرية',
      city: 'الإسكندرية',
      governorate: 'الإسكندرية',
      phone: '+20 100 000 0002',
      averageRating: 4.5,
      reviewCount: 180,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'cafe_celine',
      nameAr: 'كافيه سيلين',
      nameEn: 'Cafe Celine',
      description: 'كافيه بإطلالة على البحر',
      categoryId: 'cafes',
      ownerId: 'seed',
      location: const GeoPoint(27.2579, 33.8116),
      address: 'ممشى السياحة، الغردقة',
      city: 'الغردقة',
      governorate: 'البحر الأحمر',
      phone: '+20 100 000 0003',
      averageRating: 4.6,
      reviewCount: 95,
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
      location: const GeoPoint(30.0459, 31.2621),
      address: 'شارع المعز',
      city: 'القاهرة',
      governorate: 'القاهرة',
      phone: '+20 100 000 0004',
      averageRating: 4.8,
      reviewCount: 210,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'marriott_beach',
      nameAr: 'شاطئ ماريوت',
      nameEn: 'Marriott Beach',
      description: 'شاطئ رملي خاص بالمنتجع',
      categoryId: 'beaches',
      ownerId: 'seed',
      location: const GeoPoint(27.2311, 33.8399),
      address: 'الغردقة',
      city: 'الغردقة',
      governorate: 'البحر الأحمر',
      phone: '+20 100 000 0005',
      averageRating: 4.9,
      reviewCount: 420,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'san_stefano_beach',
      nameAr: 'شاطئ سان ستيفانو',
      nameEn: 'San Stefano Beach',
      description: 'شاطئ عائلي على الكورنيش',
      categoryId: 'beaches',
      ownerId: 'seed',
      location: const GeoPoint(31.2411, 29.9621),
      address: 'سان ستيفانو',
      city: 'الإسكندرية',
      governorate: 'الإسكندرية',
      phone: '+20 100 000 0006',
      averageRating: 4.3,
      reviewCount: 165,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'hilton_plaza',
      nameAr: 'فندق هيلتون بلازا',
      nameEn: 'Hilton Plaza Hotel',
      description: 'فندق 5 نجوم في وسط القاهرة',
      categoryId: 'hotels',
      ownerId: 'seed',
      location: const GeoPoint(30.0561, 31.2262),
      address: 'ميدان التحرير',
      city: 'القاهرة',
      governorate: 'القاهرة',
      phone: '+20 100 000 0007',
      averageRating: 4.6,
      reviewCount: 530,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'rixos_sharm',
      nameAr: 'فندق ريكسوس شرم',
      nameEn: 'Rixos Sharm',
      description: 'منتجع فاخر على البحر الأحمر',
      categoryId: 'hotels',
      ownerId: 'seed',
      location: const GeoPoint(27.9158, 34.3299),
      address: 'خليج نبق',
      city: 'شرم الشيخ',
      governorate: 'جنوب سيناء',
      phone: '+20 100 000 0008',
      averageRating: 4.8,
      reviewCount: 780,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'dream_park',
      nameAr: 'دريم بارك',
      nameEn: 'Dream Park',
      description: 'مدينة ملاهي للأسر والأطفال',
      categoryId: 'family',
      ownerId: 'seed',
      location: const GeoPoint(30.0331, 31.0171),
      address: '6 أكتوبر',
      city: 'الجيزة',
      governorate: 'الجيزة',
      phone: '+20 100 000 0009',
      averageRating: 4.4,
      reviewCount: 620,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'kidzania',
      nameAr: 'كيدزانيا',
      nameEn: 'KidZania',
      description: 'مدينة تعليمية ترفيهية للأطفال',
      categoryId: 'family',
      ownerId: 'seed',
      location: const GeoPoint(30.0263, 31.4925),
      address: 'كايرو فيستيفال سيتي',
      city: 'القاهرة',
      governorate: 'القاهرة',
      phone: '+20 100 000 0010',
      averageRating: 4.5,
      reviewCount: 290,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'giza_pyramids',
      nameAr: 'أهرامات الجيزة',
      nameEn: 'Giza Pyramids',
      description: 'أعظم معالم مصر التاريخية',
      categoryId: 'landmarks',
      ownerId: 'seed',
      location: const GeoPoint(29.9792, 31.1342),
      address: 'الهرم',
      city: 'الجيزة',
      governorate: 'الجيزة',
      phone: '+20 100 000 0011',
      averageRating: 4.9,
      reviewCount: 1540,
      isApproved: true,
      isActive: true,
    ),
    Place(
      id: 'city_stars',
      nameAr: 'سيتي ستارز مول',
      nameEn: 'City Stars Mall',
      description: 'أكبر مول تجاري في مصر',
      categoryId: 'shopping',
      ownerId: 'seed',
      location: const GeoPoint(30.0729, 31.3456),
      address: 'مدينة نصر',
      city: 'القاهرة',
      governorate: 'القاهرة',
      phone: '+20 100 000 0012',
      averageRating: 4.6,
      reviewCount: 890,
      isApproved: true,
      isActive: true,
    ),
  ];

  // ════════════════════════════════════════════════════════════
  // العمليات
  // ════════════════════════════════════════════════════════════

  Future<int> seedAllCategories() async {
    final batch = _db.batch();
    for (final cat in seedCategories) {
      batch.set(_db.collection(categoriesCol).doc(cat.id), cat.toMap());
    }
    await batch.commit();
    debugPrint('✅ Seeded ${seedCategories.length} categories');
    return seedCategories.length;
  }

  Future<int> seedAllPlaces() async {
    final batch = _db.batch();
    for (final place in seedPlaces) {
      batch.set(_db.collection(placesCol).doc(place.id), place.toMap());
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

  /// ⚠️ للتطوير فقط — يمسح كل البيانات
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
    debugPrint('🗑️ Cleared ${cats.docs.length} cats + ${places.docs.length} places');
  }
}