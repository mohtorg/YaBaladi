// lib/features/trip/screens/trip_summary_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../models/trip_plan.dart';
import '../controllers/trip_plans_controller.dart';
// ملاحظة: هنا نحتاج إحداثيات المنزل. إذا لم تكن متوفرة، نترك النسخ كخيار بديل.
// import '../../../services/map_service.dart';
// import '../../../core/location/browsing_location_controller.dart';

class TripSummaryScreen extends StatefulWidget {
  final TripPlan plan;
  const TripSummaryScreen({super.key, required this.plan});

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  bool _goingToTrips = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_markTripCompleted());
    });
  }

  Future<void> _markTripCompleted() async {
    if (widget.plan.status == TripStatus.completed) return;
    if (widget.plan.id.isEmpty) return;
    try {
      final ctrl = context.read<TripPlansController>();
      await ctrl.updateStatus(widget.plan.id, TripStatus.completed);
    } on Exception catch (e) {
      debugPrint('Failed to mark trip completed: $e');
    }
  }

  Future<void> _backToMyTrips() async {
    if (_goingToTrips) return;
    setState(() => _goingToTrips = true);
    await _markTripCompleted();
    if (!mounted) return;
    context.go(RoutePaths.trips);
  }

  void _openDetailed() {
    final id = widget.plan.id;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('معرف الرحلة غير متوفر')));
      return;
    }
    context.push(RoutePaths.tripDetailedPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;

    return Scaffold(
      appBar: AppBar(
          title: const Text('نهاية الرحلة'),
          centerTitle: true,
          automaticallyImplyLeading: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 120, color: Colors.amber),
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, size: 36, color: Colors.amber),
                    SizedBox(width: 12),
                    Text('رحلة رائعة!',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('لقد أكملت رحلتك إلى ${plan.governorateNameAr} بنجاح.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, color: Colors.grey)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                          icon: Icons.place_outlined,
                          label: 'محطات',
                          value: '${plan.stopCount}'),
                      _StatColumn(
                          icon: Icons.route_outlined,
                          label: 'مسافة',
                          value:
                              '${plan.totalDistanceKm.toStringAsFixed(0)} كم'),
                      _StatColumn(
                          icon: Icons.schedule,
                          label: 'مدة',
                          value: plan.durationLabel),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openDetailed,
                    icon: const Icon(Icons.timeline, size: 22),
                    label: const Text('عرض التفاصيل',
                        style: TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _goingToTrips ? null : _backToMyTrips,
                    icon: _goingToTrips
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.list_alt, size: 20),
                    label: Text(_goingToTrips ? 'جارٍ…' : 'العودة إلى رحلاتي',
                        style: const TextStyle(fontSize: 16)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 26),
        const SizedBox(height: 6),
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer)),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.8))),
      ],
    );
  }
}
