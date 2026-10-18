// lib/core/router/app_router.dart
//
// [v2.6 — 2026-10-17] — Wave 1c hardening
//   - FIX: sort imports alphabetically (search before trip)
//   - FIX: defensive extra handling (redirect if null, safe cast)
//   - NEW: redirect to /trips/planner if picker opened without extra
//   - DOC: clarify trip_plan import purpose
//
// [v2.5 — 2026-10-17] — Wave 1c: TripPlacePicker route
// [v2.4.2 — 2026-10-15] — FIX: /trips/planner كان يُطابق :id خطأً
// [v2.4 — 2026-10-15] — Trip details route /trips/:id
// [v2.3 — 2026-10-15] — G6.7: Trip Planner routes

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/places/screens/place_details_screen.dart';
import '../../features/places/screens/place_map_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/reviews/screens/my_reviews_screen.dart';
import '../../features/search/screens/explore_screen.dart'; // ✅ [v2.6] moved up
import '../../features/trip/screens/trip_details_screen.dart';
import '../../features/trip/screens/trip_planner_screen.dart';
import '../../features/trip/screens/trip_plans_screen.dart';
import '../../features/trip/screens/trip_place_picker_screen.dart';
import '../../models/trip_plan.dart'; // TripStop type (used in picker extra cast)
import '../../screens/home_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/settings_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// إنشاء GoRouter مع AuthController مُمرَّر
GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,
    refreshListenable: auth,
    redirect: (context, state) => authGuard(auth: auth, state: state),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // ─── Branch 0: Home + Category + Place ───
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
                    routes: [
                      GoRoute(
                        path: 'map',
                        name: RouteNames.categoryMap,
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return PlaceMapScreen(categoryId: id);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'place/:id',
                    name: RouteNames.place,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return PlaceDetailsScreen(placeId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'map',
                        name: RouteNames.placeMap,
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return PlaceMapScreen(placeId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // ─── Branch 1: Trips (Trips + Planner + Picker + Details) ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.trips,
                name: RouteNames.trips,
                builder: (context, state) => const TripPlansScreen(),
                routes: [
                  // ✅ [v2.4.2] Static FIRST — يحل تعارض /trips/planner
                  GoRoute(
                    path: 'planner',
                    name: RouteNames.tripPlanner,
                    builder: (context, state) => const TripPlannerScreen(),
                    routes: [
                      // ✅ [v2.5] Wave 1c — Picker (Static child of planner)
                      // [v2.6] redirect إذا لم يوجد extra (دخول مباشر)
                      GoRoute(
                        path: 'picker',
                        name: RouteNames.tripPlacePicker,
                        redirect: (context, state) {
                          final extra = state.extra;
                          if (extra is! Map<String, dynamic>) {
                            // دخول مباشر بدون بيانات → ارجع للـ planner
                            return RoutePaths.tripPlanner;
                          }
                          return null;
                        },
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>;

                          // ✅ [v2.6] defensive casts — لا crash
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
                  // [v2.4] Dynamic AFTER — /trips/:id
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

          // ─── Branch 2: Profile + My Reviews + Favorites ───
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

          // ─── Branch 3: Settings ───
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

      // ─── Auth routes — خارج الـ Shell ───
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

      // ─── البحث الحر — خارج الـ Shell ───
      GoRoute(
        path: RoutePaths.search,
        name: RouteNames.search,
        builder: (context, state) => const ExploreScreen(),
      ),

      // ─── المسار القديم للمفضلة — للتوافق الخلفي ───
      GoRoute(
        path: RoutePaths.favorites,
        name: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ 404')),
      body: Center(child: Text('الصفحة غير موجودة: ${state.uri}')),
    ),
  );
}
