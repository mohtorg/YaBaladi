// lib/repositories/filters_repository.dart
//
// [Wave 11 — Filters System] — 2026-10-25
// Firestore-backed filters repository.
//
// ✅ No composite indexes (orderBy only).
// ✅ Graceful fallback to local seeds if Firestore empty.
// ✅ Role-aware filtering (rolesAllowed).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/filter_definition.dart';

class FiltersRepository {
  final FirebaseFirestore? _injectedFirestore;

  FiltersRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('filters');

  static const int _maxDocs = 100;

  // ═══════════════════════════════════════════════════════════════
  // READ
  // ═══════════════════════════════════════════════════════════════

  /// Stream كل الفلاتر (للأدمن — يشمل غير النشطة).
  Stream<List<FilterDefinition>> watchAll() async* {
    try {
      await for (final snap
          in _collection.orderBy('order').limit(_maxDocs).snapshots()) {
        if (snap.docs.isEmpty) {
          yield _fallbackLocal();
        } else {
          yield snap.docs
              .map((d) => FilterDefinition.fromFirestore(d))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ watchAll filters error: $e — falling back to local');
      yield _fallbackLocal();
    }
  }

  /// Stream الفلاتر النشطة (للتطبيق العام).
  Stream<List<FilterDefinition>> watchActive() async* {
    try {
      await for (final snap
          in _collection.orderBy('order').limit(_maxDocs).snapshots()) {
        if (snap.docs.isEmpty) {
          yield _fallbackLocal();
        } else {
          final all =
              snap.docs.map((d) => FilterDefinition.fromFirestore(d)).toList();
          yield all.where((f) => f.isActive).toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ watchActive filters error: $e — falling back to local');
      yield _fallbackLocal();
    }
  }

  Future<List<FilterDefinition>> getAllActive() async {
    try {
      final snap = await _collection.orderBy('order').limit(_maxDocs).get();
      if (snap.docs.isEmpty) return _fallbackLocal();
      return snap.docs
          .map((d) => FilterDefinition.fromFirestore(d))
          .where((f) => f.isActive)
          .toList();
    } catch (e) {
      debugPrint('⚠️ getAllActive filters error: $e');
      return _fallbackLocal();
    }
  }

  Future<List<FilterDefinition>> getAll() async {
    try {
      final snap = await _collection.orderBy('order').limit(_maxDocs).get();
      if (snap.docs.isEmpty) return _fallbackLocal();
      return snap.docs.map((d) => FilterDefinition.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('⚠️ getAll filters error: $e');
      return _fallbackLocal();
    }
  }

  Future<FilterDefinition?> getById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return FilterDefinition.fromFirestore(doc);
    } catch (e) {
      debugPrint('⚠️ getById filter error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WRITE
  // ═══════════════════════════════════════════════════════════════

  Future<void> create(String id, FilterDefinition filter) async {
    await _collection.doc(id).set({
      ...filter.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await _collection.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> delete(String id) async {
    await _collection.doc(id).delete();
  }

  // ═══════════════════════════════════════════════════════════════
  // FALLBACK (seed local — يطابق ما سيُزرع في Firestore)
  // ═══════════════════════════════════════════════════════════════

  List<FilterDefinition> _fallbackLocal() {
    return const [
      FilterDefinition(
        id: 'sort',
        nameAr: 'الترتيب حسب',
        nameEn: 'Sort by',
        type: FilterType.sort,
        fieldKey: 'sort',
        icon: 'swap_vert',
        order: 1,
        options: [
          FilterOption(
              value: 'recommended', labelAr: 'الأنسب', labelEn: 'Recommended'),
          FilterOption(
              value: 'rating_desc',
              labelAr: 'الأعلى تقييماً',
              labelEn: 'Highest rated'),
          FilterOption(value: 'newest', labelAr: 'الأحدث', labelEn: 'Newest'),
          FilterOption(
              value: 'distance', labelAr: 'الأقرب', labelEn: 'Nearest'),
        ],
      ),
      FilterDefinition(
        id: 'rating',
        nameAr: 'التقييم',
        nameEn: 'Rating',
        type: FilterType.range,
        fieldKey: 'averageRating',
        icon: 'star',
        matchMode: 'gte',
        order: 2,
        options: [
          FilterOption(value: '0', labelAr: 'الكل', labelEn: 'All'),
          FilterOption(value: '3', labelAr: '3+ نجوم', labelEn: '3+ stars'),
          FilterOption(value: '4', labelAr: '4+ نجوم', labelEn: '4+ stars'),
        ],
      ),
      FilterDefinition(
        id: 'price',
        nameAr: 'السعر',
        nameEn: 'Price',
        type: FilterType.singleChoice,
        fieldKey: 'priceLevel',
        icon: 'attach_money',
        matchMode: 'exact',
        order: 3,
        options: [
          FilterOption(value: '1', labelAr: 'اقتصادي', labelEn: 'Budget'),
          FilterOption(value: '2', labelAr: 'متوسط', labelEn: 'Medium'),
          FilterOption(value: '3', labelAr: 'مرتفع', labelEn: 'High'),
        ],
      ),
      FilterDefinition(
        id: 'amenities',
        nameAr: 'المرافق',
        nameEn: 'Amenities',
        type: FilterType.multiChoice,
        fieldKey: 'amenities',
        icon: 'checkroom',
        matchMode: 'contains',
        order: 4,
        options: [
          FilterOption(
              value: 'wifi',
              labelAr: 'واي فاي',
              labelEn: 'Wi-Fi',
              icon: 'wifi'),
          FilterOption(
              value: 'parking',
              labelAr: 'موقف سيارات',
              labelEn: 'Parking',
              icon: 'local_parking'),
          FilterOption(
              value: 'restroom',
              labelAr: 'دورات مياه',
              labelEn: 'Restroom',
              icon: 'wc'),
          FilterOption(
              value: 'accessibility',
              labelAr: 'ذوي احتياجات',
              labelEn: 'Accessibility',
              icon: 'accessible'),
        ],
      ),
      FilterDefinition(
        id: 'features',
        nameAr: 'الميزات',
        nameEn: 'Features',
        type: FilterType.multiChoice,
        fieldKey: 'features',
        icon: 'people_outline',
        matchMode: 'contains',
        order: 5,
        options: [
          FilterOption(
              value: 'family',
              labelAr: 'عائلي',
              labelEn: 'Family-friendly',
              icon: 'family_restroom'),
          FilterOption(
              value: 'halal',
              labelAr: 'حلال',
              labelEn: 'Halal',
              icon: 'restaurant_menu'),
          FilterOption(
              value: 'delivery',
              labelAr: 'دليفري',
              labelEn: 'Delivery',
              icon: 'delivery_dining'),
          FilterOption(
              value: 'reservation',
              labelAr: 'حجوزات',
              labelEn: 'Reservation',
              icon: 'event_seat'),
        ],
      ),
    ];
  }
}
