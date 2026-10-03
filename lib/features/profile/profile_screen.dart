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

    // === Back Button في AppBar (يظهر في Home وليس في Auth) ===
    final appBar = AppBar(
      title: Text(l10n.profile),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: l10n.home,
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(RoutePaths.home);
          }
        },
      ),
    );

    // غير مسجل → دعوة لتسجيل الدخول
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: appBar,
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

    // === مسجل → بيانات المستخدم ===
    final displayName = auth.displayName ?? '—';
    final email = auth.email ?? '—';

    return Scaffold(
      appBar: appBar,
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: YaBaladiDesignTokens.space4,
        ),
        children: [
          // === Avatar + Name + Email ===
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _initials(displayName),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space3),

          Center(
            child: Text(
              displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space1),

          Center(
            child: Text(
              email,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space3),

          // === Chip: Governorate ===
          Center(
            child: Chip(
              avatar: Icon(
                Icons.location_on_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: Text(l10n.profileGovernorateUnknown),
            ),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space5),
          const Divider(height: 1),

          // === Stats Grid ===
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: YaBaladiDesignTokens.space4,
              vertical: YaBaladiDesignTokens.space4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: YaBaladiDesignTokens.space2,
                    bottom: YaBaladiDesignTokens.space3,
                  ),
                  child: Text(
                    l10n.profileActivity,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.favorite_border,
                        label: l10n.profileStatsFavorites,
                        value: 0,
                      ),
                    ),
                    const SizedBox(width: YaBaladiDesignTokens.space3),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.star_border,
                        label: l10n.profileStatsRatings,
                        value: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.storefront_outlined,
                        label: l10n.profileStatsPlaces,
                        value: 0,
                      ),
                    ),
                    const SizedBox(width: YaBaladiDesignTokens.space3),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.photo_outlined,
                        label: l10n.profileStatsPhotos,
                        value: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // === Logout ===
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              l10n.logout,
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmLogout(context, auth),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space4),
        ],
      ),
    );
  }

  String _initials(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty || trimmed == '—') return '؟';
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
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
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

/// بطاقة إحصائية واحدة (مفضلة / تقييمات / أماكني / صوري)
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(YaBaladiDesignTokens.space3),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(height: YaBaladiDesignTokens.space2),
            Text(
              '$value',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space1),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}