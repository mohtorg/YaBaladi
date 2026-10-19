// lib/features/trip/widgets/timeline/timeline_station_card.dart
//
// [v1.0 — 2026-10-18] — Wave 5.4: Timeline Station Card
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = stop.plannedArrival;

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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),

          // ─── Timeline line + dot ───
          SizedBox(
            width: 30,
            child: Column(
              children: [
                if (!isFirst)
                  Container(
                      width: 2,
                      height: 8,
                      color: theme.colorScheme.outlineVariant),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: theme.colorScheme.surface, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 2, color: theme.colorScheme.outlineVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ─── Station card ───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.placeNameAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${stop.plannedDurationMin ?? 60} دقيقة',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.star,
                              size: 14, color: Colors.amber.shade700),
                          const SizedBox(width: 2),
                          Text(
                            stop.rating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
