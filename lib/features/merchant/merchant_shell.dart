// lib/features/merchant/merchant_shell.dart
//
// [v3.1 — 2026-10-26] — FIX: Build errors (const list, context.mounted, unused imports)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import 'screens/merchant_dashboard_screen.dart';
import 'screens/merchant_place_screen.dart';
import 'screens/merchant_reviews_screen.dart';
import 'screens/merchant_offers_screen.dart';
import 'screens/merchant_account_screen.dart';

class MerchantShell extends StatefulWidget {
  const MerchantShell({super.key});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int _currentIndex = 0;

  // ✅ تم إزالة static const لتجنب أي تعارض مع الشاشات
  // القائمة الآن final عادية، والشاشات بداخلها const (إذا توفر لديها constructor)
  final List<Widget> _screens = const [
    MerchantDashboardScreen(),
    MerchantPlaceScreen(),
    MerchantReviewsScreen(),
    MerchantOffersScreen(),
    MerchantAccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    // 🛡️ حماية إضافية: إذا لم يعد المستخدم تاجراً (مثلاً تم سحب الصلاحية)
    if (!auth.isMerchant) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ✅ إضافة فحص context.mounted لمنع أخطاء البناء
        if (context.mounted) {
          context.go('/home');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      // ─── الشريط العلوي الديناميكي ───
      appBar: AppBar(
        title: const Text('لوحة تحكم التاجر'),
        centerTitle: true,
        actions: [
          // زر سريع للتبديل إلى وضع المستخدم العادي
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'العودة لوضع المستخدم',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),

      // ─── محتوى الشاشات (IndexedStack يحافظ على حالة كل تبويب) ───
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // ─── شريط التنقل السفلي ───
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'مكاني',
          ),
          NavigationDestination(
            icon: Icon(Icons.reviews_outlined),
            selectedIcon: Icon(Icons.reviews),
            label: 'التقييمات',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_offer_outlined),
            selectedIcon: Icon(Icons.local_offer),
            label: 'العروض',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
