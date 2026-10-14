// repositories/reviews_repository.dart
//
// [v1.2 — 2026-10-14] — Added getByUser (R: My Reviews)
//   - جلب كل مراجعات مستخدم معيّن
//   - الفرز client-side (يتفادى composite index)
//
// [v1.1 — 2026-10-14] — Added getCountByUser
// [v1.0.1 — 2026-10-14] — Removed .orderBy (composite index)
// [v1.0 — 2026-10-14]

import 'package:cloud_firestore/cloud_firestore.dart';

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

  Stream<List<Review>> watchByPlace(String placeId) =>
      _ref.where('placeId', isEqualTo: placeId).snapshots().map((s) {
        final list = s.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
        _sortNewestFirst(list);
        return list;
      });

  Future<List<Review>> getByPlace(String placeId) async {
    final snap = await _ref.where('placeId', isEqualTo: placeId).get();
    final list = snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
    _sortNewestFirst(list);
    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // USER QUERIES  [v1.1 — v1.2]
  // ═══════════════════════════════════════════════════════════════

  /// عدد المراجعات لمستخدم معيّن.
  Future<int> getCountByUser(String userId) async {
    try {
      final query = _ref.where('userId', isEqualTo: userId);
      final snap = await query.count().get();
      return snap.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// [v1.2] كل مراجعات مستخدم — للفرز client-side.
  Future<List<Review>> getByUser(String userId) async {
    final snap = await _ref.where('userId', isEqualTo: userId).get();
    final list = snap.docs.map((d) => Review.fromMap(d.id, d.data())).toList();
    _sortNewestFirst(list);
    return list;
  }

  // ═══════════════════════════════════════════════════════════════
  // MUTATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<String> create(Review review) async {
    final doc = await _ref.add(review.toMap());
    return doc.id;
  }

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
