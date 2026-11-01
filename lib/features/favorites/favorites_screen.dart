// lib/features/favorites/favorites_screen.dart
// [v2.2 — 2026-11-01] — FIXED IMPORT: Corrected the relative path to PlaceDetailsScreen.
//   - FIXED: Changed '../../places/...' to '../places/...' to resolve URI error.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../places/screens/place_details_screen.dart'; // ✅ تم تصحيح المسار هنا

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
                  final categoryId = placeData['categoryId']?.toString() ?? '';
                  final rating =
                      (placeData['averageRating'] as num?)?.toDouble() ?? 0.0;

                  final geoZoneName =
                      placeData['geoZoneName']?.toString() ?? '';
                  final city = placeData['city']?.toString() ?? '';

                  return _FavoriteCard(
                    favoriteDocId: favDoc.id,
                    placeId: placeId,
                    name: name,
                    categoryId: categoryId,
                    rating: rating,
                    geoZoneName: geoZoneName,
                    city: city,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ويدجت بطاقة المكان المفضل (مضغوطة وأنيقة)
// ═══════════════════════════════════════════════════════════════
class _FavoriteCard extends StatelessWidget {
  final String favoriteDocId;
  final String placeId;
  final String name;
  final String categoryId;
  final double rating;
  final String geoZoneName;
  final String city;

  const _FavoriteCard({
    required this.favoriteDocId,
    required this.placeId,
    required this.name,
    required this.categoryId,
    required this.rating,
    required this.geoZoneName,
    required this.city,
  });

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
    final locationText = geoZoneName.isNotEmpty ? geoZoneName : city;

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
          // ✅ إصلاح جذري: استخدام Navigator بدلاً من context.push
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlaceDetailsScreen(placeId: placeId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Icon + Rating + Delete Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconForCategory(categoryId),
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber.shade700),
                      const SizedBox(width: 2),
                      Text(rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.favorite,
                            color: Colors.red, size: 20),
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
                ],
              ),
              const SizedBox(height: 10),

              // 2. Name
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // 3. Location
              if (locationText.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
