// lib/features/admin/screens/admin_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../support/screens/admin_support_settings_dialog.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الأدمن',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _SectionTitle(title: 'إعدادات المنصة'),
          ListTile(
            leading:
                Icon(Icons.support_agent, color: theme.colorScheme.primary),
            title: const Text('إعدادات الدعم الفني (واتساب)'),
            subtitle:
                const Text('تحديد رقم الواتساب لاستقبال رسائل المستخدمين'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => AdminSupportSettingsDialog.show(context),
          ),
          const Divider(),
          _SectionTitle(title: 'الحساب'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(Icons.person,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            title: Text(auth.displayName),
            subtitle: Text(auth.user?.email ?? 'لا يوجد بريد'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () async {
              await auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
          const Divider(),
          _SectionTitle(title: 'حول التطبيق'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('إصدار لوحة التحكم'),
            subtitle: Text('v1.0.0 (Admin)'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
