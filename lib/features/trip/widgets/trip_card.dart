// lib/features/trip/widgets/trip_card.dart
import 'package:flutter/material.dart';
import '../../../models/trip_plan.dart';

class TripCard extends StatelessWidget {
  final TripPlan trip;
  final VoidCallback onTap;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
  });

  Color _statusColor() {
    return switch (trip.status) {
      TripStatus.active => Colors.green,
      TripStatus.completed => Colors.blue,
      TripStatus.cancelled => Colors.grey,
      TripStatus.draft => Colors.orange,
    };
  }

  String _statusLabel() {
    return switch (trip.status) {
      TripStatus.active => 'نشطة',
      TripStatus.completed => 'مكتملة',
      TripStatus.cancelled => 'ملغاة',
      TripStatus.draft => 'مسودة',
    };
  }

  IconData _statusIcon() {
    return switch (trip.status) {
      TripStatus.active => Icons.play_circle,
      TripStatus.completed => Icons.check_circle,
      TripStatus.cancelled => Icons.cancel,
      TripStatus.draft => Icons.edit_note,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header: Status + Date ───
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_statusIcon(), size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _statusLabel(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    trip.dateRangeLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Title ───
              Text(
                trip.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // ─── Info Row ───
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trip.governorateNameAr,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${trip.stopCount} محطات',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── Footer: Action ───
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: Icon(
                    trip.status == TripStatus.active
                        ? Icons.play_arrow
                        : Icons.visibility,
                    size: 18,
                  ),
                  label: Text(
                    trip.status == TripStatus.active
                        ? 'متابعة الرحلة'
                        : 'عرض التفاصيل',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
