// lib/core/router/route_guards.dart
//
// [v1.2 — 2026-10-26] — FIX: Compatible with AuthController v3.1 (AuthStatus)
//   - FIX: replaced auth.isInitialized with auth.status == AuthStatus.loading
//   - KEPT: all logic intact (from v1.1)

import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import 'route_paths.dart';

/// مسارات متاحة بدون تسجيل دخول ولا وضع زائر.
/// (شاشات المصادقة نفسها — الدخول إليها مسموح دائماً).
const Set<String> _authOnlyRoutes = {
  RoutePaths.login,
  RoutePaths.register,
  RoutePaths.forgotPassword,
};

/// Guard مركزي لتوجيه المستخدم حسب حالة المصادقة.
String? authGuard({
  required AuthController auth,
  required GoRouterState state,
}) {
  // ═══════════════════════════════════════════════════════════
  // قاعدة 0: لا redirect قبل تهيئة Auth (تجنب وميض شاشة الدخول)
  // ═══════════════════════════════════════════════════════════
  // ✅ التعديل: استخدام status == loading بدلاً من isInitialized
  if (auth.status == AuthStatus.loading) {
    return null;
  }

  // نستخدم `uri.path` بدلاً من `matchedLocation`
  final location = state.uri.path;

  // ─── حالة المستخدم ───
  final isLoggedIn = auth.isLoggedIn;
  final isGuest = auth.isGuest;

  // ─── هل يمكنه التصفح العام؟ ───
  final hasBrowsingAccess = isLoggedIn || isGuest;

  // ─── هل على شاشة Auth؟ ───
  final isAuthRoute = _authOnlyRoutes.contains(location);

  // ═══════════════════════════════════════════════════════════
  // قاعدة 1: مسجّل حقيقي على شاشة Auth → /home
  // ═══════════════════════════════════════════════════════════
  if (isLoggedIn && isAuthRoute) {
    return RoutePaths.home;
  }

  // ═══════════════════════════════════════════════════════════
  // قاعدة 2: زائر على شاشة Auth → مسموح
  // ═══════════════════════════════════════════════════════════
  if (isGuest && isAuthRoute) {
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // قاعدة 3: غير مسجل ومش زائر → /login?from=...
  // ═══════════════════════════════════════════════════════════
  if (!hasBrowsingAccess && !isAuthRoute) {
    final encodedFrom = Uri.encodeComponent(location);
    return '${RoutePaths.login}?from=$encodedFrom';
  }

  // ═══════════════════════════════════════════════════════════
  // قاعدة 4: مسموح
  // ═══════════════════════════════════════════════════════════
  return null;
}
