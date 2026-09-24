// services/library_content_service.dart
// مصدر الحقيقة لمكتبة يا بلدي هو Firestore.
// القراءة العامة مقصورة على المحتوى المنشور والمصرح باستخدامه بقواعد Firestore.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/library_content.dart';

class LibraryContentService {
  final CollectionReference<Map<String, dynamic>> _ref =
      FirebaseFirestore.instance.collection('content_library');

  Future<List<LibraryContent>> getPublished({String? governorateId, String? contentType}) async {
    final snapshot = await _ref
        .where('published', isEqualTo: true)
        .where('usageApproved', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => LibraryContent.fromMap(doc.id, doc.data()))
        .where((item) {
          if (contentType != null && item.contentType != contentType) return false;
          if (item.scope == 'national') return true;
          return governorateId == null || item.governorateId == governorateId;
        })
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Stream<List<LibraryContent>> watchPublished({String? governorateId, String? contentType}) {
    return _ref
        .where('published', isEqualTo: true)
        .where('usageApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LibraryContent.fromMap(doc.id, doc.data()))
            .where((item) {
              if (contentType != null && item.contentType != contentType) return false;
              if (item.scope == 'national') return true;
              return governorateId == null || item.governorateId == governorateId;
            })
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
  }

  Future<List<LibraryContent>> getAllForAdmin() async {
    final snapshot = await _ref.get();
    return snapshot.docs
        .map((doc) => LibraryContent.fromMap(doc.id, doc.data()))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<String> save(LibraryContent item) async {
    final data = item.toMap();
    if (item.published && item.publishedAt == null) {
      data['publishedAt'] = Timestamp.now();
    }
    if (item.id.isEmpty) {
      final doc = await _ref.add(data);
      return doc.id;
    }
    await _ref.doc(item.id).set(data, SetOptions(merge: true));
    return item.id;
  }

  Future<void> delete(String id) => _ref.doc(id).delete();
}
