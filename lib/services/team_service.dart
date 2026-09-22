import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/admin_permission_model.dart';
import '../models/team_member_model.dart';

class TeamService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<TeamMember>> watchMembers() {
    return _db.collection('admin_profiles').snapshots().map((snapshot) {
      final members = snapshot.docs
          .map((doc) => TeamMember.fromProfile(
                AdminPermissionProfile.fromMap(doc.id, doc.data()),
              ))
          .toList();
      members.sort((a, b) => a.displayName.toLowerCase().compareTo(
            b.displayName.toLowerCase(),
          ));
      return members;
    });
  }

  Future<int> countMembers() async {
    final result = await _db.collection('admin_profiles').count().get();
    return result.count ?? 0;
  }

  Future<int> countActiveMembers() async {
    final result = await _db
        .collection('admin_profiles')
        .where('active', isEqualTo: true)
        .count()
        .get();
    return result.count ?? 0;
  }
}
