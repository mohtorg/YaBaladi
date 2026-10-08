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
  // WATCHERS
  // ═══════════════════════════════════════════════════════════════
  //
  // ملاحظة: الفلترة على isApproved + isActive بتحصل على السيرفر.
  // ده يتطلب composite indexes (موجودة في Firebase Console).
  //
  // Index 1: categoryId + isApproved + isActive + averageRating
  // Index 2: isApproved + isActive + createdAt
  // ═══════════════════════════════════════════════════════════════

  /// يعرض كل الأماكن المعتمدة والنشطة، مرتبة بالأحدث.
  Stream<List<Place>> watchApproved({int limit = 50}) {
    return _ref
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Place.fromMap(d.id, d.data()))
            .toList());
  }

  /// يعرض أماكن تصنيف معيّن، مرتبة بالأعلى تقييمًا.
  Stream<List<Place>> watchByCategory(String categoryId, {int limit = 50}) {
    return _ref
        .where('categoryId', isEqualTo: categoryId)
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('averageRating', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => Place.fromMap(d.id, d.data()))
            .toList());
  }

  // ═══════════════════════════════════════════════════════════════
  // GET BY ID
  // ═══════════════════════════════════════════════════════════════

  Future<Place?> getById(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? Place.fromMap(doc.id, doc.data()!) : null;
  }

  // ═══════════════════════════════════════════════════════════════
  // CRUD
  // ═══════════════════════════════════════════════════════════════

  Future<String> create(Place place) async {
    final doc = await _ref.add(place.toMap());
    return doc.id;
  }

  Future<void> update(Place place) =>
      _ref.doc(place.id).update(place.toMap());

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
  // SEARCH
  // ═══════════════════════════════════════════════════════════════

  /// بحث نصي في الأماكن — يفلتر محليًا (client-side).
  Future<List<Place>> search({
    required String query,
    String? categoryId,
  }) async {
    Query<Map<String, dynamic>> q = _ref
        .where('isApproved', isEqualTo: true)
        .where('isActive', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }

    final snap = await q.get();

    final all = snap.docs
        .map((d) => Place.fromMap(d.id, d.data()))
        .toList();

    final q2 = query.trim().toLowerCase();
    if (q2.isEmpty) return all;

    return all.where((p) {
      return p.nameAr.toLowerCase().contains(q2) ||
          p.nameEn.toLowerCase().contains(q2) ||
          p.description.toLowerCase().contains(q2);
    }).toList();
  }
}