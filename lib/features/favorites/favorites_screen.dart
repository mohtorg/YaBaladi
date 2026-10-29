// lib/features/favorites/favorites_screen.dart
//
// [v2.0 — 2026-10-28] — REAL DATA: Connected to Firestore, delete action, login guard

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/controllers/auth_controller.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    // ✅ حماية: التأكد من تسجيل الدخول
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('المفضلة'), centerTitle: true),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 80, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('تسجيل الدخول مطلوب',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('سجل الدخول لعرض قائمة الأماكن المفضلة.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/login'),
                icon: const Icon(Icons.login),
                label: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('المفضلة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('favorites')
            .where('userId', isEqualTo: auth.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('خطأ في تحميل المفضلة: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState(theme, context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final favDoc = docs[index];
              final placeId = favDoc.data()['placeId']?.toString() ?? '';

              if (placeId.isEmpty) return const SizedBox.shrink();

              // ✅ جلب بيانات المكان المرتبط
              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('places')
                    .doc(placeId)
                    .get(),
                builder: (context, placeSnap) {
                  if (placeSnap.connectionState == ConnectionState.waiting) {
                    return _buildLoadingCard(theme);
                  }
                  if (!placeSnap.hasData || !placeSnap.data!.exists) {
                    return const SizedBox.shrink(); // المكان محذوف
                  }

                  final placeData = placeSnap.data!.data()!;
                  final name = placeData['nameAr']?.toString() ??
                      placeData['name']?.toString() ??
                      'بدون اسم';
                  final category =
                      placeData['categoryId']?.toString() ?? 'مكان';
                  final rating =
                      (placeData['averageRating'] as num?)?.toDouble() ?? 0.0;
                  final images = placeData['imageUrls'] as List?;
                  final image = (images != null && images.isNotEmpty)
                      ? images[0]
                      : 'https://images.unsplash.com/photo-1542314831-c6a4d146682c?w=500';

                  return _FavoriteCard(
                    favoriteDocId: favDoc.id,
                    placeId: placeId,
                    name: name,
                    category: category,
                    rating: rating,
                    image: image,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border,
                size: 80, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text('قائمتك فارغة',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('احفظ الأماكن التي تحبها لتجدها هنا بسهولة.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.explore),
              label: const Text('اكتشف أماكن جديدة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ويدجت بطاقة المكان المفضل
// ═══════════════════════════════════════════════════════════════
class _FavoriteCard extends StatelessWidget {
  final String favoriteDocId;
  final String placeId;
  final String name;
  final String category;
  final double rating;
  final String image;

  const _FavoriteCard({
    required this.favoriteDocId,
    required this.placeId,
    required this.name,
    required this.category,
    required this.rating,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/home/place/$placeId'),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, size: 40),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite,
                              color: Colors.red, size: 22),
                          onPressed: () async {
                            // ✅ حذف من المفضلة
                            await FirebaseFirestore.instance
                                .collection('favorites')
                                .doc(favoriteDocId)
                                .delete();
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(category,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(rating.toStringAsFixed(1),
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
