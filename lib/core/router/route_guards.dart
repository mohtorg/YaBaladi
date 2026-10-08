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
/// - **غير مسجل** ومش زائر → Login
/// - **مسجل حقيقي** على شاشة Auth → Home
/// - **زائر** يقدر يدخل شاشات Auth (عشان يسجّل)
/// - غير كده → مسموح
String? authGuard({
  required AuthController auth,
  required GoRouterState state,
}) {
  final location = state.matchedLocation;

  // ─── هل المستخدم مسجّل دخول حقيقي؟ ───
  final isLoggedIn = auth.isLoggedIn;

  // ─── هل المستخدم زائر؟ ───
  final isGuest = auth.isGuest;

  // ─── هل عنده access للتنقل العام؟ ───
  // (مسجّل أو زائر → يقدر يتصفح التطبيق)
  final hasBrowsingAccess = isLoggedIn || isGuest;

  // ─── هل على شاشة Auth؟ ───
  final isAuthRoute = _authOnlyRoutes.contains(location);

  // ═══════════════════════════════════════════════════════════
  // القاعدة 1: مسجّل حقيقي على شاشة Auth → Home
  // ═══════════════════════════════════════════════════════════
  // (لو مسجّل، مش محتاج يشوف Login/Register تاني)
  if (isLoggedIn && isAuthRoute) {
    return RoutePaths.home;
  }

  // ═══════════════════════════════════════════════════════════
  // القاعدة 2: زائر على شاشة Auth → مسموح
  // ═══════════════════════════════════════════════════════════
  // (الزائر عايز يسجّل → نسمح له)
  if (isGuest && isAuthRoute) {
    return null; // مفيش redirect
  }

  // ═══════════════════════════════════════════════════════════
  // القاعدة 3: غير مسجل ومش زائر → Login
  // ═══════════════════════════════════════════════════════════
  if (!hasBrowsingAccess && !isAuthRoute) {
    return '${RoutePaths.login}?from=$location';
  }

  // ═══════════════════════════════════════════════════════════
  // غير كده → مسموح
  // ═══════════════════════════════════════════════════════════
  return null;
}