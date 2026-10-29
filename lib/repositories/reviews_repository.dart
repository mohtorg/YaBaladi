// repositories/reviews_repository.dart
//
// [v1.3 — 2026-10-18] — Wave 4.1/4.2/4.3 preparation
//   - NEW: update(Review) — يحدّث rating/comment/imageUrls فقط
//          (لا يمس createdAt, isVerified, visitId, verifiedAt)
//   - NEW: watchByUser — لشاشة "تقييماتي" (Wave 4.3)
//   - NEW: getAverageRating — لعرض متوسط التقييم في Place Details (Wave 4.2)
//   - FIX: getCountByUser يستخدم on Exception catch (يلتقط Exception فقط)
//   - FIX: create throws على الفشل (بدلاً من إرجاع string فارغ)
//
// [v1.2 — 2026-10-14] — Added getByUser (R: My Reviews)
// [v1.1 — 2026-10-14] — Added getCountByUser
// [v1.0.1 — 2026-10-14] — Removed .orderBy (composite index)
// [v1.0 — 2026-10-14]

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/review.dart';

class ReviewsRepository {
  ReviewsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'reviews';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  // ═══════════════════════════════════════════════════════════════
  // PLACE QUERIES
  // ═══════════════════════════════════════════════════════════════

  /// Stream لمراجعات مكان معين (لايف — تحديثات فورية).
  Stream<List<Review>> watchByPlace(String placeId) =>
      _ref.where('placeId', isEqualTo: placeId).snapshots().map((s) {
        final list = s.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
        _sortNewestFirst(list);
        return list;
      });

  /// قائمة مراجعات مكان معين (one-time fetch).
  Future<List<Review>> getByPlace(String placeId) async {
    final snap = await _ref.where('placeId', isEqualTo: placeId).get();
    final list = snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
    _sortNewestFirst(list);
    return list;
  }

  /// [v1.3] متوسط التقييم لمكان (للعرض في Place Details — Wave 4.2).
  ///
  /// ملاحظة: يحسب client-side. للحصول على أداء أفضل، خزّن
  /// aggregate في وثيقة place عند كل create/update/delete.
  Future<double> getAverageRating(String placeId) async {
    try {
      final snap = await _ref.where('placeId', isEqualTo: placeId).get();
      if (snap.docs.isEmpty) return 0.0;
      final sum = snap.docs.fold<double>(
        0,
        (acc, d) => acc + ((d.data()['rating'] as num?)?.toDouble() ?? 0),
      );
      return sum / snap.docs.length;
    } on Exception catch (e) {
      debugPrint('ReviewsRepository.getAverageRating error: $e');
      return 0.0;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // USER QUERIES
  // ═══════════════════════════════════════════════════════════════

  /// عدد المراجعات لمستخدم معيّن (للـ Stats في Profile).
  Future<int> getCountByUser(String userId) async {
    try {
      final snap = await _ref.where('userId', isEqualTo: userId).count().get();
      return snap.count ?? 0;
    } on Exception catch (e) {
      debugPrint('ReviewsRepository.getCountByUser error: $e');
      return 0;
    }
  }

  /// كل مراجعات مستخدم — للفرز client-side (Wave 4.3).
  Future<List<Review>> getByUser(String userId) async {
    final snap = await _ref.where('userId', isEqualTo: userId).get();
    final list = snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
    _sortNewestFirst(list);
    return list;
  }

  /// [v1.3] Stream لمراجعات مستخدم (لايف — Wave 4.3).
  Stream<List<Review>> watchByUser(String userId) =>
      _ref.where('userId', isEqualTo: userId).snapshots().map((s) {
        final list = s.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
        _sortNewestFirst(list);
        return list;
      });

  // ═══════════════════════════════════════════════════════════════
  // MUTATIONS
  // ═══════════════════════════════════════════════════════════════

  /// ينشئ تقييماً جديداً. يُعيد الـ id الجديد من Firestore.
  /// يرمي استثناء عند الفشل (permission-denied، network، إلخ).
  Future<String> create(Review review) async {
    final doc = await _ref.add(review.toMap());
    return doc.id;
  }

  /// [v1.3] يحدّث تقييماً موجوداً.
  ///
  /// **مهم جداً:** يحدّث **فقط** rating + comment + imageUrls.
  /// لا يمس: createdAt (يبقى كما هو)، isVerified، visitId، verifiedAt
  /// (هذه حقول محمية — تُعيَّن فقط من server-side/QR).
  ///
  /// يرمي استثناء عند الفشل.
  Future<void> update(Review review) async {
    if (review.id.isEmpty) {
      throw ArgumentError('Cannot update review with empty id');
    }
    await _ref.doc(review.id).update({
      'rating': review.rating,
      'comment': review.comment,
      'imageUrls': review.imageUrls,
    });
  }

  /// يحذف تقييماً بالـ id.
  Future<void> delete(String id) => _ref.doc(id).delete();

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  void _sortNewestFirst(List<Review> list) {
    list.sort((a, b) {
      final da = a.createdAt ?? DateTime(2000);
      final db = b.createdAt ?? DateTime(2000);
      return db.compareTo(da);
    });
  }
}
