// lib/core/router/app_router.dart
//
// [v5.1 — 2026-10-26] — ROUTING FIX: Protect /merchant/apply & redirect existing merchants

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ─── Auth & Core ───
import '../../features/auth/controllers/auth_controller.dart';

// ─── Public Routes ───
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';

// ─── Admin Routes ───
import '../../features/admin/screens/admin_dashboard_screen.dart';

// ─── Merchant Routes ───
import '../../features/merchant/controllers/merchant_application_controller.dart';
import '../../features/merchant/merchant_shell.dart';
import '../../features/merchant/screens/merchant_application_screen.dart';

// ─── User Routes ───
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

// ✅ دالة آمنة للتحقق من المسار
String? _safeFrom(String? from) {
  if (from == null || from.isEmpty) return null;
  if (!from.startsWith('/') || from.startsWith('//')) return null;

  final path = Uri.tryParse(from)?.path ?? '';
  if (path.isEmpty) return null;
  if (path == '/login' ||
      path == '/register' ||
      path == '/forgot-password' ||
      path.startsWith('/admin')) {
    return null;
  }
  return from;
}

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;
      final roleName = auth.role.toString().split('.').last;
      final location = state.uri.path;

      // 1. حالة التحميل
      if (status == AuthStatus.loading) return null;

      final isAuthPage = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';
      final isAdminRoute = location.startsWith('/admin');

      // ✅ فصل مسار التقديم عن باقي مسارات التاجر
      final isMerchantApplyRoute = location == '/merchant/apply';
      final isMerchantDashboardRoute =
          location.startsWith('/merchant') && !isMerchantApplyRoute;

      final isStaff = roleName == 'admin' || roleName == 'moderator';

      // 2. المستخدم غير المسجل (زائر أو جديد)
      if (status == AuthStatus.unauthenticated) {
        // ✅ حماية مسار التقديم: يجب تسجيل الدخول أولاً
        if (isAdminRoute || isMerchantDashboardRoute || isMerchantApplyRoute) {
          return '/login?from=${Uri.encodeComponent(location)}';
        }
        return null; // السماح بالتصفح للزوار
      }

      // 3. المستخدم المسجل (Authenticated)
      if (status == AuthStatus.authenticated) {
        // الموظفون (أدمن/مشرف)
        if (isStaff) {
          if (!isAdminRoute) return '/admin';
          return null;
        }

        if (isAdminRoute) {
          return '/home';
        }

        // ✅ إذا كان تاجراً بالفعل، لا داعي لتقديم طلب جديد
        if (isMerchantApplyRoute && roleName == 'merchant') {
          return '/merchant/dashboard';
        }

        // منع غير التجار من دخول مسارات لوحة التحكم
        if (isMerchantDashboardRoute && roleName != 'merchant') {
          return '/home';
        }

        // منع المسجل من رؤية صفحات الدخول
        if (isAuthPage) {
          return _safeFrom(state.uri.queryParameters['from']) ?? '/home';
        }
      }

      return null; // لا تغيير في المسار
    },
    routes: [
      // ═══════════════════════════════════════════════════════════
      // 1. المسارات العامة (Public Routes)
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/merchant/apply',
        name: 'merchantApply',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => MerchantApplicationController(),
          child: const MerchantApplicationScreen(),
        ),
      ),

      // ═══════════════════════════════════════════════════════════
      // 2. مسارات الأدمن (Admin Routes)
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/admin',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),

      // ═══════════════════════════════════════════════════════════
      // 3. واجهة التاجر (Merchant Shell)
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/merchant/dashboard',
        name: 'merchantDashboard',
        builder: (context, state) => const MerchantShell(),
      ),

      // ═══════════════════════════════════════════════════════════
      // 4. واجهة المستخدم العادي (User Shell) - 5 Branches
      // ═══════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // ─── الفرع 0: الاستكشاف (Home) ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'category/:id',
                    name: 'category',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ExploreScreen(categoryId: id);
                    },
                  ),
                  GoRoute(
                    path: 'place/:id',
                    name: 'place',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return PlaceDetailsScreen(placeId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ─── الفرع 1: رحلاتي (Trips) ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trips',
                name: 'trips',
                builder: (context, state) => const TripPlansScreen(),
                routes: [
                  GoRoute(
                    path: 'planner',
                    name: 'tripPlanner',
                    builder: (context, state) => const WizardContainerScreen(),
                    routes: [
                      GoRoute(
                        path: 'picker',
                        name: 'tripPlacePicker',
                        redirect: (context, state) {
                          if (state.extra is! Map) return '/trips/planner';
                          return null;
                        },
                        builder: (context, state) {
                          final extraRaw = state.extra;
                          final extra = extraRaw is Map
                              ? Map<String, dynamic>.from(extraRaw)
                              : <String, dynamic>{};

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
                    name: 'tripDetailed',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return TripDetailedScreen(tripId: id);
                    },
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'tripDetails',
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return TripDetailsScreen(tripId: id);
                    },
                  ),
                ],
              ),
            ],
          ),

          // ─── الفرع 2: المفضلة (Favorites) ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                name: 'favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),

          // ─── الفرع 3: حسابي (Profile) ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'my-reviews',
                    name: 'myReviews',
                    builder: (context, state) => const MyReviewsScreen(),
                  ),
                  GoRoute(
                    path: 'favorites',
                    name: 'profileFavorites',
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                ],
              ),
            ],
          ),

          // ─── الفرع 4: الإعدادات (Settings) ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ═══════════════════════════════════════════════════════════
      // 5. مسارات مساعدة (Standalone)
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const ExploreScreen(),
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
              onPressed: () => context.go('/home'),
              child: const Text('الرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}
