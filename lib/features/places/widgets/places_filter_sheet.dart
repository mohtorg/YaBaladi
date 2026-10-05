import 'package:flutter/material.dart';

import '../controllers/places_controller.dart';

/// Bottom Sheet للفلاتر المتقدمة:
/// - التقييم الأدنى
/// - مستوى السعر
/// - الترتيب
Future<void> showPlacesFilterSheet({
  required BuildContext context,
  required PlacesController controller,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(controller: controller),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.controller});

  final PlacesController controller;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late double? _minRating;
  late int? _priceLevel;
  late PlaceSort _sort;

  @override
  void initState() {
    super.initState();
    _minRating = widget.controller.minRating;
    _priceLevel = widget.controller.priceLevel;
    _sort = widget.controller.sort;
  }

  void _apply() {
    widget.controller.setMinRating(_minRating);
    widget.controller.setPriceLevel(_priceLevel);
    widget.controller.setSort(_sort);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _minRating = null;
      _priceLevel = null;
      _sort = PlaceSort.ratingDesc;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'الفلاتر',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // ─── التقييم ───
          _SectionTitle(label: 'التقييم'),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'الكل',
                selected: _minRating == null,
                onTap: () => setState(() => _minRating = null),
              ),
              _FilterChip(
                label: '⭐ 3.0+',
                selected: _minRating == 3.0,
                onTap: () => setState(() => _minRating = 3.0),
              ),
              _FilterChip(
                label: '⭐ 4.0+',
                selected: _minRating == 4.0,
                onTap: () => setState(() => _minRating = 4.0),
              ),
              _FilterChip(
                label: '⭐ 4.5+',
                selected: _minRating == 4.5,
                onTap: () => setState(() => _minRating = 4.5),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── السعر ───
          _SectionTitle(label: 'السعر'),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'الكل',
                selected: _priceLevel == null,
                onTap: () => setState(() => _priceLevel = null),
              ),
              _FilterChip(
                label: '\$',
                selected: _priceLevel == 1,
                onTap: () => setState(() => _priceLevel = 1),
              ),
              _FilterChip(
                label: '\$\$',
                selected: _priceLevel == 2,
                onTap: () => setState(() => _priceLevel = 2),
              ),
              _FilterChip(
                label: '\$\$\$',
                selected: _priceLevel == 3,
                onTap: () => setState(() => _priceLevel = 3),
              ),
              _FilterChip(
                label: '\$\$\$\$',
                selected: _priceLevel == 4,
                onTap: () => setState(() => _priceLevel = 4),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ─── الترتيب ───
          _SectionTitle(label: 'الترتيب'),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(
                label: 'الأعلى تقييمًا',
                selected: _sort == PlaceSort.ratingDesc,
                onTap: () => setState(() => _sort = PlaceSort.ratingDesc),
              ),
              _FilterChip(
                label: 'الأكثر مراجعات',
                selected: _sort == PlaceSort.reviewsDesc,
                onTap: () => setState(() => _sort = PlaceSort.reviewsDesc),
              ),
              _FilterChip(
                label: 'الأبجدي',
                selected: _sort == PlaceSort.nameAsc,
                onTap: () => setState(() => _sort = PlaceSort.nameAsc),
              ),
              _FilterChip(
                label: 'الأحدث',
                selected: _sort == PlaceSort.newest,
                onTap: () => setState(() => _sort = PlaceSort.newest),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── أزرار ───
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  child: const Text('مسح'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: _apply,
                  child: const Text('تطبيق'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      label: Text(label),
    );
  }
}