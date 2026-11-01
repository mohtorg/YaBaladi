// lib/features/admin/widgets/add_edit_filter_dialog.dart
//
// [v1.4 — 2026-10-29] — FIX:
//   - إزالة RegExp (تحذير الإهمال) واستبداله بالدالة _isValidSlug (نفس الشرط ^[a-z0-9_]+$).
//   - matchMode: إن كانت القيمة المخزنة خارج القائمة المعروفة تُضاف للقائمة
//     (كان Dropdown ينهار بـ assertion عند قيمة غير معروفة).
//   - صفوف الخيارات: مفتاح ObjectKey لكل صف حتى لا تنتقل الحالة بين الصفوف عند الحذف،
//     وتأجيل dispose للـ controllers إلى ما بعد الإطار.
//   - KEPT: جميع الحقول والتحقق والواجهة والتوقيعات دون تغيير.
// [v1.2 — 2026-10-26] — BUILD FIX: Changed initialValue to value in Dropdowns
// [v1.3 — 2026-10-27] — FIX ANALYZER: DropdownButtonFormField value → initialValue

import 'package:flutter/material.dart';

import '../../../../models/filter_definition.dart';

class AddEditFilterDialog extends StatefulWidget {
  final FilterDefinition? existing;
  final int? suggestedOrder;

  const AddEditFilterDialog({
    super.key,
    this.existing,
    this.suggestedOrder,
  });

  @override
  State<AddEditFilterDialog> createState() => _AddEditFilterDialogState();
}

class _AddEditFilterDialogState extends State<AddEditFilterDialog> {
  static const List<String> _knownMatchModes = [
    'exact',
    'contains',
    'gte',
    'lte',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _idCtrl;
  late final TextEditingController _nameArCtrl;
  late final TextEditingController _nameEnCtrl;
  late final TextEditingController _fieldKeyCtrl;
  late final TextEditingController _orderCtrl;
  late FilterType _type;
  late bool _isActive;
  late bool _isRequired;
  late String _matchMode;
  late List<String> _matchModes;
  late Set<String> _rolesAllowed;
  late List<_OptionDraft> _options;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _idCtrl = TextEditingController(text: e?.id ?? '');
    _nameArCtrl = TextEditingController(text: e?.nameAr ?? '');
    _nameEnCtrl = TextEditingController(text: e?.nameEn ?? '');
    _fieldKeyCtrl = TextEditingController(text: e?.fieldKey ?? '');
    _orderCtrl = TextEditingController(
      text: (e?.order ?? widget.suggestedOrder ?? 100).toString(),
    );
    _type = e?.type ?? FilterType.singleChoice;
    _isActive = e?.isActive ?? true;
    _isRequired = e?.isRequired ?? false;
    _matchMode = e?.matchMode ?? 'exact';
    // قيمة مخزنة غير معروفة: تُضاف للقائمة بدل أن ينهار الـ Dropdown.
    _matchModes = List<String>.from(_knownMatchModes);
    if (!_matchModes.contains(_matchMode)) _matchModes.add(_matchMode);
    _rolesAllowed = Set.from(
        e?.rolesAllowed ?? const ['user', 'merchant', 'moderator', 'admin']);
    _options =
        (e?.options ?? []).map((o) => _OptionDraft.fromOption(o)).toList();
    if (_options.isEmpty) _options.add(_OptionDraft.empty());
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _fieldKeyCtrl.dispose();
    _orderCtrl.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  /// يتحقق من المعرف: أحرف إنجليزية صغيرة وأرقام و _ فقط (مكافئ ^[a-z0-9_]+$).
  static bool _isValidSlug(String s) {
    if (s.isEmpty) return false;
    for (final c in s.codeUnits) {
      final bool ok = (c >= 97 && c <= 122) || // a-z
          (c >= 48 && c <= 57) || // 0-9
          c == 95; // _
      if (!ok) return false;
    }
    return true;
  }

  FilterDefinition? _buildResult() {
    if (!_formKey.currentState!.validate()) return null;
    final id = _isEdit ? widget.existing!.id : _idCtrl.text.trim();
    if (id.isEmpty) return null;
    return FilterDefinition(
      id: id,
      nameAr: _nameArCtrl.text.trim(),
      nameEn: _nameEnCtrl.text.trim(),
      type: _type,
      fieldKey: _fieldKeyCtrl.text.trim(),
      order: int.tryParse(_orderCtrl.text.trim()) ?? 100,
      isActive: _isActive,
      isRequired: _isRequired,
      rolesAllowed: _rolesAllowed.toList(),
      options: _options
          .where((o) => o.valueCtrl.text.trim().isNotEmpty)
          .map((o) => o.toOption())
          .toList(),
      matchMode: _matchMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(_isEdit ? 'تعديل الفلتر' : 'فلتر جديد'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── ID ───
                TextFormField(
                  controller: _idCtrl,
                  enabled: !_isEdit,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: 'المعرف (slug)',
                    helperText: _isEdit
                        ? 'لا يمكن تعديله'
                        : 'أحرف إنجليزية صغيرة وأرقام و _',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (_isEdit) return null;
                    if (v == null || v.trim().isEmpty) return 'مطلوب';
                    if (!_isValidSlug(v.trim())) {
                      return 'أحرف إنجليزية صغيرة فقط';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ─── Names ───
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameArCtrl,
                        decoration: const InputDecoration(
                          labelText: 'الاسم العربي',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _nameEnCtrl,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'English name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Type + fieldKey ───
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<FilterType>(
                        initialValue: _type,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'النوع',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: FilterType.singleChoice,
                              child: Text('اختيار واحد')),
                          DropdownMenuItem(
                              value: FilterType.multiChoice,
                              child: Text('اختيار متعدد')),
                          DropdownMenuItem(
                              value: FilterType.range, child: Text('نطاق')),
                          DropdownMenuItem(
                              value: FilterType.boolean, child: Text('تبديل')),
                          DropdownMenuItem(
                              value: FilterType.sort, child: Text('ترتيب')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _type = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _fieldKeyCtrl,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText: 'الحقل (fieldKey)',
                          hintText: 'hasWifi / priceLevel',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Order + matchMode ───
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _orderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'الترتيب',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _matchMode,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'نمط المطابقة',
                          border: OutlineInputBorder(),
                        ),
                        items: _matchModes
                            .map((m) =>
                                DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _matchMode = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Switches ───
                SwitchListTile.adaptive(
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('نشط'),
                  subtitle: const Text('يظهر في التطبيق'),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile.adaptive(
                  value: _isRequired,
                  onChanged: (v) => setState(() => _isRequired = v),
                  title: const Text('مطلوب'),
                  subtitle: const Text('يجب على المستخدم اختيار قيمة'),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 12),

                // ─── Roles allowed ───
                Text('من يرى الفلتر:', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: ['user', 'merchant', 'moderator', 'admin']
                      .map((r) => FilterChip(
                            label: Text(r),
                            selected: _rolesAllowed.contains(r),
                            onSelected: (sel) {
                              setState(() {
                                if (sel) {
                                  _rolesAllowed.add(r);
                                } else {
                                  _rolesAllowed.remove(r);
                                }
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),

                // ─── Options ───
                Text('الخيارات:', style: theme.textTheme.titleSmall),
                const SizedBox(height: 6),
                ..._options.asMap().entries.map((entry) {
                  final i = entry.key;
                  final o = entry.value;
                  return Padding(
                    key: ObjectKey(o),
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: o.valueCtrl,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'value ${i + 1}',
                              hintText: 'wifi',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: o.labelArCtrl,
                            decoration: InputDecoration(
                              labelText: 'labelAr ${i + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: o.labelEnCtrl,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'labelEn ${i + 1}',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Colors.red),
                          onPressed: _options.length > 1
                              ? () {
                                  setState(() => _options.removeAt(i));
                                  // التخلص من الـ controllers بعد إزالة الصف من الشجرة.
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) => o.dispose());
                                }
                              : null,
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () =>
                      setState(() => _options.add(_OptionDraft.empty())),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة خيار'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: () {
            final result = _buildResult();
            if (result != null) Navigator.pop(context, result);
          },
          icon: const Icon(Icons.check, size: 18),
          label: Text(_isEdit ? 'حفظ' : 'إنشاء'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Draft option
// ═══════════════════════════════════════════════════════════════

class _OptionDraft {
  final TextEditingController valueCtrl;
  final TextEditingController labelArCtrl;
  final TextEditingController labelEnCtrl;

  _OptionDraft({
    required this.valueCtrl,
    required this.labelArCtrl,
    required this.labelEnCtrl,
  });

  factory _OptionDraft.empty() => _OptionDraft(
        valueCtrl: TextEditingController(),
        labelArCtrl: TextEditingController(),
        labelEnCtrl: TextEditingController(),
      );

  factory _OptionDraft.fromOption(FilterOption o) => _OptionDraft(
        valueCtrl: TextEditingController(text: o.value),
        labelArCtrl: TextEditingController(text: o.labelAr),
        labelEnCtrl: TextEditingController(text: o.labelEn),
      );

  FilterOption toOption() => FilterOption(
        value: valueCtrl.text.trim(),
        labelAr: labelArCtrl.text.trim(),
        labelEn: labelEnCtrl.text.trim(),
      );

  void dispose() {
    valueCtrl.dispose();
    labelArCtrl.dispose();
    labelEnCtrl.dispose();
  }
}
