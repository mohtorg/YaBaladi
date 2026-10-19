// lib/core/location/governorate_picker_sheet.dart
//
// [v1.1 — 2026-10-19] — Wave 5.5b: physicalPlaceName support
//   - NEW: show() يقبل physicalPlaceName اختياري (اسم GPS الدقيق)
//   - FIX: _PhysicalOption يعرض اسم GPS بدل اسم المحافظة
//          مثال: "الشرق، بورسعيد — من GPS" بدل "بورسعيد — من GPS"
//   - FIX: إزالة physical! (استبدال بـ null check)
//   - FIX: const Chip
//   - KEPT: Future<void> — توافق 100% مع welcome_header v2.0.7
//
// [v1.0 — 2026-10-14] — G4.2-c: GovernoratePickerSheet

import 'package:flutter/material.dart';

import 'browsing_location_controller.dart';
import 'egypt_governorates.dart';

class GovernoratePickerSheet extends StatelessWidget {
  const GovernoratePickerSheet({
    super.key,
    required this.controller,
    this.physicalPlaceName,
  });

  final BrowsingLocationController controller;

  /// اسم المكان الدقيق من GPS (مثل "الشرق، بورسعيد")
  /// إن لم يُمرَّر، يُستخدم اسم المحافظة من `physical.nameAr`
  final String? physicalPlaceName;

  /// يعرض الـ BottomSheet مع BrowsingLocationController الممرَّر.
  /// يُعيد Future<void> ينتهي عند اختيار محافظة أو إغلاق الشيت.
  static Future<void> show(
    BuildContext context, {
    required BrowsingLocationController controller,
    String? physicalPlaceName,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => GovernoratePickerSheet(
        controller: controller,
        physicalPlaceName: physicalPlaceName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final browsing = controller.browsing;
    final physical = controller.physical;
    final hasPhysical = controller.hasPhysicalLocation;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'اختر المحافظة',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            // ─── "استخدام موقعي الحالي" ───
            if (hasPhysical && physical != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _PhysicalOption(
                  physical: physical,
                  physicalPlaceName: physicalPlaceName,
                  isActive: controller.isUsingPhysical,
                  onTap: () {
                    controller.resetToPhysical();
                    Navigator.of(context).pop();
                  },
                ),
              ),

            const Divider(height: 24),

            // ─── نص إرشادي ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  hasPhysical ? 'أو اختر محافظة أخرى' : 'اختر محافظتك',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ─── قائمة الـ27 محافظة ───
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: kEgyptGovernorates.length,
                itemBuilder: (context, i) {
                  final gov = kEgyptGovernorates[i];
                  final isSelected = gov.id == browsing.id;
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(gov.nameAr),
                    subtitle: Text(gov.nameEn),
                    trailing: gov.isDefault
                        ? const Chip(
                            label: Text(
                              'افتراضي',
                              style: TextStyle(fontSize: 10),
                            ),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                    selected: isSelected,
                    onTap: () {
                      controller.setBrowsingGovernorate(gov.id);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhysicalOption extends StatelessWidget {
  const _PhysicalOption({
    required this.physical,
    required this.isActive,
    required this.onTap,
    this.physicalPlaceName,
  });

  final EgyptGovernorate physical;

  /// اسم المكان الدقيق من GPS (اختياري)
  final String? physicalPlaceName;
  final bool isActive;
  final VoidCallback onTap;

  String get _displayName {
    final name = physicalPlaceName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return physical.nameAr;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: isActive
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        leading: Icon(
          Icons.my_location,
          color: theme.colorScheme.primary,
        ),
        title: const Text(
          'استخدام موقعي الحالي',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('$_displayName — من GPS'),
        trailing: isActive
            ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
            : null,
        onTap: onTap,
      ),
    );
  }
}
