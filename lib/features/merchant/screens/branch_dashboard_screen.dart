// lib/features/merchant/screens/branch_dashboard_screen.dart
// [v1.1.1 — 2026-11-05] — LINTER FIX: Added braces for if statement.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../models/place.dart';
import '../../../models/review.dart';
import 'manage_offers_screen.dart';
import 'merchant_place_screen.dart';

class BranchDashboardScreen extends StatelessWidget {
  final Place branch;

  const BranchDashboardScreen({super.key, required this.branch});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(branch.nameAr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          // ✅ زر تعديل بيانات الفرع في AppBar
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'تعديل بيانات الفرع',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MerchantPlaceScreen(placeId: branch.id),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .doc(branch.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('بيانات الفرع غير متوفرة'));
          }

          final data = snapshot.data!.data()!;
          final currentPlace = Place.fromMap(snapshot.data!.id, data);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // بطاقة معلومات الفرع
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store,
                            color: theme.colorScheme.primary, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            currentPlace.nameAr,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentPlace.address.isNotEmpty
                          ? currentPlace.address
                          : 'لا يوجد عنوان',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer
                            .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // الإحصائيات
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star,
                      title: 'التقييم',
                      value: currentPlace.averageRating.toStringAsFixed(1),
                      color: Colors.amber.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.comment,
                      title: 'المراجعات',
                      value: '${currentPlace.reviewCount}',
                      color: Colors.green.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // زر إدارة العروض
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ManageOffersScreen(place: currentPlace),
                    ),
                  );
                },
                icon: const Icon(Icons.local_offer),
                label: const Text('إدارة عروض هذا الفرع'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.orange.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ زر تعديل بيانات الفرع (CTA إضافي للوضوح)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MerchantPlaceScreen(placeId: branch.id),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('تعديل بيانات الفرع'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // أحدث التقييمات
              Text('أحدث التقييمات',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _ReviewsList(placeId: currentPlace.id),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard(
      {required this.icon,
      required this.title,
      required this.value,
      required this.color});

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
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ReviewsList extends StatelessWidget {
  final String placeId;
  const _ReviewsList({required this.placeId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('reviews')
          .where('placeId', isEqualTo: placeId)
          .where('status', isEqualTo: 'published')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('لا توجد تقييمات بعد')),
          );
        }

        return Column(
          children: docs.map((doc) {
            final review = Review.fromMap(doc.id, doc.data());
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                    child: Text(
                        review.userName.isNotEmpty ? review.userName[0] : '؟')),
                title: Text(review.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(review.comment,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      5,
                      (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 14,
                            color: Colors.amber,
                          )),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
