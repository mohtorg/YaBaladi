import 'package:flutter/material.dart';

import '../controllers/places_controller.dart';

/// Bottom Sheet للفلاتر المتقدمة.
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
  // Basic
  late double? _minRating;
  late int? _priceLevel;
  late PlaceSort _sort;

  // Multi-select
  late Set<String> _amenities;
  late Set<String> _features;
  late Set<String> _payments;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _minRating = c.minRating;
    _priceLevel = c.priceLevel;
    _sort = c.sort;
    _amenities = Set<String>.from(c.amenities);
    _features = Set<String>.from(c.features);
    _payments = Set<String>.from(c.payments);
  }

  void _apply() {
    widget.controller.setMinRating(_minRating);
    widget.controller.setPriceLevel(_priceLevel);
    widget.controller.setSort(_sort);
    widget.controller.setAmenities(_amenities);
    widget.controller.setFeatures(_features);
    widget.controller.setPayments(_payments);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _minRating = null;
      _priceLevel = null;
      _sort = PlaceSort.ratingDesc;
      _amenities.clear();
      _features.clear();
      _payments.clear();
    });
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (set.contains(value)) {
        set.remove(value);
      } else {
        set.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxH = MediaQuery.of(context).size.height * 0.85;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Header ───
            Text(
              'الفلاتر',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // ─── Scrollable content ───
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ═══════════ التقييم ═══════════
                    _SectionTitle(label: 'التقييم'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'الكل',
                          selected: _minRating == null,
                          onTap: () =>
                              setState(() => _minRating = null),
                        ),
                        _Chip(
                          label: '⭐ 3.0+',
                          selected: _minRating == 3.0,
                          onTap: () =>
                              setState(() => _minRating = 3.0),
                        ),
                        _Chip(
                          label: '⭐ 4.0+',
                          selected: _minRating == 4.0,
                          onTap: () =>
                              setState(() => _minRating = 4.0),
                        ),
                        _Chip(
                          label: '⭐ 4.5+',
                          selected: _minRating == 4.5,
                          onTap: () =>
                              setState(() => _minRating = 4.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ═══════════ السعر (بالجنيه المصري) ═══════════
                    _SectionTitle(label: 'السعر (بالجنيه المصري)'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'الكل',
                          selected: _priceLevel == null,
                          onTap: () =>
                              setState(() => _priceLevel = null),
                        ),
                        _Chip(
                          label: '< 100 ج.م',
                          selected: _priceLevel == 1,
                          onTap: () => setState(() => _priceLevel = 1),
                        ),
                        _Chip(
                          label: '< 500 ج.م',
                          selected: _priceLevel == 2,
                          onTap: () => setState(() => _priceLevel = 2),
                        ),
                        _Chip(
                          label: '< 1000 ج.م',
                          selected: _priceLevel == 3,
                          onTap: () => setState(() => _priceLevel = 3),
                        ),
                        _Chip(
                          label: '> 1000 ج.م',
                          selected: _priceLevel == 4,
                          onTap: () => setState(() => _priceLevel = 4),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ═══════════ المميزات ═══════════
                    _SectionTitle(label: 'المميزات'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'مناسب للعائلات',
                          icon: Icons.family_restroom,
                          selected: _features.contains('family'),
                          onTap: () => _toggle(_features, 'family'),
                        ),
                        _Chip(
                          label: 'حلال',
                          icon: Icons.restaurant,
                          selected: _features.contains('halal'),
                          onTap: () => _toggle(_features, 'halal'),
                        ),
                        _Chip(
                          label: 'توصيل',
                          icon: Icons.delivery_dining,
                          selected: _features.contains('delivery'),
                          onTap: () => _toggle(_features, 'delivery'),
                        ),
                        _Chip(
                          label: 'حجز',
                          icon: Icons.event_available,
                          selected: _features.contains('reservation'),
                          onTap: () => _toggle(_features, 'reservation'),
                        ),
                        _Chip(
                          label: 'عروض',
                          icon: Icons.local_offer_outlined,
                          selected: _features.contains('offers'),
                          onTap: () => _toggle(_features, 'offers'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ═══════════ المرافق ═══════════
                    _SectionTitle(label: 'المرافق'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'Wi-Fi',
                          icon: Icons.wifi,
                          selected: _amenities.contains('wifi'),
                          onTap: () => _toggle(_amenities, 'wifi'),
                        ),
                        _Chip(
                          label: 'مواقف',
                          icon: Icons.local_parking,
                          selected: _amenities.contains('parking'),
                          onTap: () => _toggle(_amenities, 'parking'),
                        ),
                        _Chip(
                          label: 'دورات المياه',
                          icon: Icons.wc,
                          selected: _amenities.contains('restroom'),
                          onTap: () => _toggle(_amenities, 'restroom'),
                        ),
                        _Chip(
                          label: 'إمكانية الوصول',
                          icon: Icons.accessible,
                          selected: _amenities.contains('accessibility'),
                          onTap: () =>
                              _toggle(_amenities, 'accessibility'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ═══════════ طرق الدفع ═══════════
                    _SectionTitle(label: 'طرق الدفع'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'نقدي',
                          icon: Icons.money,
                          selected: _payments.contains('cash'),
                          onTap: () => _toggle(_payments, 'cash'),
                        ),
                        _Chip(
                          label: 'بطاقة',
                          icon: Icons.credit_card,
                          selected: _payments.contains('card'),
                          onTap: () => _toggle(_payments, 'card'),
                        ),
                        _Chip(
                          label: 'إنستاباي',
                          icon: Icons.account_balance_wallet_outlined,
                          selected: _payments.contains('instapay'),
                          onTap: () => _toggle(_payments, 'instapay'),
                        ),
                        _Chip(
                          label: 'محفظة إلكترونية',
                          icon: Icons.phone_android,
                          selected: _payments.contains('wallet'),
                          onTap: () => _toggle(_payments, 'wallet'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ═══════════ الترتيب ═══════════
                    _SectionTitle(label: 'الترتيب'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: 'الأعلى تقييمًا',
                          selected: _sort == PlaceSort.ratingDesc,
                          onTap: () => setState(
                              () => _sort = PlaceSort.ratingDesc),
                        ),
                        _Chip(
                          label: 'الأكثر مراجعات',
                          selected: _sort == PlaceSort.reviewsDesc,
                          onTap: () => setState(
                              () => _sort = PlaceSort.reviewsDesc),
                        ),
                        _Chip(
                          label: 'الأبجدي',
                          selected: _sort == PlaceSort.nameAsc,
                          onTap: () => setState(
                              () => _sort = PlaceSort.nameAsc),
                        ),
                        _Chip(
                          label: 'الأحدث',
                          selected: _sort == PlaceSort.newest,
                          onTap: () =>
                              setState(() => _sort = PlaceSort.newest),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ─── Actions ───
            const SizedBox(height: 8),
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
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 10),
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: icon != null ? Icon(icon, size: 18) : null,
      label: Text(label),
    );
  }
}