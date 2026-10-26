// lib/features/reviews/screens/my_reviews_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  // بيانات تجريبية (Mock Data)
  // في التطبيق الحقيقي، ستقوم بجلبها من Firebase بناءً على auth.uid
  final List<Map<String, dynamic>> _myReviews = [
    {
      'id': 'r1',
      'placeId': 'p1',
      'placeName': 'مطعم ريكو',
      'rating': 5.0,
      'comment': 'أفضل مطعم في بورسعيد! الأكل ممتاز والخدمة راقية جداً.',
      'date': 'منذ يومين',
      'image':
          'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=500&auto=format&fit=crop&q=60',
    },
    {
      'id': 'r2',
      'placeId': 'p4',
      'placeName': 'شاطئ بورسعيد',
      'rating': 4.0,
      'comment': 'مكان هادئ وجميل، لكن يحتاج لمزيد من النظافة في بعض الأوقات.',
      'date': 'منذ أسبوع',
      'image':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&auto=format&fit=crop&q=60',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    // حماية: إذا لم يكن مسجلاً، نعرض رسالة
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('تقييماتي')),
        body: const Center(child: Text('يرجى تسجيل الدخول لعرض تقييماتك.')),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('تقييماتي'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
      ),
      body: _myReviews.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myReviews.length,
              itemBuilder: (context, index) {
                final review = _myReviews[index];
                return _ReviewCard(review: review);
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'لم تقم بإضافة أي تقييمات بعد',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'شاركنا رأيك في الأماكن التي زرتها.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.explore),
            label: const Text('اكتشف أماكن جديدة'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ويدجت بطاقة التقييم
// ═══════════════════════════════════════════════════════════════

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = (review['rating'] as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // الانتقال لصفحة تفاصيل المكان الذي تم تقييمه
          context.push('/home/place/${review['placeId']}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── رأس البطاقة (المكان + التاريخ) ───
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      review['image'] as String,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['placeName'] as String,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review['date'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── النجوم ───
              Row(
                children: [
                  ...List.generate(5, (i) {
                    return Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    );
                  }),
                  const SizedBox(width: 8),
                  Text(
                    rating.toStringAsFixed(1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── نص التقييم ───
              Text(
                review['comment'] as String,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
