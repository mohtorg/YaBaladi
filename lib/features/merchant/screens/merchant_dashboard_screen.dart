// lib/features/merchant/screens/merchant_dashboard_screen.dart
// [v3.8 — 2026-11-03] — UX REFACTOR: Consolidated reviews into a single clickable card.
//   - REPLACED: 4 KPI cards + recent reviews list with a Master Reviews Card + 2 KPI cards.
//   - ADDED: Navigation to MerchantReviewsScreen.
//   - REMOVED: _ReviewMiniCard and unused imports.
//   - KEPT: All offers and branches management logic.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/place.dart';
import 'merchant_all_offers_screen.dart';
import 'add_branch_screen.dart';
import 'branch_dashboard_screen.dart';
import 'merchant_reviews_screen.dart'; // ✅ شاشة التقييمات الجديدة

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .where('ownerId', isEqualTo: auth.uid)
          .snapshots(),
      builder: (context, placeSnap) {
        if (placeSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!placeSnap.hasData || placeSnap.data!.docs.isEmpty) {
          return const Scaffold(body: _NoPlaceView());
        }

        final allPlaces = placeSnap.data!.docs.map((doc) {
          return Place.fromMap(doc.id, doc.data());
        }).toList();

        Place mainBranch;
        try {
          mainBranch = allPlaces.firstWhere((p) => !p.isBranch);
        } catch (_) {
          mainBranch = allPlaces.first;
        }

        final branches = allPlaces.where((p) => p.id != mainBranch.id).toList();

        int totalReviews = 0;
        double totalRatingSum = 0.0;
        int totalViews = 0;

        for (var p in allPlaces) {
          totalReviews += p.reviewCount;
          totalRatingSum += (p.averageRating * p.reviewCount);
          totalViews += p.viewCount;
        }

        final double aggregateRating =
            totalReviews > 0 ? (totalRatingSum / totalReviews) : 0.0;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('لوحة التاجر',
                style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            surfaceTintColor: Theme.of(context).colorScheme.surface,
          ),
          body: _DashboardContent(
            mainBranch: mainBranch,
            branches: branches,
            aggregateRating: aggregateRating,
            totalReviews: totalReviews,
            totalViews: totalViews,
          ),
        );
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Place mainBranch;
  final List<Place> branches;
  final double aggregateRating;
  final int totalReviews;
  final int totalViews;

  const _DashboardContent({
    required this.mainBranch,
    required this.branches,
    required this.aggregateRating,
    required this.totalReviews,
    required this.totalViews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isExcellence = aggregateRating >= 4.5 && totalReviews >= 10;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── البانر الترحيبي ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.surface,
                  child: Icon(Icons.storefront,
                      color: theme.colorScheme.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mainBranch.nameAr,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            mainBranch.isApproved
                                ? Icons.verified
                                : Icons.pending,
                            size: 16,
                            color: mainBranch.isApproved
                                ? Colors.green
                                : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mainBranch.isApproved
                                ? 'تاجر معتمد'
                                : 'قيد المراجعة',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildExcellenceBadge(isExcellence),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── أزرار الإجراءات ───
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MerchantAllOffersScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_offer),
                  label: const Text('إدارة العروض'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.orange.shade700,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddBranchScreen(mainBranch: mainBranch),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business),
                  label: const Text('إضافة فرع'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── بطاقة التقييمات (الماستر كارد) ───
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MerchantReviewsScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.shade300, width: 1.5),
                boxShadow: [
                  BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star,
                        color: Colors.amber.shade700, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('التقييمات',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(aggregateRating.toStringAsFixed(1),
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 4),
                            Icon(Icons.star,
                                color: Colors.amber.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text('($totalReviews تقييم)',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: theme.colorScheme.outline, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ─── إحصائيات سريعة (المشاهدات + الفروع) ───
          Text('نظرة عامة',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  icon: Icons.visibility,
                  label: 'المشاهدات',
                  value: '$totalViews',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  icon: Icons.store,
                  label: 'إجمالي الفروع',
                  value: '${branches.length + 1}',
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ─── رحلة التميز ───
          _ExcellenceProgressCard(
            currentRating: aggregateRating,
            currentReviewCount: totalReviews,
          ),
          const SizedBox(height: 24),

          // ─── قائمة الفروع ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('الفروع',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('${branches.length + 1} فرع',
                  style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          _BranchCard(place: mainBranch, isMain: true),
          ...branches.map((b) => _BranchCard(place: b, isMain: false)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildExcellenceBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.amber : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.amber.shade700 : Colors.grey.shade400,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive
                ? Icons.workspace_premium
                : Icons.workspace_premium_outlined,
            color: isActive ? Colors.black87 : Colors.grey.shade600,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'مميز' : 'يسعى للتميز',
            style: TextStyle(
              color: isActive ? Colors.black87 : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  final Place place;
  final bool isMain;

  const _BranchCard({required this.place, required this.isMain});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isMain
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: isMain ? 1.5 : 0.8,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isMain
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            isMain ? Icons.storefront : Icons.store,
            color: isMain
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                place.nameAr,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMain)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'الرئيسي',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Icon(Icons.star, size: 14, color: Colors.amber.shade700),
            const SizedBox(width: 4),
            Text(place.averageRating.toStringAsFixed(1),
                style: theme.textTheme.bodySmall),
            const SizedBox(width: 12),
            Icon(Icons.comment,
                size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('${place.reviewCount}', style: theme.textTheme.bodySmall),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BranchDashboardScreen(branch: place),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExcellenceProgressCard extends StatelessWidget {
  final double currentRating;
  final int currentReviewCount;

  const _ExcellenceProgressCard({
    required this.currentRating,
    required this.currentReviewCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const double targetRating = 4.5;
    const int targetReviews = 10;

    final bool isExcellence =
        currentRating >= targetRating && currentReviewCount >= targetReviews;

    final int missingReviews =
        (targetReviews - currentReviewCount).clamp(0, targetReviews);
    final double reviewProgress =
        (currentReviewCount / targetReviews).clamp(0.0, 1.0);

    if (isExcellence) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('تهانينا! لقد حصلت على شارة التميز',
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900)),
                  const SizedBox(height: 4),
                  Text('مكانك الآن ضمن أفضل الأماكن في المدينة.',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Text('رحلة التميز',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'للحصول على شارة التميز، تحتاج إلى:',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('التقييمات ($currentReviewCount / $targetReviews)',
                  style: theme.textTheme.labelMedium),
              if (missingReviews > 0)
                Text('يتبقى $missingReviews تقييم',
                    style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold))
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: reviewProgress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber.shade600),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('معدل التقييم', style: theme.textTheme.labelMedium),
              Text(
                currentRating >= targetRating
                    ? 'مكتمل ($currentRating)'
                    : 'يجب أن يصل إلى $targetRating',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: currentRating >= targetRating
                      ? Colors.green
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline,
                    color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    missingReviews > 0
                        ? 'اطلب من عملائك تقييم المكان للحصول على $missingReviews تقييمات إضافية!'
                        : 'شجع عملائك على إعطاء 5 نجوم لرفع تقييمك إلى 4.5!',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _NoPlaceView extends StatelessWidget {
  const _NoPlaceView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store_outlined,
                size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              'لم يتم ربط أي مكان بحسابك بعد',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'تواصل مع فريق الدعم لإتمام عملية الربط.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
