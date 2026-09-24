// models/admin_permission_model.dart
// نموذج دور وصلاحيات مشرف لوحة الإدارة.
// مهم: هذا النموذج للواجهة والإدارة فقط؛ الحماية الحقيقية يجب أن تبقى في
// Firebase Security Rules/Custom Claims، لذلك لا نعتمد على إخفاء الأزرار وحده.
class AdminPermissionProfile {
  final String uid;
  final String displayName;
  final String email;
  final String role; // manager | content_moderator | users_moderator | subscription_moderator | custom
  final List<String> permissions;
  final bool active;

  const AdminPermissionProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.permissions,
    this.active = true,
  });

  bool can(String permission) => permissions.contains('*') || permissions.contains(permission);

  factory AdminPermissionProfile.fromMap(String uid, Map<String, dynamic> map) {
    return AdminPermissionProfile(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'custom',
      permissions: List<String>.from(map['permissions'] ?? const []),
      active: map['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'role': role,
        'permissions': permissions,
        'active': active,
      };
}
