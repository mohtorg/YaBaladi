// lib/features/trip/screens/trip_summary_screen.dart
//
// [v2.0 — 2026-10-18] — Clipboard-based URL sharing
//   - CHANGED: dart:html → Clipboard (works everywhere: Web + Mobile + Tests)
//   - FIX: flutter test لا يفشل بعد الآن
//   - KEPT: auto-mark trip as completed
//   - KEPT: trip stats (stops/distance/duration)
//   - KEPT: "العودة إلى رحلاتي" uses context.go('/trips')
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../models/trip_plan.dart';
import '../controllers/trip_plans_controller.dart';

class TripSummaryScreen extends StatefulWidget {
  final TripPlan plan;
  const TripSummaryScreen({super.key, required this.plan});

  @override
  State<TripSummaryScreen> createState() => _TripSummaryScreenState();
}

class _TripSummaryScreenState extends State<TripSummaryScreen> {
  bool _copying = false;
  bool _goingToTrips = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markTripCompleted();
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

  Future<void> _copyHomeLink() async {
    if (_copying) return;
    setState(() => _copying = true);

    try {
      await Clipboard.setData(
        const ClipboardData(
          text: 'https://www.google.com/maps/dir/?api=1&destination=home',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'تم نسخ رابط العودة للمنزل — الصقه في المتصفح',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _backToMyTrips() async {
    if (_goingToTrips) return;
    setState(() => _goingToTrips = true);

    await _markTripCompleted();

    if (!mounted) return;
    context.go(RoutePaths.trips);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = widget.plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'نهاية الرحلة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 120,
                  color: Colors.amber,
                ),
                const SizedBox(height: 24),
                const Text(
                  '🎉 رحلة رائعة!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'لقد أكملت رحلتك إلى ${plan.governorateNameAr} بنجاح.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatColumn(
                        icon: Icons.place_outlined,
                        label: 'محطات',
                        value: '${plan.stopCount}',
                      ),
                      _StatColumn(
                        icon: Icons.route_outlined,
                        label: 'مسافة',
                        value: '${plan.totalDistanceKm.toStringAsFixed(0)} كم',
                      ),
                      _StatColumn(
                        icon: Icons.schedule,
                        label: 'مدة',
                        value: plan.durationLabel,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _copying ? null : _copyHomeLink,
                    icon: _copying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.home, size: 24),
                    label: Text(
                      _copying ? 'جارٍ النسخ…' : 'انسخ رابط العودة للمنزل',
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.colorScheme.primary,
                    ),
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.list_alt, size: 20),
                    label: Text(
                      _goingToTrips ? 'جارٍ…' : 'العودة إلى رحلاتي',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
  const _StatColumn({
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
        Icon(icon, color: theme.colorScheme.primary, size: 26),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
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
