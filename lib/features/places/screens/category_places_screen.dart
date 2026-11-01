// lib/features/places/screens/category_places_screen.dart
//
// [v1.0 — 2026-11-01] — CATEGORY PLACES SCREEN
//   - Fetches places by categoryId and governorate.
//   - Uses the shared PlaceCard widget.
//   - Includes sorting (Rating, Newest).
//   - Handles loading, empty, and error states.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/place_card.dart';
import '../../../theme/design_tokens.dart';

class CategoryPlacesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String governorate;

  const CategoryPlacesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.governorate,
  });

  @override
  State<CategoryPlacesScreen> createState() => _CategoryPlacesScreenState();
}

class _CategoryPlacesScreenState extends State<CategoryPlacesScreen> {
  String _sortBy = 'rating'; // 'rating' or 'newest'
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // استخدام go_router للرجوع
        ),
        actions: [
          // زر تبديل العرض (قائمة / شبكة)
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'عرض كقائمة' : 'عرض كشبكة',
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          // زر الترتيب
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'ترتيب حسب',
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rating',
                child: Row(children: [
                  Icon(Icons.star, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('الأعلى تقييماً'),
                ]),
              ),
              const PopupMenuItem(
                value: 'newest',
                child: Row(children: [
                  Icon(Icons.access_time, size: 18, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('الأحدث إضافة'),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('isActive', isEqualTo: true)
            .where('categoryId', isEqualTo: widget.categoryId)
            .where('governorate', isEqualTo: widget.governorate)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(theme);
          }

          // الترتيب محلياً
          final sortedDocs = docs.toList();
          sortedDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;

            if (_sortBy == 'rating') {
              final rA = (dataA['averageRating'] as num?)?.toDouble() ?? 0.0;
              final rB = (dataB['averageRating'] as num?)?.toDouble() ?? 0.0;
              return rB.compareTo(rA);
            } else {
              final tA = dataA['createdAt'] as Timestamp?;
              final tB = dataB['createdAt'] as Timestamp?;
              return (tB?.seconds ?? 0).compareTo(tA?.seconds ?? 0);
            }
          });

          return Column(
            children: [
              // شريط معلومات سريع
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
                child: Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${sortedDocs.length} مكان في ${widget.governorate}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (_sortBy == 'rating')
                      Text('مرتبة حسب التقييم',
                          style: theme.textTheme.labelSmall),
                  ],
                ),
              ),

              // عرض النتائج (قائمة أو شبكة)
              Expanded(
                child: _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: sortedDocs.length,
                        itemBuilder: (context, index) {
                          final data =
                              sortedDocs[index].data() as Map<String, dynamic>;
                          // ملاحظة: ستحتاج لإنشاء PlaceGridCard أو تعديل PlaceCard لدعم العرض الشبكي
                          // هنا نستخدم PlaceCard العادية مؤقتاً
                          return PlaceCard(
                            placeId: sortedDocs[index].id,
                            nameAr: data['nameAr'] ?? 'بدون اسم',
                            nameEn: data['nameEn'] ?? '',
                            imageUrl:
                                (data['imageUrls'] as List?)?.isNotEmpty == true
                                    ? (data['imageUrls'] as List)
                                        .first
                                        .toString()
                                    : null,
                            rating:
                                (data['averageRating'] as num?)?.toDouble() ??
                                    0.0,
                            reviewCount:
                                (data['reviewCount'] as num?)?.toInt() ?? 0,
                            categoryId: data['categoryId'],
                            geoZoneName: data['geoZoneName'],
                            city: data['city'],
                            governorate: data['governorate'],
                            address: data['address'],
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedDocs.length,
                        itemBuilder: (context, index) {
                          final data =
                              sortedDocs[index].data() as Map<String, dynamic>;
                          return PlaceCard(
                            placeId: sortedDocs[index].id,
                            nameAr: data['nameAr'] ?? 'بدون اسم',
                            nameEn: data['nameEn'] ?? '',
                            imageUrl:
                                (data['imageUrls'] as List?)?.isNotEmpty == true
                                    ? (data['imageUrls'] as List)
                                        .first
                                        .toString()
                                    : null,
                            rating:
                                (data['averageRating'] as num?)?.toDouble() ??
                                    0.0,
                            reviewCount:
                                (data['reviewCount'] as num?)?.toInt() ?? 0,
                            categoryId: data['categoryId'],
                            geoZoneName: data['geoZoneName'],
                            city: data['city'],
                            governorate: data['governorate'],
                            address: data['address'],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined,
                size: 80, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'لا توجد أماكن مضافة في "${widget.categoryName}" حتى الآن في ${widget.governorate}.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/home'),
              icon: const Icon(Icons.home),
              label: const Text('العودة للرئيسية'),
              style: FilledButton.styleFrom(
                backgroundColor: YaBaladiDesignTokens.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
