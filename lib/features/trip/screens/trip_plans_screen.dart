// lib/features/trip/screens/trip_plans_screen.dart
//
// [v1.2 — 2026-10-15] — إصلاح ومضة _EmptyView
//   - FIX: إضافة _firstLoadDone لمنع عرض EmptyView قبل انتهاء أول load()
//   - FIX: initState ينتظر انتهاء load() ثم يرفع العلم
//   - REFACTOR: _onRefresh يستخدم early return
//
// [v1.1 — 2026-10-15] — _openDetails ينتقل لـ TripDetailsScreen
//   - FIX: _openDetails كان SnackBar — الآن context.push
//
// [v1.0 — 2026-10-15] — G6.7: TripPlansScreen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/trip_plan.dart';
import '../../../theme/design_tokens.dart';
import '../../../widgets/ya_app_bar.dart';
import '../controllers/trip_plans_controller.dart';

class TripPlansScreen extends StatefulWidget {
  const TripPlansScreen({super.key});

  @override
  State<TripPlansScreen> createState() => _TripPlansScreenState();
}

class _TripPlansScreenState extends State<TripPlansScreen> {
  /// [v1.2] يمنع ومضة _EmptyView قبل انتهاء أول load()
  /// (status == idle في Frame 1 كان يُعرض كـ "لا توجد رحلات")
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final uid = context.read<AuthController>().uid;
      if (uid != null) {
        await context.read<TripPlansController>().load(uid);
      }

      if (!mounted) return;
      setState(() => _firstLoadDone = true);
    });
  }

  void _onAddTrip() {
    context.go(RoutePaths.tripPlanner);
  }

  Future<void> _onRefresh() async {
    final uid = context.read<AuthController>().uid;
    if (uid == null) return;
    await context.read<TripPlansController>().load(uid, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final tripCtrl = context.watch<TripPlansController>();

    return Scaffold(
      appBar: YaAppBar(
        title: l10n.tripsTitle,
        actions: [
          if (auth.isLoggedIn)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'رحلة جديدة',
              onPressed: _onAddTrip,
            ),
        ],
      ),
      body: _buildBody(auth, tripCtrl),
      floatingActionButton: auth.isLoggedIn && tripCtrl.hasPlans
          ? FloatingActionButton.extended(
              onPressed: _onAddTrip,
              icon: const Icon(Icons.add),
              label: const Text('رحلة جديدة'),
            )
          : null,
    );
  }

  Widget _buildBody(AuthController auth, TripPlansController tripCtrl) {
    // ─── Guest → Empty state ───
    if (!auth.isLoggedIn) {
      return _GuestView(onLogin: () => context.go(RoutePaths.login));
    }

    // ─── Loading (يغطي idle + أول تحميل + أي تحميل لاحق) ───
    if (!_firstLoadDone || (tripCtrl.isLoading && tripCtrl.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    // ─── Error ───
    if (tripCtrl.hasError && tripCtrl.isEmpty) {
      return _ErrorView(
        message: tripCtrl.error ?? 'حدث خطأ',
        onRetry: _onRefresh,
      );
    }

    // ─── Empty ───
    if (tripCtrl.isEmpty) {
      return _EmptyView(onAdd: _onAddTrip);
    }

    // ─── List ───
    final upcoming = tripCtrl.upcomingPlans;
    final completed = tripCtrl.completedPlans;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        children: [
          if (upcoming.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.upcoming_outlined,
              title: 'الرحلات القادمة',
              count: upcoming.length,
            ),
            for (final plan in upcoming) ...[
              _TripCard(plan: plan),
              const SizedBox(height: YaBaladiDesignTokens.space2),
            ],
            const SizedBox(height: YaBaladiDesignTokens.space3),
          ],

          if (completed.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.history,
              title: 'الرحلات المكتملة',
              count: completed.length,
            ),
            for (final plan in completed) ...[
              _TripCard(plan: plan, isPast: true),
              const SizedBox(height: YaBaladiDesignTokens.space2),
            ],
          ],

          // Fallback: لا رحلات في أي قسم
          if (upcoming.isEmpty && completed.isEmpty) ...[
            for (final plan in tripCtrl.plans) ...[
              _TripCard(plan: plan),
              const SizedBox(height: YaBaladiDesignTokens.space2),
            ],
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRIP CARD
// ═══════════════════════════════════════════════════════════════

class _TripCard extends StatelessWidget {
  const _TripCard({required this.plan, this.isPast = false});

  final TripPlan plan;
  final bool isPast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(YaBaladiDesignTokens.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StatusChip(status: plan.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    plan.governorateNameAr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.stopCount} محطات',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${plan.totalDistanceKm.toStringAsFixed(0)} كم',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    plan.durationLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (plan.startDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(plan.startDate!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],

              // ─── زر التفاصيل ───
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _openDetails(context),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('عرض الرحلة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [v1.1] الانتقال لـ TripDetailsScreen
  void _openDetails(BuildContext context) {
    if (plan.id.isEmpty) return;
    context.push(RoutePaths.tripDetailsPath(plan.id));
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════
// STATUS CHIP
// ═══════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color color, IconData icon) = switch (status) {
      TripStatus.draft => (Colors.grey, Icons.edit_outlined),
      TripStatus.active => (Colors.green, Icons.play_arrow),
      TripStatus.completed => (Colors.blue, Icons.check_circle_outline),
      TripStatus.cancelled => (Colors.red, Icons.cancel_outlined),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.labelAr,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY VIEW
// ═══════════════════════════════════════════════════════════════

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.explore_outlined,
              size: 96,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space4),
            Text(
              'ابدأ رحلتك الأولى',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space2),
            Text(
              'خطط رحلة مخصصة لاستكشاف أماكن جديدة،\nسنقترح عليك أفضل الأماكن حسب اهتماماتك.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space5),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('خطط رحلتي'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GUEST VIEW
// ═══════════════════════════════════════════════════════════════

class _GuestView extends StatelessWidget {
  const _GuestView({required this.onLogin});

  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: YaBaladiDesignTokens.space4),
            Text(
              'سجّل دخولك لتخطيط الرحلات',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space2),
            Text(
              'هذه الميزة تحتاج حساباً لحفظ رحلاتك',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space5),
            FilledButton.icon(
              onPressed: onLogin,
              icon: const Icon(Icons.login),
              label: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ERROR VIEW
// ═══════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}