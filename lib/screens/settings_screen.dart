import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';
import '../l10n/theme_controller.dart';
import '../theme/design_tokens.dart';
import '../widgets/language_picker_dialog.dart';
import '../widgets/theme_picker_dialog.dart';

/// Professional Settings screen for Ya Baladi.
///
/// Sections:
/// - General (Language, Theme, Location, Notifications)
/// - Account (Profile, Favorites, Logout)
/// - Legal & Policies (Privacy, Terms, About, Version)
/// - Advanced (Clear Cache, Delete Account)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.localeController,
    required this.themeController,
  });

  final LocaleController localeController;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: YaBaladiDesignTokens.space2,
        ),
        children: [
          // ============================================================
          // GENERAL
          // ============================================================
          _SectionHeader(title: l10n.settingsGeneral),

          _LanguageTile(
            localeController: localeController,
          ),

          _ThemeTile(
            themeController: themeController,
          ),

          _SettingTile(
            icon: Icons.location_on_outlined,
            title: l10n.locationLabel,
            subtitle: l10n.locationOnDemand,
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.notifications_outlined,
            title: l10n.notificationsLabel,
            subtitle: l10n.notificationsSubtitle,
            trailing: Switch(
              value: true,
              onChanged: (_) {},
            ),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space4),

          // ============================================================
          // ACCOUNT
          // ============================================================
          _SectionHeader(title: l10n.settingsAccount),

          _SettingTile(
            icon: Icons.person_outline,
            title: l10n.profile,
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.favorite_border,
            title: l10n.favorites,
            onTap: () {},
          ),

          _SettingTile(
            icon: Icons.logout,
            title: l10n.logout,
            isDestructive: true,
            onTap: () => _confirmLogout(context),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space4),

          // ============================================================
          // LEGAL & POLICIES
          // ============================================================
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

          const SizedBox(height: YaBaladiDesignTokens.space4),

          // ============================================================
          // ADVANCED
          // ============================================================
          _SectionHeader(title: l10n.settingsAdvanced),

          _SettingTile(
            icon: Icons.cleaning_services_outlined,
            title: l10n.clearCacheLabel,
            subtitle: l10n.clearCacheSubtitle,
            onTap: () => _confirmClearCache(context),
          ),

          _SettingTile(
            icon: Icons.delete_outline,
            title: l10n.deleteAccountLabel,
            subtitle: l10n.deleteAccountSubtitle,
            isDestructive: true,
            onTap: () => _confirmDeleteAccount(context),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space6),
        ],
      ),
    );
  }

  // ============================================================
  // CONFIRMATIONS
  // ============================================================

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _showConfirmDialog(
      context: context,
      title: l10n.logoutConfirmTitle,
      message: l10n.logoutConfirmMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    // TODO(G2.3): call authService.logout() when Auth is wired
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.logoutConfirmTitle)),
      );
    }
  }

  Future<void> _confirmClearCache(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _showConfirmDialog(
      context: context,
      title: l10n.clearCacheLabel,
      message: l10n.clearCacheConfirm,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.clearCacheSuccess)),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _showConfirmDialog(
      context: context,
      title: l10n.deleteAccountLabel,
      message: l10n.deleteAccountWarning,
      confirmLabel: l10n.deleteAccountButton,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );
    // TODO(G4): call authService.deleteAccount() when Auth is wired
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.deleteAccountWarning)),
      );
    }
  }

  Future<bool?> _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: isDestructive
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

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

// ============================================================
// LANGUAGE TILE
// ============================================================

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

// ============================================================
// THEME TILE
// ============================================================

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

// ============================================================
// SETTING TILE
// ============================================================

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
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
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null),
      onTap: onTap,
    );
  }
}