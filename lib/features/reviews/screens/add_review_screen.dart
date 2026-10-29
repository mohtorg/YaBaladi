// lib/features/reviews/screens/add_review_screen.dart
//
// [v1.2 — 2026-10-28] — UI/UX ENHANCEMENT: Animated Stars, Live Counter, Progress Bar

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
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار تقييم من 1 إلى 5 نجوم'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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
            isEditing ? '✅ تم تحديث التقييم بنجاح' : '✅ تم نشر تقييمك بنجاح',
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
            '❌ خطأ: $e',
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
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          isEditing ? 'تعديل تقييمك' : 'اكتب تقييماً',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ═══════════════════════════════════════════════════════
                // 1. بطاقة المكان (لتذكير المستخدم)
                // ═══════════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.store,
                            color: theme.colorScheme.primary, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تقييمك لـ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              widget.place.nameAr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ═══════════════════════════════════════════════════════
                // 2. النجوم
                // ═══════════════════════════════════════════════════════
                Text(
                  'كيف كانت تجربتك؟',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final starIndex = i + 1;
                    final filled = _rating >= starIndex;
                    return AnimatedScale(
                      scale: filled ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      child: IconButton(
                        iconSize: 48,
                        icon: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: filled
                              ? Colors.amber.shade700
                              : Colors.grey.shade400,
                        ),
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _rating = starIndex),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _rating == 0
                        ? 'اختر التقييم المناسب'
                        : _ratingLabel(_rating),
                    key: ValueKey(_rating),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _rating == 0
                          ? theme.colorScheme.onSurfaceVariant
                          : Colors.amber.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // ═══════════════════════════════════════════════════════
                // 3. حقل التعليق + العدّاد
                // ═══════════════════════════════════════════════════════
                Row(
                  children: [
                    Text(
                      'اكتب تعليقك',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'مطلوب',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _commentController,
                  maxLines: 5,
                  maxLength: 500,
                  enabled: !_submitting,
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'الرجاء كتابة تعليقك';
                    }
                    if (val.trim().length < 5) {
                      return 'التعليق قصير جداً (5 أحرف على الأقل)';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'شاركنا تجربتك في هذا المكان…',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    counterText: '', // إخفاء العدّاد الافتراضي، نستخدم المخصص
                  ),
                ),
                const SizedBox(height: 4),
                // ✅ العدّاد المخصص
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'الحد الأدنى: 5 أحرف',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${_commentController.text.length} / 500',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _commentController.text.length > 450
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ═══════════════════════════════════════════════════════
                // 4. شريط التقدم (أثناء الإرسال)
                // ═══════════════════════════════════════════════════════
                if (_submitting)
                  Column(
                    children: [
                      const LinearProgressIndicator(minHeight: 4),
                      const SizedBox(height: 8),
                      Text(
                        'جارٍ حفظ تقييمك…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // ═══════════════════════════════════════════════════════
                // 5. زر الإرسال
                // ═══════════════════════════════════════════════════════
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
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _submitting
                        ? 'جارٍ الحفظ…'
                        : (isEditing ? 'حفظ التعديلات' : 'نشر التقييم'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ═══════════════════════════════════════════════════════
                // 6. ملاحظة
                // ═══════════════════════════════════════════════════════
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        size: 14, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      'تقييمك يساعد الآخرين على اتخاذ قرارهم',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    return switch (rating) {
      1 => '⭐ ضعيف جداً',
      2 => '⭐⭐ مقبول',
      3 => '⭐⭐⭐ جيد',
      4 => '⭐⭐⭐⭐ ممتاز',
      5 => '⭐⭐⭐⭐⭐ رائع!',
      _ => '',
    };
  }
}
