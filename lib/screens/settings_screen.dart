// lib/screens/settings_screen.dart
//
// [v2.5 — 2026-10-28] — FIX: Missing import + Added Live Badge for Support Tickets

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../features/support/controllers/support_tickets_controller.dart'; // ✅ الاستيراد المطلوب

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('الإعدادات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ═══════ 1. بطاقة التاجر الديناميكية ═══════
          if (auth.isLoggedIn && auth.isMerchant) ...[
            const _MerchantDashboardCard(),
            const SizedBox(height: 16),
          ],

          // ═══════ 2. لوحة الدعم (للأدمن فقط) ═══════
          if (auth.isLoggedIn && auth.isAdmin) ...[
            const _SectionHeader(title: 'الإدارة (Admin)'),
            // ✅ استخدام Consumer لعرض الشارة الحمراء (عدد البلاغات)
            Consumer<SupportTicketsController>(
              builder: (context, supportCtrl, _) {
                return ListTile(
                  leading:
                      const Icon(Icons.support_agent, color: Colors.redAccent),
                  title: const Text(
                    'لوحة الدعم (بلاغات المستخدمين)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.redAccent),
                  ),
                  subtitle: const Text('مراجعة ومعالجة الأخطاء المرسلة'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (supportCtrl.openCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${supportCtrl.openCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      const Icon(Icons.chevron_left),
                    ],
                  ),
                  onTap: () => context.push('/admin/support'),
                );
              },
            ),
            const Divider(),
          ],

          // ═══════ 3. سجل الرحلات (عنوان جانبي) ═══════
          if (auth.isLoggedIn) ...[
            const _SectionHeader(title: 'نشاطي'),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('سجل الرحلات (تاريخية)'),
              subtitle: const Text('الرحلات التي قمت بها سابقاً'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.push('/trips'),
            ),
            const Divider(),
          ],

          // ═══════ 4. المظهر واللغة ═══════
          const _SectionHeader(title: 'المظهر واللغة'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('المظهر'),
            subtitle: const Text('النظام (افتراضي)'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('ميزة تغيير المظهر ستتوفر قريباً')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('اللغة'),
            subtitle: const Text('العربية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ميزة تغيير اللغة ستتوفر قريباً')),
              );
            },
          ),
          const Divider(),

          // ═══════ 5. الخصوصية والأذونات ═══════
          const _SectionHeader(title: 'الخصوصية والأذونات'),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('إذن الموقع'),
            subtitle: const Text('مفعّل (عند الحاجة)'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: const Text('مسح ذاكرة التخزين المؤقت'),
            subtitle: const Text('تحرير مساحة على جهازك'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ تم مسح الذاكرة المؤقتة')),
              );
            },
          ),
          const Divider(),

          // ═══════ 6. القانوني والسياسات ═══════
          const _SectionHeader(title: 'القانوني والسياسات'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق'),
            subtitle: const Text('الإصدار 1.0.0'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () {},
          ),
          const Divider(),

          // ═══════ 7. منطقة الخطر (تسجيل الخروج) ═══════
          if (auth.isLoggedIn) ...[
            const _SectionHeader(title: 'الحساب'),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content:
                        const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('تسجيل الخروج'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await auth.signOut();
                  if (context.mounted) context.go('/login');
                }
              },
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ويدجتس مساعدة
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MerchantDashboardCard extends StatelessWidget {
  const _MerchantDashboardCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
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
      ),
    );
  }
}
