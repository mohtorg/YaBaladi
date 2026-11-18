// lib/features/places/screens/all_offers_screen.dart
//
// [v1.9 — 2026-11-05] — FIXED: Added braces for if statements, corrected
//                      'category' key, and migrated to GoRouter.

// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // ✅ Added for routing

class AllOffersScreen extends StatelessWidget {
  const AllOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('أحدث العروض والخصومات'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(), // ✅ Use GoRouter pop
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('places')
              .where('hasActiveOffer', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];

            // ✅ فلترة العروض المنتهية
            final validDocs = docs.where((doc) {
              final data = doc.data();
              final expiry = (data['offerExpiryDate'] as Timestamp?)?.toDate();
              return expiry != null && expiry.isAfter(DateTime.now());
            }).toList();

            // ✅ ترتيب العروض (الأحدث أولاً)
            validDocs.sort((a, b) {
              final dataA = a.data();
              final dataB = b.data();
              final createdA =
                  (dataA['offerCreatedAt'] as Timestamp?)?.toDate();
              final createdB =
                  (dataB['offerCreatedAt'] as Timestamp?)?.toDate();

              if (createdA != null && createdB != null) {
                return createdB.compareTo(createdA);
              }
              final expiryA = (dataA['offerExpiryDate'] as Timestamp).toDate();
              final expiryB = (dataB['offerExpiryDate'] as Timestamp).toDate();
              return expiryB.compareTo(expiryA);
            });

            if (validDocs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_offer_outlined,
                        size: 80, color: theme.colorScheme.outline),
                    const SizedBox(height: 16),
                    Text(
                      'لا توجد عروض حالياً',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تفقدنا لاحقاً للحصول على أفضل الخصومات!',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: validDocs.length,
              itemBuilder: (context, index) {
                final doc = validDocs[index];
                return _CompactOfferCard(doc: doc);
              },
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COMPACT OFFER CARD WIDGET (Icon only)
// ═══════════════════════════════════════════════════════════════
class _CompactOfferCard extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const _CompactOfferCard({required this.doc});

  // ✅ دالة التنسيق الذكي
  String _smartFormatOffer(String text) {
    if (text.isEmpty) {
      return text;
    }
    final String formattedText = text.trim();
    final bool hasEmoji = RegExp(
            r'[\u{1F300}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
            unicode: true)
        .hasMatch(formattedText);
    if (hasEmoji) {
      return formattedText;
    }
    if (formattedText.contains('خصم') || formattedText.contains('%')) {
      return '🔥 $formattedText';
    }
    if (formattedText.contains('مجان') || formattedText.contains('هدية')) {
      return '🎁 $formattedText';
    }
    if (formattedText.contains('افتتاح') || formattedText.contains('جديد')) {
      return '🎉 $formattedText';
    }
    if (formattedText.contains('حصري') || formattedText.contains('مميز')) {
      return '⭐ $formattedText';
    }
    return '🏆 $formattedText';
  }

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

  // ✅ دالة جديدة لترجمة التصنيف إلى العربية
  String _nameForCategory(String? id) {
    switch (id) {
      case 'restaurants':
        return 'مطاعم';
      case 'cafes':
        return 'مقاهي';
      case 'pharmacies':
        return 'صيدليات';
      case 'hospitals':
        return 'مستشفيات';
      case 'shopping':
        return 'تسوق';
      case 'hotels':
        return 'فنادق';
      case 'landmarks':
        return 'معالم سياحية';
      case 'entertainment':
        return 'ترفيه';
      default:
        return 'مكان';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = doc.data();

    final placeName =
        data['nameAr']?.toString() ?? data['name']?.toString() ?? 'مكان';
    final offerTitle = data['offerTitle']?.toString() ?? '';
    final offerDetails = data['offerDetails']?.toString() ?? '';
    final offerExpiry = (data['offerExpiryDate'] as Timestamp).toDate();
    // ✅ Fix: Read from 'category' first, then fallback to 'categoryId'
    final categoryId = (data['category'] ?? data['categoryId'])?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            // ✅ فتح النافذة المنبثقة الإبداعية
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withValues(alpha: 0.3),
              builder: (context) => _OfferModalSheet(
                placeId: doc.id,
                placeName: placeName,
                categoryName:
                    _nameForCategory(categoryId), // ✅ تمرير الاسم العربي
                offerTitle: _smartFormatOffer(offerTitle),
                offerDetails: _smartFormatOffer(offerDetails),
                offerExpiry: offerExpiry,
                icon: _iconForCategory(categoryId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // ✅ أيقونة التصنيف فقط
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconForCategory(categoryId),
                      color: theme.colorScheme.onPrimaryContainer, size: 26),
                ),
                const SizedBox(width: 12),

                // التفاصيل المختصرة
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              placeName,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ✅ الشارة الصغيرة الجذابة
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                Color(0xFFFF7F50),
                                Color(0xFFFF4500)
                              ]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🔥 عرض حصري',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _smartFormatOffer(offerTitle),
                        style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'ينتهي: ${offerExpiry.day}/${offerExpiry.month}/${offerExpiry.year}',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // سهم يشير إلى إمكانية الفتح
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: theme.colorScheme.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ✅ الشاشة المنبثقة (The Immersive Modal)
// ═══════════════════════════════════════════════════════════════
class _OfferModalSheet extends StatelessWidget {
  final String placeId;
  final String placeName;
  final String categoryName;
  final String offerTitle;
  final String offerDetails;
  final DateTime offerExpiry;
  final IconData icon;

  const _OfferModalSheet({
    required this.placeId,
    required this.placeName,
    required this.categoryName,
    required this.offerTitle,
    required this.offerDetails,
    required this.offerExpiry,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF4500), Color(0xFFFF7F50)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 16, bottom: 16),
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Icon(icon, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(placeName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          // ✅ عرض الاسم العربي هنا
                          Text(categoryName,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('عرض حصري',
                          style: TextStyle(
                              color: Color(0xFFFF4500),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ),
                    const SizedBox(height: 16),
                    Text(offerTitle,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.3)),
                    if (offerDetails.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(offerDetails,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 16,
                              height: 1.6)),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'ينتهي العرض في: ${offerExpiry.day}/${offerExpiry.month}/${offerExpiry.year}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context); // Pop the bottom sheet
                      // ✅ FIX: Use GoRouter for navigation
                      context.push('/home/place/$placeId');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFFF4500),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('عرض تفاصيل المكان',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
