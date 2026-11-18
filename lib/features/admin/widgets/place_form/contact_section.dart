import 'package:flutter/material.dart';

class ContactSection extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController facebookCtrl;
  final Widget priceDropdown;
  final bool isEditing;
  final ThemeData theme;

  const ContactSection({
    super.key,
    required this.phoneCtrl,
    required this.websiteCtrl,
    required this.emailCtrl,
    required this.facebookCtrl,
    required this.priceDropdown,
    required this.isEditing,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: phoneCtrl,
          readOnly: !isEditing,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
              labelText: 'رقم الهاتف',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.phone),
              filled: !isEditing,
              fillColor: !isEditing
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3)
                  : null),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: websiteCtrl,
          readOnly: !isEditing,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
              labelText: 'الموقع الإلكتروني',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.language),
              filled: !isEditing,
              fillColor: !isEditing
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3)
                  : null),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: emailCtrl,
          readOnly: !isEditing,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.email),
              filled: !isEditing,
              fillColor: !isEditing
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3)
                  : null),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: facebookCtrl,
          readOnly: !isEditing,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
              labelText: 'صفحة الفيسبوك',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.facebook),
              filled: !isEditing,
              fillColor: !isEditing
                  ? theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3)
                  : null),
        ),
        const SizedBox(height: 12),
        priceDropdown,
      ],
    );
  }
}
