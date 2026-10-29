// lib/features/trip/screens/wizard/step3_duration_screen.dart
//
// [v1.0 — 2026-10-18] — Wave 5.3: Step 3 — Duration
import 'package:flutter/material.dart';

import '../../../../models/trip_plan.dart';
import '../../widgets/selection_card.dart';
import '../../widgets/wizard_step_wrapper.dart';

class Step3DurationScreen extends StatelessWidget {
  final TripDurationType selected;
  final ValueChanged<TripDurationType> onChanged;

  const Step3DurationScreen({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return WizardStepWrapper(
      emoji: '⏱️',
      title: 'كم من الوقت؟',
      subtitle: 'في أحضان المدينة',
      child: Column(
        children: TripDurationType.values.map((d) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectionCard(
              emoji: _emojiFor(d),
              title: d.labelAr,
              tagline: _taglineFor(d),
              subtitle: '${d.subtitleAr} • ${d.maxStops} محطات',
              isSelected: selected == d,
              badgeLabel: d == TripDurationType.fullDay ? 'موصى' : null,
              onTap: () => onChanged(d),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _emojiFor(TripDurationType d) => switch (d) {
        TripDurationType.halfDay => '☀️',
        TripDurationType.fullDay => '🌅',
        TripDurationType.weekend => '🗓️',
      };

  String _taglineFor(TripDurationType d) => switch (d) {
        TripDurationType.halfDay => 'كافٍ لاكتشاف سريع',
        TripDurationType.fullDay => 'المغامرة الكاملة',
        TripDurationType.weekend => 'رحلتك الكبرى',
      };
}
