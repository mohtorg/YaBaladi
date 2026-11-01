// lib/features/admin/widgets/color_picker_dialog.dart
//
// [v1.2 — 2026-10-29] — FIX: إزالة RegExp كلياً (3 تحذيرات إهمال)
//   - _normalize / _isValidHex: فحص يدوي لستة أحرف hex (0-9 A-F).
//   - inputFormatters: _CharFilterFormatter بدل FilteringTextInputFormatter.allow(RegExp).
//   - KEPT: اللوحة والمعاينة والإدخال المخصص والتوقيعات العامة دون تغيير.
// [v1.1 — 2026-10-26] — BUILD FIX: Strict analyzer compliance, types normalized

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ═══════════════════════════════════════════════════════════════
// Helpers (بدون RegExp)
// ═══════════════════════════════════════════════════════════════

/// هل الرمز من 0-9 أو A-F أو a-f ؟
bool _isHexChar(int c) =>
    (c >= 48 && c <= 57) || // 0-9
    (c >= 65 && c <= 70) || // A-F
    (c >= 97 && c <= 102); // a-f

/// هل النص ستة أحرف hex بالضبط؟
bool _isHex6(String s) => s.length == 6 && s.codeUnits.every(_isHexChar);

/// منسّق إدخال يُبقي الأحرف المقبولة فقط، ويحافظ على موضع المؤشر.
class _CharFilterFormatter extends TextInputFormatter {
  final bool Function(int codeUnit) allow;

  _CharFilterFormatter(this.allow);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    final units = text.codeUnits;

    final kept = StringBuffer();
    final keptBefore = List<int>.filled(units.length + 1, 0);
    for (var i = 0; i < units.length; i++) {
      keptBefore[i] = kept.length;
      if (allow(units[i])) kept.writeCharCode(units[i]);
    }
    keptBefore[units.length] = kept.length;

    final filtered = kept.toString();
    if (filtered == text) return newValue;

    int map(int offset) {
      if (offset < 0) return offset;
      if (offset > units.length) return filtered.length;
      return keptBefore[offset];
    }

    final sel = newValue.selection;
    return TextEditingValue(
      text: filtered,
      selection: TextSelection(
        baseOffset: map(sel.baseOffset),
        extentOffset: map(sel.extentOffset),
        affinity: sel.affinity,
        isDirectional: sel.isDirectional,
      ),
      composing: TextRange.empty,
    );
  }
}

class ColorPickerDialog extends StatefulWidget {
  final String initialColor;

  const ColorPickerDialog({super.key, this.initialColor = '#0D6EFD'});

  /// Show the dialog and return the selected color as '#RRGGBB', or null.
  static Future<String?> show(
    BuildContext context, {
    String initialColor = '#0D6EFD',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ColorPickerDialog(initialColor: initialColor),
    );
  }

  @override
  State<ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<ColorPickerDialog> {
  // 36-color curated palette (6x6)
  static const List<String> _palette = [
    // Reds
    '#D32F2F', '#E53935', '#F44336', '#EF5350', '#E57373', '#FFCDD2',
    // Oranges
    '#E65100', '#EF6C00', '#F57C00', '#FB8C00', '#FFA726', '#FFCC80',
    // Yellows & Browns
    '#F9A825', '#FDD835', '#FFEB3B', '#8D6E63', '#6D4C41', '#4E342E',
    // Greens
    '#2E7D32', '#43A047', '#66BB6A', '#81C784', '#A5D6A7', '#C8E6C9',
    // Blues
    '#0D47A1', '#1565C0', '#1976D2', '#039BE5', '#2196F3', '#90CAF9',
    // Purples & Pinks
    '#3949AB', '#6A1B9A', '#8E24AA', '#D81B60', '#E91E63', '#F06292',
  ];

  static const String _defaultColor = '#0D6EFD';

  late String _selectedHex;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _selectedHex = _normalize(widget.initialColor);
    _hexController = TextEditingController(
      text: _selectedHex.replaceAll('#', ''),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  // ─── Helpers ───
  String _normalize(String input) {
    final cleaned = input.replaceAll('#', '').trim().toUpperCase();
    if (_isHex6(cleaned)) {
      return '#$cleaned';
    }
    return _defaultColor;
  }

  Color _parseHex(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return const Color(0xFF0D6EFD); // Fallback
    }
  }

  bool _isValidHex(String input) => _isHex6(input.trim());

  Color _contrastFor(Color bg) =>
      bg.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

  void _selectColor(String hex) {
    setState(() {
      _selectedHex = _normalize(hex);
      _hexController.text = _selectedHex.replaceAll('#', '');
    });
  }

  void _onHexChanged(String value) {
    if (_isValidHex(value)) {
      setState(() => _selectedHex = '#${value.toUpperCase()}');
    } else {
      setState(() {}); // rebuild for validation styling
    }
  }

  void _confirm() {
    final hexText = _hexController.text.trim();
    if (!_isValidHex(hexText)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء إدخال لون hex صحيح (6 أحرف: 0-9, A-F)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.of(context).pop('#${hexText.toUpperCase()}');
  }

  // ─── UI ───
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previewColor = _parseHex(_selectedHex);
    final hexText = _hexController.text.trim();
    final isValid = _isValidHex(hexText);
    final showError = hexText.isNotEmpty && !isValid;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('اختيار اللون'),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 280, maxWidth: 380),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Preview ───
              _PreviewCard(color: previewColor, hex: _selectedHex),
              const SizedBox(height: 16),

              // ─── Palette grid 6x6 ───
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.0, // ✅ استخدام 1.0 بدلاً من 1
                ),
                itemCount: _palette.length,
                itemBuilder: (_, i) {
                  final hex = _palette[i];
                  final color = _parseHex(hex);
                  final isSelected = _selectedHex == hex;
                  return _SwatchTile(
                    color: color,
                    isSelected: isSelected,
                    checkColor: _contrastFor(color),
                    onTap: () => _selectColor(hex),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ─── Custom hex input ───
              TextField(
                controller: _hexController,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [
                  _CharFilterFormatter(_isHexChar),
                  LengthLimitingTextInputFormatter(6),
                ],
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  letterSpacing: 3,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: 'لون مخصص (Hex)',
                  hintText: '0D6EFD',
                  prefixText: '# ',
                  prefixStyle: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  counterText: '',
                  border: const OutlineInputBorder(),
                  errorText:
                      showError ? 'يجب أن يكون 6 أحرف hex (0-9, A-F)' : null,
                  suffixIcon: isValid
                      ? Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                        )
                      : null,
                ),
                onChanged: _onHexChanged,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _confirm,
          icon: const Icon(Icons.check, size: 18),
          label: const Text('اختيار'),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Small sub-widgets
// ═══════════════════════════════════════════════════════════════

class _PreviewCard extends StatelessWidget {
  final Color color;
  final String hex;

  const _PreviewCard({required this.color, required this.hex});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 72,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          hex,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

class _SwatchTile extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final Color checkColor;
  final VoidCallback onTap;

  const _SwatchTile({
    required this.color,
    required this.isSelected,
    required this.checkColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final outline = Theme.of(context).colorScheme.outlineVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? checkColor : outline,
            width: isSelected ? 3 : 1,
          ),
        ),
        child:
            isSelected ? Icon(Icons.check, color: checkColor, size: 20) : null,
      ),
    );
  }
}
