// lib/features/trip/widgets/wizard_step_wrapper.dart
//
// [v1.4 — 2026-10-19] — FIX: RenderFlex overflow in scrollable:false mode.
//   - FIX: Replaced Column(mainAxisSize.min) with Expanded for scrollable:false.
//   - KEPT: SingleChildScrollView for scrollable:true.

import 'package:flutter/material.dart';

class WizardStepWrapper extends StatelessWidget {
  final String? emoji;
  final IconData? icon;
  final String title;
  final String? subtitle;
  final Widget child;
  final bool scrollable;
  final Color? headerColor;
  final EdgeInsets? bodyPadding;

  const WizardStepWrapper({
    super.key,
    this.emoji,
    this.icon,
    required this.title,
    this.subtitle,
    required this.child,
    this.scrollable = true,
    this.headerColor,
    this.bodyPadding,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final padding = bodyPadding ?? const EdgeInsets.fromLTRB(20, 8, 20, 20);
    final header = _buildHeader(context);

    // 1. الوضع القابل للتمرير (الخطوات العادية)
    if (scrollable) {
      return SingleChildScrollView(
        padding: padding,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      );
    }

    // 2. الوضع غير القابل للتمرير (شاشة المعاينة Step6)
    // ✅ الحل الجذري: استخدام Expanded لإجبار المحتوى على البقاء داخل الحدود
    return Padding(
      padding: EdgeInsets.fromLTRB(
        padding.left,
        padding.top,
        padding.right,
        padding.bottom + bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: 24),
          Expanded(child: child), // ✅ يمنع الـ Overflow تماماً
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = headerColor ?? theme.colorScheme.primaryContainer;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
          ] else if (icon != null) ...[
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
          ],
          if (title.isNotEmpty)
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            if (title.isNotEmpty) const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
