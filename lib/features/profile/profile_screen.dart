import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/design_tokens.dart';
import '../auth/controllers/auth_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    // غير مسجل → دعوة لتسجيل الدخول
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.profile)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 72,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: YaBaladiDesignTokens.space4),
                Text(
                  l10n.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: YaBaladiDesignTokens.space5),
                FilledButton(
                  onPressed: () => context.go(RoutePaths.login),
                  child: Text(l10n.login),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // مسجل → بيانات المستخدم
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profile)),
      body: ListView(
        padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _initials(auth.displayName ?? auth.email ?? '؟'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space4),

          Center(
            child: Text(
              auth.displayName ?? '—',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space2),

          Center(
            child: Text(
              auth.email ?? '—',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space6),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.favorite_border),
            title: Text(l10n.favorites),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(RoutePaths.favorites),
          ),

          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settings),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(RoutePaths.settings),
          ),

          const Divider(),

          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              l10n.logout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmLogout(context, auth),
          ),
        ],
      ),
    );
  }

  String _initials(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return '؟';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Future<void> _confirmLogout(
    BuildContext context,
    AuthController auth,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await auth.signOut();
    }
  }
}