// lib/features/favorites/favorites_screen.dart
// [v2.5 — 2026-11-15] — SMART ADDRESS FORMATTING:
//   - Passed address, city, and governorate to _FavoriteCard.
//   - Added _formatAddress to display "Street - District - Governorate".
//   - Added curly braces to if statements.
// [v2.4 — FINAL: Layout Fix + Orphaned Data Cleanup]

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../places/screens/place_details_screen.dart';

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

              if (placeId.isEmpty) {
                return const SizedBox.shrink();
              }

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

                  // ✅ تنظيف البيانات اليتيمة: إذا كان المكان غير موجود، نحذف المفضلة
                  if (!placeSnap.hasData || !placeSnap.data!.exists) {
                    FirebaseFirestore.instance
                        .collection('favorites')
                        .doc(favDoc.id)
                        .delete();
                    return const SizedBox.shrink();
                  }

                  final placeData = placeSnap.data!.data()!;
                  final name = placeData['nameAr']?.toString() ??
                      placeData['name']?.toString() ??
                      'بدون اسم';
                  final categoryId = placeData['categoryId']?.toString() ?? '';
                  final rating =
                      (placeData['averageRating'] as num?)?.toDouble() ?? 0.0;

                  // ✅ جلب حقول العنوان الثلاثة
                  final address = placeData['address']?.toString() ?? '';
                  final city = placeData['city']?.toString() ?? '';
                  final governorate =
                      placeData['governorate']?.toString() ?? '';

                  return _FavoriteCard(
                    favoriteDocId: favDoc.id,
                    placeId: placeId,
                    name: name,
                    categoryId: categoryId,
                    rating: rating,
                    address: address,
                    city: city,
                    governorate: governorate,
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
      height: 80,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ويدجت بطاقة المكان المفضل (مضغوطة وأنيقة - صف أفقي)
// ═══════════════════════════════════════════════════════════════
class _FavoriteCard extends StatelessWidget {
  final String favoriteDocId;
  final String placeId;
  final String name;
  final String categoryId;
  final double rating;
  final String address;
  final String city;
  final String governorate;

  const _FavoriteCard({
    required this.favoriteDocId,
    required this.placeId,
    required this.name,
    required this.categoryId,
    required this.rating,
    required this.address,
    required this.city,
    required this.governorate,
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

  // ✅ دالة تنسيق العنوان (الشارع - حي الشرق - بورسعيد)
  String _formatAddress(String? address, String? city, String? gov) {
    final List<String> parts = [];

    final trimmedAddress = address?.trim() ?? '';
    if (trimmedAddress.isNotEmpty) {
      parts.add(trimmedAddress);
    }

    final trimmedCity = city?.trim() ?? '';
    if (trimmedCity.isNotEmpty) {
      final String formattedCity;
      if (!trimmedCity.startsWith('حي ')) {
        if (trimmedCity.startsWith('حي')) {
          formattedCity = 'حي ${trimmedCity.substring(2).trim()}';
        } else {
          formattedCity = 'حي $trimmedCity';
        }
      } else {
        formattedCity = trimmedCity;
      }
      parts.add(formattedCity);
    }

    final trimmedGov = gov?.trim() ?? '';
    if (trimmedGov.isNotEmpty) {
      parts.add(trimmedGov);
    }

    return parts.join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ استخدام الدالة الجديدة بدلاً من geoZoneName
    final locationText = _formatAddress(address, city, governorate);

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
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlaceDetailsScreen(placeId: placeId),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. الأيقونة (يسار) - تم تحديد الحجم لمنع التمدد
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForCategory(categoryId),
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // 2. الاسم والموقع (وسط)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (locationText.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.location_on,
                              size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 2),
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
                      ],
                    ),
                  ],
                ),
              ),

              // 3. زر القلب (يمين)
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red, size: 24),
                tooltip: 'إزالة من المفضلة',
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('favorites')
                      .doc(favoriteDocId)
                      .delete();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
