// lib/features/merchant/merchant_shell.dart
//
// [v2.0 — 2026-10-28] — ENHANCEMENT: Added Support Button, Improved UI, Safe Routing

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/controllers/auth_controller.dart';
import 'screens/merchant_dashboard_screen.dart';
import 'screens/merchant_place_screen.dart';
import 'screens/merchant_reviews_screen.dart';
import 'screens/merchant_offers_screen.dart';
import 'screens/merchant_account_screen.dart';

class MerchantShell extends StatefulWidget {
  final VoidCallback? onExit;

  const MerchantShell({super.key, this.onExit});

  @override
  State<MerchantShell> createState() => _MerchantShellState();
}

class _MerchantShellState extends State<MerchantShell> {
  int _currentIndex = 0;
  bool _isLoadingSupport = false;

  final List<Widget> _screens = const [
    MerchantDashboardScreen(),
    MerchantPlaceScreen(),
    MerchantReviewsScreen(),
    MerchantOffersScreen(),
    MerchantAccountScreen(),
  ];

  // ✅ دالة التواصل مع الدعم (تقرأ رقم الواتساب من إعدادات الأدمن)
  Future<void> _contactSupport() async {
    if (_isLoadingSupport) return;
    setState(() => _isLoadingSupport = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('support')
          .get();

      final number = doc.data()?['whatsappNumber'] as String?;

      if (number == null || number.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('لم يتم تعيين رقم الدعم من قبل الإدارة بعد.')),
          );
        }
        return;
      }

      final url = Uri.parse('https://wa.me/$number');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر فتح واتساب، تأكد من تثبيته.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingSupport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    // ✅ حماية إضافية: إذا لم يكن تاجراً، يُعاد توجيهه
    if (!auth.isMerchant) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          if (widget.onExit != null) {
            widget.onExit!();
          } else {
            context.go('/home');
          }
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        elevation: 1,
        title: const Text('لوحة التاجر',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // ✅ زر الدعم الفني
          IconButton(
            icon: _isLoadingSupport
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.support_agent, color: Colors.blueGrey),
            tooltip: 'الدعم الفني',
            onPressed: _contactSupport,
          ),
          // ✅ زر العودة لوضع المستخدم
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: 'العودة لوضع المستخدم',
            onPressed: widget.onExit ?? () => context.go('/home'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: theme.colorScheme.surface,
        indicatorColor: theme.colorScheme.primaryContainer,
        elevation: 8,
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
