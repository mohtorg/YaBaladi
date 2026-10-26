// lib/features/merchant/screens/merchant_dashboard_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/place.dart';
import '../../../models/review.dart';

class MerchantDashboardScreen extends StatelessWidget {
  const MerchantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .where('ownerId', isEqualTo: auth.uid)
          .limit(1)
          .snapshots(),
      builder: (context, placeSnap) {
        if (placeSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!placeSnap.hasData || placeSnap.data!.docs.isEmpty) {
          return const _NoPlaceView();
        }

        final placeDoc = placeSnap.data!.docs.first;
        // ✅ تمت إزالة علامة ! لأن data() في هذا النوع لا تقبل null
        final place = Place.fromMap(placeDoc.id, placeDoc.data());

        return _DashboardContent(place: place);
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final Place place;
  const _DashboardContent({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: const Icon(Icons.store,
                              color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                place.nameAr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.verified,
                                      color: Colors.lightBlueAccent, size: 18),
                                  const SizedBox(width: 4),
                                  Text(
                                    'تاجر معتمد',
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('نظرة عامة',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.star,
                        label: 'التقييم',
                        value: place.averageRating.toStringAsFixed(1),
                        color: Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.comment,
                        label: 'التقييمات',
                        value: '${place.reviewCount}',
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.check_circle,
                        label: 'الحالة',
                        value: place.isActive ? 'نشط' : 'معطل',
                        color: place.isActive ? Colors.blue : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiCard(
                        icon: Icons.verified_user,
                        label: 'الاعتماد',
                        value: place.isApproved ? 'معتمد' : 'معلق',
                        color: place.isApproved ? Colors.teal : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('أحدث التقييمات',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('placeId', isEqualTo: place.id)
                      .where('status', isEqualTo: 'published')
                      .limit(20)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final docs = snap.data!.docs.toList()
                      ..sort((a, b) {
                        final aT = a.data()['createdAt'] as Timestamp?;
                        final bT = b.data()['createdAt'] as Timestamp?;
                        if (aT == null) return 1;
                        if (bT == null) return -1;
                        return bT.compareTo(aT);
                      });

                    if (docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.rate_review_outlined,
                                size: 48, color: theme.colorScheme.outline),
                            const SizedBox(height: 12),
                            Text('لا توجد تقييمات بعد',
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: docs.take(3).map((doc) {
                        // ✅ إزالة علامة ! الزائدة
                        final review = Review.fromMap(doc.id, doc.data());
                        return _ReviewMiniCard(review: review);
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 32),
              ]),
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
          Icon(icon, color: color, size: 28),
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

class _ReviewMiniCard extends StatelessWidget {
  final Review review;
  const _ReviewMiniCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '؟',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.userName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
    return Scaffold(
      body: Center(
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
      ),
    );
  }
}
