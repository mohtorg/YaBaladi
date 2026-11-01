// lib/core/router/route_paths.dart
//
// [v1.9 — 2026-10-20] — Zero Internal Maps: Removed categoryMap & placeMap.
//   - REMOVED: categoryMap, categoryMapPath, placeMap, placeMapPath.
//
// [v1.8 — 2026-10-18] — Wave 5.4: Trip Detailed Route
//   - NEW: tripDetailed = '/trips/detailed/:id' (pattern)
//   - NEW: tripDetailedPath(id) helper
//   - NOTE: يجب تسجيله في app_router قبل /trips/:id

/// ثوابت مسارات التطبيق
///
/// **قاعدة ذهبية:**
///   - `*Pattern` (بـ `:param`) → تُستخدم **فقط** في `app_router.dart`
///   - `*Path(params)` (بـ `$param`) → تُستخدم في `context.go()` / `context.push()`
///
/// **قاعدة ترتيب:**
///   - كل **static** path يجب أن يُسجَّل **قبل** dynamic path في `app_router.dart`
///   - مثال: `/trips/planner` (static) قبل `/trips/:id` (dynamic)
///   - مثال: `/trips/detailed/:id` قبل `/trips/:id` (dynamic بادئة)
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

  // ═══════════════════════════════════════════════════════════════
  // PLACE
  // ═══════════════════════════════════════════════════════════════
  static const String place = '/home/place';

  static String placePath(String id) {
    assert(id.isNotEmpty, 'placePath: id must not be empty');
    return '/home/place/$id';
  }

  // ═══════════════════════════════════════════════════════════════
  // TRIPS (G6.7 + Wave 1c + Wave 5.4)
  // ═══════════════════════════════════════════════════════════════

  /// Root trips route — يعرض قائمة الرحلات (MyTripsScreen).
  static const String trips = '/trips';

  /// Static — يجب أن يُسجَّل **قبل** `tripDetails` في app_router.
  static const String tripPlanner = '/trips/planner';

  /// Helper — يبني `/trips/planner` مع query params اختيارية.
  static String tripPlannerPath({int? initialStep}) {
    if (initialStep == null) return tripPlanner;
    return '$tripPlanner?step=$initialStep';
  }

  /// [v1.6] Static — شاشة اختيار الأماكن يدوياً (Wave 1c).
  static const String tripPlacePicker = '/trips/planner/picker';

  // ─────────────────────────────────────────────────────────────
  // [v1.8] Wave 5.4 — Detailed Trip View
  // ─────────────────────────────────────────────────────────────

  /// **Route pattern** (dynamic بـ prefix) — الشاشة التفصيلية.
  static const String tripDetailed = '/trips/detailed/:id';

  static String tripDetailedPath(String id) {
    assert(id.isNotEmpty, 'tripDetailedPath: id must not be empty');
    return '/trips/detailed/$id';
  }

  // ─────────────────────────────────────────────────────────────
  // Legacy — Trip Details (القديم)
  // ─────────────────────────────────────────────────────────────

  /// **Route pattern** (dynamic) — استخدم `tripDetailsPath(id)` للـ navigation.
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
