// lib/features/trip/screens/trip_detailed_screen.dart
// [v1.3 — 2026-10-20] — AppBar uses LocationActionIcon.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/trip_plan.dart';
import '../../../repositories/trip_repository.dart';
import '../../../widgets/location_actions.dart';
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
    setState(() => _future = _repo.getById(widget.tripId));
  }

  Future<void> _finishTrip(TripPlan plan) async {
    if (_finishing || plan.id.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الرحلة'),
        content: const Text('هل أنت متأكد من إنهاء الرحلة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('إلغاء')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('إنهاء')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _finishing = true);
    try {
      final ctrl = context.read<TripPlansController>();
      await ctrl.updateStatus(plan.id, TripStatus.completed);
      if (!mounted) return;
      final updated = plan.copyWith(status: TripStatus.completed);
      // ignore: unawaited_futures
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
            builder: (_) => TripSummaryScreen(plan: updated)),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل إنهاء الرحلة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<TripPlan?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
              appBar: AppBar(title: const Text('الرحلة')),
              body: const Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('الرحلة')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off,
                      size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  const Text('تعذّر تحميل الرحلة'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة المحاولة')),
                ],
              ),
            ),
          );
        }
        final plan = snap.data;
        if (plan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('الرحلة')),
            body: const Center(child: Text('الرحلة غير موجودة')),
          );
        }

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
                // ✅ أيقونة صغيرة أنيقة
                if (plan.firstStop != null)
                  LocationActionIcon(
                    lat: plan.firstStop!.lat,
                    lng: plan.firstStop!.lng,
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
                Expanded(
                  child: tabCount > 1
                      ? TabBarView(
                          children: [
                            for (var i = 0; i < tabCount; i++)
                              TimelineView(
                                  stops: days[i],
                                  transportMode: plan.transportMode),
                          ],
                        )
                      : TimelineView(
                          stops: days.first, transportMode: plan.transportMode),
                ),
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
                                      strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.flag_outlined),
                          label: Text(
                              _finishing ? 'جارٍ الإنهاء…' : 'إنهاء الرحلة',
                              style: const TextStyle(fontSize: 16)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            ),
          ),
        );
      },
    );
  }
}
