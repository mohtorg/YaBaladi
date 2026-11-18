// lib/features/admin/widgets/district_form_dialog.dart
// [v1.2 — 2026-11-15] — LINTER FIX: Added curly braces to single-line if statement in _submit.
// [v1.1 — FIXED] — UI & UX ENHANCEMENTS:
//   - ADDED: SingleChildScrollView to prevent keyboard overflow.
//   - ADDED: Unfocus keyboard on submit.
//   - KEPT: All validation, return types, and logic intact.

import 'package:flutter/material.dart';

import '../../../models/district.dart';

class DistrictFormDialog extends StatefulWidget {
  final District? initial;
  const DistrictFormDialog({super.key, this.initial});

  /// Helper: يعرض النافذة ويعيد النتيجة.
  static Future<Map<String, String>?> show(
    BuildContext context, {
    District? initial,
  }) {
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => DistrictFormDialog(initial: initial),
    );
  }

  @override
  State<DistrictFormDialog> createState() => _DistrictFormDialogState();
}

class _DistrictFormDialogState extends State<DistrictFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEnCtrl;

  @override
  void initState() {
    super.initState();
    _nameArCtrl = TextEditingController(text: widget.initial?.nameAr ?? '');
    _nameEnCtrl = TextEditingController(text: widget.initial?.nameEn ?? '');
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    // ✅ إخفاء الكيبورد قبل التحقق والحفظ
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop({
      'nameAr': _nameArCtrl.text.trim(),
      'nameEn': _nameEnCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initial != null;
    return AlertDialog(
      title: Text(isEdit ? 'تعديل الحي' : 'إضافة حي جديد'),
      content: Form(
        key: _formKey,
        // ✅ تغليف المحتوى بـ SingleChildScrollView لمنع الانكسار عند ظهور الكيبورد
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameArCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالعربية *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameEnCtrl,
                decoration: const InputDecoration(
                  labelText: 'الاسم بالإنجليزية (اختياري)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.language),
                ),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(isEdit ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }
}
