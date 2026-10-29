// lib/features/trip/widgets/timeline/timeline_transport_row.dart
//
// [v1.2 — 2026-10-18] — FIX: import path (3 → 4 levels up)
//   - FIX (CRITICAL): '../../../models/trip_plan.dart' كان خطأ
//     → الصحيح: '../../../../models/trip_plan.dart' (4 مستويات)
//   - سبب الخطأ: timeline/ + widgets/ + trip/ + features/ = 4
//
// [v1.1 — 2026-10-18] — Wave 5.4 initial
import 'package:flutter/material.dart';

import '../../../../models/trip_plan.dart'; // ✅ 4 مستويات

class TimelineTransportRow extends StatelessWidget {
  final int minutes;
  final TripTransportMode transportMode;

  const TimelineTransportRow({
    super.key,
    required this.minutes,
    required this.transportMode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final IconData icon = switch (transportMode) {
      TripTransportMode.walking => Icons.directions_walk,
      TripTransportMode.driving => Icons.directions_car,
      TripTransportMode.transit => Icons.directions_bus,
    };
    final label = switch (transportMode) {
      TripTransportMode.walking => 'سيراً',
      TripTransportMode.driving => 'بالسيارة',
      TripTransportMode.transit => 'بالمواصلات',
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Empty time column
          const SizedBox(width: 60),
          // Dashed line
          SizedBox(
            width: 30,
            child: Center(
              child: Container(
                width: 2,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Transport row
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$label • $minutes دقيقة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
