// lib/core/auth/permissions.dart
//
// [v1.1 — 2026-10-25] — FIX: Non-exhaustive switch in defaultPermissionsFor
//   - ADDED: default case returns empty set to prevent compilation error
//     if UserRole enum contains additional values in role.dart.
//   - KEPT: all permissions, labels, and logic identical.

import 'role.dart';

/// مفاتيح الصلاحيات — من Master Plan § 7.2.
enum Permission {
  // ─── Users ───
  usersRead,
  usersWrite,

  // ─── Places ───
  placesRead,
  placesWrite,

  // ─── Merchants ───
  merchantsRead,
  merchantsWrite,

  // ─── Reports ───
  reportsRead,
  reportsExport,
  reportsPrint,

  // ─── Analytics ───
  analyticsRead,
  analyticsExport,

  // ─── Audit ───
  auditRead,

  // ─── Team ───
  teamRead,
  teamWrite,

  // ─── Moderators ───
  moderatorsRead,
  moderatorsWrite,

  // ─── Governorates ───
  governoratesRead,
  governoratesWrite,

  // ─── Content ───
  contentRead,
  contentWrite,

  // ─── Product features ───
  offersWrite,
  rewardsWrite,
  subscriptionsWrite,
  notificationsWrite,
  complaintsWrite,
  supportRead,
  supportWrite,
  featuredWrite,
}

extension PermissionX on Permission {
  /// كود نصي — للتسجيل أو Firestore.
  String get code => switch (this) {
        Permission.usersRead => 'users.read',
        Permission.usersWrite => 'users.write',
        Permission.placesRead => 'places.read',
        Permission.placesWrite => 'places.write',
        Permission.merchantsRead => 'merchants.read',
        Permission.merchantsWrite => 'merchants.write',
        Permission.reportsRead => 'reports.read',
        Permission.reportsExport => 'reports.export',
        Permission.reportsPrint => 'reports.print',
        Permission.analyticsRead => 'analytics.read',
        Permission.analyticsExport => 'analytics.export',
        Permission.auditRead => 'audit.read',
        Permission.teamRead => 'team.read',
        Permission.teamWrite => 'team.write',
        Permission.moderatorsRead => 'moderators.read',
        Permission.moderatorsWrite => 'moderators.write',
        Permission.governoratesRead => 'governorates.read',
        Permission.governoratesWrite => 'governorates.write',
        Permission.contentRead => 'content.read',
        Permission.contentWrite => 'content.write',
        Permission.offersWrite => 'offers.write',
        Permission.rewardsWrite => 'rewards.write',
        Permission.subscriptionsWrite => 'subscriptions.write',
        Permission.notificationsWrite => 'notifications.write',
        Permission.complaintsWrite => 'complaints.write',
        Permission.supportRead => 'support.read',
        Permission.supportWrite => 'support.write',
        Permission.featuredWrite => 'featured.write',
      };

  /// اسم عربي مختصر — للعرض في جداول الصلاحيات.
  String get labelAr => switch (this) {
        Permission.usersRead => 'قراءة المستخدمين',
        Permission.usersWrite => 'كتابة المستخدمين',
        Permission.placesRead => 'قراءة الأماكن',
        Permission.placesWrite => 'كتابة الأماكن',
        Permission.merchantsRead => 'قراءة التجار',
        Permission.merchantsWrite => 'كتابة التجار',
        Permission.reportsRead => 'قراءة التقارير',
        Permission.reportsExport => 'تصدير التقارير',
        Permission.reportsPrint => 'طباعة التقارير',
        Permission.analyticsRead => 'قراءة التحليلات',
        Permission.analyticsExport => 'تصدير التحليلات',
        Permission.auditRead => 'قراءة السجل',
        Permission.teamRead => 'قراءة الفريق',
        Permission.teamWrite => 'كتابة الفريق',
        Permission.moderatorsRead => 'قراءة المشرفين',
        Permission.moderatorsWrite => 'كتابة المشرفين',
        Permission.governoratesRead => 'قراءة المحافظات',
        Permission.governoratesWrite => 'كتابة المحافظات',
        Permission.contentRead => 'قراءة المحتوى',
        Permission.contentWrite => 'كتابة المحتوى',
        Permission.offersWrite => 'كتابة العروض',
        Permission.rewardsWrite => 'كتابة المكافآت',
        Permission.subscriptionsWrite => 'كتابة الاشتراكات',
        Permission.notificationsWrite => 'كتابة الإشعارات',
        Permission.complaintsWrite => 'كتابة الشكاوى',
        Permission.supportRead => 'قراءة الدعم',
        Permission.supportWrite => 'كتابة الدعم',
        Permission.featuredWrite => 'كتابة المميزة',
      };
}

/// المصفوفة الرسمية — من Master Plan § 7.1.
///
/// تُعيد مجموعة الصلاحيات الافتراضية لكل دور.
Set<Permission> defaultPermissionsFor(UserRole role) {
  switch (role) {
    case UserRole.visitor:
      // تصفح عام فقط.
      return {
        Permission.placesRead,
        Permission.contentRead,
        Permission.governoratesRead,
      };

    case UserRole.member:
      return {
        Permission.placesRead,
        Permission.contentRead,
        Permission.governoratesRead,
        Permission.merchantsRead,
      };

    case UserRole.merchant:
      return {
        Permission.placesRead,
        Permission.placesWrite,
        Permission.contentRead,
        Permission.governoratesRead,
        Permission.merchantsRead,
        Permission.merchantsWrite,
        Permission.offersWrite,
        Permission.featuredWrite,
      };

    case UserRole.team:
      return {
        Permission.placesRead,
        Permission.contentRead,
        Permission.governoratesRead,
        Permission.merchantsRead,
        Permission.usersRead,
      };

    case UserRole.moderator:
      return {
        Permission.placesRead,
        Permission.placesWrite,
        Permission.contentRead,
        Permission.contentWrite,
        Permission.governoratesRead,
        Permission.merchantsRead,
        Permission.usersRead,
        Permission.reportsRead,
        Permission.auditRead,
        Permission.complaintsWrite,
        Permission.supportRead,
        Permission.supportWrite,
      };

    case UserRole.manager:
      return {
        Permission.placesRead,
        Permission.placesWrite,
        Permission.contentRead,
        Permission.contentWrite,
        Permission.governoratesRead,
        Permission.governoratesWrite,
        Permission.merchantsRead,
        Permission.merchantsWrite,
        Permission.usersRead,
        Permission.usersWrite,
        Permission.reportsRead,
        Permission.reportsExport,
        Permission.analyticsRead,
        Permission.auditRead,
        Permission.teamRead,
        Permission.teamWrite,
        Permission.moderatorsRead,
        Permission.moderatorsWrite,
        Permission.complaintsWrite,
        Permission.supportRead,
        Permission.supportWrite,
      };

    case UserRole.admin:
      // كل الصلاحيات.
      return Permission.values.toSet();

    // [FIX] تمت إضافة هذه الحالة لمنع خطأ التجميع (Non-exhaustive switch)
    // في حال كان الـ enum UserRole يحتوي على أدوار إضافية.
    default:
      return {};
  }
}

/// فحص سريع: هل [role] يملك [permission]؟
bool roleHasPermission(UserRole role, Permission permission) {
  return defaultPermissionsFor(role).contains(permission);
}
