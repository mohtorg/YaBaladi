// lib/features/rating/widgets/ratings_section.dart
// [v2.5 — 2026-11-15] — Review: Confirmed queries are place-specific.
// [v2.4 — 2026-11-12] — REPORT INTEGRATION

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/place_aggregate_model.dart';
import '../../../models/rating_model.dart';
import '../../../models/review_criterion_model.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';

import '../../auth/controllers/auth_controller.dart';
import '../services/rating_service.dart';
import 'rating_card_widget.dart';
import 'report_dialog.dart';
import 'variance_badge_widget.dart';
import '../screens/rate_place_screen.dart';

const Map<String, String> _legacyLabels = {
  'cleanliness': 'النظافة',
  'service': 'الخدمة',
  'price': 'السعر',
  'access': 'سهولة الوصول',
  'overall': 'التقييم العام',
};

class RatingsSection extends StatelessWidget {
  final String placeId;
  final String placeName;
  final double placeLat;
  final double placeLng;
  final String? pinObfuscated;
  final String? zoneId;
  final String categoryId;
  final String? fullLocation;

  const RatingsSection({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.placeLat,
    required this.placeLng,
    required this.categoryId,
    this.pinObfuscated,
    this.zoneId,
    this.fullLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'التقييمات',
                style: YaBaladiTypography.headingSection.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            _RateButton(
              placeId: placeId,
              placeName: placeName,
              placeLat: placeLat,
              placeLng: placeLng,
              categoryId: categoryId,
              pinObfuscated: pinObfuscated,
              zoneId: zoneId,
            ),
          ],
        ),
        if (fullLocation != null && fullLocation!.trim().isNotEmpty) ...[
          const SizedBox(height: YaBaladiDesignTokens.space2),
          _LocationContextBadge(locationText: fullLocation!),
        ],
        const SizedBox(height: YaBaladiDesignTokens.space3),
        _AggregateSummary(placeId: placeId, categoryId: categoryId),
        const SizedBox(height: YaBaladiDesignTokens.space3),
        _RatingsList(placeId: placeId),
      ],
    );
  }
}

class _LocationContextBadge extends StatelessWidget {
  final String locationText;
  const _LocationContextBadge({required this.locationText});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: YaBaladiDesignTokens.space3,
        vertical: YaBaladiDesignTokens.space2,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(YaBaladiDesignTokens.radiusSmall),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 16,
            color: YaBaladiDesignTokens.primaryBlue,
          ),
          const SizedBox(width: YaBaladiDesignTokens.space2),
          Expanded(
            child: Text(
              locationText,
              style: YaBaladiTypography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final String placeId;
  final String placeName;
  final double placeLat;
  final double placeLng;
  final String categoryId;
  final String? pinObfuscated;
  final String? zoneId;

  const _RateButton({
    required this.placeId,
    required this.placeName,
    required this.placeLat,
    required this.placeLng,
    required this.categoryId,
    required this.pinObfuscated,
    required this.zoneId,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(80, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RatePlaceScreen(
              placeId: placeId,
              placeName: placeName,
              placeLat: placeLat,
              placeLng: placeLng,
              categoryId: categoryId,
              pinObfuscated: pinObfuscated,
              zoneId: zoneId,
            ),
          ),
        );
      },
      icon: const Icon(Icons.rate_review_rounded, size: 18),
      label: const Text('قيّم'),
    );
  }
}

class _AggregateSummary extends StatelessWidget {
  final String placeId;
  final String categoryId;
  const _AggregateSummary({required this.placeId, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('place_aggregates')
          .doc(placeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final agg = PlaceAggregateModel.fromFirestore(snapshot.data!);
        if (agg.totalRatings == 0) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('review_criteria')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, criteriaSnap) {
            final Map<String, ReviewCriterionModel> criteriaMap = {};
            if (criteriaSnap.hasData) {
              for (final doc in criteriaSnap.data!.docs) {
                final c = ReviewCriterionModel.fromFirestore(doc);
                if (c.isGeneral || c.categoryId == categoryId) {
                  criteriaMap[c.fieldKey] = c;
                }
              }
            }

            return Card(
              child: Padding(
                padding: YaBaladiDesignTokens.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          agg.averageOverall.toStringAsFixed(1),
                          style: YaBaladiTypography.display.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 36,
                          ),
                        ),
                        const SizedBox(width: YaBaladiDesignTokens.space3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _StarsRow(value: agg.averageOverall),
                              const SizedBox(
                                  height: YaBaladiDesignTokens.space1),
                              Text(
                                '(${agg.totalRatings} تقييم)',
                                style: YaBaladiTypography.caption.copyWith(
                                  color: YaBaladiDesignTokens.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (agg.dimensionAverages.isNotEmpty) ...[
                      const SizedBox(height: YaBaladiDesignTokens.space4),
                      Wrap(
                        spacing: YaBaladiDesignTokens.space2,
                        runSpacing: YaBaladiDesignTokens.space2,
                        children: agg.dimensionAverages.entries.map((entry) {
                          final criterion = criteriaMap[entry.key];
                          final label = criterion?.nameAr ??
                              _legacyLabels[entry.key] ??
                              entry.key;
                          final desc = criterion?.descriptionAr ?? '';
                          final score = entry.value.toStringAsFixed(1);

                          final Widget chipContent = Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: YaBaladiDesignTokens.space2,
                              vertical: YaBaladiDesignTokens.space1,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                  YaBaladiDesignTokens.radiusSmall),
                              border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .outlineVariant),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: YaBaladiTypography.bodySmall.copyWith(
                                    color: YaBaladiDesignTokens.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  score,
                                  style: YaBaladiTypography.labelSmall.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (desc.isNotEmpty) {
                            return Tooltip(
                              message: desc,
                              triggerMode: TooltipTriggerMode.tap,
                              child: chipContent,
                            );
                          }
                          return chipContent;
                        }).toList(),
                      ),
                    ],
                    if (agg.totalRatings >= 3) ...[
                      const SizedBox(height: YaBaladiDesignTokens.space4),
                      VarianceBadgeWidget(
                        variance: agg.ratingVariance,
                        totalRatings: agg.totalRatings,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StarsRow extends StatelessWidget {
  final double value;
  const _StarsRow({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = (i + 1) <= value;
        final halfFilled = !filled && (i + 0.5) <= value;
        return Icon(
          filled
              ? Icons.star_rounded
              : (halfFilled
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded),
          color: (filled || halfFilled)
              ? YaBaladiDesignTokens.gold
              : YaBaladiDesignTokens.grey300,
          size: 18,
        );
      }),
    );
  }
}

class _RatingsList extends StatelessWidget {
  final String placeId;
  const _RatingsList({required this.placeId});

  Future<void> _handleReport(
    BuildContext context,
    RatingModel rating,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthController>();

    if (auth.user == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول لإرسال بلاغ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final result = await showReportDialog(context);
    if (result == null) {
      return;
    }

    try {
      await RatingService().reportRating(
        ratingId: rating.id,
        reason: result.reason,
        note: result.note,
      );
      messenger.showSnackBar(
        const SnackBar(
          content:
              Text('تم إرسال البلاغ — شكراً لك. سيتم مراجعته من فريق الإشراف.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('تعذّر إرسال البلاغ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('ratings')
          .where('placeId', isEqualTo: placeId)
          .where('status', isEqualTo: 'PUBLISHED')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(YaBaladiDesignTokens.space5),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
            child: Text(
              'تعذر تحميل التقييمات',
              style: YaBaladiTypography.bodySmall.copyWith(
                color: YaBaladiDesignTokens.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        final ratings = docs
            .map((doc) => RatingModel.fromFirestore(doc))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (ratings.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
              child: Column(
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 32,
                    color: YaBaladiDesignTokens.textTertiary,
                  ),
                  const SizedBox(height: YaBaladiDesignTokens.space2),
                  Text(
                    'لا توجد تقييمات بعد',
                    style: YaBaladiTypography.bodyMedium.copyWith(
                      color: YaBaladiDesignTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: YaBaladiDesignTokens.space1),
                  Text(
                    'كن أول من يشارك تجربته',
                    style: YaBaladiTypography.bodySmall.copyWith(
                      color: YaBaladiDesignTokens.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final auth = context.watch<AuthController>();
        final currentUserId = auth.user?.uid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: ratings.map((rating) {
            final canReport =
                currentUserId != null && rating.userId != currentUserId;

            return RatingCardWidget(
              rating: rating,
              onReport: canReport ? () => _handleReport(context, rating) : null,
            );
          }).toList(),
        );
      },
    );
  }
}
