// lib/features/merchant/screens/merchant_reviews_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/review.dart';

class MerchantReviewsScreen extends StatelessWidget {
  const MerchantReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقييمات'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('ownerId', isEqualTo: auth.uid)
            .limit(1)
            .snapshots(),
        builder: (context, placeSnap) {
          if (placeSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!placeSnap.hasData || placeSnap.data!.docs.isEmpty) {
            return const Center(child: Text('لا يوجد مكان مرتبط بحسابك'));
          }

          final placeId = placeSnap.data!.docs.first.id;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('reviews')
                .where('placeId', isEqualTo: placeId)
                .where('status', isEqualTo: 'published')
                .snapshots(),
            builder: (context, reviewSnap) {
              if (reviewSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!reviewSnap.hasData) {
                return const Center(child: Text('خطأ في تحميل التقييمات'));
              }

              final docs = reviewSnap.data!.docs.toList()
                ..sort((a, b) {
                  final aT = a.data()['createdAt'] as Timestamp?;
                  final bT = b.data()['createdAt'] as Timestamp?;
                  if (aT == null) return 1;
                  if (bT == null) return -1;
                  return bT.compareTo(aT);
                });

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 80, color: theme.colorScheme.outline),
                      const SizedBox(height: 12),
                      Text('لا توجد تقييمات بعد',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  // ✅ إزالة علامة ! الزائدة
                  final review = Review.fromMap(doc.id, doc.data());
                  return _ReviewCard(review: review);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    review.userName.isNotEmpty ? review.userName[0] : '؟',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
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
                ),
                if (review.createdAt != null)
                  Text(
                    _formatDate(review.createdAt!),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review.comment, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return 'منذ ${diff.inDays} يوم';
    if (diff.inHours > 0) return 'منذ ${diff.inHours} ساعة';
    if (diff.inMinutes > 0) return 'منذ ${diff.inMinutes} دقيقة';
    return 'الآن';
  }
}
