// lib/features/profile/profile_screen.dart
// [v2.2 — 2026-11-15] — ADDED: Logout & Delete Account options for logged-in users.
// [v2.1 — 2026-11-03] — LINT FIX: Removed null check on non-nullable auth.uid.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/controllers/auth_controller.dart';
import '../notifications/widgets/notification_bell.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingSupport = false;

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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoadingSupport = false);
    }
  }

  Future<void> _handleDeleteAccount(
      BuildContext context, AuthController auth) async {
    final passwordController = TextEditingController();
    final requiresPassword = auth.hasPasswordProvider;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ حذف الحساب نهائياً'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'سيتم حذف حسابك وبياناتك (تقييماتك، مفضلتك، إلخ) نهائياً. لا يمكن التراجع عن هذا الإجراء.',
            ),
            if (requiresPassword) ...[
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'أدخل كلمة المرور للتأكيد',
                  border: OutlineInputBorder(),
                ),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await auth.deleteAccount(
        password: requiresPassword ? passwordController.text : null,
      );

      if (!context.mounted) return;

      if (result.isSuccess) {
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'تعذر حذف الحساب'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final displayName = auth.isLoggedIn ? auth.displayName : 'زائر';
    final email = auth.isLoggedIn
        ? (auth.user?.email ?? 'لا يوجد بريد')
        : 'سجل الدخول للاستفادة من الميزات';
    final photoUrl = auth.photoUrl;
    final isMerchant = auth.isMerchant;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Header ───
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            title: Text(displayName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              const NotificationBell(),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => context.push('/settings'),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage:
                                (photoUrl != null && photoUrl.isNotEmpty)
                                    ? NetworkImage(photoUrl)
                                    : null,
                            child: (photoUrl == null || photoUrl.isEmpty)
                                ? Icon(Icons.person,
                                    size: 50, color: theme.colorScheme.primary)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(email,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Stats Card ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _StatsRow(userId: auth.uid),
            ),
          ),

          // ─── Merchant Card ───
          if (isMerchant)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _MerchantDashboardCard(),
              ),
            ),

          // ─── Menu ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.reviews_outlined,
                          color: Colors.blue),
                      title: const Text('تقييماتي'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => auth.isLoggedIn
                          ? context.push('/profile/my-reviews')
                          : _showLoginDialog(context),
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
                    ListTile(
                      leading: const Icon(Icons.history, color: Colors.purple),
                      title: const Text('سجل الرحلات'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () => context.push('/trips'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: _isLoadingSupport
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.support_agent,
                              color: Colors.orange),
                      title: const Text('الدعم الفني'),
                      subtitle: const Text('تواصل معنا لأي استفسار'),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: _isLoadingSupport ? null : _contactSupport,
                    ),
                    if (!isMerchant) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            const Icon(Icons.storefront, color: Colors.orange),
                        title: const Text('هل أنت صاحب عمل؟'),
                        subtitle: const Text('انضم إلينا كتاجر معتمد'),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () => context.push('/merchant/apply'),
                      ),
                    ],
                    if (auth.isLoggedIn) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'تسجيل الخروج',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          await auth.signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        title: const Text(
                          'حذف الحساب نهائياً',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        onTap: () => _handleDeleteAccount(context, auth),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ─── Login Button (if not logged in) ───
          if (!auth.isLoggedIn)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('تسجيل الدخول'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
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

// ─── Stats Row ───
class _StatsRow extends StatelessWidget {
  final String userId;
  const _StatsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
            child: _statStream(theme, Icons.reviews, 'تقييماتي', 'reviews',
                userId, Colors.blue)),
        const SizedBox(width: 8),
        Expanded(
            child: _statStream(theme, Icons.favorite, 'مفضلتي', 'favorites',
                userId, Colors.red)),
        const SizedBox(width: 8),
        Expanded(
            child: _statStream(theme, Icons.map, 'رحلاتي', 'trip_plans', userId,
                Colors.purple)),
      ],
    );
  }

  Widget _statStream(ThemeData theme, IconData icon, String label,
      String collection, String userId, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text('$count',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: theme.textTheme.labelSmall,
                  textAlign: TextAlign.center),
            ],
          ),
        );
      },
    );
  }
}

// ─── Merchant Card ───
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
                offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle),
                child:
                    const Icon(Icons.dashboard, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎉 أنت تاجر معتمد',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('اضغط هنا لإدارة نشاطك التجاري',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
