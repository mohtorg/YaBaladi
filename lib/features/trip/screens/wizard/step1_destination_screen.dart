// lib/features/trip/screens/wizard/step1_destination_screen.dart
//
// [v1.0 — 2026-10-18] — Wave 5.3: Step 1 — Destination
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/location/browsing_location_controller.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../places/controllers/places_controller.dart';
import '../../../../models/place.dart';
import '../../widgets/wizard_step_wrapper.dart';

class Step1DestinationScreen extends StatelessWidget {
  final String? selectedGovernorateId;
  final ValueChanged<String> onChanged;

  const Step1DestinationScreen({
    super.key,
    required this.selectedGovernorateId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final browsingCtrl = context.watch<BrowsingLocationController>();
    final places = context.watch<PlacesController>().allPlacesRaw;

    return WizardStepWrapper(
      emoji: '✈️',
      title: 'إلى أين تطير بنا اليوم؟',
      subtitle: 'اختر وجهتك... كل مكان يحكي قصة',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Current location ───
          if (browsingCtrl.hasPhysicalLocation) ...[
            _CurrentLocationCard(
              nameAr: browsingCtrl.browsing.nameAr,
              isSelected: selectedGovernorateId == browsingCtrl.browsing.id,
              onTap: () => onChanged(browsingCtrl.browsing.id),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'أو اختر من القائمة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // ─── Grid ───
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: kEgyptGovernorates.length,
            itemBuilder: (context, i) {
              final gov = kEgyptGovernorates[i];
              final count = _countIn(places, gov.nameAr, gov.nameEn);
              return _GovernorateTile(
                id: gov.id,
                nameAr: gov.nameAr,
                nameEn: gov.nameEn,
                count: count,
                isSelected: selectedGovernorateId == gov.id,
                onTap: count > 0 ? () => onChanged(gov.id) : null,
              );
            },
          ),
        ],
      ),
    );
  }

  int _countIn(List<Place> places, String nameAr, String nameEn) {
    final tAr = nameAr.toLowerCase().trim();
    final tEn = nameEn.toLowerCase().trim();
    return places.where((p) {
      final pg = p.governorate.toLowerCase().trim();
      if (pg == tAr || pg == tEn) return true;
      if (tAr == 'بورسعيد' &&
          (pg == 'portsaid' || pg == 'port said' || pg == 'port_said')) {
        return true;
      }
      if (tAr == 'القاهرة' && pg == 'cairo') return true;
      return false;
    }).length;
  }
}

// ═══════════════════════════════════════════════════════════════
// CURRENT LOCATION CARD
// ═══════════════════════════════════════════════════════════════

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard({
    required this.nameAr,
    required this.isSelected,
    required this.onTap,
  });

  final String nameAr;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.my_location,
                color: theme.colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'موقعك الحالي',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      nameAr,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GOVERNORATE TILE
// ═══════════════════════════════════════════════════════════════

class _GovernorateTile extends StatelessWidget {
  const _GovernorateTile({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = count > 0;

    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer
          : isAvailable
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isAvailable ? '🏙️' : '🌱',
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nameAr,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAvailable
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAvailable ? '$count مكان' : 'قريباً',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isAvailable
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (isSelected)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Icon(
                    Icons.check_circle,
                    size: 20,
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
