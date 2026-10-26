// lib/features/places/screens/place_details_screen.dart
//
// [v4.0 — 2026-10-26] — BULLETPROOF REBUILD: Zero external controllers, strict null safety

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final String placeId;
  const PlaceDetailsScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _placeFuture;
  bool _isFavorite = false; // حالة محلية للمفضلة (لتجنب أخطاء الكنترولر)

  @override
  void initState() {
    super.initState();
    _placeFuture = FirebaseFirestore.instance
        .collection('places')
        .doc(widget.placeId)
        .get();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المكان'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () {
              final auth = context.read<AuthController>();
              if (!auth.isLoggedIn) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
                );
                return;
              }
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFavorite
                      ? 'تمت الإضافة إلى المفضلة'
                      : 'تمت الإزالة من المفضلة'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _placeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('خطأ في تحميل البيانات: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('المكان غير موجود'));
          }

          final data = snapshot.data!.data()!;

          // استخراج البيانات بأمان تام
          final nameAr = data['nameAr']?.toString() ?? 'بدون اسم';
          final nameEn = data['nameEn']?.toString() ?? '';
          final desc = data['description']?.toString() ?? '';
          final address = data['address']?.toString() ?? '';
          final city = data['city']?.toString() ?? '';
          final gov = data['governorate']?.toString() ?? '';
          final phone = data['phone']?.toString() ??
              data['businessPhone']?.toString() ??
              '';
          final rating = (data['averageRating'] as num?)?.toDouble() ?? 0.0;
          final reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;

          final imagesRaw = data['imageUrls'] as List?;
          final images = imagesRaw?.map((e) => e.toString()).toList() ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── الصورة ───
              if (images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images.first,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Center(
                          child: Icon(Icons.broken_image, size: 50)),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(child: Icon(Icons.image, size: 64)),
                ),
              const SizedBox(height: 16),

              // ─── الاسم والتقييم ───
              Text(
                nameAr,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (nameEn.isNotEmpty)
                Text(
                  nameEn,
                  style:
                      theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ...List.generate(
                      5,
                      (i) => Icon(
                            i < rating.floor() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          )),
                  const SizedBox(width: 8),
                  Text('${rating.toStringAsFixed(1)} ($reviewCount)'),
                ],
              ),
              const SizedBox(height: 24),

              // ─── الوصف ───
              if (desc.isNotEmpty) ...[
                Text(desc, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 24),
              ],

              // ─── العنوان ───
              if (address.isNotEmpty || city.isNotEmpty) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: const Text('العنوان'),
                  subtitle: Text([address, city, gov]
                      .where((s) => s.isNotEmpty)
                      .join(', ')),
                ),
                const Divider(),
              ],

              // ─── الهاتف ───
              if (phone.isNotEmpty) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone, color: Colors.green),
                  title: const Text('الهاتف'),
                  subtitle: Text(phone),
                  trailing: IconButton(
                    icon: const Icon(Icons.call),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('الاتصال بـ $phone...')),
                      );
                    },
                  ),
                ),
                const Divider(),
              ],

              const SizedBox(height: 24),

              // ─── التقييمات ───
              Text('التقييمات',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _ReviewsSection(placeId: widget.placeId),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// قسم التقييمات (مستقل تماماً)
// ═══════════════════════════════════════════════════════════════

class _ReviewsSection extends StatelessWidget {
  final String placeId;
  const _ReviewsSection({required this.placeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: placeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('لا توجد تقييمات بعد.');
        }

        // فرز محلي (بدون فهارس)
        final docs = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final aT = a.data()['createdAt'] as Timestamp?;
            final bT = b.data()['createdAt'] as Timestamp?;
            if (aT == null) return 1;
            if (bT == null) return -1;
            return bT.compareTo(aT);
          });

        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final user = data['userName']?.toString() ?? 'مستخدم';
            final rating = (data['rating'] as num?)?.toInt() ?? 0;
            final comment = data['comment']?.toString() ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(user.isNotEmpty ? user[0] : '؟'),
                ),
                title: Row(
                  children: List.generate(
                      5,
                      (i) => Icon(
                            i < rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          )),
                ),
                subtitle: Text(comment),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
