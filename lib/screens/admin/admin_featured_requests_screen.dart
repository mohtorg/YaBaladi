// screens/admin/admin_featured_requests_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// بتعرض بس الأماكن اللي التاجر طلب تميّزها (featuredRequestPending = true).
// الأدمن يقدر يوافق (isFeatured = true) أو يرفض - القرار المادي
// (هل التاجر دفع فعلًا أو لأ) بيتم خارج التطبيق حاليًا، والأدمن بيسجّل
// النتيجة هنا بعد التأكد يدويًا
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/place.dart';

class AdminFeaturedRequestsScreen extends StatelessWidget {
  const AdminFeaturedRequestsScreen({super.key});

  // ------------------------------------------------------------
  // الفكرة: دالة واحدة بتتعامل مع الحالتين (موافقة/رفض) -
  // في الحالتين بنقفل الطلب (featuredRequestPending = false) عشان
  // يختفي من القائمة فورًا، والفرق بس في القيمة النهائية لـ isFeatured
  // ------------------------------------------------------------
  Future<void> _resolveRequest(String placeId, {required bool approve}) async {
    await FirebaseFirestore.instance.collection('places').doc(placeId).update({
      'isFeatured': approve,
      'featuredRequestPending': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات التميّز'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('featuredRequestPending', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد طلبات تميّز معلّقة حاليًا'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final place = Place.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(place.nameAr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(place.category, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 12),
                      // ------------------------------------------------------------
                      // الفكرة: زرارين واضحين جنب بعض - موافقة (أخضر) ورفض (أحمر)
                      // ------------------------------------------------------------
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resolveRequest(place.id, approve: true),
                              icon: const Icon(Icons.check),
                              label: const Text('موافقة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _resolveRequest(place.id, approve: false),
                              icon: const Icon(Icons.close),
                              label: const Text('رفض'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
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
