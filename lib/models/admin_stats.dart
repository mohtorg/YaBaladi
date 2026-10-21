// lib/features/admin/models/admin_stats.dart
//
// [v1.0 — 2026-10-21] — Admin dashboard statistics model

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

  bool get hasData => totalPlaces > 0 || totalUsers > 0 || totalReviews > 0;
}
