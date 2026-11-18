// lib/features/trip/screens/trip_summary_screen.dart
//
// [v2.1 — 2026-11-15] — LINTER FIX: Added curly braces to all single-line if statements
//   and converted hoursLabel/minutesLabel to final with definite assignment.
// [v2.0 - CELEBRATORY + DARK THEME]
//   - UPDATED: Dark theme (#0F172A) matching the entire trip flow.
//   - ADDED: Entrance animation (fade + scale) for trophy and content.
//   - ADDED: Confetti-style decorative dots (pure Dart, no package).
//   - FIXED: Arabic pluralization for stops/duration.
//   - IMPROVED: _openDetailed now awaits _markTripCompleted() first
//     (guarantees detailed screen shows correct status).
//   - KEPT: _markTripCompleted guard, _backToMyTrips, navigation.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
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
  bool _goingToTrips = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_markTripCompleted());
    });
  }

  Future<void> _markTripCompleted() async {
    if (widget.plan.status == TripStatus.completed) {
      return;
    }
    if (widget.plan.id.isEmpty) {
      return;
    }
    try {
      final ctrl = context.read<TripPlansController>();
      await ctrl.updateStatus(widget.plan.id, TripStatus.completed);
    } on Exception catch (e) {
      debugPrint('Failed to mark trip completed: $e');
    }
  }

  Future<void> _backToMyTrips() async {
    if (_goingToTrips) {
      return;
    }
    setState(() => _goingToTrips = true);
    await _markTripCompleted();
    if (!mounted) {
      return;
    }
    context.go(RoutePaths.trips);
  }

  Future<void> _openDetailed() async {
    final id = widget.plan.id;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('معرف الرحلة غير متوفر')),
      );
      return;
    }
    // Ensure status is synced before opening detailed (consistency).
    await _markTripCompleted();
    if (!mounted) {
      return;
    }
    context.push(RoutePaths.tripDetailedPath(id));
  }

  /// Arabic pluralization for stops.
  String _arabicStops(int n) {
    if (n == 1) {
      return 'محطة واحدة';
    }
    if (n == 2) {
      return 'محطتان';
    }
    if (n >= 3 && n <= 10) {
      return '$n محطات';
    }
    return '$n محطة';
  }

  /// Arabic duration: "ساعة واحدة" / "ساعتان" / "3 ساعات و 15 دقيقة".
  String _arabicDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;

    // ✅ Linter Fix: final with definite assignment
    final String hoursLabel;
    if (h == 0) {
      hoursLabel = '';
    } else if (h == 1) {
      hoursLabel = 'ساعة واحدة';
    } else if (h == 2) {
      hoursLabel = 'ساعتان';
    } else if (h <= 10) {
      hoursLabel = '$h ساعات';
    } else {
      hoursLabel = '$h ساعة';
    }

    // ✅ Linter Fix: final with definite assignment
    final String minutesLabel;
    if (m == 0) {
      minutesLabel = '';
    } else if (m == 1) {
      minutesLabel = 'دقيقة';
    } else if (m == 2) {
      minutesLabel = 'دقيقتان';
    } else if (m <= 10) {
      minutesLabel = '$m دقائق';
    } else {
      minutesLabel = '$m دقيقة';
    }

    if (hoursLabel.isEmpty && minutesLabel.isEmpty) {
      return '0 دقيقة';
    }
    if (hoursLabel.isEmpty) {
      return minutesLabel;
    }
    if (minutesLabel.isEmpty) {
      return hoursLabel;
    }
    return '$hoursLabel و $minutesLabel';
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      child: Builder(
        builder: (innerCtx) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'نهاية الرحلة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: Stack(
              children: [
                // ─── Decorative confetti dots ───
                const Positioned.fill(child: _ConfettiBackground()),

                // ─── Main content ───
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (c, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 24 * (1 - v)),
                          child: child,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Trophy with scale-in animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.5, end: 1),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.elasticOut,
                            builder: (c, v, child) => Transform.scale(
                              scale: v,
                              child: child,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.amber.withValues(alpha: 0.3),
                                    Colors.amber.withValues(alpha: 0.05),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.emoji_events,
                                size: 110,
                                color: Colors.amber,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'رحلة رائعة!',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لقد أكملت رحلتك إلى ${plan.governorateNameAr} بنجاح.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ─── Stats Card ───
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatColumn(
                                  icon: Icons.place_outlined,
                                  label: 'المحطات',
                                  value: _arabicStops(plan.stopCount),
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                _StatColumn(
                                  icon: Icons.route_outlined,
                                  label: 'المسافة',
                                  value:
                                      '${plan.totalDistanceKm.toStringAsFixed(0)} كم',
                                ),
                                Container(
                                  width: 1,
                                  height: 50,
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                _StatColumn(
                                  icon: Icons.schedule,
                                  label: 'المدة',
                                  value: _arabicDuration(plan.totalDurationMin),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ─── Actions ───
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _openDetailed,
                              icon: const Icon(Icons.timeline, size: 22),
                              label: const Text(
                                'عرض التفاصيل',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: const Color(0xFF0EA5E9),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
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
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white70),
                                    )
                                  : const Icon(Icons.list_alt, size: 20),
                              label: Text(
                                _goingToTrips ? 'جارٍ…' : 'العودة إلى رحلاتي',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

// ═══════════════════════════════════════════════════════════════
// STAT COLUMN
// ═══════════════════════════════════════════════════════════════

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF0EA5E9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFETTI BACKGROUND (Pure Dart, no package)
// ═══════════════════════════════════════════════════════════════

class _ConfettiBackground extends StatelessWidget {
  const _ConfettiBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Deterministic "random" dots based on position.
    final colors = [
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFFA855F7),
    ];
    final paint = Paint()..style = PaintingStyle.fill;

    final rng = math.Random(42); // Fixed seed → stable, no flicker
    for (var i = 0; i < 22; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = 2.0 + rng.nextDouble() * 4.0;
      final color = colors[i % colors.length];
      paint.color = color.withValues(alpha: 0.15 + rng.nextDouble() * 0.15);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
