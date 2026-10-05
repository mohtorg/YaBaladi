import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/controllers/auth_controller.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../l10n/theme_controller.dart';
import '../theme/design_tokens.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/language_picker_dialog.dart';
import '../widgets/theme_picker_dialog.dart';
import '../widgets/ya_app_bar.dart';

/// شاشة الإعدادات — كل ما يخص تخصيص التطبيق:
/// - المظهر (اللغة + الثيم)
/// - الخصوصية والأذونات (الموقع + مسح الذاكرة)
/// - القانوني والسياسات (4 بنود)
/// - منطقة الخطر (حذف الحساب)
///
/// ملاحظة: بيانات المستخدم موجودة في ProfileScreen.
/// لا يوجد تكرار.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeController = context.watch<LocaleController>();
    final themeController = context.watch<ThemeController>();
    final auth = context.watch<AuthController>();

    return Scaffold(
      appBar: YaAppBar(title: l10n.settings),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: YaBaladiDesignTokens.space2,
        ),
        children: [
          // ═══════ المظهر ═══════
          _SectionHeader(title: l10n.settingsAppearance),

          _LanguageTile(localeController: localeController),
          _ThemeTile(themeController: themeController),

          const SizedBox(height: YaBaladiDesignTokens.space4),

          // ═══════ الخصوصية والأذونات ═══════
          _SectionHeader(title: l10n.settingsPrivacySection),

          _SettingTile(
            icon: Icons.location_on_outlined,
            title: l10n.locationLabel,
            subtitle: l10n.locationOnDemand,
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.cleaning_services_outlined,
            title: l10n.clearCacheLabel,
            subtitle: l10n.clearCacheSubtitle,
            onTap: () => _confirmClearCache(context),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space4),

          // ═══════ القانوني والسياسات ═══════
          _SectionHeader(title: l10n.settingsLegal),

          _SettingTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicyLabel,
            subtitle: l10n.privacyPolicySubtitle,
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.description_outlined,
            title: l10n.termsLabel,
            subtitle: l10n.termsSubtitle,
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.info_outline,
            title: l10n.aboutLabel,
            subtitle: l10n.aboutSubtitle,
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.numbers,
            title: l10n.versionLabel,
            subtitle: l10n.versionValue,
            onTap: null,
          ),

          // ═══════ منطقة الخطر ═══════
          if (auth.isLoggedIn) ...[
            const SizedBox(height: YaBaladiDesignTokens.space4),
            _SectionHeader(title: l10n.settingsDangerSection),

            _SettingTile(
              icon: Icons.delete_forever,
              title: l10n.deleteAccountLabel,
              subtitle: l10n.deleteAccountSubtitle,
              isDestructive: true,
              onTap: () => _confirmDeleteAccount(context),
            ),
          ],

          const SizedBox(height: YaBaladiDesignTokens.space6),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CONFIRMATIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _confirmClearCache(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showYaConfirmDialog(
      context: context,
      title: l10n.clearCacheLabel,
      message: l10n.clearCacheConfirm,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.clearPersistence();
      await FirebaseFirestore.instance.terminate();
      await FirebaseFirestore.instance.enableNetwork();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.clearCacheSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء المسح')),
        );
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

    // الحوار الأول: تأكيد عام
    final confirmed = await showYaConfirmDialog(
      context: context,
      title: l10n.deleteAccountLabel,
      message: l10n.deleteAccountWarning,
      confirmLabel: l10n.deleteAccountButton,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // الحوار الثاني: تحذير إضافي
    await showYaConfirmDialog(
      context: context,
      title: l10n.deleteAccountLabel,
      message: l10n.deleteAccountConfirm,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );
    // TODO(G4): call authService.deleteAccount() when wired
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        YaBaladiDesignTokens.space5,
        YaBaladiDesignTokens.space4,
        YaBaladiDesignTokens.space4,
        YaBaladiDesignTokens.space2,
      ),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LANGUAGE TILE
// ═══════════════════════════════════════════════════════════════

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: localeController,
      builder: (context, _) {
        final current = localeController.isArabic
            ? l10n.languageArabic
            : l10n.languageEnglish;

        return _SettingTile(
          icon: Icons.language,
          title: l10n.languageLabel,
          subtitle: current,
          onTap: () => LanguagePickerDialog.show(
            context,
            controller: localeController,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// THEME TILE
// ═══════════════════════════════════════════════════════════════

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        final current = themeController.isSystem
            ? l10n.themeSystem
            : themeController.isLight
                ? l10n.themeLight
                : l10n.themeDark;

        return _SettingTile(
          icon: Icons.palette_outlined,
          title: l10n.themeLabel,
          subtitle: current,
          onTap: () => ThemePickerDialog.show(
            context,
            controller: themeController,
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SETTING TILE
// ═══════════════════════════════════════════════════════════════

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? theme.colorScheme.error
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_left,
              color: theme.colorScheme.onSurfaceVariant,
            )
          : null,
      onTap: onTap,
    );
  }
}