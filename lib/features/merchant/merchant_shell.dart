// lib/features/merchant/merchant_shell.dart
//
// [v2.2 — GEO HIERARCHY AWARE]
//   - placeId is now passed dynamically from AuthController.
//   - Added _NoPlaceAssignedScreen for merchants without an assigned place.
//   - MerchantPlaceScreen is no longer const (needs placeId).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/controllers/auth_controller.dart';
import 'screens/merchant_dashboard_screen.dart';
import 'screens/merchant_place_screen.dart';
import 'screens/merchant_reviews_screen.dart';
import 'screens/merchant_all_offers_screen.dart';
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

  /// ✅ بناء الشاشات ديناميكياً بناءً على placeId الحالي
  List<Widget> _buildScreens(String? placeId) {
    return [
      const MerchantDashboardScreen(),
      // إذا لم يكن للتاجر مكان معيّن، نعرض شاشة توضيحية
      if (placeId != null && placeId.isNotEmpty)
        MerchantPlaceScreen(placeId: placeId)
      else
        _NoPlaceAssignedScreen(onContactSupport: _contactSupport),
      const MerchantReviewsScreen(),
      const MerchantAllOffersScreen(),
      const MerchantAccountScreen(),
    ];
  }

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

    final screens = _buildScreens(auth.placeId);

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
        children: screens,
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

// ═══════════════════════════════════════════════════════════════
// شاشة توضيحية عند عدم تعيين مكان للتاجر
// ═══════════════════════════════════════════════════════════════
class _NoPlaceAssignedScreen extends StatelessWidget {
  final Future<void> Function() onContactSupport;

  const _NoPlaceAssignedScreen({required this.onContactSupport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined,
                size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'لم يتم تعيين مكان لك بعد',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'سيقوم فريق الإدارة بإنشاء مكانك وربطه بحسابك. '
              'سيصلك إشعار عند الانتهاء.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onContactSupport,
              icon: const Icon(Icons.support_agent),
              label: const Text('تواصل مع الدعم'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
