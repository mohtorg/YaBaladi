import 'package:flutter_test/flutter_test.dart';
import 'package:ya_baladi/models/admin_permission_model.dart';

void main() {
  test('admin profile scope round-trips through Firestore map shape', () {
    const profile = AdminPermissionProfile(
      uid: 'u1',
      displayName: 'Moderator',
      email: 'm@example.com',
      role: 'custom',
      permissions: ['places.write'],
      scopeAll: false,
      governorateIds: ['port_said'],
      cityIds: ['port_said'],
      categoryIds: ['restaurant'],
      groupIds: ['group_1'],
    );

    final restored = AdminPermissionProfile.fromMap(profile.uid, profile.toMap());

    expect(restored.scopeAll, isFalse);
    expect(restored.governorateIds, ['port_said']);
    expect(restored.cityIds, ['port_said']);
    expect(restored.categoryIds, ['restaurant']);
    expect(restored.groupIds, ['group_1']);
  });

  test('legacy moderator profile has no unrestricted scope by default', () {
    final profile = AdminPermissionProfile.fromMap('u2', {
      'displayName': 'Legacy',
      'email': 'legacy@example.com',
      'role': 'custom',
      'permissions': ['places.write'],
      'active': true,
    });

    expect(profile.scopeAll, isFalse);
    expect(profile.governorateIds, isEmpty);
    expect(profile.cityIds, isEmpty);
    expect(profile.categoryIds, isEmpty);
    expect(profile.groupIds, isEmpty);
  });
}
