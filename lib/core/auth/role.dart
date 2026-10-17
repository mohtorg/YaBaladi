// lib/core/auth/role.dart
//
// [v1.1 — 2026-10-16] — Wave 1a AUTH-BUG-1 fix
//   - FIX: roleFromCode يقبل 'user' كمرادف لـ 'member'
//     السبب: signUp() يكتب role='user' في Firestore
//     بينما الـ enum.code = 'member'
//   - النتيجة: توافق كامل بدون تعديل firestore.rules
//
// [v1.0 — 2026-10-14] — G4.1: UserRole enum + extension

/// الأدوار السبعة في YaBaladi — من الأقل صلاحية إلى الأعلى.
enum UserRole {
  visitor,
  member,
  merchant,
  team,
  moderator,
  manager,
  admin,
}

extension UserRoleX on UserRole {
  /// كود نصي — يُخزَّن في Firestore (users/{uid}.role).
  String get code => switch (this) {
        UserRole.visitor => 'visitor',
        UserRole.member => 'member',
        UserRole.merchant => 'merchant',
        UserRole.team => 'team',
        UserRole.moderator => 'moderator',
        UserRole.manager => 'manager',
        UserRole.admin => 'admin',
      };

  /// اسم عربي للعرض.
  String get labelAr => switch (this) {
        UserRole.visitor => 'زائر',
        UserRole.member => 'عضو',
        UserRole.merchant => 'تاجر',
        UserRole.team => 'فريق',
        UserRole.moderator => 'مشرف',
        UserRole.manager => 'مدير',
        UserRole.admin => 'مسؤول',
      };

  /// اسم إنجليزي.
  String get labelEn => switch (this) {
        UserRole.visitor => 'Visitor',
        UserRole.member => 'Member',
        UserRole.merchant => 'Merchant',
        UserRole.team => 'Team',
        UserRole.moderator => 'Moderator',
        UserRole.manager => 'Manager',
        UserRole.admin => 'Admin',
      };

  /// المستوى الهرمي (0 = الأدنى، 6 = الأعلى).
  int get level => switch (this) {
        UserRole.visitor => 0,
        UserRole.member => 1,
        UserRole.merchant => 2,
        UserRole.team => 3,
        UserRole.moderator => 4,
        UserRole.manager => 5,
        UserRole.admin => 6,
      };

  /// هل المستخدم زائر (غير مسجل)؟
  bool get isGuest => this == UserRole.visitor;

  /// هل المستخدم مسجل بأي شكل؟
  bool get isAuthenticated => this != UserRole.visitor;

  /// هل الدور ≥ [other] في السلسلة الهرمية؟
  bool isAtLeast(UserRole other) => level >= other.level;

  /// هل يمكنه إدارة الأماكن (إضافة/تعديل أي مكان)؟
  bool get canManagePlaces =>
      this == UserRole.merchant ||
      this == UserRole.moderator ||
      this == UserRole.manager ||
      this == UserRole.admin;

  /// هل يرى الأدوات الإدارية (Reports / Users / Audit)؟
  bool get hasAdminTools =>
      this == UserRole.moderator ||
      this == UserRole.manager ||
      this == UserRole.admin;

  /// هل هو مسؤول كامل الصلاحيات؟
  bool get isSuperAdmin => this == UserRole.admin;
}

/// يحوّل نصاً قادماً من Firestore إلى [UserRole].
///
/// [v1.1] — يقبل 'user' كمرادف لـ 'member'
///   (لأن signUp() يكتب 'user' في Firestore بينما code = 'member').
///
/// - `null` أو نص غير معروف → [UserRole.member] (افتراضي للمستخدمين المسجلين).
UserRole roleFromCode(String? code) {
  return switch (code) {
    'visitor' => UserRole.visitor,
    'member' || 'user' => UserRole.member, // ← المرادف
    'merchant' => UserRole.merchant,
    'team' => UserRole.team,
    'moderator' => UserRole.moderator,
    'manager' => UserRole.manager,
    'admin' => UserRole.admin,
    _ => UserRole.member,
  };
}
