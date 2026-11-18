// lib/features/rating/widgets/report_dialog.dart
// [v1.0 — 2026-11-12] — REPORT DIALOG:
//   - Shown when the user taps "إبلاغ" on any RatingCardWidget.
//   - 7 standardized reasons (ReportReason enum).
//   - Optional note (max 300 chars).
//   - Returns ReportResult? (null if cancelled).

import 'package:flutter/material.dart';

import '../../../models/moderation_log_model.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';

class ReportResult {
  final ReportReason reason;
  final String? note;
  const ReportResult({required this.reason, this.note});
}

Future<ReportResult?> showReportDialog(BuildContext context) {
  return showDialog<ReportResult>(
    context: context,
    builder: (_) => const _ReportDialog(),
  );
}

class _ReportDialog extends StatefulWidget {
  const _ReportDialog();

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  ReportReason? _selectedReason;
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedReason == null) {
      return;
    }
    final note = _noteController.text.trim();
    Navigator.pop(
      context,
      ReportResult(
        reason: _selectedReason!,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.flag_outlined,
            color: theme.colorScheme.error,
            size: 22,
          ),
          const SizedBox(width: YaBaladiDesignTokens.space2),
          Expanded(
            child: Text(
              'الإبلاغ عن تقييم',
              style: YaBaladiTypography.headingLabel.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ما سبب الإبلاغ؟',
                style: YaBaladiTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: YaBaladiDesignTokens.space1),
              Text(
                'سيتم مراجعة البلاغ من فريق الإشراف. لن يُحذف التقييم تلقائياً.',
                style: YaBaladiTypography.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: YaBaladiDesignTokens.space3),
              ...ReportReason.values.map((reason) => _buildOption(reason)),
              const SizedBox(height: YaBaladiDesignTokens.space3),
              TextField(
                controller: _noteController,
                maxLines: 3,
                maxLength: 300,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة إضافية (اختياري)',
                  hintText: 'أضف تفاصيل تساعد فريق المراجعة...',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _selectedReason == null ? null : _submit,
          icon: const Icon(Icons.send, size: 18),
          label: const Text('إرسال البلاغ'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildOption(ReportReason reason) {
    final theme = Theme.of(context);
    final selected = _selectedReason == reason;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedReason = reason),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.errorContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.error
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                  size: 20,
                ),
              ),
              const SizedBox(width: YaBaladiDesignTokens.space2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason.labelAr,
                      style: YaBaladiTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reason.descriptionAr,
                      style: YaBaladiTypography.caption.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
