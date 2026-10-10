// repositories/places_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/place.dart';

class PlacesRepository {
  PlacesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'places';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  // ═══════════════════════════════════════════════════════════════
  // WATCHERS (legacy — stream-based, kept for compatibility)
  // ═══════════════════════════════════════════════════════════════

  /// [legacy] يعرض كل الأماكن المعتمدة والنشطة، مرتبة بالأحدث.
  /// ملاحظة: يستخدم `.snapshots()` — لا يعمل في FlutLab Web.
  /// استخدم `loadAll()` بدلاً منه.
  Stream<List<Place>> watchApproved({int limit = 50}) {
    return _ref
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Place.fromMap(d.id, d.data())).toList());
  }

  /// [legacy] يعرض أماكن تصنيف معيّن، مرتبة بالأعلى تقييمًا.
  Stream<List<Place>> watchByCategory(String categoryId, {int limit = 50}) {
    return _ref
        .where('categoryId', isEqualTo: categoryId)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('averageRating', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => Place.fromMap(d.id, d.data())).toList());
  }

  // ═══════════════════════════════════════════════════════════════
  // LOAD (One-shot — يعمل في كل البيئات)
  // ═══════════════════════════════════════════════════════════════

  /// يحمّل كل الأماكن المعتمدة والنشطة بـ `.get()` واحد.
  ///
  /// - يستخدم `.get()` بدل `.snapshots()` — يعمل في كل البيئات
  ///   (FlutLab Web, Mobile, Desktop)
  /// - لا يحتاج Composite Index
  /// - النتائج تُخزّن في الـ Controller للفلترة client-side
  Future<List<Place>> loadAll({int limit = 500}) async {
    final snap = await _ref
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();
  }

  /// يحمّل أماكن تصنيف معين بـ `.get()` واحد.
  Future<List<Place>> loadByCategory(
    String categoryId, {
    int limit = 500,
  }) async {
    final snap = await _ref
        .where('categoryId', isEqualTo: categoryId)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(limit)
        .get();

    return snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // GET BY ID
  // ═══════════════════════════════════════════════════════════════

  Future<Place?> getById(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? Place.fromMap(doc.id, doc.data()!) : null;
  }

  /// جلب مجموعة أماكن بمعرّفاتها (Favorites / Multi-select).
  /// يعمل chunking (10 عناصر لكل query) بسبب حد `whereIn`.
  Future<List<Place>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final result = <Place>[];
    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
      final snap = await _ref.where(FieldPath.documentId, whereIn: chunk).get();
      result.addAll(
        snap.docs.map((d) => Place.fromMap(d.id, d.data())),
      );
    }
    return result;
  }

  // ═══════════════════════════════════════════════════════════════
  // TRENDING (الأكثر بحثًا / تفاعلًا)
  // ═══════════════════════════════════════════════════════════════

  /// يعرض الأماكن الأكثر تفاعلًا (Top [limit]).
  ///
  /// ملاحظة: يستخدم `.get()` — يعمل في كل البيئات.
  /// الترتيب client-side بدلاً من Firestore orderBy (لتجنب Index).
  Future<List<Place>> getTrending({int limit = 5}) async {
    try {
      // نحمّل الأماكن المعتمدة فقط (بدون orderBy — لتجنب Index)
      final snap = await _ref
          .where('isApproved', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .limit(200)
          .get();

      final places =
          snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();

      // الترتيب client-side: reviewCount DESC
      places.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));

      return places.take(limit).toList();
    } catch (e) {
      return const [];
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<String> create(Place place) async {
    final doc = await _ref.add(place.toMap());
    return doc.id;
  }

  Future<void> update(Place place) => _ref.doc(place.id).update(place.toMap());

  Future<void> delete(String id) => _ref.doc(id).delete();

  Future<void> updateRating({
    required String placeId,
    required double average,
    required int count,
  }) =>
      _ref.doc(placeId).update({
        'averageRating': average,
        'reviewCount': count,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  // ═══════════════════════════════════════════════════════════════
  // SEARCH (legacy — client-side، سيُلغى)
  // ═══════════════════════════════════════════════════════════════

  /// بحث نصي في الأماكن — يفلتر محليًا (client-side).
  /// [legacy] استخدم PlacesController.loadAll() + places getter بدلاً منه.
  Future<List<Place>> search({
    required String query,
    String? categoryId,
    int limit = 100,
  }) async {
    Query<Map<String, dynamic>> q = _ref
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }

    q = q.limit(limit);

    final snap = await q.get();

    final all = snap.docs.map((d) => Place.fromMap(d.id, d.data())).toList();

    final q2 = query.trim().toLowerCase();
    if (q2.isEmpty) return all;

    return all.where((p) {
      return p.nameAr.toLowerCase().contains(q2) ||
          p.nameEn.toLowerCase().contains(q2) ||
          p.description.toLowerCase().contains(q2);
    }).toList();
  }
}
