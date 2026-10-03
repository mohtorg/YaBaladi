import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import 'route_paths.dart';

/// المسارات العامة (بدون تسجيل دخول)
const Set<String> _publicRoutes = {
  RoutePaths.home,
  RoutePaths.search,
  RoutePaths.settings,
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.forgotPassword,
};

/// Guard رئيسي: يُعيد مسارًا للـ redirect أو null
String? authGuard({
  required AuthController auth,
  required GoRouterState state,
}) {
  final location = state.matchedLocation;

  final isPublic = _publicRoutes.contains(location);
  final isAuthRoute = location == RoutePaths.login ||
      location == RoutePaths.register ||
      location == RoutePaths.forgotPassword;

  // مسجل دخول ويحاول فتح صفحة Auth → Home
  if (auth.isLoggedIn && isAuthRoute) {
    return RoutePaths.home;
  }

  // غير مسجل ويحاول فتح صفحة محمية → Login
  if (!auth.isLoggedIn && !isPublic) {
    return '${RoutePaths.login}?from=$location';
  }

  return null;
}