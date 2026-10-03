import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/route_paths.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const List<_NavDest> _destinations = [
    _NavDest(Icons.home_outlined, Icons.home, 'الرئيسية', RoutePaths.home),
    _NavDest(Icons.person_outline, Icons.person, 'حسابي', RoutePaths.profile),
    _NavDest(Icons.favorite_border, Icons.favorite, 'المفضلة', RoutePaths.favorites),
    _NavDest(Icons.settings_outlined, Icons.settings, 'الإعدادات', RoutePaths.settings),
  ];

  int _indexFromLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final idx = _destinations.indexWhere((d) => d.path == location);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexFromLocation(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}

class _NavDest {
  const _NavDest(this.icon, this.selectedIcon, this.label, this.path);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
}
