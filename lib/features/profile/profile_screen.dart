import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/auth/role.dart';
import '../../../core/router/route_paths.dart';
import '../../../features/favorites/controllers/favorites_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../repositories/reviews_repository.dart';
import '../../../services/seed_service.dart'; // ⚠️ TEMPORARY — يُحذف بعد Seed
import '../../../theme/design_tokens.dart';
import '../../../widgets/confirm_dialog.dart';
import '../../../widgets/ya_app_bar.dart';
import '../auth/controllers/auth_controller.dart';

/// شاشة حسابي:
/// - Guest → بطاقة ترقية الحساب + خروج من الوضع الزائر
/// - User → بيانات + إحصائيات + بطاقات مستقبلية + خروج
///
/// [v1.5 — 2026-10-16] — TEMPORARY: Seed Button
///   - NEW: _TempSeedCard يظهر للمسجلين فقط
///   - ⚠️ يُحذف هذا القسم فوراً بعد تنفيذ Seed
///
/// [v1.4 — 2026-10-14] — G4.1-d: Role Badge
/// [v1.3 — 2026-10-14] — Favorites drill-down
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    // ═══════════════════════════════════════════════════════════
    // GUEST أو غير مسجل
    // ═══════════════════════════════════════════════════════════
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: YaAppBar(title: l10n.profile),
        body: auth.isGuest
            ? _GuestUpgradeCard(
                onLogin: () => context.go(RoutePaths.login),
                onRegister: () => context.go(RoutePaths.register),
                onExitGuest: () => _confirmExitGuest(context, auth),
              )
            : _LoginRequired(
                onLogin: () => context.go(RoutePaths.login),
                onRegister: () => context.go(RoutePaths.register),
              ),
      );
    }

    // ═══════════════════════════════════════════════════════════
    // مستخدم مسجّل
    // ═══════════════════════════════════════════════════════════
    final displayName = auth.displayName ?? '—';

    return Scaffold(
      appBar: YaAppBar(title: l10n.profile),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: YaBaladiDesignTokens.space4,
        ),
        children: [
          // ─── Profile Header (Avatar + Greeting) ───
          _ProfileHeader(
            name: displayName,
            initials: _initials(displayName),
          ),

          // [v1.4 — G4.1-d] Role Badge — يظهر للأدوار المرتفعة فقط
          const SizedBox(height: 8),
          _RoleBadge(role: auth.currentRole),

          const SizedBox(height: YaBaladiDesignTokens.space5),
          const Divider(height: 1),

          // ─── Stats Grid (مفضلة + تقييمات) ───
          const _StatsSection(),
          const Divider(height: 1),

          // ─── نقاط الولاء (قريبًا) ───
          const _LoyaltyComingSoonCard(),

          // ─── دعوة صديق (قريبًا) ───
          const _ReferralComingSoonCard(),

          // ═══════════════════════════════════════════════════════
          // ⚠️ TEMPORARY — Seed Data (يُحذف بعد الـ Seed)
          // ═══════════════════════════════════════════════════════
          const _TempSeedCard(),

          const SizedBox(height: YaBaladiDesignTokens.space4),
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
    final parts = trimmed.trim().split(RegExp(r'\s+'));
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

  /// تأكيد الخروج من الوضع الزائر.
  Future<void> _confirmExitGuest(
    BuildContext context,
    AuthController auth,
  ) async {
    final confirmed = await showYaConfirmDialog(
      context: context,
      title: 'خروج من الوضع الزائر',
      message: 'هل تريد الخروج من وضع الزائر والعودة لصفحة تسجيل الدخول؟',
      confirmLabel: 'خروج',
      cancelLabel: 'إلغاء',
      isDestructive: true,
    );

    if (confirmed == true) {
      await auth.signOut();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// ⚠️ TEMPORARY — SEED CARD (يُحذف بعد الـ Seed)
// ═══════════════════════════════════════════════════════════════

class _TempSeedCard extends StatefulWidget {
  const _TempSeedCard();

  @override
  State<_TempSeedCard> createState() => _TempSeedCardState();
}

class _TempSeedCardState extends State<_TempSeedCard> {
  bool _busy = false;

  Future<void> _runSeed() async {
    if (_busy) return;
    setState(() => _busy = true);

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('⏳ جارٍ الزرع...')),
    );

    try {
      final result = await SeedService().seedAll();
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              '✅ Seed: ${result['categories']} تصنيف + '
              '${result['places']} مكان',
            ),
            duration: const Duration(seconds: 5),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('❌ فشل: $e'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade800,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ إجراء مؤقت — Seed Data',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'هذا الزر يزرع 9 تصنيفات + 12 مكان في Firestore. '
              'يُحذف من الكود بعد نجاح الزرع.',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _runSeed,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload, size: 18),
              label: Text(_busy ? 'جارٍ الزرع…' : 'زرع البيانات الأولية'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ROLE BADGE  [v1.4 — G4.1-d]
// ═══════════════════════════════════════════════════════════════

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    // عضو عادي أو زائر — لا شارة
    if (role == UserRole.member || role == UserRole.visitor) {
      return const SizedBox.shrink();
    }

    final (Color color, IconData icon) = switch (role) {
      UserRole.merchant => (Colors.blue, Icons.storefront),
      UserRole.team => (Colors.teal, Icons.groups),
      UserRole.moderator => (Colors.orange, Icons.verified_user),
      UserRole.manager => (Colors.purple, Icons.admin_panel_settings),
      UserRole.admin => (Colors.red, Icons.shield),
      _ => (Colors.grey, Icons.person),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Chip(
          avatar: Icon(icon, size: 16, color: color),
          label: Text(
            role.labelAr,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          backgroundColor: color.withValues(alpha: 0.1),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GUEST UPGRADE CARD
// ═══════════════════════════════════════════════════════════════

class _GuestUpgradeCard extends StatelessWidget {
  const _GuestUpgradeCard({
    required this.onLogin,
    required this.onRegister,
    required this.onExitGuest,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onExitGuest;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: YaBaladiDesignTokens.space5),
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space5),
          Text(
            isArabic ? 'أنت تتصفّح كزائر' : "You're browsing as guest",
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space2),
          Text(
            isArabic
                ? 'أنشئ حسابًا الآن لحفظ الأماكن المفضلة،\nإضافة تقييماتك، ومتابعة عروض يا بلدي.'
                : 'Create an account to save favorites,\nadd reviews, and follow Ya Baladi offers.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space5),
          _BenefitRow(
            icon: Icons.favorite_border,
            label:
                isArabic ? 'احفظ مفضلتك في أي وقت' : 'Save favorites anytime',
          ),
          const SizedBox(height: YaBaladiDesignTokens.space2),
          _BenefitRow(
            icon: Icons.star_border,
            label: isArabic
                ? 'شارك تقييماتك مع المجتمع'
                : 'Share your reviews with community',
          ),
          const SizedBox(height: YaBaladiDesignTokens.space2),
          _BenefitRow(
            icon: Icons.local_offer_outlined,
            label: isArabic ? 'احصل على عروض حصرية' : 'Get exclusive offers',
          ),
          const SizedBox(height: YaBaladiDesignTokens.space5),
          FilledButton.icon(
            onPressed: onRegister,
            icon: const Icon(Icons.person_add_alt_1),
            label: Text(l10n.registerCta),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: YaBaladiDesignTokens.space3),
          OutlinedButton.icon(
            onPressed: onLogin,
            icon: const Icon(Icons.login),
            label: Text(l10n.login),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          // ═══════════ زر الخروج من الوضع الزائر ═══════════
          const SizedBox(height: YaBaladiDesignTokens.space5),
          const Divider(),
          const SizedBox(height: YaBaladiDesignTokens.space2),
          TextButton.icon(
            onPressed: onExitGuest,
            icon: Icon(
              Icons.logout,
              size: 18,
              color: theme.colorScheme.error,
            ),
            label: Text(
              isArabic ? 'الخروج من الوضع الزائر' : 'Exit guest mode',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 14,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROFILE HEADER
// ═══════════════════════════════════════════════════════════════

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.initials,
  });

  final String name;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    final greeting = isArabic ? 'أهلاً بك يا $name' : 'Welcome, $name';

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            greeting,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATS SECTION
// ═══════════════════════════════════════════════════════════════

class _StatsSection extends StatefulWidget {
  const _StatsSection();

  @override
  State<_StatsSection> createState() => _StatsSectionState();
}

class _StatsSectionState extends State<_StatsSection> {
  final _reviewsRepo = ReviewsRepository();
  Future<int>? _reviewsCountFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final uid = context.read<AuthController>().uid;
      if (uid != null) {
        setState(() {
          _reviewsCountFuture = _reviewsRepo.getCountByUser(uid);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final favorites = context.watch<FavoritesController>();

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
                  value: favorites.count,
                  onTap: () => context.go(RoutePaths.profileFavorites),
                ),
              ),
              const SizedBox(width: YaBaladiDesignTokens.space3),
              Expanded(
                child: FutureBuilder<int>(
                  future: _reviewsCountFuture,
                  builder: (context, snap) {
                    final count = snap.data ?? 0;
                    return _StatCard(
                      icon: Icons.star_border,
                      label: l10n.profileStatsRatings,
                      value: count,
                      onTap: () => context.go(RoutePaths.myReviews),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LOYALTY COMING SOON CARD
// ═══════════════════════════════════════════════════════════════

class _LoyaltyComingSoonCard extends StatelessWidget {
  const _LoyaltyComingSoonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'نقاط الولاء' : 'Loyalty Points',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isArabic ? 'قريبًا' : 'Coming soon',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.lock_outline,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              isArabic
                  ? '🎁 كيف ستكسب نقاطًا من تفاعلك؟'
                  : '🎁 How to earn points from your activity?',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _LoyaltyRuleRow(
              icon: Icons.favorite_border,
              label: isArabic ? 'إضافة مفضلة' : 'Add favorite',
              points: '+10',
            ),
            _LoyaltyRuleRow(
              icon: Icons.star_border,
              label: isArabic ? 'كتابة تقييم' : 'Write review',
              points: '+50',
            ),
            _LoyaltyRuleRow(
              icon: Icons.person_add_outlined,
              label: isArabic ? 'دعوة صديق' : 'Invite friend',
              points: '+100',
            ),
            _LoyaltyRuleRow(
              icon: Icons.calendar_today_outlined,
              label: isArabic ? 'تسجيل دخول يومي' : 'Daily check-in',
              points: '+5',
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoyaltyRuleRow extends StatelessWidget {
  const _LoyaltyRuleRow({
    required this.icon,
    required this.label,
    required this.points,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String points;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            points,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REFERRAL COMING SOON CARD
// ═══════════════════════════════════════════════════════════════

class _ReferralComingSoonCard extends StatelessWidget {
  const _ReferralComingSoonCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.group_add_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        isArabic ? 'دعوة صديق' : 'Invite a friend',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isArabic ? 'قريبًا' : 'Soon',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isArabic
                        ? 'شارك التطبيق مع أصدقائك'
                        : 'Share the app with your friends',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.lock_outline,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
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
  const _LoginRequired({
    required this.onLogin,
    required this.onRegister,
  });

  final VoidCallback onLogin;
  final VoidCallback onRegister;

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
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onLogin,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.login),
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space3),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRegister,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.registerCta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}