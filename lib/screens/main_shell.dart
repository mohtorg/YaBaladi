import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../l10n/theme_controller.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Root shell that hosts the 4 primary tabs of the app:
/// - Home
/// - Search (placeholder for G3)
/// - Favorites (placeholder for G4)
/// - Settings
///
/// Controllers (locale + theme) are passed in from YaBaladiApp.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final destinations = <_NavDestination>[
      _NavDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.home,
      ),
      _NavDestination(
        icon: Icons.search_outlined,
        selectedIcon: Icons.search,
        label: l10n.search,
      ),
      _NavDestination(
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        label: l10n.favorites,
      ),
      _NavDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
      ),
    ];

    final pages = <Widget>[
      const HomeScreen(),
      _PlaceholderScreen(
        icon: Icons.search_outlined,
        title: l10n.search,
        message: l10n.noResults,
      ),
      _PlaceholderScreen(
        icon: Icons.favorite_border,
        title: l10n.favorites,
        message: l10n.noResults,
      ),
      SettingsScreen(
        localeController: widget.localeController,
        themeController: widget.themeController,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: [
          for (final destination in destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: Icon(destination.selectedIcon),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

// ============================================================
// NAV DESTINATION (private model)
// ============================================================

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

// ============================================================
// PLACEHOLDER SCREEN
// ============================================================

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}