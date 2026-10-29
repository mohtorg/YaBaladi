// lib/screens/main_shell.dart
//
// [v4.4 — 2026-10-27] — UI: Changed Bag tab to Flight/Trip tab

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
    final bag = context.watch<TripBagController>();

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
            // ✅ التعديل: استخدام أيقونة الطائرة وتغيير النص لرحلتي
            icon: Badge(
              isLabelVisible: bag.itemCount > 0,
              label: Text('${bag.itemCount}'),
              child: const Icon(Icons.flight),
            ),
            selectedIcon: Badge(
              isLabelVisible: bag.itemCount > 0,
              label: Text('${bag.itemCount}'),
              child: const Icon(Icons.flight_takeoff),
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
