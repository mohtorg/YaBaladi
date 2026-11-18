// lib/features/trip/screens/trip_overview_screen.dart
//
// [v2.1 - LINGUISTIC & INTERACTION POLISH]
//   - FIXED: Arabic plural for days count (يوم/يومان/أيام/يوماً).
//   - IMPROVED: Day chips wrapped in Material + InkWell (real ink feedback).
//   - ADDED: Semantics labels for accessibility.
//   - KEPT: All v2.0 logic, safety guards, and dark theme.
//
// ⚠️ MODEL LIMITATION (out of scope for this file):
//   TripPlan.totalDays currently caps at 2 (weekend). A 5-day trip
//   will display as 2 days in this screen. Consider updating the
//   model to derive totalDays from startDate/endDate when available.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../models/trip_plan.dart';
import '../widgets/timeline/timeline_view.dart';

class TripOverviewScreen extends StatefulWidget {
  final TripPlan plan;

  const TripOverviewScreen({super.key, required this.plan});

  @override
  State<TripOverviewScreen> createState() => _TripOverviewScreenState();
}

class _TripOverviewScreenState extends State<TripOverviewScreen> {
  int _selectedDay = 1;

  /// Correct Arabic pluralization for days.
  String _pluralizeDays(int n) {
    if (n == 1) return 'يوم واحد';
    if (n == 2) return 'يومان';
    if (n >= 3 && n <= 10) return '$n أيام';
    return '$n يوماً';
  }

  void _openDetailed() {
    final id = widget.plan.id;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن عرض التفاصيل: معرف الرحلة غير متوفر'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    context.push(RoutePaths.tripDetailedPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    final totalDays = plan.totalDays;
    final hasStops = plan.stopsByDay.isNotEmpty;

    final safeDay = totalDays > 0 ? _selectedDay.clamp(1, totalDays) : 1;
    final dayIndex =
        hasStops ? (safeDay - 1).clamp(0, plan.stopsByDay.length - 1) : 0;
    final displayTitle = plan.title.isEmpty ? 'رحلتي' : plan.title;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ملخص الرحلة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'عرض التفاصيل الكاملة',
            icon: const Icon(Icons.article_outlined, color: Colors.white),
            onPressed: _openDetailed,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _pluralizeDays(totalDays),
                      style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Day Selector ──
            if (totalDays > 1 && hasStops)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: totalDays,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final day = i + 1;
                    final selected = day == safeDay;
                    return Semantics(
                      label: 'اختيار اليوم $day',
                      selected: selected,
                      button: true,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => _selectedDay = day),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF0EA5E9)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF0EA5E9)
                                    : Colors.white.withValues(alpha: 0.1),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'اليوم $day',
                                style: TextStyle(
                                  color:
                                      selected ? Colors.white : Colors.white54,
                                  fontWeight: selected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),

            // ── Timeline / Empty State ──
            Expanded(
              child: hasStops
                  ? TimelineView(
                      stops: plan.stopsByDay[dayIndex],
                      transportMode: plan.transportMode,
                    )
                  : const _EmptyStopsView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDetailed,
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.timeline),
        label: const Text(
          'التفاصيل الكاملة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════

class _EmptyStopsView extends StatelessWidget {
  const _EmptyStopsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 72,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'لا توجد محطات في هذه الرحلة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'قد تكون الخطة فارغة أو لم تُحفظ بعد',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
