// lib/features/places/widgets/places_filter_sheet.dart
//
// [v3.0 — 2026-10-20] — UX OVERHAUL:
//   - NEW: Preview count in apply button (e.g., "عرض 12 نتيجة").
//   - NEW: Active filters chips at top — removable individually.
//   - NEW: Card-based sections for visual hierarchy.
//   - NEW: Close (X) button in header.
//   - NEW: Per-section counter badges.
//   - NEW: Adaptive colors (better dark-mode contrast).
//   - KEPT: All controller API (setAmenities, setFeatures).

import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tempRating = widget.controller.minRating;
    _tempPrice = widget.controller.priceLevel;
    _tempSort = widget.controller.sort;
    _tempAmenities = Set.from(widget.controller.amenities);
    _tempFeatures = Set.from(widget.controller.features);
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  void _apply() {
    widget.controller.setMinRating(_tempRating);
    widget.controller.setPriceLevel(_tempPrice);
    widget.controller.setSort(_tempSort);
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

  int _previewCount() {
    var result = [...widget.controller.places];

    if (_tempRating != null) {
      result = result.where((p) => p.averageRating >= _tempRating!).toList();
    }
    if (_tempPrice != null) {
      result = result.where((p) => p.priceLevel <= _tempPrice!).toList();
    }
    if (_tempAmenities.contains('wifi')) {
      result = result.where((p) => p.hasWifi).toList();
    }
    if (_tempAmenities.contains('parking')) {
      result = result.where((p) => p.hasParking).toList();
    }
    if (_tempAmenities.contains('restroom')) {
      result = result.where((p) => p.hasRestroom).toList();
    }
    if (_tempAmenities.contains('accessibility')) {
      result = result.where((p) => p.hasAccessibility).toList();
    }
    if (_tempFeatures.contains('family')) {
      result = result.where((p) => p.isFamilyFriendly).toList();
    }
    if (_tempFeatures.contains('halal')) {
      result = result.where((p) => p.isHalal).toList();
    }
    if (_tempFeatures.contains('delivery')) {
      result = result.where((p) => p.hasDelivery).toList();
    }
    if (_tempFeatures.contains('reservation')) {
      result = result.where((p) => p.hasReservation).toList();
    }

    return result.length;
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
    final hasLocation = widget.controller.userLat != null;

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
                  // 1. Sort
                  _buildSortSection(theme, hasLocation),
                  const SizedBox(height: 12),

                  // 2. Rating
                  _buildRatingSection(theme),
                  const SizedBox(height: 12),

                  // 3. Price
                  _buildPriceSection(theme),
                  const SizedBox(height: 12),

                  // 4. Amenities
                  _buildAmenitiesSection(theme),
                  const SizedBox(height: 12),

                  // 5. Features
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'إغلاق',
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.tune, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'تصفية النتائج',
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
              label: const Text('مسح'),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            )
          else
            const SizedBox(width: 48), // توازن مكاني
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // ACTIVE FILTERS ROW
  // ═══════════════════════════════════════════════════════════════

  Widget _buildActiveFiltersRow(ThemeData theme) {
    final chips = <Widget>[];

    if (_tempRating != null) {
      chips.add(_activeChip(
        theme,
        label: '⭐ ${_tempRating!.toStringAsFixed(0)}+ نجوم',
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
    for (final a in _tempAmenities) {
      chips.add(_activeChip(
        theme,
        label: _amenityLabel(a),
        onRemove: () => setState(() => _tempAmenities.remove(a)),
      ));
    }
    for (final f in _tempFeatures) {
      chips.add(_activeChip(
        theme,
        label: _featureLabel(f),
        onRemove: () => setState(() => _tempFeatures.remove(f)),
      ));
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: chips.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) => chips[i],
        ),
      ),
    );
  }

  Widget _activeChip(ThemeData theme,
      {required String label, required VoidCallback onRemove}) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 10, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close,
                  size: 16, color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
          const SizedBox(width: 4),
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
    return _sectionCard(
      theme,
      icon: Icons.swap_vert,
      title: 'الترتيب حسب',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _premiumChoice(
            label: 'الأنسب',
            selected: _tempSort == PlaceSort.recommended,
            onTap: () => setState(() => _tempSort = PlaceSort.recommended),
          ),
          _premiumChoice(
            label: 'الأعلى تقييماً',
            selected: _tempSort == PlaceSort.ratingDesc,
            onTap: () => setState(() => _tempSort = PlaceSort.ratingDesc),
          ),
          _premiumChoice(
            label: 'الأحدث',
            selected: _tempSort == PlaceSort.newest,
            onTap: () => setState(() => _tempSort = PlaceSort.newest),
          ),
          if (hasLocation)
            _premiumChoice(
              label: 'الأقرب إليك',
              selected: _tempSort == PlaceSort.distance,
              onTap: () => setState(() => _tempSort = PlaceSort.distance),
            ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(ThemeData theme) {
    return _sectionCard(
      theme,
      icon: Icons.star,
      title: 'التقييم',
      child: Wrap(
        spacing: 8,
        children: [
          _premiumChoice(
            label: 'الكل',
            selected: _tempRating == null,
            onTap: () => setState(() => _tempRating = null),
          ),
          _premiumChoice(
            label: '3+ ★★★',
            selected: _tempRating == 3.0,
            onTap: () => setState(() => _tempRating = 3.0),
          ),
          _premiumChoice(
            label: '4+ ★★★★',
            selected: _tempRating == 4.0,
            onTap: () => setState(() => _tempRating = 4.0),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(ThemeData theme) {
    return _sectionCard(
      theme,
      icon: Icons.attach_money,
      title: 'السعر',
      child: Wrap(
        spacing: 8,
        children: [
          _premiumChoice(
            label: 'الكل',
            selected: _tempPrice == null,
            onTap: () => setState(() => _tempPrice = null),
          ),
          _premiumChoice(
            label: 'اقتصادي',
            selected: _tempPrice == 1,
            onTap: () => setState(() => _tempPrice = 1),
          ),
          _premiumChoice(
            label: 'متوسط',
            selected: _tempPrice == 2,
            onTap: () => setState(() => _tempPrice = 2),
          ),
          _premiumChoice(
            label: 'مرتفع',
            selected: _tempPrice == 3,
            onTap: () => setState(() => _tempPrice = 3),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection(ThemeData theme) {
    return _sectionCard(
      theme,
      icon: Icons.checkroom,
      title: 'المرافق',
      badge: _tempAmenities.isNotEmpty ? '${_tempAmenities.length} محدد' : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _premiumFilter(
            label: 'واي فاي',
            selected: _tempAmenities.contains('wifi'),
            onTap: (v) => setState(() =>
                v ? _tempAmenities.add('wifi') : _tempAmenities.remove('wifi')),
          ),
          _premiumFilter(
            label: 'موقف سيارات',
            selected: _tempAmenities.contains('parking'),
            onTap: (v) => setState(() => v
                ? _tempAmenities.add('parking')
                : _tempAmenities.remove('parking')),
          ),
          _premiumFilter(
            label: 'دورات مياه',
            selected: _tempAmenities.contains('restroom'),
            onTap: (v) => setState(() => v
                ? _tempAmenities.add('restroom')
                : _tempAmenities.remove('restroom')),
          ),
          _premiumFilter(
            label: 'ذوي احتياجات',
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
    return _sectionCard(
      theme,
      icon: Icons.people_outline,
      title: 'الطابع',
      badge: _tempFeatures.isNotEmpty ? '${_tempFeatures.length} محدد' : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _premiumFilter(
            label: 'عائلي',
            selected: _tempFeatures.contains('family'),
            onTap: (v) => setState(() => v
                ? _tempFeatures.add('family')
                : _tempFeatures.remove('family')),
          ),
          _premiumFilter(
            label: 'حلال',
            selected: _tempFeatures.contains('halal'),
            onTap: (v) => setState(() =>
                v ? _tempFeatures.add('halal') : _tempFeatures.remove('halal')),
          ),
          _premiumFilter(
            label: 'دليفري',
            selected: _tempFeatures.contains('delivery'),
            onTap: (v) => setState(() => v
                ? _tempFeatures.add('delivery')
                : _tempFeatures.remove('delivery')),
          ),
          _premiumFilter(
            label: 'حجوزات',
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
    final count = _previewCount();
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
            onPressed: _apply,
            icon: Icon(
              hasResults ? Icons.check_circle_outline : Icons.search_off,
              size: 22,
            ),
            label: Text(
              hasResults ? 'عرض $count نتيجة' : 'لا توجد نتائج مطابقة',
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
    switch (price) {
      case 1:
        return 'اقتصادي';
      case 2:
        return 'متوسط';
      case 3:
        return 'مرتفع';
      default:
        return '';
    }
  }

  String _amenityLabel(String key) {
    switch (key) {
      case 'wifi':
        return 'واي فاي';
      case 'parking':
        return 'موقف';
      case 'restroom':
        return 'دورات مياه';
      case 'accessibility':
        return 'ذوي احتياجات';
      default:
        return key;
    }
  }

  String _featureLabel(String key) {
    switch (key) {
      case 'family':
        return 'عائلي';
      case 'halal':
        return 'حلال';
      case 'delivery':
        return 'دليفري';
      case 'reservation':
        return 'حجوزات';
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
