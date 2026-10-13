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
import '../../screens/home_screen.dart';
import '../../screens/main_shell.dart';
import '../../features/search/screens/explore_screen.dart';
import '../../screens/settings_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// إنشاء GoRouter مع AuthController مُمرَّر
///
/// [v2.0 — StatefulShellRoute Migration]
///   - تم التحويل من ShellRoute البسيط إلى StatefulShellRoute.indexedStack
///     لحفظ حالة التبويبات ومنع إعادة إنشاء HomeScreen/WelcomeHeader في كل تنقل.
///   - /category/:id و /place/:id أصبحت routes فرعية لـ / (branch 0).
///   - URLs لم تتغيّر (نفس RoutePaths.categoryPath/placePath).
GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,

    // ✅ يخلي GoRouter يعيد تقييم redirect
    // كل ما AuthController ينبّه (login / signup / guest / signout).
    refreshListenable: auth,

    redirect: (context, state) {
      return authGuard(auth: auth, state: state);
    },

    routes: [
      // ═══════════════════════════════════════════════════════════
      // Stateful Shell (Bottom Nav) — 4 branches
      // ═══════════════════════════════════════════════════════════
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // ─── Branch 0: Home + Category + Place ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.home, // '/'
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  // /category/:id — تحت branch 0 (Home)
                  GoRoute(
                    path: 'category/:id', // → '/category/:id'
                    name: RouteNames.category,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return ExploreScreen(categoryId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'map', // → '/category/:id/map'
                        name: RouteNames.categoryMap,
                        builder: (context, state) {
                          final id = state.pathParameters['id'] ?? '';
                          return PlaceMapScreen(categoryId: id);
                        },
                      ),
                    ],
                  ),
                  // /place/:id — تحت branch 0 (Home)
                  GoRoute(
                    path: 'place/:id', // → '/place/:id'
                    name: RouteNames.place,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return PlaceDetailsScreen(placeId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'map', // → '/place/:id/map'
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

          // ─── Branch 1: Profile ───
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: RouteNames.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),

          // ─── Branch 2: Favorites ───
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

      // ═══════════════════════════════════════════════════════════
      // Auth routes — خارج الـ Shell (بدون Bottom Nav)
      // ═══════════════════════════════════════════════════════════
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
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ 404')),
      body: Center(
        child: Text('الصفحة غير موجودة: ${state.uri}'),
      ),
    ),
  );
}
