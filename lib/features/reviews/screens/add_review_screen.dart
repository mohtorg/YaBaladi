// lib/features/reviews/screens/add_review_screen.dart
//
// [v1.1 — 2026-10-26] — FIX: Null Safety in displayName (uses AuthController getter)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../../models/place.dart';
import '../../../models/review.dart';
import '../../../repositories/reviews_repository.dart';

class AddReviewScreen extends StatefulWidget {
  final Place place;
  final Review? existingReview;

  const AddReviewScreen({
    super.key,
    required this.place,
    this.existingReview,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _rating = widget.existingReview!.rating.round();
      _commentController.text = widget.existingReview!.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _rating > 0 && _commentController.text.trim().isNotEmpty && !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final auth = context.read<AuthController>();

    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول لإضافة تقييم'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final isEditing = widget.existingReview != null;
    final repo = ReviewsRepository();

    // ✅ [FIX] استخدام auth.displayName الآمن (غير قابل للـ null)
    final safeName = auth.displayName;

    final review = Review(
      id: widget.existingReview?.id ?? '',
      placeId: widget.place.id,
      userId: auth.uid,
      userName: safeName,
      rating: _rating.toDouble(),
      comment: _commentController.text.trim(),
      createdAt: widget.existingReview?.createdAt,
      isVerified: widget.existingReview?.isVerified ?? false,
    );

    try {
      if (isEditing) {
        await repo.update(review);
      } else {
        await repo.create(review);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? '✅ تم تحديث التقييم' : '✅ تم حفظ التقييم',
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ: $e',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingReview != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'تعديل تقييمك' : 'اكتب تقييماً'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.place.nameAr,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Text(
                'تقييمك',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  final filled = _rating >= starIndex;
                  return IconButton(
                    iconSize: 48,
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: filled ? Colors.amber.shade700 : Colors.grey,
                    ),
                    onPressed: _submitting
                        ? null
                        : () => setState(() => _rating = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _rating == 0 ? 'اختر التقييم' : _ratingLabel(_rating),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Text(
                    'تعليقك',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(مطلوب)',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 1000,
                enabled: !_submitting,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'شاركنا تجربتك في هذا المكان…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _canSubmit ? _submit : null,
                icon: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _submitting
                      ? 'جارٍ الحفظ…'
                      : (isEditing ? 'حفظ التعديلات' : 'نشر التقييم'),
                  style: const TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    return switch (rating) {
      1 => '⭐ ضعيف',
      2 => '⭐⭐ مقبول',
      3 => '⭐⭐⭐ جيد',
      4 => '⭐⭐⭐⭐ ممتاز',
      5 => '⭐⭐⭐⭐⭐ رائع',
      _ => '',
    };
  }
}
