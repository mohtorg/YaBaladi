// lib/features/reviews/widgets/add_review_sheet.dart
//
// [v1.0.1 — 2026-10-25] — FIX: Removed unsupported userPhotoUrl from Review, added isVerified
//   - FIXED: Review instantiation to match add_review_screen.dart structure
//   - KEPT: all UI, sheet logic, and focus handling identical.

import 'package:flutter/material.dart';

import '../../../models/review.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/reviews_controller.dart';

class AddReviewSheet extends StatefulWidget {
  const AddReviewSheet({
    super.key,
    required this.controller,
    required this.placeId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl = '',
  });

  final ReviewsController controller;
  final String placeId;
  final String userId;
  final String userName;
  final String userPhotoUrl;

  /// يعرض الـ BottomSheet ويُرجع:
  ///   - `true` عند نجاح الإرسال
  ///   - `null` عند الإلغاء
  static Future<bool?> show(
    BuildContext context, {
    required ReviewsController controller,
    required String placeId,
    required String userId,
    required String userName,
    String userPhotoUrl = '',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddReviewSheet(
        controller: controller,
        placeId: placeId,
        userId: userId,
        userName: userName,
        userPhotoUrl: userPhotoUrl,
      ),
    );
  }

  @override
  State<AddReviewSheet> createState() => _AddReviewSheetState();
}

class _AddReviewSheetState extends State<AddReviewSheet> {
  final _commentController = TextEditingController();
  final _commentFocus = FocusNode();

  double _rating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _commentFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _rating > 0 &&
      _commentController.text.trim().isNotEmpty &&
      !_isSubmitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    // [FIX] تعديل كائن الـ Review ليتوافق مع الموديل الخاص بك
    final review = Review(
      id: '',
      placeId: widget.placeId,
      userId: widget.userId,
      userName: widget.userName,
      // userPhotoUrl: widget.userPhotoUrl, // ⚠️ قم بإزالة التعليق إذا كان الموديل يدعم هذا الحقل
      rating: _rating,
      comment: _commentController.text.trim(),
      createdAt: DateTime.now(),
      isVerified:
          false, // [FIX] إضافة هذا الحقل لتفادي خطأ "Required parameter"
    );

    final ok = await widget.controller.submit(review);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              widget.controller.error ?? 'تعذّر إرسال المراجعة',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Drag Handle ───
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ─── Title ───
              Text(
                'اكتب مراجعتك',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'شارك تجربتك مع الآخرين',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // ─── Rating ───
              Text(
                'تقييمك',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starValue = i + 1;
                  final isFilled = starValue <= _rating;
                  return IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(
                              () => _rating = starValue.toDouble(),
                            ),
                    iconSize: 40,
                    tooltip: '$starValue نجوم',
                    icon: Icon(
                      isFilled ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                    ),
                  );
                }),
              ),
              if (_rating > 0) ...[
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    _ratingLabel(_rating),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ─── Comment ───
              Text(
                'تعليقك',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                focusNode: _commentFocus,
                enabled: !_isSubmitting,
                maxLines: 5,
                minLines: 3,
                maxLength: 1000,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'اكتب تجربتك…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),

              // ─── Buttons ───
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(null),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _canSubmit ? _submit : null,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, size: 18),
                      label: Text(
                        _isSubmitting ? 'جارٍ الإرسال…' : 'أرسل المراجعة',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: YaBaladiDesignTokens.space3),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(double r) {
    if (r >= 4.5) return 'ممتاز';
    if (r >= 3.5) return 'جيد جداً';
    if (r >= 2.5) return 'جيد';
    if (r >= 1.5) return 'مقبول';
    return 'ضعيف';
  }
}
