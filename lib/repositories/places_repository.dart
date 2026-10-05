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
  // ملاحظة مهمة: كل الاستعلامات تحت تستخدم **حقل واحد فقط**
  // في الفلترة على السيرفر، والباقي (isActive / ترتيب) على الـ client.
  //
  // السبب: تفادي composite indexes في Firestore.
  // Firestore بيتطلب index مركّب لأي query فيه أكثر من حقل + orderBy.
  // الفلترة على الـ client أبطأ شوية، لكن مع بيانات قليلة (12 مكان حالياً)
  // الفرق مش محسوس، ومفيش indexes محتاجة إدارة.
  // ═══════════════════════════════════════════════════════════════

  /// يعرض كل الأماكن المعتمدة (isApproved = true).
  ///
  /// الفلترة على `isActive` والترتيب بـ `createdAt` على الـ client.
  Stream<List<Place>> watchApproved({int limit = 50}) {
    return _ref
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((s) {
      final places = s.docs
          .map((d) => Place.fromMap(d.id, d.data()))
          .where((p) => p.isActive)
          .toList()
        ..sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });

      return places.take(limit).toList();
    });
  }

  /// يعرض أماكن تصنيف معيّن.
  ///
  /// الفلترة على `isApproved`/`isActive` والترتيب بـ `averageRating` على الـ client.
  Stream<List<Place>> watchByCategory(String categoryId, {int limit = 50}) {
    return _ref
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((s) {
      final places = s.docs
          .map((d) => Place.fromMap(d.id, d.data()))
          .where((p) => p.isApproved && p.isActive)
          .toList()
        ..sort((a, b) => b.averageRating.compareTo(a.averageRating));

      return places.take(limit).toList();
    });
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
  ///
  /// - [query]: النص (عربي أو إنجليزي)
  /// - [categoryId]: لو ممرَّر → يفلتر على تصنيف معيّن
  ///
  /// يبحث في: nameAr, nameEn, description.
  Future<List<Place>> search({
    required String query,
    String? categoryId,
  }) async {
    // لو categoryId ممرَّر → استخدمه (حقل واحد فقط، مفيش composite index)
    // غير كده → جيب كل الأماكن
    Query<Map<String, dynamic>> q = _ref;
    if (categoryId != null && categoryId.isNotEmpty) {
      q = q.where('categoryId', isEqualTo: categoryId);
    }

    final snap = await q.get();

    // فلترة isApproved/isActive على الـ client
    final all = snap.docs
        .map((d) => Place.fromMap(d.id, d.data()))
        .where((p) => p.isApproved && p.isActive)
        .toList();

    // فلترة النص
    final q2 = query.trim().toLowerCase();

    if (q2.isEmpty) return all;

    return all.where((p) {
      return p.nameAr.toLowerCase().contains(q2) ||
          p.nameEn.toLowerCase().contains(q2) ||
          p.description.toLowerCase().contains(q2);
    }).toList();
  }
}