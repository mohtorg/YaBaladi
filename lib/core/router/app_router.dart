// lib/core/router/app_router.dart
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

GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    // ✅ التصحيح: البدء من شاشة الدخول لتجنب تعارض الـ Shell
    initialLocation: RoutePaths.login,
    debugLogDiagnostics: true,
    refreshListenable: auth,
    redirect: (context, state) {
      final status = auth.status;
      final role = auth.role;
      final isLoggingIn = state.matchedLocation == RoutePaths.login;
      final isRegistering = state.matchedLocation == RoutePaths.register;
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      if (status == AuthStatus.loading) {
        return null;
      }

      if (status == AuthStatus.unauthenticated) {
        if (isAdminRoute) return RoutePaths.login;
        if (isLoggingIn || isRegistering) return null;

        if (!auth.isGuest) return RoutePaths.login;

        return null;
      }

      if (status == AuthStatus.authenticated) {
        if (role == UserRole.admin || role == UserRole.moderator) {
          if (!isAdminRoute) return '/admin';
        } else {
          if (isAdminRoute) return RoutePaths.home;
          if (isLoggingIn) return RoutePaths.home;
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
                          final extra = state.extra;
                          if (extra is! Map<String, dynamic>) {
                            return RoutePaths.tripPlanner;
                          }
                          return null;
                        },
                        builder: (context, state) {
                          final extra = state.extra as Map<String, dynamic>;
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
      body: Center(child: Text('الصفحة غير موجودة: ${state.uri}')),
    ),
  );
}
