// lib/features/profile/profile_screen.dart
//
// [v1.1 — 2026-10-26] — FINAL BUILD FIX: Corrected import path & const constructor

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// ✅ [FIX] المسار الصحيح (بدون features)
import '../auth/controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    // البيانات الافتراضية في حال عدم وجود مستخدم (زائر)
    final displayName = auth.isLoggedIn ? auth.displayName : 'زائر';
    final email = auth.user?.email ?? 'سجل الدخول للاستفادة من الميزات';
    final photoUrl = auth.photoUrl;
    final isMerchant = auth.isMerchant;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('حسابي'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══════ 1. بطاقة المستخدم ═══════
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: theme.colorScheme.primaryContainer,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl == null || photoUrl.isEmpty
                  ? Icon(
                      Icons.person,
                      size: 50,
                      color: theme.colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // ═══════ 2. بطاقة التاجر الذكية ═══════
          if (isMerchant) ...[
            const _MerchantDashboardCard(),
            const SizedBox(height: 24),
          ],

          // ═══════ 3. القائمة ═══════
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.reviews_outlined),
                  title: const Text('تقييماتي'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    if (auth.isLoggedIn) {
                      context.push('/profile/my-reviews');
                    } else {
                      _showLoginDialog(context);
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.favorite_outline),
                  title: const Text('المفضلة'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push('/profile/favorites'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('الإعدادات'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push('/settings'),
                ),
                if (!isMerchant) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.storefront, color: Colors.orange),
                    title: const Text('هل أنت صاحب عمل؟'),
                    subtitle: const Text('انضم إلينا كتاجر معتمد'),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => context.push('/merchant/apply'),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ═══════ 4. زر تسجيل الخروج ═══════
          if (auth.isLoggedIn)
            OutlinedButton.icon(
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: Colors.red),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          else
            FilledButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('تسجيل الدخول'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الدخول مطلوب'),
        content: const Text('يجب عليك تسجيل الدخول لعرض تقييماتك.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/login');
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// بطاقة الانتقال للوحة التاجر
// ═══════════════════════════════════════════════════════════════

class _MerchantDashboardCard extends StatelessWidget {
  // ✅ [FIX] إضافة const constructor
  const _MerchantDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/merchant/dashboard'),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 أنت تاجر معتمد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'اضغط هنا لإدارة نشاطك التجاري.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
