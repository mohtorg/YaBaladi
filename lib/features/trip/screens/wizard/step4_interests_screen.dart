// lib/features/trip/screens/wizard/step4_interests_screen.dart
//
// [v1.0 — 2026-10-18] — Wave 5.3: Step 4 — Interests
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/wizard_step_wrapper.dart';

class Step4InterestsScreen extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const Step4InterestsScreen({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const List<({String id, String label, IconData icon})> _options = [
    (id: 'landmarks', label: 'معالم', icon: Icons.account_balance),
    (id: 'restaurants', label: 'مطاعم', icon: Icons.restaurant),
    (id: 'cafes', label: 'كافيهات', icon: Icons.local_cafe),
    (id: 'beaches', label: 'شواطئ', icon: Icons.beach_access),
    (id: 'shopping', label: 'تسوق', icon: Icons.shopping_bag),
    (id: 'hotels', label: 'فنادق', icon: Icons.hotel),
    (id: 'parks', label: 'حدائق', icon: Icons.park),
    (id: 'family', label: 'عائلي', icon: Icons.family_restroom),
    (id: 'events', label: 'فعاليات', icon: Icons.event),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WizardStepWrapper(
      emoji: '🎯',
      title: 'ماذا يشعل شغفك؟',
      subtitle: 'اختر ما يلامس قلبك (اختياري)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: _options.map((opt) {
              final isSelected = selected.contains(opt.id);
              return _InterestTile(
                label: opt.label,
                icon: opt.icon,
                isSelected: isSelected,
                onTap: () {
                  HapticFeedback.selectionClick();
                  final next = Set<String>.from(selected);
                  if (isSelected) {
                    next.remove(opt.id);
                  } else {
                    next.add(opt.id);
                  }
                  onChanged(next);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _FeedbackBanner(selected: selected, theme: theme),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// INTEREST TILE
// ═══════════════════════════════════════════════════════════════

class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 26,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FEEDBACK BANNER
// ═══════════════════════════════════════════════════════════════

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.selected, required this.theme});

  final Set<String> selected;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final String message;
    final IconData icon;

    if (selected.isEmpty) {
      (message, icon) = ('رحلة عشوائية ممتعة 🎲', Icons.casino);
    } else if (selected.length >= 3) {
      (message, icon) = ('رحلة متنوعة ✨', Icons.auto_awesome);
    } else if (selected.contains('beaches') &&
        (selected.contains('restaurants') || selected.contains('cafes'))) {
      (message, icon) = ('يوم بحري 🌊', Icons.beach_access);
    } else if (selected.contains('landmarks') || selected.contains('culture')) {
      (message, icon) = ('مغامرة ثقافية 🏛️', Icons.account_balance);
    } else if (selected.contains('shopping') || selected.contains('cafes')) {
      (message, icon) = ('يوم اكتشاف 🛍️', Icons.shopping_bag);
    } else if (selected.contains('family') || selected.contains('kids')) {
      (message, icon) = ('رحلة عائلية دافئة 👨‍👩‍👧', Icons.family_restroom);
    } else {
      (message, icon) = ('رحلة مميزة ⭐', Icons.star);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              selected.isEmpty
                  ? message
                  : 'اخترت ${selected.length} • $message',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}