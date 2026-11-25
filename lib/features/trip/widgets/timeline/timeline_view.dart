// lib/features/trip/widgets/timeline/timeline_view.dart
//
// [v1.2 - VISIBILITY + PERFORMANCE]
//   - FIXED: Empty state text was invisible on dark background
//     (inherited dark grey from default light theme).
//   - IMPROVED: Empty state now has an icon + explicit colors + padding.
//   - ADDED: cacheExtent for smoother scrolling on long trips.
//   - KEPT: All v1.1.1 fixes (clamp toInt, primary: false, travel-min efficiency).

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;

import '../../../../models/trip_plan.dart';
import 'timeline_station_card.dart';
import 'timeline_transport_row.dart';

class TimelineView extends StatelessWidget {
  final List<TripStop> stops;
  final TripTransportMode transportMode;

  const TimelineView({
    super.key,
    required this.stops,
    required this.transportMode,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timeline,
                size: 48,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                'لا توجد محطات في هذه الرحلة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build items: station + optional transport row between stations
    final children = <Widget>[];
    for (var i = 0; i < stops.length; i++) {
      if (i > 0) {
        final travel = _travelMin(stops[i - 1], stops[i]);
        if (travel > 0) {
          children.add(
            TimelineTransportRow(
              minutes: travel,
              transportMode: transportMode,
            ),
          );
        }
      }
      children.add(
        TimelineStationCard(
          stop: stops[i],
          isFirst: i == 0,
          isLast: i == stops.length - 1,
        ),
      );
    }

    return ListView(
      // Prevents PrimaryScrollController conflict inside TabBarView
      // (used by trip_detailed_screen for multi-day trips).
      primary: false,
      // ✅ Smoother scrolling for longer trips.
      scrollCacheExtent: const ScrollCacheExtent.pixels(500),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: children,
    );
  }

  /// Travel minutes between two stops:
  ///   total_gap = arrival_B - arrival_A
  ///   travel_min = total_gap - visit_duration_A
  ///
  /// Edge cases handled:
  ///   - Missing arrival times → returns 0 (no transport row shown).
  ///   - Missing visit duration → treats as 0 (all gap = travel).
  ///   - Negative result (overlapping stops) → clamped to 0.
  int _travelMin(TripStop prev, TripStop next) {
    final t1 = prev.plannedArrival;
    final t2 = next.plannedArrival;
    if (t1 == null || t2 == null) return 0;
    final diff = t2.difference(t1).inMinutes;
    final visit = prev.plannedDurationMin ?? 0;
    return (diff - visit).clamp(0, 999).toInt();
  }
}
