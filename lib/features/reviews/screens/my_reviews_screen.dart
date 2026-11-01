// lib/features/reviews/screens/my_reviews_screen.dart
// [v2.1 — 2026-11-01] — FINAL REVIEW: Ensured Navigator.push is used, fixed null safety for rating.
//   - FIXED: Fully verified no context.push remains for places.
//   - KEPT: All mock data and layout.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../places/screens/place_details_screen.dart'; // ✅ المسار صحيح

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  // بيانات تجريبية (Mock Data)
  final List<Map<String, dynamic>> _myReviews = [
    {
      'id': 'r1',
      'placeId': 'p1',
      'placeName': 'مطعم ريكو',
      'rating': 5.0,
      'comment': 'أفضل مطعم في بورسعيد! الأكل ممتاز والخدمة راقية جداً.',
      'date': 'منذ يومين',
      'categoryId': 'restaurants',
    },
    {
      'id': 'r2',
      'placeId': 'p4',
      'placeName': 'شاطئ بورسعيد',
      'rating': 4.0,
      'comment': 'مكان هادئ وجميل، لكن يحتاج لمزيد من النظافة في بعض الأوقات.',
      'date': 'منذ أسبوع',
      'categoryId': 'entertainment',
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
        title: const Text('تقييماتي',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
// ويدجت بطاقة التقييم (مضغوطة وأنيقة)
// ═══════════════════════════════════════════════════════════════

class _ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;

  const _ReviewCard({required this.review});

  IconData _iconForCategory(String? id) {
    switch (id) {
      case 'restaurants':
        return Icons.restaurant;
      case 'cafes':
        return Icons.local_cafe;
      case 'pharmacies':
        return Icons.local_pharmacy;
      case 'hospitals':
        return Icons.local_hospital;
      case 'shopping':
        return Icons.shopping_bag;
      case 'hotels':
        return Icons.hotel;
      case 'landmarks':
        return Icons.account_balance;
      case 'entertainment':
        return Icons.attractions;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // ✅ استخدام ?. للتعامل الآمن مع البيانات
    final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final categoryId = review['categoryId']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // ✅ إصلاح جذري: استخدام Navigator.push بدلاً من context.push
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  PlaceDetailsScreen(placeId: review['placeId']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── رأس البطاقة (أيقونة المكان + الاسم + التاريخ) ───
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _iconForCategory(categoryId),
                      color: theme.colorScheme.primary,
                      size: 22,
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
                        const SizedBox(height: 2),
                        Text(
                          review['date'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // التقييم على اليسار
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ─── النجوم + نص التقييم ───
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                review['comment'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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
