import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import 'route_paths.dart';

/// مسارات متاحة بدون تسجيل دخول ولا وضع زائر
/// (شاشات المصادقة نفسها).
const Set<String> _authOnlyRoutes = {
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.forgotPassword,
};

/// Guard مركزي:
///
/// - مش مسجل ومش زائر → Login
/// - مسجل أو زائر + على شاشة Auth → Home
/// - غير كده → مسموح
String? authGuard({
  required AuthController auth,
  required GoRouterState state,
}) {
  final location = state.matchedLocation;

  final hasAccess = auth.isLoggedIn || auth.isGuest;
  final isAuthRoute = _authOnlyRoutes.contains(location);

  // لو مسجل/زائر وبيحاول يدخل شاشة Login → Home
  if (hasAccess && isAuthRoute) {
    return RoutePaths.home;
  }

  // لو مش مسجل ومش زائر → Login
  if (!hasAccess && !isAuthRoute) {
    return '${RoutePaths.login}?from=$location';
  }

  return null;
}