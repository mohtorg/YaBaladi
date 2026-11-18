// lib/features/admin/models/admin_stats.dart
//
// [v1.1 — CLEANED] — Cleaned and formatted.
//   - ADDED: copyWith method for safe future updates.
//   - KEPT: All existing fields and logic intact.

class AdminStats {
  final int totalPlaces;
  final int approvedPlaces;
  final int unapprovedPlaces;
  final int activePlaces;
  final int inactivePlaces;
  final int totalUsers;
  final int totalReviews;

  const AdminStats({
    this.totalPlaces = 0,
    this.approvedPlaces = 0,
    this.unapprovedPlaces = 0,
    this.activePlaces = 0,
    this.inactivePlaces = 0,
    this.totalUsers = 0,
    this.totalReviews = 0,
  });

  /// ✅ للتحقق السريع مما إذا كانت هناك أي بيانات في النظام
  bool get hasData => totalPlaces > 0 || totalUsers > 0 || totalReviews > 0;

  /// ✅ دالة copyWith تُستخدم لتحديث جزء من البيانات
  /// دون الحاجة لإنشاء كائن جديد بالكامل
  AdminStats copyWith({
    int? totalPlaces,
    int? approvedPlaces,
    int? unapprovedPlaces,
    int? activePlaces,
    int? inactivePlaces,
    int? totalUsers,
    int? totalReviews,
  }) {
    return AdminStats(
      totalPlaces: totalPlaces ?? this.totalPlaces,
      approvedPlaces: approvedPlaces ?? this.approvedPlaces,
      unapprovedPlaces: unapprovedPlaces ?? this.unapprovedPlaces,
      activePlaces: activePlaces ?? this.activePlaces,
      inactivePlaces: inactivePlaces ?? this.inactivePlaces,
      totalUsers: totalUsers ?? this.totalUsers,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}
