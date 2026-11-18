// lib/screens/settings_screen.dart
//
// [v3.4 - CLEAN] - Small hardening (non-breaking):
//   - FIXED: Removed unused 'auth_token' from keysToKeep (not stored there).
//   - FIXED: Wrapped RadioListTile with Material in theme picker bottom sheet.
//   - FIXED: Added hideCurrentSnackBar before 'soon' SnackBar.
//   - KEPT: All settings sections, theme logic, and admin tab intact.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../l10n/theme_controller.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/support/controllers/support_tickets_controller.dart';
import '../features/legal/screens/legal_page_screen.dart';
import '../features/about/screens/about_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _clearing = false;

  Future<void> _clearCache() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _clearing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      // Preserve only the theme key (auth token is stored elsewhere).
      const keysToKeep = {'app_theme_mode'};
      final allKeys = prefs.getKeys();
      for (final key in allKeys) {
        if (!keysToKeep.contains(key)) await prefs.remove(key);
      }
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      await DefaultCacheManager().emptyCache();

      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم مسح الذاكرة المؤقتة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'فاتح';
      case ThemeMode.dark:
        return 'داكن';
      case ThemeMode.system:
        return 'حسب النظام';
    }
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  void _showThemePicker(ThemeController themeCtrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('اختر المظهر',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              RadioGroup<ThemeMode>(
                groupValue: themeCtrl.themeMode,
                onChanged: (v) {
                  if (v != null) {
                    themeCtrl.setMode(v);
                    Navigator.pop(ctx);
                  }
                },
                child: Material(
                  color: Colors.transparent,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.light,
                        title: Text('فاتح'),
                        secondary: Icon(Icons.light_mode),
                      ),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.dark,
                        title: Text('داكن'),
                        secondary: Icon(Icons.dark_mode),
                      ),
                      RadioListTile<ThemeMode>(
                        value: ThemeMode.system,
                        title: Text('حسب النظام'),
                        secondary: Icon(Icons.brightness_auto),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSnackBar() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(content: Text('قريباً: دعم لغات إضافية')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final themeCtrl = context.watch<ThemeController>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('الإعدادات'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Admin Dashboard
          if (auth.isLoggedIn && auth.isAdmin) ...[
            const _SectionHeader(
                title: 'الإدارة', icon: Icons.admin_panel_settings),
            Consumer<SupportTicketsController>(
              builder: (context, ctrl, _) => ListTile(
                leading:
                    const Icon(Icons.support_agent, color: Colors.redAccent),
                title: const Text('لوحة الدعم',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (ctrl.openCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('${ctrl.openCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    const Icon(Icons.chevron_left),
                  ],
                ),
                onTap: () => context.push('/admin/support'),
              ),
            ),
            const Divider(),
          ],

          // Appearance
          const _SectionHeader(
              title: 'المظهر واللغة', icon: Icons.palette_outlined),
          ListTile(
            leading: Icon(_themeIcon(themeCtrl.themeMode)),
            title: const Text('المظهر'),
            subtitle: Text(_themeLabel(themeCtrl.themeMode)),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _showThemePicker(themeCtrl),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('اللغة'),
            subtitle: const Text('العربية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: _showLanguageSnackBar,
          ),
          const Divider(),

          // Permissions
          const _SectionHeader(title: 'الأذونات', icon: Icons.lock_outline),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('إذن الموقع'),
            subtitle: const Text('فتح إعدادات النظام'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () =>
                AppSettings.openAppSettings(type: AppSettingsType.location),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('إعدادات الإشعارات'),
            subtitle: const Text('فتح إعدادات النظام'),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () =>
                AppSettings.openAppSettings(type: AppSettingsType.notification),
          ),
          const Divider(),

          // Data
          const _SectionHeader(title: 'البيانات', icon: Icons.storage),
          ListTile(
            leading: _clearing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cleaning_services_outlined),
            title: const Text('مسح الذاكرة المؤقتة'),
            subtitle: const Text('حذف الملفات المؤقتة والإعدادات المحلية'),
            onTap: _clearing ? null : _clearCache,
          ),
          const Divider(),

          // Legal
          const _SectionHeader(title: 'القانوني والخصوصية', icon: Icons.policy),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const LegalPageScreen(type: LegalType.privacy))),
          ),
          ListTile(
            leading: const Icon(Icons.gavel),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const LegalPageScreen(type: LegalType.terms))),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('عن التطبيق'),
            subtitle: const Text('الإصدار 1.0.0'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          const Divider(),

          // Account
          if (auth.isLoggedIn) ...[
            const _SectionHeader(title: 'الحساب', icon: Icons.person_outline),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('تسجيل الخروج',
                  style: TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('تسجيل الخروج'),
                    content: const Text('هل أنت متأكد؟'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء')),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
