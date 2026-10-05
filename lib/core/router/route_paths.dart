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

  // ─── تصنيف / أماكن ───
  static const String category = '/category/:id';
  static String categoryPath(String id) => '/category/$id';

  // ─── تفاصيل المكان ───
  static const String place = '/place/:id';
  static String placePath(String id) => '/place/$id';
}