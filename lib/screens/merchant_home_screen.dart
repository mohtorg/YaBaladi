// screens/merchant_home_screen.dart
// الشاشة الرئيسية للتاجر بعد تسجيل الدخول
// النسخة الأولى: عرض أماكنه المملوكة فقط
// (زر "إضافة مكان" و"مسح كود التقييم" هيتضافوا في الخطوة الجاية من خطة التنفيذ)

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/place.dart';
import 'scan_qr_screen.dart';
import 'redeem_coupon_screen.dart';
import 'place_reviews_screen.dart';

class MerchantHomeScreen extends StatelessWidget {
  const MerchantHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التاجر'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.card_giftcard),
            tooltip: 'استبدال كوبون',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RedeemCouponScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanQrScreen()),
          );
        },
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('مسح كود الزبون'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('ownerId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لسه معندكش أماكن مضافة.\nهتقدر تضيف مكانك الأول قريبًا.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final place = Place.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(place.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('⭐ ${place.rating.toStringAsFixed(1)} (${place.ratingCount} تقييم)'),
                        trailing: place.isFeatured
                            ? const Icon(Icons.star, color: Color(0xFFD4AF37))
                            : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlaceReviewsScreen(
                                placeId: place.id,
                                isMerchantView: true,
                              ),
                            ),
                          );
                        },
                      ),
                      // ------------------------------------------------------------
                      // الفكرة: لو المكان مش مميز ومفيش طلب معلّق أصلاً، نوري زرار الطلب
                      // لو فيه طلب معلّق، نوضح للتاجر إنه مستني مراجعة الأدمن
                      // لو مميز بالفعل، مفيش داعي نعرض أي زرار خالص
                      // ------------------------------------------------------------
                      if (!place.isFeatured)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: place.featuredRequestPending
                              ? const Text('⏳ طلب التميّز قيد المراجعة', style: TextStyle(color: Colors.orange))
                              : OutlinedButton.icon(
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('places')
                                        .doc(place.id)
                                        .update({'featuredRequestPending': true});
                                  },
                                  icon: const Icon(Icons.star_border, size: 18),
                                  label: const Text('اطلب أن يكون مميزًا'),
                                ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
