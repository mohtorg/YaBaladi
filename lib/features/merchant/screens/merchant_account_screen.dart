// lib/features/merchant/screens/merchant_account_screen.dart
//
// [v2.0 — 2026-10-28] — ENHANCEMENT: Active WhatsApp Support Integration + UI Polish

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../features/auth/controllers/auth_controller.dart';

class MerchantAccountScreen extends StatefulWidget {
  const MerchantAccountScreen({super.key});

  @override
  State<MerchantAccountScreen> createState() => _MerchantAccountScreenState();
}

class _MerchantAccountScreenState extends State<MerchantAccountScreen> {
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

    final displayName = auth.displayName;
    final email = auth.user?.email ?? 'لا يوجد بريد إلكتروني';
    final photoUrl = auth.photoUrl;
    final hasPlace = auth.hasPlace;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('حساب التاجر',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══════ 1. صورة وبيانات التاجر ═══════
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

          // ═══════ 2. حالة النشاط التجاري ═══════
          Card(
            elevation: 0,
            color: hasPlace
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: hasPlace
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    hasPlace ? Icons.verified : Icons.hourglass_top,
                    color: hasPlace ? Colors.green : Colors.orange,
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasPlace ? 'نشاطك التجاري معتمد' : 'قيد المراجعة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: hasPlace
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasPlace
                              ? 'يمكنك الآن إدارة العروض، التقييمات، وبيانات المكان.'
                              : 'نحن نراجع طلبك حالياً. سيتم تفعيل لوحة التحكم قريباً.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: hasPlace
                                ? Colors.green.shade900
                                : Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ═══════ 3. الإجراءات ═══════
          const Text(
            'الإجراءات',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                  title: const Text('العودة لوضع المستخدم'),
                  subtitle: const Text('تصفح التطبيق كعميل عادي'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => context.go('/home'),
                ),
                const Divider(height: 1),
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
              ],
            ),
          ),
          const SizedBox(height: 32),

          // ═══════ 4. تسجيل الخروج ═══════
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('تسجيل الخروج'),
                  content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
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
          ),
        ],
      ),
    );
  }
}
