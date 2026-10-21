// lib/features/trip/screens/active_stop_screen.dart
// [v1.4 — 2026-10-20] — Beautiful single-button design.

import 'package:flutter/material.dart';
import '../../../models/trip_plan.dart';
import '../../../widgets/location_actions.dart';

class ActiveStopScreen extends StatelessWidget {
  final TripStop stop;
  const ActiveStopScreen({super.key, required this.stop});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(stop.placeNameAr, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              stop.placeNameAr,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stop.placeNameEn,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _InfoChip(
                  icon: Icons.star,
                  label:
                      '${stop.rating.toStringAsFixed(1)} (${stop.reviewCount})',
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                _InfoChip(
                  icon: Icons.category,
                  label: stop.categoryId,
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              'ملاحظات المحطة',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                stop.notes?.isNotEmpty == true
                    ? stop.notes!
                    : 'لا توجد ملاحظات إضافية لهذه المحطة.',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 32),

            // ✅ زر أنيق (دبوس خريطة) - كبير نسبياً لشاشة التفاصيل
            Center(
              child: LocationActions(
                lat: stop.lat,
                lng: stop.lng,
                large: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
