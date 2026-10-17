// lib/features/trip/screens/trip_details_screen.dart
//
// [v1.1 — 2026-10-15] — إصلاح "الرحلة غير موجودة"
//   - FIX: _loadPlan أصبح async ويستدعي ctrl.load(uid) إذا لم يجد الخطة
//   - FIX: _markAsCompleted يُحدّث _plan المحلية بعد النجاح
//   - FIX: حماية mounted في كل await
//
// [v1.0.1 — 2026-10-15] — Removed url_launcher dependency (cache fix)
//   - FIX: إزالة import url_launcher
//   - CHANGE: _openDirections → SnackBar مؤقت
//
// [v1.0 — 2026-10-15] — G6.7: TripDetailsScreen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/trip_plan.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/trip_plans_controller.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  TripPlan? _plan;
  bool _loading = true;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadPlan();
    });
  }

  /// [v1.1] يحاول أولاً من الذاكرة، ثم يحمّل من Firestore إن لزم.
  Future<void> _loadPlan() async {
    final ctrl = context.read<TripPlansController>();
    final auth = context.read<AuthController>();

    // ─── 1. ابحث في الذاكرة ───
    var plan = ctrl.plans.where((p) => p.id == widget.tripId).firstOrNull;

    // ─── 2. إن لم نجد → حمّل من Firestore ───
    if (plan == null) {
      final uid = auth.uid;
      if (uid != null) {
        try {
          await ctrl.load(uid, force: true);
        } catch (_) {
          // تجاهل — ستُعرض "غير موجودة" إذا لم تُوجد لاحقاً
        }
        if (!mounted) return;
        plan = ctrl.plans.where((p) => p.id == widget.tripId).firstOrNull;
      }
    }

    if (!mounted) return;
    setState(() {
      _plan = plan;
      _loading = false;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  /// [v1.0.1] مؤقتاً — SnackBar بدل فتح الخرائط.
  /// يستخدم `url_launcher` عند إعادة الحزمة.
  Future<void> _openDirections(TripStop stop) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('الاتجاهات إلى ${stop.placeNameAr} — قريباً'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _openPlace(TripStop stop) {
    if (stop.placeId.isEmpty) return;
    context.push(RoutePaths.placePath(stop.placeId));
  }

  Future<void> _confirmDelete() async {
    final plan = _plan;
    if (plan == null) return;

    final ctrl = context.read<TripPlansController>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) {
        final theme = Theme.of(dctx);
        return AlertDialog(
          icon: Icon(
            Icons.delete_forever,
            color: theme.colorScheme.error,
            size: 32,
          ),
          title: const Text('حذف الرحلة'),
          content: Text(
            'هل أنت متأكد من حذف "${plan.title}"؟\n'
            'لا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              onPressed: () => Navigator.of(dctx).pop(true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _actionInProgress = true);
    final ok = await ctrl.delete(plan.id);
    if (!mounted) return;

    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تم حذف الرحلة')),
        );
      // ارجع لشاشة "رحلتي"
      if (router.canPop()) {
        router.pop();
      } else {
        router.go(RoutePaths.trips);
      }
    } else {
      setState(() => _actionInProgress = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(ctrl.error ?? 'تعذّر الحذف')),
        );
    }
  }

  Future<void> _markAsCompleted() async {
    final plan = _plan;
    if (plan == null) return;
    if (plan.status == TripStatus.completed) return;

    final ctrl = context.read<TripPlansController>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _actionInProgress = true);
    final ok = await ctrl.updateStatus(plan.id, TripStatus.completed);
    if (!mounted) return;

    if (ok) {
      // [v1.1] حدّث _plan المحلية من الـ controller
      final updated = ctrl.plans.where((p) => p.id == plan.id).firstOrNull;
      setState(() {
        _actionInProgress = false;
        if (updated != null) _plan = updated;
      });
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('✅ تم إكمال الرحلة')),
        );
    } else {
      setState(() => _actionInProgress = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(ctrl.error ?? 'تعذّر التحديث')),
        );
    }
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.trips);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        title: Text(_plan?.title ?? 'تفاصيل الرحلة'),
        actions: [
          if (_plan != null && !_actionInProgress)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'حذف',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final plan = _plan;
    if (plan == null) {
      return _EmptyView(onBack: _onBack);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        _HeaderCard(plan: plan),
        const SizedBox(height: YaBaladiDesignTokens.space3),
        _StatsCard(plan: plan),
        const SizedBox(height: YaBaladiDesignTokens.space4),

        // ─── خط السير ───
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'خط السير',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: YaBaladiDesignTokens.space2),
        ...plan.stops.asMap().entries.map((entry) {
          final idx = entry.key;
          final stop = entry.value;
          return _StopDetailsCard(
            index: idx + 1,
            stop: stop,
            isLast: idx == plan.stops.length - 1,
            onDirections: () => _openDirections(stop),
            onOpenPlace: () => _openPlace(stop),
          );
        }),

        const SizedBox(height: YaBaladiDesignTokens.space5),

        // ─── إجراءات ───
        if (plan.status != TripStatus.completed)
          FilledButton.icon(
            onPressed: _actionInProgress ? null : _markAsCompleted,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('إكمال الرحلة'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _actionInProgress ? null : _confirmDelete,
          icon: Icon(
            Icons.delete_outline,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          label: Text(
            'حذف الرحلة',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: BorderSide(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER CARD
// ═══════════════════════════════════════════════════════════════

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusChip(status: plan.status),
                const Spacer(),
                Text(
                  plan.transportMode.labelAr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  plan.governorateNameAr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  plan.dateRangeLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (plan.isMultiDay) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${plan.durationInDays} أيام',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.labelAr,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATS CARD
// ═══════════════════════════════════════════════════════════════

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.plan});

  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.place_outlined,
            label: 'محطات',
            value: '${plan.stopCount}',
          ),
          _StatItem(
            icon: Icons.route_outlined,
            label: 'المسافة',
            value: '${plan.totalDistanceKm.toStringAsFixed(0)} كم',
          ),
          _StatItem(
            icon: Icons.schedule,
            label: 'المدة',
            value: plan.durationLabel,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STOP DETAILS CARD
// ═══════════════════════════════════════════════════════════════

class _StopDetailsCard extends StatelessWidget {
  const _StopDetailsCard({
    required this.index,
    required this.stop,
    required this.isLast,
    required this.onDirections,
    required this.onOpenPlace,
  });

  final int index;
  final TripStop stop;
  final bool isLast;
  final VoidCallback onDirections;
  final VoidCallback onOpenPlace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = stop.plannedArrival;
    final timeLabel = time == null
        ? '--:--'
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── العمود: رقم + خط ───
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 120,
                color: theme.colorScheme.outlineVariant,
              ),
          ],
        ),
        const SizedBox(width: 12),

        // ─── البطاقة ───
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : YaBaladiDesignTokens.space3,
            ),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(YaBaladiDesignTokens.space3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── الوقت + الاسم ───
                    Row(
                      children: [
                        Text(
                          timeLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            stop.placeNameAr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // ─── نجوم + مدة ───
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 3),
                        Text(
                          stop.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 3),
                        Text(
                          '${stop.plannedDurationMin ?? 0} د',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),

                    // ─── الأزرار ───
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onDirections,
                            icon:
                                const Icon(Icons.directions_outlined, size: 16),
                            label: const Text(
                              'الاتجاهات',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: onOpenPlace,
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text(
                              'عرض المكان',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY VIEW
// ═══════════════════════════════════════════════════════════════

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onBack});

  final VoidCallback onBack;

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
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'الرحلة غير موجودة',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ربما حُذفت من مكان آخر',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('العودة لرحلاتي'),
            ),
          ],
        ),
      ),
    );
  }
}
