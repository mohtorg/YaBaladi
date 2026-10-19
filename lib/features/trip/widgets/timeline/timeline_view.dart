// lib/features/trip/widgets/timeline/timeline_view.dart
//
// [v1.1 — 2026-10-19] — Wave 5.5b: robustness + efficiency
//   - FIX: primary: false — يمنع scroll conflicts في TabBarView
//          (رحلة متعددة الأيام في trip_detailed_screen)
//   - FIX: _travelMin يُحسب مرة واحدة بدل مرتين (minor efficiency)
//   - KEPT: signature (stops, transportMode) — توافق 100%
//          مع trip_overview v1.3.2 و trip_detailed v1.2
//   - KEPT: منطق حساب وقت الانتقال (plannedArrival + plannedDurationMin)
//
// [v1.0 — 2026-10-18] — Wave 5.4: Timeline View

import 'package:flutter/material.dart';

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
      return const Center(child: Text('لا توجد محطات'));
    }

    // بناء العناصر: محطة + صف انتقال (إن وُجد وقت انتقال)
    final children = <Widget>[];
    for (var i = 0; i < stops.length; i++) {
      if (i > 0) {
        // [v1.1] حساب وقت الانتقال مرة واحدة فقط
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
      // [v1.1] يمنع conflicts على PrimaryScrollController
      //        عندما يكون داخل TabBarView (رحلة متعددة الأيام)
      primary: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: children,
    );
  }

  int _travelMin(TripStop prev, TripStop next) {
    final t1 = prev.plannedArrival;
    final t2 = next.plannedArrival;
    if (t1 == null || t2 == null) return 0;
    final diff = t2.difference(t1).inMinutes;
    // نخصم مدة الزيارة (لأن plannedArrival = بداية الوصول)
    final visit = prev.plannedDurationMin ?? 0;
    return (diff - visit).clamp(0, 999);
  }
}
