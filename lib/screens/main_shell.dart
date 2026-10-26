// lib/screens/main_shell.dart
//
// [v3.0 — 2026-10-26] — ARCHITECTURE: User Shell with Smart Merchant Switch

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ نراقب حالة المصادقة لمعرفة ما إذا كان المستخدم تاجراً أم لا
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      // ─── محتوى التبويبات (يُدار بواسطة GoRouter) ───
      body: navigationShell,

      // ─── زر التبديل الذكي (يظهر فقط للتجار) ───
      // ابتكار: بدلاً من وضع التبويب في القائمة السفلية وإزعاج المستخدم العادي،
      // نضع زراً عائماً (FAB) أنيقاً يظهر فقط لمن لديه صلاحية تاجر.
      floatingActionButton: auth.isMerchant
          ? FloatingActionButton.extended(
              onPressed: () {
                // الانتقال إلى لوحة تحكم التاجر
                context.push('/merchant/dashboard');
              },
              icon: const Icon(Icons.storefront),
              label: const Text('لوحة التاجر'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 4,
            )
          : null,

      // ─── شريط التنقل السفلي (للمستخدم العادي) ───
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (int index) {
          navigationShell.goBranch(
            index,
            // العودة إلى الصفحة الرئيسية للتبويب إذا تم الضغط عليه مرة أخرى
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'الاستكشاف',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'رحلاتي',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'المفضلة',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}
