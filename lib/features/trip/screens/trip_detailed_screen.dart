// lib/features/trip/screens/trip_detailed_screen.dart
//
// [v2.0 - DARK THEME + LOGIC FIX]
//   - FIXED: Days are no longer clamped to 3. Now supports unlimited days.
//   - FIXED: Dark theme wrapper forces TimelineView to adapt.
//   - UPDATED: Finish button uses brand colors and rounded corners.
//   - KEPT: All reload, error, empty, and finish logic.

import 'dart:async';

import 'package:flutter/material.dart';
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
        backgroundColor: const Color(0xFF1E293B),
        title:
            const Text('إنهاء الرحلة', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من إنهاء الرحلة؟',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981)),
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

      unawaited(
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
              builder: (_) => TripSummaryScreen(plan: updated)),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('فشل إنهاء الرحلة: $e'),
            backgroundColor: const Color(0xFFEF4444)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ تغليف الشاشة بالكامل بثيم داكن لإجبار TimelineView على التكيف
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0EA5E9),
          surface: Color(0xFF1E293B),
        ),
      ),
      child: Builder(
        builder: (innerContext) {
          return FutureBuilder<TripPlan?>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  appBar: AppBar(title: const Text('الرحلة')),
                  body: const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF0EA5E9))),
                );
              }
              if (snap.hasError) {
                return Scaffold(
                  appBar: AppBar(title: const Text('الرحلة')),
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 64, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        const Text('تعذّر تحميل الرحلة',
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('إعادة المحاولة'),
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0EA5E9))),
                      ],
                    ),
                  ),
                );
              }

              final plan = snap.data;
              if (plan == null) {
                return Scaffold(
                  appBar: AppBar(title: const Text('الرحلة')),
                  body: const Center(
                      child: Text('الرحلة غير موجودة',
                          style: TextStyle(color: Colors.white))),
                );
              }

              final days = plan.stopsByDay;

              if (days.isEmpty) {
                return Scaffold(
                  appBar: AppBar(title: Text(plan.title)),
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map_outlined,
                            size: 64, color: Colors.white54),
                        const SizedBox(height: 16),
                        const Text('لا توجد محطات في هذه الرحلة',
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('العودة'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9)),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ✅ إزالة clamp(1, 3) لدعم أي عدد من الأيام
              final tabCount = days.length;
              final titles = List.generate(tabCount, (i) => 'اليوم ${i + 1}');
              final isCompleted = plan.status == TripStatus.completed;

              return DefaultTabController(
                length: tabCount,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(plan.title, overflow: TextOverflow.ellipsis),
                    actions: [
                      if (plan.firstStop != null)
                        LocationActionIcon(
                          lat: plan.firstStop!.lat,
                          lng: plan.firstStop!.lng,
                        ),
                    ],
                    bottom: tabCount > 1
                        ? TabBar(
                            isScrollable: true, // ✅ لدعم أي عدد من التبويبات
                            tabs: [for (final t in titles) Tab(text: t)],
                            labelColor: const Color(0xFF0EA5E9),
                            unselectedLabelColor: Colors.white60,
                            indicatorColor: const Color(0xFF0EA5E9),
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
                                stops: days.first,
                                transportMode: plan.transportMode),
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
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(Icons.flag_outlined),
                                label: Text(
                                    _finishing
                                        ? 'جارٍ الإنهاء…'
                                        : 'إنهاء الرحلة',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: const Color(0xFF10B981),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
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
        },
      ),
    );
  }
}
