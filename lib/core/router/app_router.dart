// lib/core/router/app_router.dart
//
// [v6.9.2 — 2026-11-05] — ADDED: Admin bulk import route.
// [v6.9.1 — 2026-11-05] — HOTFIX: Fixed UserRole.code error by using native .name property.
// [v6.9 — 2026-11-05] — FIX: Un-trapped Admin (can now browse public app),
//                        Improved merchant route protection.

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ─── Auth & Core ───
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/splash_screen.dart';

// ─── Public Routes ───
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';

// ─── Admin Routes ───
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/manage_geo_hierarchy_screen.dart';
import '../../features/admin/screens/manage_review_criteria_screen.dart';
import '../../features/admin/screens/owner_claim_requests_screen.dart';
import '../../features/admin/screens/admin_merchants_screen.dart';
import '../../features/admin/screens/geo_zones_admin_screen.dart';
import '../../features/admin/screens/admin_statistics_screen.dart';
import '../../features/admin/screens/admin_offer_requests_screen.dart';
import '../../features/admin/screens/admin_recompute_screen.dart';
import '../../features/admin/screens/admin_broadcast_notification_screen.dart';
import '../../features/admin/screens/admin_reports_screen.dart';
import '../../features/admin/screens/admin_settings_screen.dart';
import '../../features/support/controllers/support_tickets_controller.dart';
import '../../features/support/screens/admin_support_screen.dart';
// ✅ إضافة استيراد شاشة استيراد الإكسل
import '../../screens/admin/bulk_import_screen.dart';

// ─── Merchant Routes ───
import '../../features/merchant/controllers/merchant_application_controller.dart';
import '../../features/merchant/merchant_shell.dart';
import '../../features/merchant/screens/merchant_application_screen.dart';

// ─── Legal & About Routes ───
import '../../features/legal/screens/legal_page_screen.dart';
import '../../features/about/screens/about_screen.dart';

// ─── User Routes ───
import '../../features/favorites/favorites_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/places/screens/all_offers_screen.dart';
import '../../features/places/screens/place_details_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reviews/screens/my_reviews_screen.dart';
import '../../features/search/screens/explore_screen.dart';
import '../../features/search/screens/all_categories_screen.dart';
import '../../features/trip/screens/trip_detailed_screen.dart';
import '../../features/trip/screens/trip_place_picker_screen.dart';
import '../../features/trip/screens/trip_plans_screen.dart';
import '../../features/trip/screens/trip_bag_screen.dart';
import '../../features/trip/screens/trip_planner_screen.dart';
import '../../models/trip_plan.dart';
import '../../screens/home_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/settings_screen.dart';

String? _safeFrom(String? from) {
  if (from == null || from.isEmpty) return null;
  if (!from.startsWith('/') || from.startsWith('//')) return null;

  final path = Uri.tryParse(from)?.path ?? '';
  if (path.isEmpty) return null;
  if (path == '/login' ||
      path == '/register' ||
      path == '/forgot-password' ||
      path == '/splash' ||
      path.startsWith('/admin')) {
    return null;
  }
  return from;
}

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;

      // ✅ الحل: استخدام الخاصية المدمجة .name للـ Enum (لا تحتاج لاستيراد extension)
      final roleCode = auth.role.name;

      final location = state.uri.path;
      final isRoleReady = auth.isRoleReady;
      final isSplash = location == '/splash';

      // 1. حالة التحميل: اذهب للسبلاش
      if (status == AuthStatus.loading || !isRoleReady) {
        if (!isSplash) return '/splash';
        return null;
      }

      final isAuthPage = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';
      final isAdminRoute = location.startsWith('/admin');
      final isMerchantApplyRoute = location == '/merchant/apply';
      final isMerchantDashboardRoute =
          location.startsWith('/merchant') && !isMerchantApplyRoute;
      final isNotificationsRoute = location == '/notifications';

      final isStaff = roleCode == 'admin' || roleCode == 'moderator';

      // 2. غير مسجل الدخول: يمنع الوصول للمسارات المحمية
      if (status == AuthStatus.unauthenticated) {
        if (isSplash) return '/login';
        if (isAdminRoute ||
            isMerchantDashboardRoute ||
            isMerchantApplyRoute ||
            isNotificationsRoute) {
          return '/login?from=${Uri.encodeComponent(location)}';
        }
        return null;
      }

      // 3. مسجل الدخول
      if (status == AuthStatus.authenticated) {
        // التوجيه الأولي بعد السبلاش
        if (isSplash) {
          if (isStaff) return '/admin';
          if (roleCode == 'merchant') return '/merchant/dashboard';
          return '/home';
        }

        // ✅ حماية مسارات الأدمن: فقط الـ Staff يمكنهم الدخول
        if (isAdminRoute && !isStaff) {
          return '/home';
        }

        // حماية مسارات التاجر: فقط التاجر يمكنه الدخول (ما لم يكن أدمن)
        if (isMerchantDashboardRoute && roleCode != 'merchant' && !isStaff) {
          return '/home';
        }

        // إذا كان تاجراً وحاول الدخول لصفحة تقديم الطلب مجدداً
        if (isMerchantApplyRoute && roleCode == 'merchant') {
          return '/merchant/dashboard';
        }

        // إذا كان مسجلاً بالفعل وحاول الدخول لصفحات الدخول/التسجيل
        if (isAuthPage) {
          return _safeFrom(state.uri.queryParameters['from']) ?? '/home';
        }
      }

      return null;
    },
    routes: [
      // ═══════════════════════════════════════════════════════════
      // 0. Splash
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ═══════════════════════════════════════════════════════════
      // 1. Public Routes
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

      // ─── Legal & About (Public) ───
      GoRoute(
        path: '/legal/privacy',
        name: 'privacyPolicy',
        builder: (context, state) =>
            const LegalPageScreen(type: LegalType.privacy),
      ),
      GoRoute(
        path: '/legal/terms',
        name: 'termsOfUse',
        builder: (context, state) =>
            const LegalPageScreen(type: LegalType.terms),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),

      // ═══════════════════════════════════════════════════════════
      // 2. Admin Routes
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/admin',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/support',
        name: 'adminSupport',
        builder: (context, state) => ChangeNotifierProvider(
          create: (_) => SupportTicketsController(),
          child: const AdminSupportScreen(),
        ),
      ),
      // ✅ إضافة مسار شاشة استيراد الإكسل
      GoRoute(
        path: '/admin/bulk-import',
        name: 'adminBulkImport',
        builder: (context, state) => const BulkImportScreen(),
      ),
      GoRoute(
        path: '/admin/geo-hierarchy',
        name: 'adminGeoHierarchy',
        builder: (context, state) => const ManageGeoHierarchyScreen(),
      ),
      GoRoute(
        path: '/admin/review-criteria',
        name: 'adminReviewCriteria',
        builder: (context, state) => const ManageReviewCriteriaScreen(),
      ),
      GoRoute(
        path: '/admin/owner-claims',
        name: 'adminOwnerClaims',
        builder: (context, state) => const OwnerClaimRequestsScreen(),
      ),
      GoRoute(
        path: '/admin/merchants',
        name: 'adminMerchants',
        builder: (context, state) => const AdminMerchantsScreen(),
      ),
      GoRoute(
        path: '/admin/geo-zones',
        name: 'adminGeoZones',
        builder: (context, state) => const GeoZonesAdminScreen(),
      ),
      GoRoute(
        path: '/admin/statistics',
        name: 'adminStatistics',
        builder: (context, state) => const AdminStatisticsScreen(),
      ),
      GoRoute(
        path: '/admin/offer-requests',
        name: 'adminOfferRequests',
        builder: (context, state) => const AdminOfferRequestsScreen(),
      ),
      GoRoute(
        path: '/admin/recompute',
        name: 'adminRecompute',
        builder: (context, state) => const AdminRecomputeScreen(),
      ),
      GoRoute(
        path: '/admin/broadcast',
        name: 'adminBroadcast',
        builder: (context, state) => const AdminBroadcastNotificationScreen(),
      ),
      GoRoute(
        path: '/admin/reports',
        name: 'adminReports',
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: '/admin/settings',
        name: 'adminSettings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),

      // ═══════════════════════════════════════════════════════════
      // 3. Merchant Shell
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/merchant/dashboard',
        name: 'merchantDashboard',
        builder: (context, state) => const MerchantShell(),
      ),

      // ═══════════════════════════════════════════════════════════
      // 4. Standalone Routes
      // ═══════════════════════════════════════════════════════════
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/offers',
        name: 'allOffers',
        builder: (context, state) => const AllOffersScreen(),
      ),
      GoRoute(
        path: '/trips',
        name: 'tripsHistory',
        builder: (context, state) => const TripPlansScreen(),
      ),
      // ✅ Planner: TripPlannerScreen
      GoRoute(
        path: '/trips/planner',
        name: 'tripPlanner',
        builder: (context, state) {
          final extra = state.extra;
          List<Map<String, dynamic>>? initialPlaces;
          if (extra is List) {
            initialPlaces = extra.whereType<Map<String, dynamic>>().toList();
          }
          return TripPlannerScreen(initialPlaces: initialPlaces);
        },
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
              final governorateId = govIdRaw is String ? govIdRaw : '';

              final govNameRaw = extra['governorateNameAr'];
              final governorateNameAr = govNameRaw is String ? govNameRaw : '';

              final maxStopsRaw = extra['maxStops'];
              final maxStops = maxStopsRaw is int ? maxStopsRaw : 8;

              final userIdRaw = extra['userId'];
              final userId = userIdRaw is String ? userIdRaw : 'guest';

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
        path: '/trips/detailed/:id',
        name: 'tripDetailed',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TripDetailedScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/trips/:id',
        name: 'tripDetails',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TripDetailedScreen(tripId: id);
        },
      ),
      GoRoute(
        path: '/categories',
        name: 'allCategories',
        builder: (context, state) => AllCategoriesScreen(
          governorate: state.uri.queryParameters['gov'],
        ),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => ExploreScreen(
          searchQuery: state.uri.queryParameters['q'],
        ),
      ),
      GoRoute(
        path: '/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),

      // ═══════════════════════════════════════════════════════════
      // 5. User Shell
      // ═══════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
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
                      final name = state.uri.queryParameters['name'];
                      final gov = state.uri.queryParameters['gov'];
                      return ExploreScreen(
                        categoryId: id,
                        categoryName: name,
                        governorate: gov,
                      );
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bag',
                name: 'tripBag',
                builder: (context, state) => const TripBagScreen(),
              ),
            ],
          ),
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
              onPressed: () {
                context.go('/home');
              },
              child: const Text('الرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}
