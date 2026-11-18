// lib/features/rating/widgets/rating_card_widget.dart
// [v1.1 — 2026-11-12] — VERIFIED: No changes needed for governance.
//   - This widget is a pure presentation layer. It accepts `onReport` as an
//     optional callback; the caller is responsible for wiring it.

import 'package:flutter/material.dart';
import '../../../models/rating_model.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';

import 'trust_badge_widget.dart';

class RatingCardWidget extends StatelessWidget {
  final RatingModel rating;
  final VoidCallback? onHelpful;
  final VoidCallback? onReport;

  const RatingCardWidget({
    super.key,
    required this.rating,
    this.onHelpful,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateStr =
        '${rating.createdAt.year}/${rating.createdAt.month.toString().padLeft(2, '0')}/${rating.createdAt.day.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: YaBaladiDesignTokens.space3),
      child: Padding(
        padding: YaBaladiDesignTokens.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.10),
                  child: Text(
                    rating.userDisplayName.isNotEmpty
                        ? rating.userDisplayName.characters.first
                        : '؟',
                    style: YaBaladiTypography.labelLarge.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: YaBaladiDesignTokens.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rating.userDisplayName,
                        style: YaBaladiTypography.headingLabel.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: YaBaladiDesignTokens.space1),
                      Wrap(
                        spacing: YaBaladiDesignTokens.space2,
                        runSpacing: YaBaladiDesignTokens.space1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            dateStr,
                            style: YaBaladiTypography.caption.copyWith(
                              color: YaBaladiDesignTokens.textTertiary,
                            ),
                          ),
                          TrustBadgeWidget(
                            verificationMethod: rating.verificationMethod,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: YaBaladiDesignTokens.space2),
                _StarRow(rating: rating.overall),
              ],
            ),
            const SizedBox(height: YaBaladiDesignTokens.space3),
            Text(
              rating.body,
              style: YaBaladiTypography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
            if (rating.availableDimensions.isNotEmpty) ...[
              const SizedBox(height: YaBaladiDesignTokens.space3),
              Wrap(
                spacing: YaBaladiDesignTokens.space2,
                runSpacing: YaBaladiDesignTokens.space2,
                children: rating.availableDimensions.entries.map((e) {
                  return _DimensionChip(label: e.key, value: e.value);
                }).toList(),
              ),
            ],
            if (rating.hasMerchantReply) ...[
              const SizedBox(height: YaBaladiDesignTokens.space3),
              Container(
                padding: const EdgeInsets.all(YaBaladiDesignTokens.space3),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  borderRadius:
                      BorderRadius.circular(YaBaladiDesignTokens.radiusSmall),
                  border: Border(
                    right: BorderSide(color: colorScheme.primary, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store_rounded,
                            size: 14, color: colorScheme.primary),
                        const SizedBox(width: YaBaladiDesignTokens.space1),
                        Text(
                          'رد صاحب المكان',
                          style: YaBaladiTypography.caption.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space1),
                    Text(
                      rating.merchantReply!,
                      style: YaBaladiTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: YaBaladiDesignTokens.space2),
            Row(
              children: [
                TextButton.icon(
                  onPressed: onHelpful,
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                  label: Text('مفيد (${rating.helpfulCount})'),
                  style: TextButton.styleFrom(
                    textStyle: YaBaladiTypography.labelMedium,
                  ),
                ),
                const Spacer(),
                if (onReport != null)
                  TextButton.icon(
                    onPressed: onReport,
                    icon: const Icon(Icons.flag_outlined, size: 16),
                    label: const Text('إبلاغ'),
                    style: TextButton.styleFrom(
                      textStyle: YaBaladiTypography.labelMedium,
                      foregroundColor: YaBaladiDesignTokens.textSecondary,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int rating;
  const _StarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= rating;
        return Icon(
          filled ? Icons.star_rounded : Icons.star_outline_rounded,
          color:
              filled ? YaBaladiDesignTokens.gold : YaBaladiDesignTokens.grey300,
          size: 16,
        );
      }),
    );
  }
}

class _DimensionChip extends StatelessWidget {
  final String label;
  final int value;
  const _DimensionChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaBaladiDesignTokens.space2,
        vertical: YaBaladiDesignTokens.space1,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(YaBaladiDesignTokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: YaBaladiTypography.caption.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: YaBaladiDesignTokens.space1),
          Text(
            '$value/5',
            style: YaBaladiTypography.caption.copyWith(
              color: YaBaladiDesignTokens.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
