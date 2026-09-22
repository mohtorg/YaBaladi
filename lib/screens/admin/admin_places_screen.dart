// screens/admin/admin_places_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// عرض كل الأماكن الموجودة في كل المحافظات (مش محافظة واحدة بس زي الشاشة
// الرئيسية العادية) - الأدمن هنا شايف كل حاجة عشان يقدر يتحكم فيها بالكامل.
// كل مكان في القائمة ليه زرار تعديل وزرار حذف، وفيه زرار عائم للإضافة.
// ============================================================

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/place.dart';
import 'admin_place_form_screen.dart';

class AdminPlacesScreen extends StatelessWidget {
  const AdminPlacesScreen({super.key});

  // ------------------------------------------------------------
  // الفكرة: تأكيد قبل الحذف - الحذف عملية لا رجعة فيها،
  // فبنوقف الأدمن لحظة ونتأكد إنه قاصد فعلاً قبل التنفيذ
  // ------------------------------------------------------------
  Future<void> _confirmAndDelete(BuildContext context, Place place) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل أنت متأكد من حذف "${place.nameAr}"؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('places').doc(place.id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأماكن'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      // ------------------------------------------------------------
      // الفكرة: زرار الإضافة بيفتح نفس فورم التعديل، لكن من غير مكان
      // موجود مسبقًا (existingPlace = null) - كده الكود بيتقل مرة واحدة
      // للإضافة والتعديل مع بعض بدل ما يتكرر في شاشتين منفصلتين
      // ------------------------------------------------------------
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AdminPlaceFormScreen())),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: const Color(0xFF1A237E),
        icon: const Icon(Icons.add),
        label: const Text('إضافة مكان'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // ------------------------------------------------------------
        // الفكرة: مفيش فلترة بمحافظة هنا عن قصد - الأدمن محتاج يشوف
        // كل حاجة في كل مكان، الترتيب هنا بالأحدث إضافة في الأول
        // ------------------------------------------------------------
        stream: FirebaseFirestore.instance.collection('places').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد أماكن مضافة بعد'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final place = Place.fromMap(docs[index].id, docs[index].data() as Map<String, dynamic>);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: place.isFeatured
                      ? const Icon(Icons.star, color: Color(0xFFD4AF37))
                      : const Icon(Icons.place, color: Colors.grey),
                  title: Text(place.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${place.category} · ${place.cityId} · ⭐ ${place.rating.toStringAsFixed(1)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (context) => AdminPlaceFormScreen(existingPlace: place))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmAndDelete(context, place),
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
