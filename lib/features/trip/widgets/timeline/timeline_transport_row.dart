// lib/features/trip/widgets/timeline/timeline_transport_row.dart
//
// [v1.3 - DARK THEME + ARABIC PLURALS]
//   - FIXED: Explicit dark-friendly colors (was using theme.colorScheme,
//     producing high-contrast white lines and unreadable grey text).
//   - FIXED: Arabic pluralization for minutes (1/2/3-10/11+).
//   - KEPT: Column widths (60/30/8), IntrinsicHeight, switch labels, icon.
//   - KEPT: Import path (../../../../ = 4 levels up).

import 'package:flutter/material.dart';

import '../../../../models/trip_plan.dart';

class TimelineTransportRow extends StatelessWidget {
  final int minutes;
  final TripTransportMode transportMode;

  const TimelineTransportRow({
    super.key,
    required this.minutes,
    required this.transportMode,
  });

  /// Arabic pluralization for durations in minutes.
  String _arabicDuration(int minutes) {
    if (minutes == 1) return 'دقيقة واحدة';
    if (minutes == 2) return 'دقيقتان';
    if (minutes >= 3 && minutes <= 10) return '$minutes دقائق';
    return '$minutes دقيقة';
  }

  @override
  Widget build(BuildContext context) {
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
          // Empty time column (matches TimelineStationCard width)
          const SizedBox(width: 60),

          // Dashed connector (matches TimelineStationCard dot column)
          SizedBox(
            width: 30,
            child: Center(
              child: Container(
                width: 2,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Transport info row
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: const Color(0xFF0EA5E9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$label • ${_arabicDuration(minutes)}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
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
