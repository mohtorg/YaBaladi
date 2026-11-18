// lib/screens/main_shell.dart
//
// [v4.6 - FIXED] - Real bug fix:
//   - FIXED: _BadgeIcon no longer takes an unused `selectedIcon` param.
//   - FIXED: NavigationDestination now has its own `selectedIcon` (so
//     the flight icon correctly becomes flight_takeoff when selected).
//   - KEPT: All index mapping, merchant push, and layout intact.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/trip/controllers/trip_bag_controller.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final tripBag = context.watch<TripBagController>();

    final bool showMerchantTab = auth.isMerchant;

    int visualIndex = navigationShell.currentIndex;
    if (showMerchantTab && visualIndex >= 2) {
      visualIndex += 1;
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: visualIndex,
        onDestinationSelected: (int tappedIndex) {
          if (showMerchantTab && tappedIndex == 2) {
            context.push('/merchant/dashboard');
            return;
          }

          final int branchIndex = (showMerchantTab && tappedIndex > 2)
              ? tappedIndex - 1
              : tappedIndex;

          navigationShell.goBranch(
            branchIndex,
            initialLocation: branchIndex == navigationShell.currentIndex,
          );
        },
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: _BadgeIcon(
              icon: Icons.flight,
              count: tripBag.itemCount,
            ),
            selectedIcon: _BadgeIcon(
              icon: Icons.flight_takeoff,
              count: tripBag.itemCount,
            ),
            label: 'رحلتي',
          ),
          if (showMerchantTab)
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'لوحة التاجر',
            ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BadgeIcon({
    required this.icon,
    required this.count,
  });

  String get _countLabel {
    if (count <= 0) return '';
    return count > 99 ? '99+' : '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(_countLabel),
      child: Icon(icon),
    );
  }
}
