// lib/repositories/categories_repository.dart
//
// [v2.2.1 — FIXED] — Defensive enhancements (behavior-preserving).
//   - ADDED: Early return in delete() if doc doesn't exist (saves network call).
//   - ADDED: Guard in update() to prevent empty-id calls.
//   - IMPROVED: Clearer error message in delete() when doc exists.
//   - KEPT: All v2.2 fixes (Web SDK b815 workaround, limits, local fallback).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;

import '../models/category.dart';
import '../models/place_categories.dart';

class CategoriesRepository {
  final FirebaseFirestore? _injectedFirestore;

  CategoriesRepository({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore;

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('categories');

  // [v2.2] Defensive upper bound on list queries.
  static const int _maxDocs = 500;

  // ═══════════════════════════════════════════════════════════════
  // READ
  // ═══════════════════════════════════════════════════════════════

  /// Stream of active categories, ordered by `order`.
  ///
  /// [v2.2] No `.where()` here — filtering is done in Dart to avoid
  /// the composite index requirement (`where + orderBy`).
  Stream<List<Category>> watchActive() async* {
    try {
      await for (final snap
          in _collection.orderBy('order').limit(_maxDocs).snapshots()) {
        if (snap.docs.isEmpty) {
          yield _fallbackLocal();
        } else {
          final all = snap.docs.map((d) => Category.fromFirestore(d)).toList();
          yield all.where((c) => c.isActive).toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ watchActive error: $e — falling back to local');
      yield _fallbackLocal();
    }
  }

  /// Stream of all categories (admin — includes inactive).
  Stream<List<Category>> watchAll() async* {
    try {
      await for (final snap
          in _collection.orderBy('order').limit(_maxDocs).snapshots()) {
        if (snap.docs.isEmpty) {
          yield _fallbackLocal();
        } else {
          yield snap.docs.map((d) => Category.fromFirestore(d)).toList();
        }
      }
    } catch (e) {
      debugPrint('⚠️ watchAll error: $e — falling back to local');
      yield _fallbackLocal();
    }
  }

  /// One-shot fetch of active categories.
  ///
  /// [v2.2] Same composite-index reasoning as `watchActive`.
  Future<List<Category>> getAllActive() async {
    try {
      final snap = await _collection.orderBy('order').limit(_maxDocs).get();
      if (snap.docs.isEmpty) return _fallbackLocal();
      final all = snap.docs.map((d) => Category.fromFirestore(d)).toList();
      return all.where((c) => c.isActive).toList();
    } catch (e) {
      debugPrint('⚠️ getAllActive error: $e — falling back to local');
      return _fallbackLocal();
    }
  }

  /// One-shot fetch of all categories (admin).
  Future<List<Category>> getAll() async {
    try {
      final snap = await _collection.orderBy('order').limit(_maxDocs).get();
      if (snap.docs.isEmpty) return _fallbackLocal();
      return snap.docs.map((d) => Category.fromFirestore(d)).toList();
    } catch (e) {
      debugPrint('⚠️ getAll error: $e — falling back to local');
      return _fallbackLocal();
    }
  }

  /// Single category by id.
  Future<Category?> getById(String id) async {
    if (id.isEmpty) return null;
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return Category.fromFirestore(doc);
    } catch (e) {
      debugPrint('⚠️ getById error: $e');
      return null;
    }
  }

  /// Look up a category by one of its aliases.
  ///
  /// Uses `arrayContains` — single-field index, no composite needed.
  Future<Category?> findByAlias(String alias) async {
    if (alias.isEmpty) return null;
    try {
      final snap = await _collection
          .where('aliases', arrayContains: alias)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return null;
      return Category.fromFirestore(snap.docs.first);
    } catch (e) {
      debugPrint('⚠️ findByAlias error: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // WRITE
  // ═══════════════════════════════════════════════════════════════

  /// Create a new category. `id` is the slug and must be unique.
  /// Uses `.set()` (full overwrite) — intended for creation only.
  Future<void> create(String id, Category category) async {
    if (id.isEmpty) {
      throw ArgumentError('Category id cannot be empty.');
    }
    await _collection.doc(id).set(category.toMap());
  }

  /// Partial update. Uses `.update()` (merge) — safe for partial data.
  Future<void> update(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) return; // ✅ حماية: لا تُرسل طلب لـ Firebase بمعرف فارغ
    await _collection.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a category. Rejects if it still has associated places.
  Future<void> delete(String id) async {
    if (id.isEmpty) return; // ✅ حماية: لا تُرسل طلب لـ Firebase بمعرف فارغ

    final doc = await _collection.doc(id).get();
    // ✅ إذا كانت الوثيقة غير موجودة، لا داعي لإجراء طلب حذف (no-op) على Firebase
    if (!doc.exists) return;

    final count = (doc.data()?['placesCount'] as num?)?.toInt() ?? 0;
    if (count > 0) {
      final name = (doc.data()?['nameAr'] as String?) ?? id;
      throw Exception(
        'لا يمكن حذف التصنيف "$name" لاحتوائه على $count مكان. عطّله بدلاً من ذلك.',
      );
    }
    await _collection.doc(id).delete();
  }

  /// Atomically increment `placesCount` (delta may be positive or negative).
  ///
  /// Note: uses `FieldValue.increment` — server-side atomic, safe under
  /// concurrent writers. Failures are logged but do NOT throw: a
  /// counter drift should never fail the primary save operation.
  Future<void> incrementPlacesCount(String categoryId, int delta) async {
    if (categoryId.isEmpty) return;
    try {
      await _collection.doc(categoryId).update({
        'placesCount': FieldValue.increment(delta),
      });
    } catch (e) {
      debugPrint('⚠️ incrementPlacesCount error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // LOCAL FALLBACK
  // ═══════════════════════════════════════════════════════════════

  List<Category> _fallbackLocal() {
    return PlaceCategories.all.map(_convertLocal).toList();
  }

  Category _convertLocal(PlaceCategory pc) {
    // Reverse-lookup IconData → iconName.
    //
    // [v2.2] Guard against null fontFamily: only compare when both
    // sides have a non-null family. Otherwise we could match against
    // the fallback `Icons.category` unintentionally.
    String iconName = 'category';
    final targetCode = pc.icon.codePoint;
    final targetFamily = pc.icon.fontFamily;

    if (targetFamily != null) {
      for (final entry in Category.availableIcons.entries) {
        if (entry.value.codePoint == targetCode &&
            entry.value.fontFamily == targetFamily) {
          iconName = entry.key;
          break;
        }
      }
    }

    return Category(
      id: pc.id,
      nameAr: pc.labelAr,
      nameEn: pc.labelEn,
      iconName: iconName,
      colorHex: '#0D6EFD',
      order: pc.order,
      isActive: true,
      isFeatured: pc.order <= 6,
      aliases: const [],
    );
  }
}
