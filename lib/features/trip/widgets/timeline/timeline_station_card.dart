// lib/features/trip/widgets/timeline/timeline_station_card.dart
//
// [v1.1 - DARK THEME + ARABIC PLURALS]
//   - UPDATED: Glassmorphism card matching the dark trip flow.
//   - FIXED: Arabic pluralization for minutes (1/2/3-10/11+).
//   - FIXED: Dot border now uses the actual screen background color
//     instead of theme.surface (avoids visual halos on dark).
//   - IMPROVED: Connector colors use white alpha for consistency.
//   - KEPT: IntrinsicHeight layout, isFirst/isLast logic, all data.

import 'package:flutter/material.dart';

import '../../../../models/trip_plan.dart';

class TimelineStationCard extends StatelessWidget {
  final TripStop stop;
  final bool isFirst;
  final bool isLast;

  const TimelineStationCard({
    super.key,
    required this.stop,
    this.isFirst = false,
    this.isLast = false,
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
    const primaryBlue = Color(0xFF0EA5E9);
    const screenBg = Color(0xFF0F172A);
    final time = stop.plannedArrival;
    final minutes = stop.plannedDurationMin ?? 60;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Time column (left) ───
          SizedBox(
            width: 60,
            child: Column(
              children: [
                const SizedBox(height: 8),
                if (time != null)
                  Text(
                    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: primaryBlue,
                    ),
                  ),
              ],
            ),
          ),

          // ─── Timeline dot + connectors ───
          SizedBox(
            width: 30,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                    width: 2,
                    height: 8,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    shape: BoxShape.circle,
                    // ✅ Use actual screen background for the "hole"
                    border: Border.all(color: screenBg, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ─── Station card ───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.placeNameAr,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 14, color: Color(0xFF0EA5E9)),
                        const SizedBox(width: 4),
                        Text(
                          _arabicDuration(minutes),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(
                          stop.rating.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
