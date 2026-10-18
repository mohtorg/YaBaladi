// lib/core/router/route_names.dart
//
// [v1.7 — 2026-10-17] — Polish + docs
//   - ADD: file header + usage docs
//   - ADD: section headers (مطابقة route_paths.dart)
//   - DOC: favorites (legacy) vs profileFavorites (current)
//
// [v1.6 — 2026-10-17] — Wave 1c: tripPlacePicker
// [v1.5 — 2026-10-15] — Trip planner + details

/// أسماء التنقل — تُستخدم مع GoRouter:
///
/// **الاستخدام:**
/// ```dart
/// // Simple navigation:
/// context.goNamed(RouteNames.trips);
///
/// // With path parameters:
/// context.pushNamed(
///   RouteNames.tripDetails,
///   pathParameters: {'id': 'abc123'},
/// );
/// ```
///
/// **الفرق عن `RoutePaths`:**
///   - `RouteNames`  → للاستخدام في `name:` داخل `app_router.dart`
///                    + `context.goNamed()` / `pushNamed()`
///   - `RoutePaths`  → للاستخدام في `path:` داخل `app_router.dart`
///                    + `context.go()` / `push()`
///
/// **القواعد:**
///   1. كل اسم **فريد** (Dart يرمي exception عند التكرار في GoRouter).
///   2. camelCase (اتفاقية Dart لـ `static const`).
///   3. يُفضَّل استخدام `Named` في navigation — أقل عرضة للأخطاء.
class RouteNames {
  RouteNames._();

  // ═══════════════════════════════════════════════════════════════
  // MAIN NAVIGATION (Bottom Tabs)
  // ═══════════════════════════════════════════════════════════════
  static const String home = 'home';
  static const String trips = 'trips';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String search = 'search';

  // ═══════════════════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════════════════
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';

  // ═══════════════════════════════════════════════════════════════
  // CATEGORIES & PLACES
  // ═══════════════════════════════════════════════════════════════
  static const String category = 'category';
  static const String place = 'place';

  // ─── الخرائط ───
  static const String placeMap = 'placeMap';
  static const String categoryMap = 'categoryMap';

  // ═══════════════════════════════════════════════════════════════
  // PROFILE SUB-ROUTES
  // ═══════════════════════════════════════════════════════════════
  static const String myReviews = 'myReviews';

  /// ✅ **الحديث** — `/profile/favorites` (داخل BottomNav).
  /// استخدم هذا للوصول للمفضلة من شاشة الحساب.
  static const String profileFavorites = 'profileFavorites';

  // ═══════════════════════════════════════════════════════════════
  // TRIPS (G6.7 — Wave 1c)
  // ═══════════════════════════════════════════════════════════════
  static const String tripPlanner = 'tripPlanner';
  static const String tripPlacePicker = 'tripPlacePicker';
  static const String tripDetails = 'tripDetails';

  // ═══════════════════════════════════════════════════════════════
  // FAVORITES (legacy — backward compat)
  // ═══════════════════════════════════════════════════════════════
  /// 🔴 **Legacy** — `/favorites` (خارج BottomNav).
  ///
  /// ⚠️ **لا تستخدم هذا للتنقل الجديد** — يقفز خارج `MainShell`
  /// (لا Bottom Navigation Bar أسفل الشاشة).
  ///
  /// **البديل الحديث:** استخدم `profileFavorites` أو `RoutePaths.profileFavorites`.
  ///
  /// هذا المسار محفوظ للتوافق مع:
  ///   - روابط قديمة (deep links)
  ///   - إشعارات سابقة
  ///   - أي كود لم يُحدَّث بعد
  static const String favorites = 'favorites';
}
