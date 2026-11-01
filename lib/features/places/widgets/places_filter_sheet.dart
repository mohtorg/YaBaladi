// lib/features/places/widgets/places_filter_sheet.dart
//
// [v4.1 — 2026-10-25] — Wave 11 FIX: imports مصححة + pending_strings
//
//   - FIX: filters_controller path: ../../../ → ../../
//   - FIX: filter_definition path: ../../../../ → ../../../
//   - ADD: import pending_strings.dart (filterSheetTitle, showResultsCount, noMatchingResults)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/pending_strings.dart';
import '../../../models/filter_definition.dart';
import '../../filters/controllers/filters_controller.dart';
import '../controllers/places_controller.dart';

void showPlacesFilterSheet({
  required BuildContext context,
  required PlacesController controller,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _FilterSheet(controller: controller),
  );
}

class _FilterSheet extends StatefulWidget {
  final PlacesController controller;
  const _FilterSheet({required this.controller});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Map<String, FilterSelection> _temp;

  @override
  void initState() {
    super.initState();
    final filtersCtrl = context.read<FiltersController>();
    _temp = Map.from(filtersCtrl.selection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtersCtrl = context.watch<FiltersController>();
    final l10n = AppLocalizations.of(context);

    final visibleFilters = filtersCtrl.visibleFor(filtersCtrl.currentRole);
    final filtersCount = _temp.values.where((s) => s.isNotEmpty).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            _buildHeader(theme, l10n, filtersCount),
            const Divider(height: 1),
            if (filtersCount > 0) _buildActiveChips(theme, l10n),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  ...visibleFilters.map((f) => _buildFilterSection(theme, f)),
                ],
              ),
            ),
            _buildApplyButton(theme, l10n, filtersCtrl),
          ],
        );
      },
    );
  }

  // ─── Header ───
  Widget _buildHeader(ThemeData theme, AppLocalizations l10n, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.close,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.filterSheetTitle,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (count > 0)
            TextButton.icon(
              onPressed: () => setState(() => _temp = {}),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l10n.clearFilters),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  // ─── Active chips ───
  Widget _buildActiveChips(ThemeData theme, AppLocalizations l10n) {
    final chips = <Widget>[];
    _temp.forEach((filterId, selection) {
      if (selection.isEmpty) return;
      final filter = _findFilter(filterId);
      if (filter == null) return;
      for (final v in selection.values) {
        final opt = filter.options.firstWhere(
          (o) => o.value == v,
          orElse: () => FilterOption(value: v, labelAr: v, labelEn: v),
        );
        chips.add(_activeChip(
          theme,
          label: opt.labelAr,
          onRemove: () => setState(() {
            final next = Set<String>.from(selection.values)..remove(v);
            if (next.isEmpty) {
              _temp.remove(filterId);
            } else {
              _temp[filterId] = FilterSelection(next);
            }
          }),
        ));
      }
    });
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (int i = 0; i < chips.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              chips[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _activeChip(ThemeData theme,
      {required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                Icons.close,
                size: 16,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter section (dynamic) ───
  Widget _buildFilterSection(ThemeData theme, FilterDefinition filter) {
    final selection = _temp[filter.id] ?? FilterSelection.empty;

    switch (filter.type) {
      case FilterType.sort:
        return _sectionCard(
          theme,
          icon: Icons.swap_vert,
          title: filter.nameAr,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filter.options.map((o) {
              final selected = selection.values.contains(o.value);
              return _premiumChip(
                label: o.labelAr,
                selected: selected,
                onTap: () => setState(() {
                  _temp[filter.id] = FilterSelection({o.value});
                }),
              );
            }).toList(),
          ),
        );

      case FilterType.singleChoice:
        return _sectionCard(
          theme,
          icon: Icons.radio_button_checked,
          title: filter.nameAr,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filter.options.map((o) {
              final selected = selection.values.contains(o.value);
              return _premiumChip(
                label: o.labelAr,
                selected: selected,
                onTap: () => setState(() {
                  if (selected) {
                    _temp.remove(filter.id);
                  } else {
                    _temp[filter.id] = FilterSelection({o.value});
                  }
                }),
              );
            }).toList(),
          ),
        );

      case FilterType.multiChoice:
        return _sectionCard(
          theme,
          icon: Icons.checklist,
          title: filter.nameAr,
          badge:
              selection.isNotEmpty ? '${selection.values.length} محدد' : null,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filter.options.map((o) {
              final selected = selection.values.contains(o.value);
              return _premiumChip(
                label: o.labelAr,
                selected: selected,
                onTap: () => setState(() {
                  final next = Set<String>.from(selection.values);
                  if (selected) {
                    next.remove(o.value);
                  } else {
                    next.add(o.value);
                  }
                  if (next.isEmpty) {
                    _temp.remove(filter.id);
                  } else {
                    _temp[filter.id] = FilterSelection(next);
                  }
                }),
                showCheck: true,
              );
            }).toList(),
          ),
        );

      case FilterType.range:
        return _sectionCard(
          theme,
          icon: Icons.trending_up,
          title: filter.nameAr,
          child: Wrap(
            spacing: 8,
            children: filter.options.map((o) {
              final selected = selection.values.contains(o.value);
              return _premiumChip(
                label: o.labelAr,
                selected: selected,
                onTap: () => setState(() {
                  if (selected) {
                    _temp.remove(filter.id);
                  } else {
                    _temp[filter.id] = FilterSelection({o.value});
                  }
                }),
              );
            }).toList(),
          ),
        );

      case FilterType.boolean:
        return _sectionCard(
          theme,
          icon: Icons.toggle_on,
          title: filter.nameAr,
          child: SwitchListTile.adaptive(
            value: selection.values.contains('true'),
            onChanged: (v) => setState(() {
              if (v) {
                _temp[filter.id] = FilterSelection({'true'});
              } else {
                _temp.remove(filter.id);
              }
            }),
            title: Text(filter.options.isNotEmpty
                ? filter.options.first.labelAr
                : filter.nameAr),
            contentPadding: EdgeInsets.zero,
          ),
        );
    }
  }

  FilterDefinition? _findFilter(String id) {
    final ctrl = context.read<FiltersController>();
    for (final f in ctrl.all) {
      if (f.id == id) return f;
    }
    return null;
  }

  // ─── Apply button ───
  Widget _buildApplyButton(
      ThemeData theme, AppLocalizations l10n, FiltersController ctrl) {
    final preview = widget.controller.applyFilters(_temp);
    final count = preview.length;
    final hasResults = count > 0;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              ctrl.replaceSelection(_temp);
              widget.controller.applyDynamicFilters(_temp);
              Navigator.pop(context);
            },
            icon: Icon(
              hasResults ? Icons.check_circle_outline : Icons.search_off,
              size: 22,
            ),
            label: Text(
              hasResults
                  ? l10n.showResultsCount(count)
                  : l10n.noMatchingResults,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───
  Widget _sectionCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? badge,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              if (badge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _premiumChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool showCheck = false,
  }) {
    return _PremiumChip(
      label: label,
      selected: selected,
      onTap: onTap,
      showCheck: showCheck,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PremiumChip
// ═══════════════════════════════════════════════════════════════

class _PremiumChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showCheck;

  const _PremiumChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.showCheck = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor =
        selected ? theme.colorScheme.primary : theme.colorScheme.surface;
    final fgColor =
        selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;
    final borderColor =
        selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck) ...[
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 16,
                  color: fgColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: fgColor,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
