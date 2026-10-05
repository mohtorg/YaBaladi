import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/design_tokens.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/ya_app_bar.dart';
import '../auth/controllers/auth_controller.dart';

/// شاشة حسابي:
/// - بيانات المستخدم (Avatar + Name + Email + Governorate)
/// - زر تعديل الملف الشخصي
/// - إحصائيات (مفضلة / تقييمات / أماكني / صوري)
/// - تسجيل الخروج
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    // === غير مسجل → دعوة لتسجيل الدخول ===
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: YaAppBar(title: l10n.profile),
        body: _LoginRequired(onLogin: () => context.go(RoutePaths.login)),
      );
    }

    final displayName = auth.displayName ?? '—';
    final email = auth.email ?? '—';

    return Scaffold(
      appBar: YaAppBar(title: l10n.profile),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: YaBaladiDesignTokens.space4,
        ),
        children: [
          // ─── Header: Avatar + Name + Email ───
          _ProfileHeader(
            name: displayName,
            email: email,
            initials: _initials(displayName),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space3),

          // ─── Governorate Chip ───
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

          const SizedBox(height: YaBaladiDesignTokens.space3),

          // ─── Edit Profile Button ───
          Center(
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO(G4): edit profile screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('قريبًا')),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('تعديل الملف الشخصي'),
            ),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space5),
          const Divider(height: 1),

          // ─── Stats Grid ───
          _StatsSection(),
          const Divider(height: 1),

          // ─── Logout ───
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

  static String _initials(String input) {
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
    final confirmed = await showYaConfirmDialog(
      context: context,
      title: l10n.logoutConfirmTitle,
      message: l10n.logoutConfirmMessage,
      confirmLabel: l10n.confirm,
      cancelLabel: l10n.cancel,
      isDestructive: true,
    );

    if (confirmed == true) {
      await auth.signOut();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PROFILE HEADER
// ═══════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.initials,
  });

  final String name;
  final String email;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            initials,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: YaBaladiDesignTokens.space3),
        Text(
          name,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: YaBaladiDesignTokens.space1),
        Text(
          email,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATS SECTION
// ═══════════════════════════════════════════════════════════════

class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STAT CARD
// ═══════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════
// LOGIN REQUIRED
// ═══════════════════════════════════════════════════════════════

class _LoginRequired extends StatelessWidget {
  const _LoginRequired({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
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
              onPressed: onLogin,
              child: Text(l10n.login),
            ),
          ],
        ),
      ),
    );
  }
}