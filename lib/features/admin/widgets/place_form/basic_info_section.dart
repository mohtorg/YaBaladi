import 'package:flutter/material.dart';

class BasicInfoSection extends StatelessWidget {
  final TextEditingController nameArCtrl;
  final TextEditingController nameEnCtrl;
  final TextEditingController descCtrl;
  final bool isEditing;
  final ThemeData theme;

  const BasicInfoSection({
    super.key,
    required this.nameArCtrl,
    required this.nameEnCtrl,
    required this.descCtrl,
    required this.isEditing,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
            theme, Icons.info_outline, 'المعلومات الأساسية', 'الاسم والوصف'),
        const SizedBox(height: 12),
        TextFormField(
          controller: nameArCtrl,
          readOnly: !isEditing,
          decoration: InputDecoration(
            labelText: 'اسم المكان (بالعربية) *',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.title),
            hintText: 'مثال: ميدان الشهداء',
            filled: !isEditing,
            fillColor: !isEditing
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3)
                : null,
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: nameEnCtrl,
          readOnly: !isEditing,
          decoration: InputDecoration(
            labelText: 'اسم المكان (بالإنجليزية)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.language),
            filled: !isEditing,
            fillColor: !isEditing
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: descCtrl,
          maxLines: 3,
          readOnly: !isEditing,
          decoration: InputDecoration(
            labelText: 'الوصف (اختياري)',
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
            prefixIcon: const Icon(Icons.description),
            filled: !isEditing,
            fillColor: !isEditing
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3)
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
      ThemeData theme, IconData icon, String title, String subtitle) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(subtitle,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    ]);
  }
}
