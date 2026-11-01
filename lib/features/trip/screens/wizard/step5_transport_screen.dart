// lib/features/trip/screens/wizard/step5_transport_screen.dart
//
// [v1.0 — 2026-10-18] — Wave 5.3: Step 5 — Transport
import 'package:flutter/material.dart';

import '../../../../models/trip_plan.dart';
import '../../widgets/selection_card.dart';
import '../../widgets/wizard_step_wrapper.dart';

class Step5TransportScreen extends StatelessWidget {
  final TripTransportMode selected;
  final ValueChanged<TripTransportMode> onChanged;

  const Step5TransportScreen({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return WizardStepWrapper(
      emoji: '🚗',
      title: 'كيف تفضل التحرك؟',
      subtitle: 'اختر وسيلتك المفضلة',
      child: Column(
        children: TripTransportMode.values.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectionCard(
              icon: _iconFor(m),
              title: m.labelAr,
              tagline: _taglineFor(m),
              subtitle: '~${m.speedKmH.toStringAsFixed(0)} كم/ساعة',
              isSelected: selected == m,
              badgeLabel: m == TripTransportMode.driving ? 'موصى' : null,
              onTap: () => onChanged(m),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(TripTransportMode m) => switch (m) {
        TripTransportMode.walking => Icons.directions_walk,
        TripTransportMode.driving => Icons.directions_car,
        TripTransportMode.transit => Icons.directions_bus,
      };

  String _taglineFor(TripTransportMode m) => switch (m) {
        TripTransportMode.walking => 'أبطأ — لكن أعمق',
        TripTransportMode.driving => 'أسرع — مسافات أطول',
        TripTransportMode.transit => 'توازن بين السرعة والتكلفة',
      };
}
