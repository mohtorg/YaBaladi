import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/route_paths.dart';
import '../l10n/app_localizations.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _indexFromLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final paths = [
      RoutePaths.home,
      RoutePaths.profile,
      RoutePaths.favorites,
      RoutePaths.settings,
    ];
    final idx = paths.indexWhere((p) => p == location);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final index = _indexFromLocation(context);

    final destinations = [
      _NavDest(Icons.home_outlined, Icons.home, l10n.home, RoutePaths.home),
      _NavDest(Icons.person_outline, Icons.person, l10n.profile, RoutePaths.profile),
      _NavDest(Icons.favorite_border, Icons.favorite, l10n.favorites, RoutePaths.favorites),
      _NavDest(Icons.settings_outlined, Icons.settings, l10n.settings, RoutePaths.settings),
    ];

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(destinations[i].path),
        destinations: [
          for (final d in destinations)
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