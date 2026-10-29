// lib/features/auth/widgets/auth_primary_button.dart
//
// [v1.1 — 2026-10-25] — FIX: Visible loading indicator on primary background
//   - ADDED: color: Theme.of(context).colorScheme.onPrimary to CircularProgressIndicator
//   - REMOVED: const from SizedBox (required because CircularProgressIndicator now uses Theme)
//   - KEPT: all logic identical.

import 'package:flutter/material.dart';

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48), // تحسين حجم الزر ليكون متناسقاً
      ),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                // [FIX] لون المؤشر يجب أن يكون متبايناً مع لون الزر
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
