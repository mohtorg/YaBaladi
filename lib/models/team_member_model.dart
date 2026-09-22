import 'admin_permission_model.dart';

class TeamMember {
  final AdminPermissionProfile profile;

  const TeamMember(this.profile);

  String get uid => profile.uid;
  String get displayName => profile.displayName;
  String get email => profile.email;
  String get role => profile.role;
  bool get active => profile.active;
  List<String> get permissions => profile.permissions;

  factory TeamMember.fromProfile(AdminPermissionProfile profile) =>
      TeamMember(profile);
}
