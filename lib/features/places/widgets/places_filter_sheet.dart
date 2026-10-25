// lib/features/places/widgets/places_filter_sheet.dart
//
// [v3.2 — 2026-10-24] — Keep i18n + apply CRITICAL logic fixes
//   - FIX (critical): price filter used `<=` making "مرتفع" == "الكل".
//     Now: 1 → economic, 2 → medium, 3 → high (>= 3, includes luxury).
//   - FIX: `sort == distance` auto-resets to `recommended` when the
//     user has no location (both in initState and _apply()).
//   - FIX: `_previewCount()` is a single-pass predicate (previously
//     allocated a new list for each of 8 filters).
//   - FIX: active-filters row no longer pinned to 36px height
//     (adapts to large text scale without overflow).
//   - FIX: apply button distinguishes "empty data" from "no match".
//   - FIX: chip close-button tap target ≥ 32px (a11y).
//   - FIX: iterating over `.toList()` copies of sets during build to
//     prevent ConcurrentModificationError if a chip is removed
//     mid-build (defensive).
//   - NEW: _hasLocation getter for readability.
//   - KEPT: ALL l10n keys — no new strings introduced. If any of
//     the (starsPlus / showResultsCount / selectedCount / ratingChoice)
//     functions perform Arabic pluralization, they MUST live in the
//     pending_strings extension.
//   - KEPT: PlacesController API unchanged.
//
// [v3.1 — 2026-10-24] — i18n of hard-coded strings
//   - كل النصوص العربية الثابتة صارت عبر AppLocalizations (AR/EN).
//   - REUSE من ARB: close, clearFilters, filterAll, filterRating,
//     filterPrice, sortRatingDesc, sortNewest. الباقي من
//     pending_strings.dart.
//   - CHANGE (نصّي طفيف): تسمية «موقف» في الشريحة الفعّالة صارت
//     «موقف سيارات» لتتطابق مع زر الاختيار.
//
// [v3.0 — 2026-10-20] — UX OVERHAUL
//   - Preview count in apply button, active filter chips, close (X)
//     button, per-section counters, adaptive colors.
//   - All controller API preserved (setAmenities, setFeatures).

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/pending_strings.dart';
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
  late double? _tempRating;
  late int? _tempPrice;
  late PlaceSort _tempSort;
  late Set<String> _tempAmenities;
  late Set<String> _tempFeatures;

  /// [v3.2] Convenience — used by initState, apply, sort-section, and
  /// the sort guard. Kept as a getter to avoid duplication.
  bool get _hasLocation => widget.controller.userLat != null;

  @override
  void initState() {
    super.initState();
    _tempRating = widget.controller.minRating;
    _tempPrice = widget.controller.priceLevel;
    _tempSort = widget.controller.sort;
    _tempAmenities = Set.from(widget.controller.amenities);
    _tempFeatures = Set.from(widget.controller.features);

    // [v3.2] Guard: never keep 'distance' sort without a location.
    if (!_hasLocation && _tempSort == PlaceSort.distance) {
      _tempSort = PlaceSort.recommended;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _apply() {
    // [v3.2] Final safety pass — mirror the initState guard.
    final sort = (!_hasLocation && _tempSort == PlaceSort.distance)
        ? PlaceSort.recommended
        : _tempSort;

    widget.controller.setMinRating(_tempRating);
    widget.controller.setPriceLevel(_tempPrice);
    widget.controller.setSort(sort);
    widget.controller.setAmenities(_tempAmenities);
    widget.controller.setFeatures(_tempFeatures);
    Navigator.pop(context);
  }

  void _clearAll() {
    setState(() {
      _tempRating = null;
      _tempPrice = null;
      _tempSort = PlaceSort.recommended;
      _tempAmenities.clear();
      _tempFeatures.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PREVIEW — عدد النتائج المطابقة (محلياً)
  // ═══════════════════════════════════════════════════════════════

  /// [v3.2] Single-pass count — same result, no 8 intermediate lists.
  int _previewCount() {
    final places = widget.controller.places;
    if (places.isEmpty) return 0;

    final rating = _tempRating;
    final price = _tempPrice;

    return places.where((p) {
      if (rating != null && p.averageRating < rating) return false;

      // [v3.2] Fix: exact tier match.
      //   1 → economic, 2 → medium, 3 → high (incl. luxury).
      if (price != null) {
        switch (price) {
          case 1:
            if (p.priceLevel != 1) return false;
            break;
          case 2:
            if (p.priceLevel != 2) return false;
            break;
          case 3:
            if (p.priceLevel < 3) return false;
            break;
        }
      }

      if (_tempAmenities.contains('wifi') && !p.hasWifi) return false;
      if (_tempAmenities.contains('parking') && !p.hasParking) {
        return false;
      }
      if (_tempAmenities.contains('restroom') && !p.hasRestroom) {
        return false;
      }
      if (_tempAmenities.contains('accessibility') && !p.hasAccessibility) {
        return false;
      }

      if (_tempFeatures.contains('family') && !p.isFamilyFriendly) {
        return false;
      }
      if (_tempFeatures.contains('halal') && !p.isHalal) return false;
      if (_tempFeatures.contains('delivery') && !p.hasDelivery) {
        return false;
      }
      if (_tempFeatures.contains('reservation') && !p.hasReservation) {
        return false;
      }

      return true;
    }).length;
  }

  int _filtersCount() {
    int count = 0;
    if (_tempRating != null) count++;
    if (_tempPrice != null) count++;
    if (_tempSort != PlaceSort.recommended) count++;
    count += _tempAmenities.length;
    count += _tempFeatures.length;
    return count;
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtersCount = _filtersCount();
    final hasLocation = _hasLocation;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            _buildHeader(theme, filtersCount),
            const Divider(height: 1),

            // ─── Active filters row ───
            if (filtersCount > 0) _buildActiveFiltersRow(theme),

            // ─── Content ───
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  _buildSortSection(theme, hasLocation),
                  const SizedBox(height: 12),
                  _buildRatingSection(theme),
                  const SizedBox(height: 12),
                  _buildPriceSection(theme),
                  const SizedBox(height: 12),
                  _buildAmenitiesSection(theme),
                  const SizedBox(height: 12),
                  _buildFeaturesSection(theme),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // ─── Apply button ───
            _buildApplyButton(theme),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════

  Widget _buildHeader(ThemeData theme, int filtersCount) {
    final l10n = AppLocalizations.of(context);
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
                Icon(
                  Icons.tune,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.filterSheetTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (filtersCount > 0)
            TextButton.icon(
              onPressed: _clearAll,
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

  // ═══════════════════════════════════════════════════════════════
  // ACTIVE FILTERS ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActiveFiltersRow(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];

    if (_tempRating != null) {
      chips.add(_activeChip(
        theme,
        label: l10n.starsPlus(_tempRating!.round()),
        onRemove: () => setState(() => _tempRating = null),
      ));
    }
    if (_tempPrice != null) {
      chips.add(_activeChip(
        theme,
        label: '💰 ${_priceLabel(_tempPrice!)}',
        onRemove: () => setState(() => _tempPrice = null),
      ));
    }
    // [v3.2] Iterate over a copy to be safe against mid-build removal.
    for (final a in _tempAmenities.toList()) {
      chips.add(_activeChip(
        theme,
        label: _amenityLabel(a),
        onRemove: () => setState(() => _tempAmenities.remove(a)),
      ));
    }
    for (final f in _tempFeatures.toList()) {
      chips.add(_activeChip(
        theme,
        label: _featureLabel(f),
        onRemove: () => setState(() => _tempFeatures.remove(f)),
      ));
    }

    // [v3.2] No fixed height — SingleChildScrollView inside an
    // intrinsic-height row so it adapts to text-scale.
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

  Widget _activeChip(
    ThemeData theme, {
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // [v3.2] 32×32 tap target for a11y (icon 16px centered).
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

  // ═══════════════════════════════════════════════════════════════
  // SECTIONS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildSortSection(ThemeData theme, bool hasLocation) {
    final l10n = AppLocalizations.of(context);
    return _sectionCard(
      theme,
      icon: Icons.swap_vert,
      title: l10n.sortByTitle,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _premiumChoice(
            label: l10n.sortRecommended,
            selected: _tempSort == PlaceSort.recommended,
            onTap: () => setState(() => _tempSort = PlaceSort.recommended),
          ),
          _premiumChoice(
            label: l10n.sortRatingDesc,
            selected: _tempSort == PlaceSort.ratingDesc,
            onTap: () => setState(() => _tempSort = PlaceSort.ratingDesc),
          ),
          _premiumChoice(
            label: l10n.sortNewest,
            selected: _tempSort == PlaceSort.newest,
            onTap: () => setState(() => _tempSort = PlaceSort.newest),
          ),
          if (hasLocation)
            _premiumChoice(
              label: l10n.sortNearest,
              selected: _tempSort == PlaceSort.distance,
              onTap: () => setState(() => _tempSort = PlaceSort.distance),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return _sectionCard(
      theme,
      icon: Icons.star,
      title: l10n.filterRating,
      child: Wrap(
        spacing: 8,
        children: [
          _premiumChoice(
            label: l10n.filterAll,
            selected: _tempRating == null,
            onTap: () => setState(() => _tempRating = null),
          ),
          _premiumChoice(
            label: l10n.ratingChoice(3),
            selected: _tempRating == 3.0,
            onTap: () => setState(() => _tempRating = 3.0),
          ),
          _premiumChoice(
            label: l10n.ratingChoice(4),
            selected: _tempRating == 4.0,
            onTap: () => setState(() => _tempRating = 4.0),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return _sectionCard(
      theme,
      icon: Icons.attach_money,
      title: l10n.filterPrice,
      child: Wrap(
        spacing: 8,
        children: [
          _premiumChoice(
            label: l10n.filterAll,
            selected: _tempPrice == null,
            onTap: () => setState(() => _tempPrice = null),
          ),
          _premiumChoice(
            label: l10n.priceBudget,
            selected: _tempPrice == 1,
            onTap: () => setState(() => _tempPrice = 1),
          ),
          _premiumChoice(
            label: l10n.priceMedium,
            selected: _tempPrice == 2,
            onTap: () => setState(() => _tempPrice = 2),
          ),
          _premiumChoice(
            label: l10n.priceHigh,
            selected: _tempPrice == 3,
            onTap: () => setState(() => _tempPrice = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return _sectionCard(
      theme,
      icon: Icons.checkroom,
      title: l10n.amenitiesTitle,
      badge: _tempAmenities.isNotEmpty
          ? l10n.selectedCount(_tempAmenities.length)
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _premiumFilter(
            label: l10n.amenityWifi,
            selected: _tempAmenities.contains('wifi'),
            onTap: (v) => setState(() =>
                v ? _tempAmenities.add('wifi') : _tempAmenities.remove('wifi')),
          ),
          _premiumFilter(
            label: l10n.amenityParking,
            selected: _tempAmenities.contains('parking'),
            onTap: (v) => setState(() => v
                ? _tempAmenities.add('parking')
                : _tempAmenities.remove('parking')),
          ),
          _premiumFilter(
            label: l10n.amenityRestroom,
            selected: _tempAmenities.contains('restroom'),
            onTap: (v) => setState(() => v
                ? _tempAmenities.add('restroom')
                : _tempAmenities.remove('restroom')),
          ),
          _premiumFilter(
            label: l10n.amenityAccessibility,
            selected: _tempAmenities.contains('accessibility'),
            onTap: (v) => setState(() => v
                ? _tempAmenities.add('accessibility')
                : _tempAmenities.remove('accessibility')),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return _sectionCard(
      theme,
      icon: Icons.people_outline,
      title: l10n.featuresTitle,
      badge: _tempFeatures.isNotEmpty
          ? l10n.selectedCount(_tempFeatures.length)
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _premiumFilter(
            label: l10n.featureFamily,
            selected: _tempFeatures.contains('family'),
            onTap: (v) => setState(() => v
                ? _tempFeatures.add('family')
                : _tempFeatures.remove('family')),
          ),
          _premiumFilter(
            label: l10n.featureHalal,
            selected: _tempFeatures.contains('halal'),
            onTap: (v) => setState(() =>
                v ? _tempFeatures.add('halal') : _tempFeatures.remove('halal')),
          ),
          _premiumFilter(
            label: l10n.featureDelivery,
            selected: _tempFeatures.contains('delivery'),
            onTap: (v) => setState(() => v
                ? _tempFeatures.add('delivery')
                : _tempFeatures.remove('delivery')),
          ),
          _premiumFilter(
            label: l10n.featureReservation,
            selected: _tempFeatures.contains('reservation'),
            onTap: (v) => setState(() => v
                ? _tempFeatures.add('reservation')
                : _tempFeatures.remove('reservation')),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // APPLY BUTTON
  // ═══════════════════════════════════════════════════════════════

  Widget _buildApplyButton(ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    final total = widget.controller.places.length;
    final count = _previewCount();
    final hasData = total > 0;
    final hasResults = count > 0;

    // [v3.2] Distinguish "empty data" from "no match":
    //   • hasData == false  → list not loaded yet.
    //   • hasResults == false → filters exclude everything.
    final String label;
    final IconData icon;
    if (!hasData) {
      label = l10n.noMatchingResults;
      icon = Icons.info_outline;
    } else if (!hasResults) {
      label = l10n.noMatchingResults;
      icon = Icons.search_off;
    } else {
      label = l10n.showResultsCount(count);
      icon = Icons.check_circle_outline;
    }

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
            onPressed: _apply,
            icon: Icon(icon, size: 22),
            label: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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

  // ═══════════════════════════════════════════════════════════════
  // HELPER WIDGETS
  // ═══════════════════════════════════════════════════════════════

  Widget _sectionCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    String? badge,
    required Widget child,
  }) {
    return Container(
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
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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

  Widget _premiumChoice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return _PremiumChip(
      label: label,
      selected: selected,
      onTap: onTap,
    );
  }

  Widget _premiumFilter({
    required String label,
    required bool selected,
    required ValueChanged<bool> onTap,
  }) {
    return _PremiumChip(
      label: label,
      selected: selected,
      onTap: () => onTap(!selected),
      showCheck: true,
    );
  }

  // ─── Labels ───
  String _priceLabel(int price) {
    final l10n = AppLocalizations.of(context);
    switch (price) {
      case 1:
        return l10n.priceBudget;
      case 2:
        return l10n.priceMedium;
      case 3:
        return l10n.priceHigh;
      default:
        return '';
    }
  }

  String _amenityLabel(String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'wifi':
        return l10n.amenityWifi;
      case 'parking':
        return l10n.amenityParking;
      case 'restroom':
        return l10n.amenityRestroom;
      case 'accessibility':
        return l10n.amenityAccessibility;
      default:
        return key;
    }
  }

  String _featureLabel(String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'family':
        return l10n.featureFamily;
      case 'halal':
        return l10n.featureHalal;
      case 'delivery':
        return l10n.featureDelivery;
      case 'reservation':
        return l10n.featureReservation;
      default:
        return key;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PREMIUM CHIP — تصميم مخصص برشاقة
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
