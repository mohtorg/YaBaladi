// lib/core/router/route_names.dart
//
// [v1.8 — 2026-10-18] — Wave 5.4: tripDetailed
//   - NEW: tripDetailed — '/trips/detailed/:id'
//   - KEPT: tripDetails (legacy) — '/trips/:id'
//
// [v1.7 — 2026-10-17] — Wave 1c: tripPlacePicker
// [v1.6 — 2026-10-15] — G6.7: tripPlanner + tripDetails
// [v1.5 — 2026-10-15] — Routes + Bottom Nav

/// أسماء المسارات — للاستخدام مع `context.goNamed()` / `goNamed()`
///
/// **قاعدة:** كل اسم يبدأ بحرف صغير (camelCase) — مطابقة لـ `GoRoute.name`.
class RouteNames {
  RouteNames._();

  // ═══════════════════════════════════════════════════════════════
  // HOME
  // ═══════════════════════════════════════════════════════════════
  static const String home = 'home';

  // ═══════════════════════════════════════════════════════════════
  // CATEGORY
  // ═══════════════════════════════════════════════════════════════
  static const String category = 'category';
  static const String categoryMap = 'categoryMap';

  // ═══════════════════════════════════════════════════════════════
  // PLACE
  // ═══════════════════════════════════════════════════════════════
  static const String place = 'place';
  static const String placeMap = 'placeMap';

  // ═══════════════════════════════════════════════════════════════
  // TRIPS
  // ═══════════════════════════════════════════════════════════════
  static const String trips = 'trips';
  static const String tripPlanner = 'tripPlanner';
  static const String tripPlacePicker = 'tripPlacePicker';

  /// ✅ [v1.8] Wave 5.4 — الشاشة التفصيلية (Timeline بالساعات)
  static const String tripDetailed = 'tripDetailed';

  /// Legacy — تفاصيل الرحلة القديمة
  static const String tripDetails = 'tripDetails';

  // ═══════════════════════════════════════════════════════════════
  // PROFILE
  // ═══════════════════════════════════════════════════════════════
  static const String profile = 'profile';
  static const String myReviews = 'myReviews';
  static const String profileFavorites = 'profileFavorites';

  // ═══════════════════════════════════════════════════════════════
  // SETTINGS
  // ═══════════════════════════════════════════════════════════════
  static const String settings = 'settings';

  // ═══════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';

  // ═══════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════
  static const String search = 'search';

  // ═══════════════════════════════════════════════════════════════
  // FAVORITES (legacy)
  // ═══════════════════════════════════════════════════════════════
  static const String favorites = 'favorites';
}
