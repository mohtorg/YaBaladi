// lib/features/admin/widgets/icon_picker_dialog.dart
//
// [Wave 10 — file 7/12] — 2026-10-24
// Icon Picker Dialog for Category management.
//
// Reads from Category.availableIcons (v2.0) — single source of truth.
// Returns the icon's string key (e.g. 'restaurant') or null on cancel.
//
// Usage:
//   final iconName = await IconPickerDialog.show(
//     context,
//     initialIconName: category.iconName,
//     accentColor: category.color,
//   );
//   if (iconName != null) { ... }

import 'package:flutter/material.dart';

import '../../../models/category.dart';

class IconPickerDialog extends StatefulWidget {
  final String initialIconName;
  final Color? accentColor;

  const IconPickerDialog({
    super.key,
    this.initialIconName = 'category',
    this.accentColor,
  });

  /// Show the dialog and return the selected icon key, or null.
  static Future<String?> show(
    BuildContext context, {
    String initialIconName = 'category',
    Color? accentColor,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => IconPickerDialog(
        initialIconName: initialIconName,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  late String _selected;
  late final TextEditingController _searchController;
  String _query = '';

  // ═══════════════════════════════════════════════════════════════
  // Arabic labels for common icons (search aid only).
  // Any icon key not in this map is still displayed — just searched
  // by its English key.
  // ═══════════════════════════════════════════════════════════════
  static const Map<String, String> _arabicLabels = {
    'restaurant': 'مطعم',
    'coffee': 'قهوة',
    'beach_access': 'شاطئ',
    'hotel': 'فندق',
    'family_restroom': 'عائلة',
    'account_balance': 'معلم',
    'shopping_bag': 'تسوق',
    'park': 'حديقة',
    'event': 'فعالية',
    'category': 'عام',
    'shopping_cart': 'عربة تسوق',
    'store': 'متجر',
    'storefront': 'واجهة متجر',
    'local_mall': 'مول',
    'local_cafe': 'مقهى',
    'local_bar': 'بار',
    'local_pizza': 'بيتزا',
    'local_gas_station': 'محطة وقود',
    'local_hospital': 'مستشفى',
    'local_pharmacy': 'صيدلية',
    'local_library': 'مكتبة',
    'local_laundry_service': 'غسيل',
    'local_atm': 'صراف',
    'local_parking': 'موقف',
    'restaurant_menu': 'قائمة طعام',
    'fastfood': 'وجبات سريعة',
    'bakery_dining': 'مخبز',
    'lunch_dining': 'غداء',
    'dinner_dining': 'عشاء',
    'brunch_dining': 'فطور',
    'icecream': 'مثلجات',
    'cake': 'كيك',
    'wine_bar': 'بار نبيذ',
    'sports_bar': 'بار رياضي',
    'nightlife': 'حياة ليلية',
    'casino': 'كازينو',
    'attractions': 'جاذبية',
    'museum': 'متحف',
    'theater_comedy': 'مسرح',
    'movie': 'سينما',
    'music_note': 'موسيقى',
    'sports_soccer': 'ملعب كرة',
    'sports_basketball': 'ملعب سلة',
    'fitness_center': 'صالة رياضية',
    'spa': 'سبا',
    'pool': 'مسبح',
    'child_care': 'رعاية أطفال',
    'toys': 'ألعاب',
    'pets': 'حيوانات',
    'church': 'كنيسة',
    'mosque': 'مسجد',
    'school': 'مدرسة',
    'university': 'جامعة',
    'business': 'أعمال',
    'work': 'عمل',
    'apartment': 'سكن',
    'home': 'منزل',
    'villa': 'فيلا',
    'house': 'بيت',
    'location_city': 'مدينة',
    'map': 'خريطة',
    'terrain': 'تضاريس',
    'forest': 'غابة',
    'water': 'ماء',
    'sailing': 'إبحار',
    'flight': 'طيران',
    'train': 'قطار',
    'directions_bus': 'أتوبيس',
    'directions_car': 'سيارة',
    'directions_bike': 'دراجة',
    'anchor': 'مرسى',
    'tour': 'جولة',
    'photo_camera': 'كاميرا',
    'camera_alt': 'تصوير',
    'image': 'صورة',
    'palette': 'فن',
    'brush': 'رسم',
    'library_music': 'موسيقى',
    'menu_book': 'كتاب',
    'auto_stories': 'قصص',
    'celebration': 'احتفال',
    'cake_outlined': 'احتفال',
  };

  @override
  void initState() {
    super.initState();
    _selected = _validKey(widget.initialIconName);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _validKey(String key) =>
      Category.availableIcons.containsKey(key) ? key : 'category';

  // ─── Filtering ───
  List<MapEntry<String, IconData>> _filteredIcons() {
    final q = _query.trim().toLowerCase();
    final all = Category.availableIcons.entries.toList();

    // Sort by key for stable display
    all.sort((a, b) => a.key.compareTo(b.key));

    if (q.isEmpty) return all;

    return all.where((entry) {
      final key = entry.key.toLowerCase();
      final ar = _arabicLabels[entry.key] ?? '';
      return key.contains(q) || ar.contains(q);
    }).toList();
  }

  // ─── UI ───
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;
    final icons = _filteredIcons();
    final selectedIcon = Category.availableIcons[_selected] ?? Icons.category;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.emoji_emotions_outlined, color: accent),
          const SizedBox(width: 8),
          const Text('اختيار الأيقونة'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 300,
          maxWidth: 420,
          maxHeight: 520,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Preview ───
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Column(
                children: [
                  Icon(selectedIcon, size: 44, color: accent),
                  const SizedBox(height: 6),
                  Text(
                    _selected,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_arabicLabels[_selected] != null)
                    Text(
                      _arabicLabels[_selected]!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── Search ───
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم الإنجليزي أو العربي...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '${icons.length} أيقونة متاحة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ─── Grid ───
            Expanded(
              child: icons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: theme.colorScheme.outline,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد أيقونات مطابقة',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: icons.length,
                      itemBuilder: (_, i) {
                        final entry = icons[i];
                        final isSelected = entry.key == _selected;
                        return _IconTile(
                          icon: entry.value,
                          label: entry.key,
                          accent: accent,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _selected = entry.key);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_selected),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('اختيار'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Private tile widget
// ═══════════════════════════════════════════════════════════════

class _IconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final bool isSelected;
  final VoidCallback onTap;

  const _IconTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outlineVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accent : outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? accent : theme.colorScheme.onSurface,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  color:
                      isSelected ? accent : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
