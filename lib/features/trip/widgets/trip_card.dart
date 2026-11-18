// lib/features/trip/widgets/trip_card.dart
//
// [v2.0 - DARK THEME + ARABIC PLURALS]
//   - UPDATED: Glassmorphism card matching the entire trip flow
//     (was using default white card — visual shock on dark bg).
//   - FIXED: Arabic pluralization for stop counts.
//   - FIXED: Button and icon colors are now explicit (not theme-dependent).
//   - KEPT: Status mapping, onTap logic, and all data fields.

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
      TripStatus.active => const Color(0xFF10B981), // emerald
      TripStatus.completed => const Color(0xFF0EA5E9), // sky blue
      TripStatus.cancelled => const Color(0xFFEF4444), // red
      TripStatus.draft => const Color(0xFFF59E0B), // amber
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

  /// Arabic pluralization for "X stops".
  String _arabicStops(int n) {
    if (n == 1) return 'محطة واحدة';
    if (n == 2) return 'محطتان';
    if (n >= 3 && n <= 10) return '$n محطات';
    return '$n محطة';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
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
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Title ───
                Text(
                  trip.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // ─── Info Row ───
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trip.governorateNameAr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: Color(0xFF0EA5E9),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _arabicStops(trip.stopCount),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
