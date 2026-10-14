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
import '../../screens/home_screen.dart';
import '../../screens/main_shell.dart';
import '../../features/search/screens/explore_screen.dart';
import '../../screens/settings_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// إنشاء GoRouter مع AuthController مُمرَّر
///
/// [v2.2 — 2026-10-14] — Favorites drill-down from Profile
///   - NEW: /profile/favorites (نفس FavoritesScreen — لكن back يرجع لـ Profile)
///
/// [v2.1 — 2026-10-14] — R4: My Reviews route
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

          // ─── Branch 1: Profile + My Reviews + Favorites (drill-down) ───
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
                  // [v2.2] Favorites drill-down — نفس الشاشة، لكن back يرجع لـ Profile
                  GoRoute(
                    path: 'favorites',
                    name: RouteNames.profileFavorites,
                    builder: (context, state) => const FavoritesScreen(),
                  ),
                ],
              ),
            ],
          ),

          // ─── Branch 2: Favorites (bottom nav tab) ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.favorites,
                name: RouteNames.favorites,
                builder: (context, state) => const FavoritesScreen(),
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
      GoRoute(
        path: RoutePaths.search,
        name: RouteNames.search,
        builder: (context, state) => const ExploreScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ 404')),
      body: Center(child: Text('الصفحة غير موجودة: ${state.uri}')),
    ),
  );
}
