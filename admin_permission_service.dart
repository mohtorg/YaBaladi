// services/admin_permission_service.dart
// خدمة مركزية لإدارة أدوار وصلاحيات المشرفين.
// لا تمنح هذه الخدمة صلاحية Firebase Admin بنفسها؛ الـ Custom Claim
// يظل هو بوابة الأدمن الأساسية، بينما هذا المستند يحدد نطاق عمل المشرف.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_permission_model.dart';

class AdminPermissionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AdminPermissionProfile>> watchProfiles() {
    return _db.collection('admin_profiles').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AdminPermissionProfile.fromMap(doc.id, doc.data()))
        .toList());
  }

  Future<void> saveProfile(AdminPermissionProfile profile) async {
    await _db.collection('admin_profiles').doc(profile.uid).set({
      ...profile.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteProfile(String uid) => _db.collection('admin_profiles').doc(uid).delete();
}
