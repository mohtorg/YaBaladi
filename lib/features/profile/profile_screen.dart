// lib/features/profile/profile_screen.dart
//
// [v1.4 — 2026-10-28] — ADD: NotificationBell in AppBar

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ المسار الصحيح للكنترولر
import '../auth/controllers/auth_controller.dart';
import '../notifications/widgets/notification_bell.dart'; // ✅ استيراد جديد

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingSupport = false;

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
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    final displayName = auth.isLoggedIn ? auth.displayName : 'زائر';
    final email = auth.isLoggedIn
        ? (auth.user?.email ?? 'لا يوجد بريد مسجل')
        : 'سجل الدخول للاستفادة من الميزات';
    final photoUrl = auth.photoUrl;
    final isMerchant = auth.isMerchant;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title:
            const Text('حسابي', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          // ✅ زر الإشعارات (مع شارة حمراء عند وجود إشعارات جديدة)
          const NotificationBell(),
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
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
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

          // ═══════ 2. بطاقة التاجر الذكية (تظهر فقط للتجار) ═══════
          if (isMerchant) ...[
            const _MerchantDashboardCard(),
            const SizedBox(height: 24),
          ],

          // ═══════ 3. القائمة (تقييماتي، المفضلة، الدعم، الإعدادات) ═══════
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.reviews_outlined, color: Colors.blue),
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
                  leading:
                      const Icon(Icons.favorite_outline, color: Colors.red),
                  title: const Text('المفضلة'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.push('/profile/favorites'),
                ),
                const Divider(height: 1),
                // ✅ زر الدعم الفني
                ListTile(
                  leading: _isLoadingSupport
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.support_agent, color: Colors.orange),
                  title: const Text('الدعم الفني'),
                  subtitle: const Text('تواصل معنا لأي استفسار'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: _isLoadingSupport ? null : _contactSupport,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined,
                      color: Colors.blueGrey),
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

          // ═══════ 4. زر تسجيل الخروج / الدخول ═══════
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
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // نافذة تنبيه عند محاولة الزائر الوصول لميزة تتطلب تسجيل الدخول
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
// بطاقة الانتقال للوحة التاجر (تظهر فقط إذا كان المستخدم تاجراً)
// ═══════════════════════════════════════════════════════════════

class _MerchantDashboardCard extends StatelessWidget {
  const _MerchantDashboardCard();

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 أنت تاجر معتمد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'اضغط هنا لإدارة نشاطك التجاري.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
