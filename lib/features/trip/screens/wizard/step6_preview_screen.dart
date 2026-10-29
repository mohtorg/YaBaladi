// lib/features/trip/screens/wizard/step6_preview_screen.dart
//
// [v1.0 — 2026-10-18] — Wave 5.3: Step 6 — Preview
//   - Trip summary
//   - Mini timeline (first 4 stops)
//   - Regenerate button
//   - Save button (in nav bar)
import 'package:flutter/material.dart';

import '../../../../models/trip_plan.dart';
import '../../widgets/wizard_step_wrapper.dart';

class Step6PreviewScreen extends StatelessWidget {
  final TripPlan? plan;
  final bool generating;
  final VoidCallback onSave;
  final Future<void> Function() onRegenerate;

  const Step6PreviewScreen({
    super.key,
    required this.plan,
    required this.generating,
    required this.onSave,
    required this.onRegenerate,
  });

  @override
  Widget build(BuildContext context) {
    if (generating) {
      return const WizardStepWrapper(
        emoji: '⏳',
        title: 'نجهّز رحلتك…',
        subtitle: 'لحظات ونعرض لك أجمل الخطة',
        scrollable: false,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (plan == null || plan!.isEmpty) {
      return WizardStepWrapper(
        emoji: '🤔',
        title: 'لا توجد أماكن كافية',
        subtitle: 'جرّب تغيير المدة أو الاهتمامات',
        child: Center(
          child: OutlinedButton.icon(
            onPressed: onRegenerate,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ),
      );
    }

    final p = plan!;
    final theme = Theme.of(context);

    return WizardStepWrapper(
      emoji: '🎉',
      title: 'رحلتك جاهزة!',
      subtitle: 'راجع الخطة قبل الحفظ',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Title ───
          Text(
            p.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // ─── Stats ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Stat(
                  icon: Icons.place_outlined,
                  label: 'محطات',
                  value: '${p.stopCount}',
                ),
                _Stat(
                  icon: Icons.route_outlined,
                  label: 'مسافة',
                  value: '${p.totalDistanceKm.toStringAsFixed(0)} كم',
                ),
                _Stat(
                  icon: Icons.schedule,
                  label: 'مدة',
                  value: p.durationLabel,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── Mini timeline ───
          Row(
            children: [
              Icon(
                Icons.format_list_numbered,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'محطاتك المقترحة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...p.stops.take(6).toList().asMap().entries.map((e) {
            return _StopPreviewRow(
              index: e.key + 1,
              stop: e.value,
            );
          }),
          if (p.stops.length > 6)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'و ${p.stops.length - 6} محطات أخرى…',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 20),

          // ─── Regenerate ───
          OutlinedButton.icon(
            onPressed: onRegenerate,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة التوليد'),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _StopPreviewRow extends StatelessWidget {
  const _StopPreviewRow({required this.index, required this.stop});

  final int index;
  final TripStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = stop.plannedArrival;
    final timeLabel = time == null
        ? '--:--'
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              '$index',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              stop.placeNameAr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timeLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
