// lib/core/router/route_paths.dart
//
// [v1.5 — 2026-10-15] — G6.7: Trip planner + details paths
//   - ADDED: tripPlanner = '/trips/planner'  (STATIC)
//   - ADDED: tripDetails = '/trips/:id'      (DYNAMIC)
//   - ADDED: tripDetailsPath(id) helper
//
// [v1.4 — 2026-10-15] — Routes + Bottom Nav (4 tabs)
//   - ADDED: trips, profileFavorites, myReviews
//
// [v1.3 — 2026-10-14] — Favorites drill-down
// [v1.2 — 2026-10-14] — My Reviews route
// [v1.1 — 2026-10-14] — StatefulShellRoute Migration
// [v1.0 — 2026-10-13] — Initial routes

/// ثوابت مسارات التطبيق
///
/// القاعدة الذهبية: أي static path يجب أن يكون **قبل** dynamic path
/// في `app_router.dart` لتجنب التعارض (مثل /trips/planner vs /trips/:id).
class RoutePaths {
  RoutePaths._(); // منع الإنشاء

  // ═══════════════════════════════════════════════════════════════
  // HOME
  // ═══════════════════════════════════════════════════════════════
  static const String home = '/home';

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY
  // ═══════════════════════════════════════════════════════════════
  static const String category = '/home/category';
  static String categoryPath(String id) => '/home/category/$id';

  static const String categoryMap = '/home/category/:id/map';
  static String categoryMapPath(String id) => '/home/category/$id/map';

  // ═══════════════════════════════════════════════════════════════
  // PLACE
  // ═══════════════════════════════════════════════════════════════
  static const String place = '/home/place';
  static String placePath(String id) => '/home/place/$id';

  static const String placeMap = '/home/place/:id/map';
  static String placeMapPath(String id) => '/home/place/$id/map';

  // ═══════════════════════════════════════════════════════════════
  // TRIPS (G6.7)
  // ═══════════════════════════════════════════════════════════════
  static const String trips = '/trips';

  /// [v1.5] Static — يجب أن يُسجَّل **قبل** tripDetails في app_router
  static const String tripPlanner = '/trips/planner';

  /// [v1.5] Dynamic — /trips/{id}
  static const String tripDetails = '/trips/:id';
  static String tripDetailsPath(String id) => '/trips/$id';

  // ═══════════════════════════════════════════════════════════════
  // PROFILE
  // ═══════════════════════════════════════════════════════════════
  static const String profile = '/profile';

  static const String myReviews = '/profile/my-reviews';
  static const String profileFavorites = '/profile/favorites';

  // ═══════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════
  static const String settings = '/settings';

  // ═══════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ═══════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════
  static const String search = '/search';

  // ═══════════════════════════════════════════════════════════════
  // FAVORITES (legacy — backward compat)
  // ═══════════════════════════════════════════════════════════════
  static const String favorites = '/favorites';
}
