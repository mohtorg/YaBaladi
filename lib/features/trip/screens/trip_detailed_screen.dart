// lib/features/trip/screens/trip_detailed_screen.dart
//
// [v1.2 — 2026-10-19] — Wave 5.5.3: زر "إنهاء الرحلة"
//   - NEW: زر أسفل Timeline → تأكيد → updateStatus(completed) → TripSummaryScreen
//   - NEW: progress indicator أثناء الإنهاء
//   - NEW: يخفي الزر إذا كانت الرحلة completed بالفعل
//   - KEPT: TabController + Timeline + error handling + "عرض على الخريطة"
//
// [v1.1 — 2026-10-18] — Robust error handling + empty state
// [v1.0 — 2026-10-18] — Wave 5.4: Trip Detailed Screen
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../models/trip_plan.dart';
import '../../../repositories/trip_repository.dart';
import '../controllers/trip_plans_controller.dart';
import '../widgets/timeline/timeline_view.dart';
import 'trip_summary_screen.dart';

class TripDetailedScreen extends StatefulWidget {
  final String tripId;
  const TripDetailedScreen({super.key, required this.tripId});

  @override
  State<TripDetailedScreen> createState() => _TripDetailedScreenState();
}

class _TripDetailedScreenState extends State<TripDetailedScreen> {
  final _repo = TripRepository();
  late Future<TripPlan?> _future;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.getById(widget.tripId);
  }

  void _reload() {
    setState(() {
      _future = _repo.getById(widget.tripId);
    });
  }

  // ─── [v1.2] إنهاء الرحلة ───
  Future<void> _finishTrip(TripPlan plan) async {
    if (_finishing || plan.id.isEmpty) return;

    // ── تأكيد ──
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الرحلة'),
        content: const Text(
          'هل أنت متأكد من إنهاء الرحلة؟ سيتم نقلك إلى ملخص الرحلة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _finishing = true);

    try {
      // ── 1) تحديث status إلى completed ──
      final ctrl = context.read<TripPlansController>();
      await ctrl.updateStatus(plan.id, TripStatus.completed);

      if (!mounted) return;

      // ── 2) الانتقال إلى ملخص الرحلة ──
      // نستخدم Navigator.pushReplacement — نفس نمط wizard fallback
      // (TripSummaryScreen يستقبل plan مباشرةً عبر constructor)
      final updated = plan.copyWith(status: TripStatus.completed);
      // ignore: unawaited_futures
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (_) => TripSummaryScreen(plan: updated),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل إنهاء الرحلة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<TripPlan?>(
      future: _future,
      builder: (context, snap) {
        // ─── Loading ───
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('الرحلة')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // ─── Error ───
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('الرحلة')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off,
                      size: 64,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تعذّر تحميل الرحلة',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snap.error}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final plan = snap.data;

        // ─── Not found ───
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('الرحلة')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  const Text('الرحلة غير موجودة'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            ),
          );
        }

        // ─── Empty stops ───
        if (plan.stops.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text(plan.title)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 64,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    const Text('لا توجد محطات في هذه الرحلة'),
                    const SizedBox(height: 8),
                    Text(
                      'قد تكون الخطة فارغة أو لم تُحفظ بعد',
                      textAlign: TextAlign.center,
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

        // ─── Success ───
        final days = plan.stopsByDay;
        final tabCount = days.length.clamp(1, 3);
        final titles = List.generate(tabCount, (i) => 'اليوم ${i + 1}');
        final isCompleted = plan.status == TripStatus.completed;

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            appBar: AppBar(
              title: Text(plan.title, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  icon: const Icon(Icons.map),
                  tooltip: 'عرض على الخريطة',
                  onPressed: () {
                    if (plan.firstStop != null) {
                      context.push(
                        RoutePaths.placeMapPath(plan.firstStop!.placeId),
                      );
                    }
                  },
                ),
              ],
              bottom: tabCount > 1
                  ? TabBar(
                      isScrollable: false,
                      tabs: [for (final t in titles) Tab(text: t)],
                      labelColor: theme.colorScheme.primary,
                      indicatorColor: theme.colorScheme.primary,
                    )
                  : null,
            ),
            body: Column(
              children: [
                // ─── Timeline ───
                Expanded(
                  child: tabCount > 1
                      ? TabBarView(
                          children: [
                            for (var i = 0; i < tabCount; i++)
                              TimelineView(
                                stops: days[i],
                                transportMode: plan.transportMode,
                              ),
                          ],
                        )
                      : TimelineView(
                          stops: days.first,
                          transportMode: plan.transportMode,
                        ),
                ),

                // ─── [v1.2] زر "إنهاء الرحلة" (Wave 5.5.3) ───
                if (!isCompleted)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              _finishing ? null : () => _finishTrip(plan),
                          icon: _finishing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.flag_outlined),
                          label: Text(
                            _finishing ? 'جارٍ الإنهاء…' : 'إنهاء الرحلة',
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'رحلة مكتملة',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
