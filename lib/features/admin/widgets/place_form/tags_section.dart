import 'package:flutter/material.dart';

class TagsSection extends StatelessWidget {
  final TextEditingController tagsCtrl;
  final bool isEditing;
  final ThemeData theme;

  const TagsSection({
    super.key,
    required this.tagsCtrl,
    required this.isEditing,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: tagsCtrl,
          readOnly: !isEditing,
          decoration: InputDecoration(
            labelText: 'الكلمات المفتاحية',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.tag),
            hintText: 'معلم, ميدان, نصب',
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
}
