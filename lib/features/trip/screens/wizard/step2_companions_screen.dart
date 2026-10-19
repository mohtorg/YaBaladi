// lib/features/trip/screens/wizard/step2_companions_screen.dart
//
// [v1.0 — 2026-10-18] — Wave 5.3: Step 2 — Companions
import 'package:flutter/material.dart';

import '../../../../models/companion_type.dart';
import '../../widgets/selection_card.dart';
import '../../widgets/wizard_step_wrapper.dart';

class Step2CompanionsScreen extends StatelessWidget {
  final CompanionType selected;
  final ValueChanged<CompanionType> onChanged;

  const Step2CompanionsScreen({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return WizardStepWrapper(
      emoji: '👥',
      title: 'من سيشاركك المغامرة؟',
      subtitle: 'كل رفيق يضيف بهجة مختلفة',
      child: Column(
        children: CompanionType.values.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SelectionCard(
              emoji: c.emoji,
              title: c.labelAr,
              tagline: c.tagline,
              isSelected: selected == c,
              accentColor: c.color,
              onTap: () => onChanged(c),
            ),
          );
        }).toList(),
      ),
    );
  }
}
