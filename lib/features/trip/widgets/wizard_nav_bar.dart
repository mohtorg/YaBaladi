// lib/features/trip/widgets/wizard_nav_bar.dart
//
// [v1.0 — 2026-10-18] — Wave 5.2: Wizard Nav Bar
//   - Prev / Next buttons
//   - Loading state (spinner in next)
//   - Disabled logic (canProceed)
//   - Custom labels
//   - SafeArea (iOS notch)
//   - Optional "skip" button
import 'package:flutter/material.dart';

class WizardNavBar extends StatelessWidget {
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  /// هل Next مُفعّل؟
  final bool canProceed;

  /// في حالة loading؟
  final bool isLoading;

  /// تسمية زر Next (default: "التالي").
  final String nextLabel;

  /// تسمية زر Prev (default: "السابق").
  final String prevLabel;

  /// هل هذه آخر خطوة؟ (يُخفي Prev، ويُظهر nextLabel "حفظ")
  final bool isLast;

  /// نصوص بديلة لآخر خطوة.
  final String lastLabel;

  /// Optional: زر "تخطي" بجانب Prev.
  final VoidCallback? onSkip;
  final String skipLabel;

  const WizardNavBar({
    super.key,
    required this.onPrev,
    required this.onNext,
    this.canProceed = true,
    this.isLoading = false,
    this.nextLabel = 'التالي',
    this.prevLabel = 'السابق',
    this.isLast = false,
    this.lastLabel = 'حفظ',
    this.onSkip,
    this.skipLabel = 'تخطي',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showPrev = onPrev != null;
    final currentLabel = isLast ? lastLabel : nextLabel;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // ─── Skip (اختياري) ───
            if (onSkip != null) ...[
              TextButton(
                onPressed: isLoading ? null : onSkip,
                child: Text(skipLabel),
              ),
              const SizedBox(width: 4),
            ],

            // ─── Prev ───
            if (showPrev)
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onPrev,
                  child: Text(prevLabel),
                ),
              ),

            if (showPrev) const SizedBox(width: 12),

            // ─── Next ───
            Expanded(
              flex: showPrev ? 2 : 1,
              child: FilledButton.icon(
                onPressed: (!canProceed || isLoading) ? null : onNext,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isLast ? Icons.check : Icons.arrow_forward,
                        size: 18,
                      ),
                label: Text(
                  isLoading ? 'جارٍ…' : currentLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
