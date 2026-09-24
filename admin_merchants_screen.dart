// screens/admin/admin_merchants_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// عرض كل التجار المسجلين في التطبيق، مع إمكانية "توثيقهم" (verified)
// التوثيق ده حاليًا علامة ثقة معلوماتية بس، مش شرط لعمل التاجر -
// عشان منعطلش أي تاجر جديد لحد ما الأدمن يراجعه يدويًا
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/merchant_profile.dart';

class AdminMerchantsScreen extends StatelessWidget {
  const AdminMerchantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التجار'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('merchants').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('لا يوجد تجار مسجلين بعد'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final merchant = MerchantProfile.fromMap(
                docs[index].id,
                docs[index].data() as Map<String, dynamic>,
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    merchant.verified ? Icons.verified : Icons.person_outline,
                    color: merchant.verified ? Colors.green : Colors.grey,
                  ),
                  title: Text(merchant.businessName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('📞 ${merchant.phone}\nأماكن مملوكة: ${merchant.ownedPlaceIds.length}'),
                  isThreeLine: true,
                  // ------------------------------------------------------------
                  // الفكرة: زرار توثيق/إلغاء توثيق - بيقلب الحالة الحالية مباشرة
                  // من غير ما يحتاج شاشة منفصلة، عشان الإجراء ده بسيط وسريع
                  // ------------------------------------------------------------
                  trailing: Switch(
                    value: merchant.verified,
                    onChanged: (value) {
                      FirebaseFirestore.instance
                          .collection('merchants')
                          .doc(merchant.uid)
                          .update({'verified': value});
                    },
                    activeThumbColor: Colors.green,
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
