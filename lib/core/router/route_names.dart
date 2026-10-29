// lib/core/router/route_names.dart
//
// [v1.9 — 2026-10-20] — Zero Internal Maps: Removed categoryMap & placeMap.
//   - REMOVED: categoryMap, placeMap.
//
// [v1.8 — 2026-10-18] — Wave 5.4: tripDetailed
//   - NEW: tripDetailed — '/trips/detailed/:id'

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

  // ═══════════════════════════════════════════════════════════════
  // PLACE
  // ═══════════════════════════════════════════════════════════════
  static const String place = 'place';

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
