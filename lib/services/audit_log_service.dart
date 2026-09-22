import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditLogService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> record({
    required String action,
    required String targetType,
    required String targetId,
    Map<String, dynamic> details = const {},
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('audit_logs').add({
      'actorUid': uid,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watch({
    int limit = 100,
  }) {
    return _db
        .collection('audit_logs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyActivity({
    int limit = 100,
  }) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('audit_logs')
        .where('actorUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }
}
