// lib/features/search/screens/all_categories_screen.dart
//
// [v2.9 — 2026-10-27] — SAFE BUILD: Replaced withValues, simplified Query types
// [v3.0 — 2026-10-27] — FIX ANALYZER: withOpacity → withValues(alpha:), Prefer final

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class _LocalCategory {
  final String id;
  final String nameAr;
  final Color color;
  final IconData icon;
  final int placesCount;

  const _LocalCategory({
    required this.id,
    required this.nameAr,
    required this.color,
    required this.icon,
    required this.placesCount,
  });
}

class AllCategoriesScreen extends StatefulWidget {
  final String? governorate;
  const AllCategoriesScreen({super.key, this.governorate});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  late Future<List<_LocalCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _loadCategoriesAndCount();
  }

  Future<List<_LocalCategory>> _loadCategoriesAndCount() async {
    try {
      // 1. جلب التصنيفات
      final catSnap = await FirebaseFirestore.instance
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .get();

      // 2. جلب الأماكن مع فلتر المحافظة
      Query placesQuery = FirebaseFirestore.instance.collection('places');

      if (widget.governorate != null && widget.governorate!.isNotEmpty) {
        placesQuery =
            placesQuery.where('governorate', isEqualTo: widget.governorate);
      }

      final placesSnap = await placesQuery.get();

      // 3. حساب العدد الفعلي لكل تصنيف
      final Map<String, int> realCounts = {}; // ✅ تمت إضافة final
      for (var doc in placesSnap.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final catId = data['categoryId'] as String?;
          if (catId != null) {
            realCounts[catId] = (realCounts[catId] ?? 0) + 1;
          }
        }
      }

      // 4. دمج التصنيفات مع العدد الصحيح
      final loadedCats = catSnap.docs.map((doc) {
        final data = doc.data();

        final colorHex = data['colorHex'] as String? ?? '#0D6EFD';
        Color parsedColor;
        try {
          parsedColor =
              Color(int.parse('FF${colorHex.replaceAll('#', '')}', radix: 16));
        } catch (_) {
          parsedColor = Colors.blue;
        }

        final iconName = data['iconName'] as String? ?? 'category';
        IconData parsedIcon = Icons.category;
        if (iconName.contains('restaurant'))
          parsedIcon = Icons.restaurant;
        else if (iconName.contains('cafe'))
          parsedIcon = Icons.local_cafe;
        else if (iconName.contains('hotel'))
          parsedIcon = Icons.hotel;
        else if (iconName.contains('beach'))
          parsedIcon = Icons.beach_access;
        else if (iconName.contains('shop')) parsedIcon = Icons.shopping_bag;

        return _LocalCategory(
          id: doc.id,
          nameAr: data['nameAr'] as String? ?? 'بدون اسم',
          color: parsedColor,
          icon: parsedIcon,
          placesCount: realCounts[doc.id] ?? 0,
        );
      }).toList();

      loadedCats.sort((a, b) => a.nameAr.compareTo(b.nameAr));
      return loadedCats;
    } catch (e) {
      debugPrint('Error loading categories: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('كل التصنيفات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: FutureBuilder<List<_LocalCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cats = snapshot.data ?? [];
          if (cats.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('لا توجد تصنيفات متاحة',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
            ),
            itemCount: cats.length,
            itemBuilder: (context, index) {
              return _CategoryGridCard(
                category: cats[index],
                governorate: widget.governorate,
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryGridCard extends StatelessWidget {
  final _LocalCategory category;
  final String? governorate;
  const _CategoryGridCard({required this.category, this.governorate});

  @override
  Widget build(BuildContext context) {
    final baseColor = category.color;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            baseColor.withValues(alpha: 0.9), // ✅ تم التعديل
            baseColor.withValues(alpha: 0.6), // ✅ تم التعديل
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.35), // ✅ تم التعديل
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final encodedName = Uri.encodeComponent(category.nameAr);
            final govParam = (governorate != null && governorate!.isNotEmpty)
                ? '&gov=${Uri.encodeComponent(governorate!)}'
                : '';
            context
                .go('/home/category/${category.id}?name=$encodedName$govParam');
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3), // ✅ تم التعديل
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: 0.1), // ✅ تم التعديل
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(category.icon, color: Colors.white, size: 32),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      category.nameAr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (category.placesCount > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          Colors.black.withValues(alpha: 0.45), // ✅ تم التعديل
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1), // ✅ تم التعديل
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${category.placesCount} مكان',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
