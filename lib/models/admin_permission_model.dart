// models/admin_permission_model.dart
// نموذج دور وصلاحيات مشرف لوحة الإدارة.
// الحماية الحقيقية تبقى في Firebase Security Rules/Custom Claims.
class AdminPermissionProfile {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final List<String> permissions;
  final bool active;

  final bool scopeAll;
  final List<String> governorateIds;
  final List<String> cityIds;
  final List<String> categoryIds;
  final List<String> groupIds;

  const AdminPermissionProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.permissions,
    this.active = true,
    this.scopeAll = false,
    this.governorateIds = const [],
    this.cityIds = const [],
    this.categoryIds = const [],
    this.groupIds = const [],
  });

  bool can(String permission) =>
      permissions.contains('*') || permissions.contains(permission);

  factory AdminPermissionProfile.fromMap(
    String uid,
    Map<String, dynamic> map,
  ) {
    final rawScope = map['scope'];
    final scope = rawScope is Map
        ? Map<String, dynamic>.from(rawScope)
        : const <String, dynamic>{};

    return AdminPermissionProfile(
      uid: uid,
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'custom',
      permissions: List<String>.from(map['permissions'] ?? const []),
      active: map['active'] ?? true,
      scopeAll: scope['all'] == true,
      governorateIds:
          List<String>.from(scope['governorateIds'] ?? const []),
      cityIds: List<String>.from(scope['cityIds'] ?? const []),
      categoryIds:
          List<String>.from(scope['categoryIds'] ?? const []),
      groupIds: List<String>.from(scope['groupIds'] ?? const []),
    );
  }

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'email': email,
        'role': role,
        'permissions': permissions,
        'active': active,
        'scope': {
          'all': scopeAll,
          'governorateIds': governorateIds,
          'cityIds': cityIds,
          'categoryIds': categoryIds,
          'groupIds': groupIds,
        },
      };
}
