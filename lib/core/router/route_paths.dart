/// مسارات التنقل في التطبيق
class RoutePaths {
  RoutePaths._();

  static const String home = '/';
  static const String profile = '/profile';
  static const String favorites = '/favorites';
  static const String settings = '/settings';
  static const String search = '/search';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // [v1.2 — 2026-10-14] مسارات فرعية تحت profile (drill-down)
  static const String myReviews = '/profile/my-reviews';
  static const String profileFavorites = '/profile/favorites';

  // ─── تصنيف / أماكن ───
  static const String category = '/category/:id';
  static String categoryPath(String id) => '/category/$id';

  static const String place = '/place/:id';
  static String placePath(String id) => '/place/$id';

  // ─── الخرائط ───
  static const String placeMap = '/place/:id/map';
  static String placeMapPath(String id) => '/place/$id/map';

  static const String categoryMap = '/category/:id/map';
  static String categoryMapPath(String id) => '/category/$id/map';
}
