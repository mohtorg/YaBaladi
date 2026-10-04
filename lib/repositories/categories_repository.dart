// repositories/categories_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category.dart';

class CategoriesRepository {
  CategoriesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String collection = 'categories';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(collection);

  Stream<List<Category>> watchActive() => _ref
      .where('isActive', isEqualTo: true)
      .orderBy('order')
      .snapshots()
      .map((s) =>
          s.docs.map((d) => Category.fromMap(d.id, d.data())).toList());

  Future<List<Category>> getAllActive() async {
    final snap = await _ref
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();
    return snap.docs.map((d) => Category.fromMap(d.id, d.data())).toList();
  }

  Future<Category?> getById(String id) async {
    final doc = await _ref.doc(id).get();
    return doc.exists ? Category.fromMap(doc.id, doc.data()!) : null;
  }

  Future<String> create(Category category) async {
    final doc = await _ref.add(category.toMap());
    return doc.id;
  }

  Future<void> update(Category category) =>
      _ref.doc(category.id).update(category.toMap());

  Future<void> delete(String id) => _ref.doc(id).delete();

  /// يزود/ينقص placeCount لتصنيف معيّن
  Future<void> incrementPlaceCount(String id, int delta) =>
      _ref.doc(id).update({'placeCount': FieldValue.increment(delta)});
}