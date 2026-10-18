// lib/core/router/route_paths.dart
//
// [v1.7 — 2026-10-17] — Polish + safety
//   - NEW: assert(id.isNotEmpty) في helpers (يمنع URLs مشوهة)
//   - NEW: tripPlannerPath() helper (للمستقبل — query params)
//   - DOC: توضيح أن tripDetails/categoryMap/placeMap هي "patterns"
//
// [v1.6 — 2026-10-17] — Wave 1c: TripPlacePicker route
// [v1.5 — 2026-10-15] — G6.7: Trip planner + details paths
// [v1.4 — 2026-10-15] — Routes + Bottom Nav (4 tabs)

/// ثوابت مسارات التطبيق
///
/// **قاعدة ذهبية:**
///   - `*Pattern` (بـ `:param`) → تُستخدم **فقط** في `app_router.dart`
///   - `*Path(params)` (بـ `$param`) → تُستخدم في `context.go()` / `context.push()`
///
/// **قاعدة ترتيب:**
///   - كل **static** path يجب أن يُسجَّل **قبل** dynamic path في `app_router.dart`
///   - مثال: `/trips/planner` (static) قبل `/trips/:id` (dynamic)
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

  static String categoryPath(String id) {
    assert(id.isNotEmpty, 'categoryPath: id must not be empty');
    return '/home/category/$id';
  }

  /// **Route pattern** — استخدم `categoryMapPath(id)` للـ navigation.
  static const String categoryMap = '/home/category/:id/map';

  static String categoryMapPath(String id) {
    assert(id.isNotEmpty, 'categoryMapPath: id must not be empty');
    return '/home/category/$id/map';
  }

  // ═══════════════════════════════════════════════════════════════
  // PLACE
  // ═══════════════════════════════════════════════════════════════
  static const String place = '/home/place';

  static String placePath(String id) {
    assert(id.isNotEmpty, 'placePath: id must not be empty');
    return '/home/place/$id';
  }

  /// **Route pattern** — استخدم `placeMapPath(id)` للـ navigation.
  static const String placeMap = '/home/place/:id/map';

  static String placeMapPath(String id) {
    assert(id.isNotEmpty, 'placeMapPath: id must not be empty');
    return '/home/place/$id/map';
  }

  // ═══════════════════════════════════════════════════════════════
  // TRIPS (G6.7 + Wave 1c)
  // ═══════════════════════════════════════════════════════════════
  static const String trips = '/trips';

  /// Static — يجب أن يُسجَّل **قبل** `tripDetails` في app_router.
  static const String tripPlanner = '/trips/planner';

  /// Helper — يبني `/trips/planner` مع query params اختيارية.
  /// مفيد للمستقبل (مثلاً: resume من deep link على step معين).
  static String tripPlannerPath({int? initialStep}) {
    if (initialStep == null) return tripPlanner;
    return '$tripPlanner?step=$initialStep';
  }

  /// [v1.6] Static — شاشة اختيار الأماكن يدوياً (Wave 1c).
  static const String tripPlacePicker = '/trips/planner/picker';

  /// **Route pattern** (dynamic) — استخدم `tripDetailsPath(id)` للـ navigation.
  /// ⚠️ لا تستخدمها في `context.go()` مباشرة.
  static const String tripDetails = '/trips/:id';

  static String tripDetailsPath(String id) {
    assert(id.isNotEmpty, 'tripDetailsPath: id must not be empty');
    return '/trips/$id';
  }

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
