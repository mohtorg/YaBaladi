// lib/features/admin/widgets/add_edit_category_dialog.dart
//
// [v1.3 — 2026-10-26] — BULLETPROOF BUILD: SwitchListTile standard, strict analyzer compliance

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/category.dart';
import '../../../repositories/categories_repository.dart';
import 'color_picker_dialog.dart';
import 'icon_picker_dialog.dart';

class AddEditCategoryDialog extends StatefulWidget {
  final Category? category;
  final CategoriesRepository? repository;
  final int? suggestedOrder;

  const AddEditCategoryDialog({
    super.key,
    this.category,
    this.repository,
    this.suggestedOrder,
  });

  bool get isEditMode => category != null;

  static Future<bool?> show(
    BuildContext context, {
    Category? category,
    CategoriesRepository? repository,
    int? suggestedOrder,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddEditCategoryDialog(
        category: category,
        repository: repository,
        suggestedOrder: suggestedOrder,
      ),
    );
  }

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _idController;
  late final TextEditingController _nameArController;
  late final TextEditingController _nameEnController;
  late final TextEditingController _orderController;
  late final TextEditingController _aliasesController;
  late final TextEditingController _searchKeywordsController;

  late String _iconName;
  late String _colorHex;
  late bool _isActive;
  late bool _isFeatured;

  bool _saving = false;

  CategoriesRepository get _repo => widget.repository ?? CategoriesRepository();

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _idController = TextEditingController(text: cat?.id ?? '');
    _nameArController = TextEditingController(text: cat?.nameAr ?? '');
    _nameEnController = TextEditingController(text: cat?.nameEn ?? '');
    _orderController = TextEditingController(
      text: (cat?.order ?? widget.suggestedOrder ?? 100).toString(),
    );
    _aliasesController = TextEditingController(
      text: (cat?.aliases ?? const <String>[]).join(', '),
    );
    _searchKeywordsController = TextEditingController(
      text: (cat?.searchKeywords ?? const <String>[]).join(', '),
    );
    _iconName = cat?.iconName ?? 'category';
    _colorHex = cat?.colorHex ?? '#0D6EFD';
    _isActive = cat?.isActive ?? true;
    _isFeatured = cat?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameArController.dispose();
    _nameEnController.dispose();
    _orderController.dispose();
    _aliasesController.dispose();
    _searchKeywordsController.dispose();
    super.dispose();
  }

  // ─── Helpers ───
  List<String> _splitList(String input) => input
      .split(RegExp(r'[,\n]'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  String? _validateSlug(String? value) {
    if (value == null || value.trim().isEmpty) return 'المعرف مطلوب';
    final v = value.trim();
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(v)) {
      return 'حروف إنجليزية صغيرة وأرقام و _ فقط';
    }
    if (v.length < 2) return 'المعرف قصير جداً';
    if (v.length > 50) return 'المعرف طويل جداً';
    return null;
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) return '$label مطلوب';
    return null;
  }

  String? _validateOrder(String? value) {
    if (value == null || value.trim().isEmpty) return 'الترتيب مطلوب';
    final n = int.tryParse(value.trim());
    if (n == null) return 'يجب أن يكون رقماً';
    if (n < 1 || n > 9999) return 'الترتيب بين 1 و 9999';
    return null;
  }

  // ─── Save ───
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final id = _idController.text.trim();
    final nameAr = _nameArController.text.trim();
    final nameEn = _nameEnController.text.trim();
    final order = int.parse(_orderController.text.trim());
    final aliases = _splitList(_aliasesController.text);
    final keywords = _splitList(_searchKeywordsController.text);

    try {
      if (widget.isEditMode) {
        await _repo.update(id, {
          'nameAr': nameAr,
          'nameEn': nameEn,
          'iconName': _iconName,
          'colorHex': _colorHex,
          'order': order,
          'isActive': _isActive,
          'isFeatured': _isFeatured,
          'aliases': aliases,
          'searchKeywords': keywords,
          'updatedAt': DateTime.now(),
        });
      } else {
        // Duplicate ID check
        final existing = await _repo.getById(id);
        if (existing != null) {
          if (!mounted) return;
          setState(() => _saving = false);
          _showError('المعرف "$id" مستخدم مسبقاً. اختر معرّفاً آخر.');
          return;
        }

        final category = Category(
          id: id,
          nameAr: nameAr,
          nameEn: nameEn,
          iconName: _iconName,
          colorHex: _colorHex,
          order: order,
          isActive: _isActive,
          isFeatured: _isFeatured,
          aliases: aliases,
          searchKeywords: keywords,
          placesCount: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _repo.create(id, category);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('فشل الحفظ: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Pickers ───
  Future<void> _pickIcon() async {
    final selected = await IconPickerDialog.show(
      context,
      initialIconName: _iconName,
      accentColor: _parseHex(_colorHex),
    );
    if (selected != null && mounted) {
      setState(() => _iconName = selected);
    }
  }

  Future<void> _pickColor() async {
    final selected = await ColorPickerDialog.show(
      context,
      initialColor: _colorHex,
    );
    if (selected != null && mounted) {
      setState(() => _colorHex = selected);
    }
  }

  Color _parseHex(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF0D6EFD);
    }
  }

  // ─── UI ───
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _parseHex(_colorHex);
    final title = widget.isEditMode ? 'تعديل التصنيف' : 'تصنيف جديد';
    final iconData = Category.availableIcons[_iconName] ?? Icons.category;

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            widget.isEditMode ? Icons.edit_outlined : Icons.add_circle_outline,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Preview banner ───
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(iconData, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameArController.text.isEmpty
                                  ? 'اسم التصنيف'
                                  : _nameArController.text,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _nameEnController.text.isEmpty
                                  ? 'Category name'
                                  : _nameEnController.text,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ─── ID (slug) ───
                TextFormField(
                  controller: _idController,
                  enabled: !widget.isEditMode,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'المعرف (slug)',
                    hintText: 'restaurants',
                    helperText: widget.isEditMode
                        ? 'لا يمكن تعديل المعرف بعد الإنشاء'
                        : 'أحرف إنجليزية صغيرة، أرقام، و _ فقط',
                    prefixIcon: const Icon(Icons.tag),
                    border: const OutlineInputBorder(),
                    suffixIcon: widget.isEditMode
                        ? Icon(
                            Icons.lock,
                            size: 18,
                            color: theme.colorScheme.outline,
                          )
                        : null,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-z0-9_]')),
                  ],
                  validator: widget.isEditMode ? null : (v) => _validateSlug(v),
                ),
                const SizedBox(height: 12),

                // ─── Names (AR + EN) ───
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameArController,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(
                          labelText: 'الاسم العربي',
                          hintText: 'مطاعم',
                          prefixIcon: Icon(Icons.abc),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) => _validateRequired(v, 'الاسم العربي'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _nameEnController,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'الاسم الإنجليزي',
                          hintText: 'Restaurants',
                          prefixIcon: Icon(Icons.language),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (v) =>
                            _validateRequired(v, 'الاسم الإنجليزي'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Icon & Color pickers ───
                Row(
                  children: [
                    Expanded(
                      child: _PickerButton(
                        label: 'الأيقونة',
                        value: _iconName,
                        leading: Icon(iconData, color: accent),
                        onTap: _pickIcon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PickerButton(
                        label: 'اللون',
                        value: _colorHex,
                        leading: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant,
                            ),
                          ),
                        ),
                        onTap: _pickColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Order ───
                TextFormField(
                  controller: _orderController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'الترتيب',
                    hintText: '10',
                    helperText: 'رقم أصغر = يظهر أولاً',
                    prefixIcon: Icon(Icons.format_list_numbered),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateOrder,
                ),
                const SizedBox(height: 16),

                // ─── Flags ───
                _SwitchTile(
                  title: 'نشط',
                  subtitle: 'يظهر في التطبيق للمستخدمين',
                  icon: Icons.visibility_outlined,
                  value: _isActive,
                  accent: accent,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 6),
                _SwitchTile(
                  title: 'مميز',
                  subtitle: 'يظهر في أعلى القائمة (Featured)',
                  icon: Icons.star_outline,
                  value: _isFeatured,
                  accent: accent,
                  onChanged: (v) => setState(() => _isFeatured = v),
                ),
                const SizedBox(height: 16),

                // ─── Aliases ───
                _ListField(
                  controller: _aliasesController,
                  label: 'المرادفات (aliases)',
                  hint: 'restaurant, food, مطعم',
                  helper: 'افصل بفاصلة. تُستخدم للبحث والاستيراد.',
                  icon: Icons.alt_route,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),

                // ─── Search keywords ───
                _ListField(
                  controller: _searchKeywordsController,
                  label: 'كلمات البحث',
                  hint: 'restaurant, مطعم, اكل',
                  helper: 'افصل بفاصلة. تُحسّن نتائج البحث.',
                  icon: Icons.search,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(_saving ? 'جاري الحفظ...' : 'حفظ'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

class _PickerButton extends StatelessWidget {
  final String label;
  final String value;
  final Widget leading;
  final VoidCallback onTap;

  const _PickerButton({
    required this.label,
    required this.value,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      // ✅ [FIX] استخدام SwitchListTile العادي بدلاً من adaptive
      // لأن activeThumbColor مدعومة بشكل أفضل فيه.
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        secondary: Icon(
          icon,
          color: value ? accent : theme.colorScheme.outline,
        ),
        title: Text(title, style: theme.textTheme.bodyMedium),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        activeTrackColor: accent.withValues(alpha: 0.5),
        activeThumbColor: accent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}

class _ListField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String helper;
  final IconData icon;
  final VoidCallback onChanged;

  const _ListField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.helper,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final count = controller.text
        .split(RegExp(r'[,\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .length;

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixText: count > 0 ? '$count عنصر' : null,
        suffixStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
