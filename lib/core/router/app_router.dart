import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/search_screen.dart';
import '../../screens/settings_screen.dart';
import 'route_guards.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// إنشاء GoRouter مع AuthController مُمرَّر (بدل context.read)
///
/// هذا يحل مشكلة الوصول لـ Provider من داخل redirect
GoRouter createAppRouter(AuthController auth) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    debugLogDiagnostics: true,

    redirect: (context, state) {
      return authGuard(auth: auth, state: state);
    },

    routes: [
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: RoutePaths.profile,
            name: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RoutePaths.favorites,
            name: RouteNames.favorites,
            builder: (context, state) => const FavoritesScreen(),
          ),
          GoRoute(
            path: RoutePaths.settings,
            name: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
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
        builder: (context, state) => const SearchScreen(),
      ),
    ],

    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('خطأ 404')),
      body: Center(child: Text('المسار غير موجود: ${state.uri}')),
    ),
  );
}