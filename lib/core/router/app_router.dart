import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/favorites/favorites_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/main_shell.dart';
import '../../screens/search_screen.dart';
import 'route_names.dart';
import 'route_paths.dart';

/// Placeholder مؤقت — سنستبدله بـ SettingsScreen الحقيقي بعد
/// ربط LocaleController و ThemeController عبر Provider أو InheritedWidget
class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: const Center(child: Text('شاشة الإعدادات — قيد الربط')),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: RoutePaths.home,
  debugLogDiagnostics: true,

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
          builder: (context, state) => const _SettingsPlaceholder(),
        ),
      ],
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
