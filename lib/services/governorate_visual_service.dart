// services/governorate_visual_service.dart
//
// خدمة موحدة لصور المحافظات.
// القراءة العامة تعتمد فقط على الصور المنشورة والمصرح باستخدامها.
// الكتابة محصورة بلوحة الإدارة عبر Firestore Rules؛ هذه الخدمة لا تمنح صلاحية.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/governorate_visual_profile.dart';

class GovernorateVisualService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<GovernorateVisualProfile?> getPublished(String governorateId) async {
    final doc = await _db.collection('governorate_visuals').doc(governorateId).get();
    if (!doc.exists || doc.data() == null) return null;

    final profile = GovernorateVisualProfile.fromMap(governorateId, doc.data()!);
    if (!profile.published || !profile.usageApproved || profile.heroImageUrl.trim().isEmpty) {
      return null;
    }
    return profile;
  }

  Stream<GovernorateVisualProfile?> watchPublished(String governorateId) {
    return _db.collection('governorate_visuals').doc(governorateId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      final profile = GovernorateVisualProfile.fromMap(governorateId, doc.data()!);
      if (!profile.published || !profile.usageApproved || profile.heroImageUrl.trim().isEmpty) {
        return null;
      }
      return profile;
    });
  }

  Future<GovernorateVisualProfile?> getForAdmin(String governorateId) async {
    final doc = await _db.collection('governorate_visuals').doc(governorateId).get();
    if (!doc.exists || doc.data() == null) return null;
    return GovernorateVisualProfile.fromMap(governorateId, doc.data()!);
  }

  Future<void> saveForAdmin(GovernorateVisualProfile profile) async {
    await _db.collection('governorate_visuals').doc(profile.governorateId).set(
          profile.toMap(),
          SetOptions(merge: true),
        );
  }
}
