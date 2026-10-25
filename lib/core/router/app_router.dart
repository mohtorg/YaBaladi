// lib/core/router/app_router.dart
//
// [v1.1 — 2026-10-22] — Redirect fixes
//   - FIX: «نسيت كلمة المرور» كانت تُعاد إلى شاشة الدخول للمستخدم غير المسجّل،
//          لأن مسار forgotPassword لم يُستثنَ من التحويل.
//   - FIX: المستخدم المسجّل لا يبقى في شاشة التسجيل (register) → يُحوَّل للرئيسية.
//   - NEW: دعم المعامل `from`: عند محاولة فتح صفحة محمية يُحوَّل لشاشة الدخول
//          مع `?from=...`، وبعد النجاح يُعاد إلى الصفحة المطلوبة
//          (مسارات داخلية آمنة فقط). يعالج TODO في route_guards.dart.
//   - FIX: مسار picker يقبل أي Map (وليس Map<String, dynamic> حصراً).
//   - CHANGE: debugLogDiagnostics في وضع التطوير فقط.
//   - NEW: زر «الرئيسية» في صفحة 404.
//   - NOTE: createAppRouter يجب أن يُستدعى مرة واحدة فقط (لا داخل build).
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/places/screens/place_details_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reviews/screens/my_reviews_screen.dart';
import '../../features/search/screens/explore_screen.dart';
import '../../features/trip/screens/trip_detailed_screen.dart';
import '../../features/trip/screens/trip_details_screen.dart';
import '../../features/trip/screens/trip_place_picker_screen.dart';
import '../../features/trip/screens/trip_plans_screen.dart';
import '../../features/trip/screens/wizard/wizard_container_screen.dart';
import '../../models/trip_plan.dart';
import '../../screens/home_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/settings_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../core/auth/role.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// يقبل `from` فقط إذا كان مساراً داخلياً آمناً (يمنع التحويل لمواقع خارجية
/// أو العودة لصفحات الدخول أو لوحة الإدارة).
String? _safeFrom(String? from) {
  if (from == null || from.isEmpty) return null;
  if (!from.startsWith('/') || from.startsWith('//')) return null;

  final path = Uri.tryParse(from)?.path ?? '';
  if (path.isEmpty) return null;
  if (path == RoutePaths.login ||
      path == RoutePaths.register ||
      path == RoutePaths.forgotPassword ||
      path.startsWith('/admin')) {
    return null;
  }
  return from;
}

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    // ✅ التصحيح: البدء من شاشة الدخول لتجنب تعارض الـ Shell
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;
      final role = auth.role;
      final location = state.matchedLocation;

      final isLoggingIn = location == RoutePaths.login;
      final isRegistering = location == RoutePaths.register;
      final isForgotPassword = location == RoutePaths.forgotPassword;
      final isAuthPage = isLoggingIn || isRegistering || isForgotPassword;
      final isAdminRoute = location.startsWith('/admin');
      final isStaff = role == UserRole.admin || role == UserRole.moderator;

      if (status == AuthStatus.loading) {
        return null;
      }

      // ─── غير مسجّل (زائر أو لم يدخل بعد) ───
      if (status == AuthStatus.unauthenticated) {
        if (isAdminRoute) return RoutePaths.login;
        if (isAuthPage) return null;

        if (!auth.isGuest) {
          final from = state.uri.toString();
          if (from == RoutePaths.home) return RoutePaths.login;
          return '${RoutePaths.login}?from=${Uri.encodeComponent(from)}';
        }

        return null;
      }

      // ─── مسجّل ───
      if (status == AuthStatus.authenticated) {
        if (isStaff) {
          if (!isAdminRoute) return '/admin';
          return null;
        }

        if (isAdminRoute) return RoutePaths.home;
        if (isLoggingIn || isRegistering) {
          return _safeFrom(state.uri.queryParameters['from']) ??
              RoutePaths.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/admin',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.register,
        name: RouteNames.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'category/:id',
                    name: RouteNames.category,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ExploreScreen(categoryId: id);
                    },
                  ),
                  GoRoute(
                    path: 'place/:id',
                    name: RouteNames.place,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return PlaceDetailsScreen(placeId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.trips,
                name: RouteNames.trips,
                builder: (context, state) => const TripPlansScreen(),
                routes: [
                  GoRoute(
                    path: 'planner',
                    name: RouteNames.tripPlanner,
                    builder: (context, state) => const WizardContainerScreen(),
                    routes: [
                      GoRoute(
                        path: 'picker',
                        name: RouteNames.tripPlacePicker,
                        redirect: (context, state) {
                          // extra يُفقد عند تحديث الصفحة على الويب → ارجع للمعالج
                          if (state.extra is! Map) {
                            return RoutePaths.tripPlanner;
                          }
                          return null;
                        },
                        builder: (context, state) {
                          final extra =
                              Map<String, dynamic>.from(state.extra! as Map);
                          final initialStopsRaw = extra['initialStops'];
                          final initialStops = initialStopsRaw is List
                              ? initialStopsRaw.whereType<TripStop>().toList()
                              : <TripStop>[];
                          final govIdRaw = extra['governorateId'];
                          final governorateId =
                              govIdRaw is String ? govIdRaw : '';
                          final govNameRaw = extra['governorateNameAr'];
                          final governorateNameAr =
                              govNameRaw is String ? govNameRaw : '';
                          final maxStopsRaw = extra['maxStops'];
                          final maxStops = maxStopsRaw is int ? maxStopsRaw : 8;
                          final userIdRaw = extra['userId'];
                          final userId =
                              userIdRaw is String ? userIdRaw : 'guest';

                          return TripPlacePickerScreen(
                            initialStops: initialStops,
                            governorateId: governorateId,
                            governorateNameAr: governorateNameAr,
                            maxStops: maxStops,
                            userId: userId,
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'detailed/:id',
                    name: RouteNames.tripDetailed,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return TripDetailedScreen(tripId: id);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    name: RouteNames.tripDetails,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return TripDetailsScreen(tripId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'my-reviews',
                    name: RouteNames.myReviews,
                    builder: (context, state) => const MyReviewsScreen(),
                  ),
                  GoRoute(
                    path: 'favorites',
                    name: RouteNames.profileFavorites,
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                name: RouteNames.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.search,
        name: RouteNames.search,
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: RoutePaths.favorites,
        name: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ 404')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الصفحة غير موجودة: ${state.uri}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(RoutePaths.home),
              child: const Text('الرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}
