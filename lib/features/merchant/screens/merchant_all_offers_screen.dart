// lib/features/merchant/screens/merchant_all_offers_screen.dart
// [v1.2 — 2026-11-03] — POLISHED:
//   - ADDED: Visual distinction between main branch and sub-branches.
//   - ADDED: Warning for data inconsistency (hasActiveOffer=true but expiry=null).
//   - ADDED: Pull-to-refresh for manual reload.
//   - KEPT: All logic, StreamBuilder, and navigation intact.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/place.dart';
import 'manage_offers_screen.dart'; // ✅ استيراد الشاشة الصحيحة (الجمع)

class MerchantAllOffersScreen extends StatelessWidget {
  const MerchantAllOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('إدارة العروض',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('ownerId', isEqualTo: auth.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: theme.colorScheme.error),
                  const SizedBox(height: 12),
                  Text('حدث خطأ: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('لا توجد فروع مسجلة باسمك حالياً.',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          final places = snapshot.data!.docs.map((doc) {
            return Place.fromMap(doc.id, doc.data());
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              // إعطاء إحساس بالتحديث (StreamBuilder يُحدّث تلقائياً)
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: places.length,
              itemBuilder: (context, index) {
                final place = places[index];

                // ✅ حالة العرض:
                // - null: لا يوجد عرض فعّال
                // - true: عرض فعّال وتاريخه سليم
                // - 'invalid': عرض فعّال لكن بياناته ناقصة
                final bool hasActiveFlag = place.hasActiveOffer;
                final bool hasExpiry = place.offerExpiryDate != null;
                final bool isExpiryValid =
                    hasExpiry && place.offerExpiryDate!.isAfter(DateTime.now());
                final bool hasValidOffer = hasActiveFlag && isExpiryValid;
                final bool hasInvalidData = hasActiveFlag && !hasExpiry;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: hasInvalidData
                          ? Colors.red.shade200
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  theme.colorScheme.primaryContainer,
                              child: Icon(
                                place.isBranch
                                    ? Icons.store_outlined
                                    : Icons.storefront,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place.nameAr,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // ✅ تمييز الفرع الرئيسي
                                  Text(
                                    place.isBranch ? 'فرع' : 'الفرع الرئيسي',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: place.isBranch
                                          ? theme.colorScheme.outline
                                          : Colors.amber.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildOfferBadge(
                                theme, hasValidOffer, hasInvalidData),
                          ],
                        ),

                        // تفاصيل العرض (إذا كان موجوداً وسليماً)
                        if (hasValidOffer) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_offer,
                                        size: 14, color: Colors.deepOrange),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        place.offerTitle ?? 'بدون عنوان',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepOrange),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ينتهي في: ${place.offerExpiryDate!.day}/${place.offerExpiryDate!.month}/${place.offerExpiryDate!.year}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ⚠️ تحذير: عرض فعّال لكن بياناته ناقصة
                        if (hasInvalidData) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    size: 20, color: Colors.red.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'يوجد خلل في بيانات العرض (تاريخ الانتهاء مفقود). يرجى إعادة تعيينه.',
                                    style: TextStyle(
                                        color: Colors.red.shade900,
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // زر الإدارة
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ManageOffersScreen(place: place),
                                ),
                              );
                            },
                            icon: Icon(hasValidOffer || hasInvalidData
                                ? Icons.edit
                                : Icons.add),
                            label: Text(
                              hasValidOffer || hasInvalidData
                                  ? 'تعديل العرض'
                                  : 'إضافة عرض جديد',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              foregroundColor: (hasValidOffer || hasInvalidData)
                                  ? Colors.deepOrange
                                  : theme.colorScheme.primary,
                              side: BorderSide(
                                  color: (hasValidOffer || hasInvalidData)
                                      ? Colors.deepOrange
                                      : theme.colorScheme.primary),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ✅ ويدجت مساعدة لعرض شارة حالة العرض
  Widget _buildOfferBadge(
      ThemeData theme, bool hasValidOffer, bool hasInvalidData) {
    if (hasInvalidData) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          '⚠️ بيانات ناقصة',
          style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 10,
              fontWeight: FontWeight.bold),
        ),
      );
    }
    if (hasValidOffer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Text(
          '✅ عرض نشط',
          style: TextStyle(
              color: Colors.green.shade800,
              fontSize: 10,
              fontWeight: FontWeight.bold),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        'لا يوجد عرض',
        style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 10,
            fontWeight: FontWeight.bold),
      ),
    );
  }
}
