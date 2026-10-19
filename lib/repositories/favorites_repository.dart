// repositories/favorites_repository.dart
//
// [v1.1 — 2026-10-18] — Resilience + Error Handling
//   - FIX: isFavorite uses Source.server (cold-start accuracy)
//   - FIX: try/catch on all Firestore ops (FirebaseException + TimeoutException)
//   - FIX: add uses SetOptions(merge: true) (safety — لا يمسح حقول)
//   - NEW: toggle guard — يمنع double-tap race condition
//   - NEW: debugPrint for all errors
//   - NOTE: watchByUser stream يعتمد على createdAt — يجب أن يكون موجوداً
//
// [v1.0 — الأصل]
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/favorite.dart';

/// Repository للمفضلة — يستخدم Subcollection:
/// `users/{uid}/favorites/{placeId}`
///
/// مطابق لـ Master Plan v1.0:
///   users/{uid}/favorites/{pid}   ← المفضلة
class FavoritesRepository {
  FavoritesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String usersCollection = 'users';
  static const String favoritesCollection = 'favorites';

  /// timeout لكل عملية قراءة (cold start في FlutLab).
  static const Duration _timeout = Duration(seconds: 15);

  /// حماية من double-tap — يمنع race condition في `toggle`.
  final Set<String> _inFlight = <String>{};

  /// مرجع Subcollection: users/{userId}/favorites
  CollectionReference<Map<String, dynamic>> _favoritesRef(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .collection(favoritesCollection);
  }

  // ═══════════════════════════════════════════════════════════════
  // WATCH
  // ═══════════════════════════════════════════════════════════════

  /// Stream لكل مفضلات المستخدم (مرتّبة بالأحدث).
  ///
  /// ⚠️ لا يستخدم `Source.server` — streams تُدير التحديث تلقائياً.
  Stream<List<Favorite>> watchByUser(String userId) {
    return _favoritesRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => Favorite.fromMap(userId, d.id, d.data()))
              .toList(),
        );
  }

  // ═══════════════════════════════════════════════════════════════
  // QUERIES
  // ═══════════════════════════════════════════════════════════════

  /// هل المكان مفضّل؟
  ///
  /// ✅ يستخدم `Source.server` لضمان دقة الحالة على FlutLab Web
  /// (cold start: cache فارغ → يعطي false خاطئ بدون هذا).
  Future<bool> isFavorite(String userId, String placeId) async {
    try {
      final doc = await _favoritesRef(userId)
          .doc(placeId)
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);
      return doc.exists;
    } on TimeoutException {
      debugPrint(
        '⏱️ FavoritesRepository.isFavorite timeout — '
        'user=$userId place=$placeId',
      );
      return false;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ FavoritesRepository.isFavorite error — '
        'user=$userId place=$placeId — $e',
      );
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // MUTATIONS
  // ═══════════════════════════════════════════════════════════════

  /// إضافة للمفضلة.
  ///
  /// ✅ يستخدم `SetOptions(merge: true)` — آمن لو أُعيد الاستدعاء
  /// (لا يمسح حقول موجودة إن وُجدت).
  ///
  /// يرمي `FirebaseException` على فشل (permission-denied، network).
  Future<void> add(String userId, String placeId) async {
    await _favoritesRef(userId).doc(placeId).set(
      {
        'placeId': placeId,
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// إزالة من المفضلة.
  ///
  /// يرمي `FirebaseException` على فشل.
  Future<void> remove(String userId, String placeId) async {
    await _favoritesRef(userId).doc(placeId).delete();
  }

  // ═══════════════════════════════════════════════════════════════
  // TOGGLE — guard من double-tap
  // ═══════════════════════════════════════════════════════════════

  /// Toggle — يعيد الحالة الجديدة.
  ///
  /// ✅ يمنع race condition: إذا كانت العملية جارية لنفس المكان،
  ///    يعيد الحالة الحالية فوراً (بدون تنفيذ toggle ثانٍ).
  Future<bool> toggle(String userId, String placeId) async {
    // حماية من double-tap
    if (_inFlight.contains(placeId)) {
      debugPrint(
        '⚠️ FavoritesRepository.toggle — already in flight for $placeId',
      );
      // ارجع الحالة الحالية بدون تعديل
      return isFavorite(userId, placeId);
    }

    _inFlight.add(placeId);
    try {
      final current = await isFavorite(userId, placeId);
      if (current) {
        await remove(userId, placeId);
        return false;
      }
      await add(userId, placeId);
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
        '❌ FavoritesRepository.toggle error — '
        'user=$userId place=$placeId — $e',
      );
      rethrow; // يُعيد للـ controller للتعامل معه
    } finally {
      _inFlight.remove(placeId);
    }
  }
}
