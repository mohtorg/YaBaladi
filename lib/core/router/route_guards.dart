// lib/core/router/route_guards.dart
//
// [v1.1 — 2026-10-17] — Critical fixes
//   - FIX: don't redirect during auth initialization (prevents login flash on cold start)
//   - FIX: URL-encode ?from= query param (prevents broken URLs)
//   - IMPROVE: use state.uri.path (safer than matchedLocation)
//   - TODO: use `from` param after successful login (LoginScreen change)
//
// [v1.0 — 2026-10-14] — Initial guard

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
///
/// **القواعد (بالترتيب):**
///   0. **[v1.1]** إذا Auth لم يُهيَّأ بعد → **allow** (يمنع وميض Login)
///   1. مسجّل حقيقي على شاشة Auth → `/home`
///   2. زائر على شاشة Auth → **allow** (يستطيع التسجيل)
///   3. غير مسجل ومش زائر على مسار محمي → `/login?from=...`
///   4. غير ذلك → **allow**
String? authGuard({
  required AuthController auth,
  required GoRouterState state,
}) {
  // ═══════════════════════════════════════════════════════════
  // قاعدة 0: [v1.1 — CRITICAL] لا redirect قبل تهيئة Auth
  // ═══════════════════════════════════════════════════════════
  // بدون هذا: عند cold start (500ms-2s الأولى) نعتبر
  // المستخدم "غير مسجل" حتى لو كان مسجّلاً → وميض Login.
  if (!auth.isInitialized) {
    return null;
  }

  // [v1.1] نستخدم `uri.path` بدلاً من `matchedLocation`
  // (أكثر وضوحاً — لا يشمل query params ولا fragments).
  final location = state.uri.path;

  // ─── حالة المستخدم ───
  final isLoggedIn = auth.isLoggedIn;
  final isGuest = auth.isGuest;

  // ─── هل يمكنه التصفح العام؟ ───
  // (مسجّل أو زائر → yes)
  final hasBrowsingAccess = isLoggedIn || isGuest;

  // ─── هل على شاشة Auth؟ ───
  final isAuthRoute = _authOnlyRoutes.contains(location);

  // ═══════════════════════════════════════════════════════════
  // قاعدة 1: مسجّل حقيقي على شاشة Auth → /home
  // ═══════════════════════════════════════════════════════════
  // (لا يحتاج رؤية Login/Register مرة أخرى)
  if (isLoggedIn && isAuthRoute) {
    return RoutePaths.home;
  }

  // ═══════════════════════════════════════════════════════════
  // قاعدة 2: زائر على شاشة Auth → مسموح
  // ═══════════════════════════════════════════════════════════
  // (يريد التسجيل — نسمح له)
  if (isGuest && isAuthRoute) {
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // قاعدة 3: غير مسجل ومش زائر → /login?from=...
  // ═══════════════════════════════════════════════════════════
  if (!hasBrowsingAccess && !isAuthRoute) {
    // [v1.1] URL-encode لتفادي كسر الـ URL إذا احتوى المسار على
    // `&`, `=`, `?`, أو أحرف خاصة.
    // مثال: /home/place/abc?x=1 → ?from=%2Fhome%2Fplace%2Fabc%3Fx%3D1
    final encodedFrom = Uri.encodeComponent(location);

    // TODO [v1.2]: يستخدم LoginScreen الـ `from` بعد النجاح
    // للعودة للمسار الأصلي (خارج نطاق route_guards).
    return '${RoutePaths.login}?from=$encodedFrom';
  }

  // ═══════════════════════════════════════════════════════════
  // قاعدة 4: مسموح
  // ═══════════════════════════════════════════════════════════
  return null;
}

