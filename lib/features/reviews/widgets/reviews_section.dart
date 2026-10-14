// lib/features/reviews/widgets/reviews_section.dart
//
// [v1.0.2 — 2026-10-14] — Removed duplicate "Add Review" button in _EmptyState
//   - زر واحد فقط الآن (في _Header) — يحترم قاعدة UI/UX "عنصر رئيسي واحد"
//   - _EmptyState يعرض رسالة تشجيعية فقط + تلميح للزر أعلى
//
// [v1.0.1 — 2026-10-14] — Fixed FilledButton infinite width in Row
// [v1.0 — 2026-10-14] — F2.2: ReviewsSection widget

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/review.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/reviews_controller.dart';

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.currentUserId,
    required this.onAddReview,
  });

  final String? currentUserId;
  final VoidCallback onAddReview;

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ReviewsController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(
          average: ctrl.averageRating,
          count: ctrl.count,
          onAdd: onAddReview,
        ),
        const SizedBox(height: YaBaladiDesignTokens.space3),
        _Body(
          ctrl: ctrl,
          currentUserId: currentUserId,
          onAddReview: onAddReview,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.average,
    required this.count,
    required this.onAdd,
  });

  final double average;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'المراجعات',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              if (count > 0)
                Row(
                  children: [
                    _RatingStars(rating: average, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      average.toStringAsFixed(1),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($count)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'لا توجد مراجعات بعد',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          fit: FlexFit.loose,
          child: FilledButton.tonalIcon(
            onPressed: onAdd,
            icon: const Icon(Icons.rate_review_outlined, size: 18),
            label: const Text('أضف مراجعة'),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BODY (state router)
// ═══════════════════════════════════════════════════════════════

class _Body extends StatelessWidget {
  const _Body({
    required this.ctrl,
    required this.currentUserId,
    required this.onAddReview,
  });

  final ReviewsController ctrl;
  final String? currentUserId;
  final VoidCallback onAddReview;

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoading && ctrl.reviews.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (ctrl.hasError && ctrl.reviews.isEmpty) {
      return _ErrorState(message: ctrl.error ?? 'حدث خطأ');
    }

    if (ctrl.reviews.isEmpty) {
      return const _EmptyState();
    }

    return Column(
      children: [
        for (final r in ctrl.reviews) ...[
          _ReviewCard(
            review: r,
            isOwn: currentUserId != null && r.userId == currentUserId,
            onDelete: currentUserId != null && r.userId == currentUserId
                ? () => _confirmDelete(context, r)
                : null,
          ),
          const SizedBox(height: YaBaladiDesignTokens.space3),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, Review review) async {
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) {
        final dTheme = Theme.of(dctx);
        return AlertDialog(
          title: const Text('حذف المراجعة'),
          content: const Text('هل أنت متأكد من حذف مراجعتك؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dctx).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: dTheme.colorScheme.error,
              ),
              onPressed: () => Navigator.of(dctx).pop(true),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (currentUserId == null) return;

    final ok = await ctrl.remove(review.id, currentUserId!);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'تم حذف المراجعة' : (ctrl.error ?? 'تعذّر حذف المراجعة'),
          ),
        ),
      );
  }
}

// ═══════════════════════════════════════════════════════════════
// REVIEW CARD
// ═══════════════════════════════════════════════════════════════

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.isOwn,
    required this.onDelete,
  });

  final Review review;
  final bool isOwn;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateText = _formatDate(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(YaBaladiDesignTokens.space3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                imageUrl: review.userPhotoUrl,
                name: review.userName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName.isEmpty ? 'مستخدم' : review.userName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _RatingStars(rating: review.rating, size: 14),
                        if (dateText.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            dateText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwn && onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: 'حذف',
                  onPressed: onDelete,
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '';
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}

// ═══════════════════════════════════════════════════════════════
// AVATAR
// ═══════════════════════════════════════════════════════════════

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageUrl, required this.name});

  final String imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl.trim().isNotEmpty;
    final initial = _initial(name);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? Image.network(
              imageUrl,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _fallback(theme, initial),
            )
          : _fallback(theme, initial),
    );
  }

  Widget _fallback(ThemeData theme, String initial) => Text(
        initial,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      );

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '؟';
    return trimmed.substring(0, 1).toUpperCase();
  }
}

// ═══════════════════════════════════════════════════════════════
// RATING STARS
// ═══════════════════════════════════════════════════════════════

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final rounded = rating.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= rounded;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: size,
          color: Colors.amber.shade700,
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'كن أول من يشارك تجربته',
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'اضغط "أضف مراجعة" في الأعلى',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ERROR
// ═══════════════════════════════════════════════════════════════

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
