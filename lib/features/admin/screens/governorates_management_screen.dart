// lib/features/admin/screens/governorates_management_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GovernoratesManagementScreen extends StatefulWidget {
  const GovernoratesManagementScreen({super.key});

  @override
  State<GovernoratesManagementScreen> createState() =>
      _GovernoratesManagementScreenState();
}

class _GovernoratesManagementScreenState
    extends State<GovernoratesManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isSeeding = false;

  // قائمة الـ 27 محافظة بالبيانات الأساسية
  final List<Map<String, dynamic>> _all27Governorates = [
    {'id': 'cairo', 'nameAr': 'القاهرة', 'nameEn': 'Cairo', 'order': 1},
    {'id': 'giza', 'nameAr': 'الجيزة', 'nameEn': 'Giza', 'order': 2},
    {
      'id': 'alexandria',
      'nameAr': 'الإسكندرية',
      'nameEn': 'Alexandria',
      'order': 3
    },
    {'id': 'qalyubia', 'nameAr': 'القليوبية', 'nameEn': 'Qalyubia', 'order': 4},
    {'id': 'portsaid', 'nameAr': 'بورسعيد', 'nameEn': 'Port Said', 'order': 5},
    {'id': 'suez', 'nameAr': 'السويس', 'nameEn': 'Suez', 'order': 6},
    {
      'id': 'ismailia',
      'nameAr': 'الإسماعيلية',
      'nameEn': 'Ismailia',
      'order': 7
    },
    {'id': 'damietta', 'nameAr': 'دمياط', 'nameEn': 'Damietta', 'order': 8},
    {'id': 'dakahlia', 'nameAr': 'الدقهلية', 'nameEn': 'Dakahlia', 'order': 9},
    {'id': 'sharqia', 'nameAr': 'الشرقية', 'nameEn': 'Sharqia', 'order': 10},
    {'id': 'gharbia', 'nameAr': 'الغربية', 'nameEn': 'Gharbia', 'order': 11},
    {'id': 'monufia', 'nameAr': 'المنوفية', 'nameEn': 'Monufia', 'order': 12},
    {'id': 'beheira', 'nameAr': 'البحيرة', 'nameEn': 'Beheira', 'order': 13},
    {
      'id': 'kafrelsheikh',
      'nameAr': 'كفر الشيخ',
      'nameEn': 'Kafr El Sheikh',
      'order': 14
    },
    {'id': 'fayoum', 'nameAr': 'الفيوم', 'nameEn': 'Fayoum', 'order': 15},
    {
      'id': 'benisuef',
      'nameAr': 'بني سويف',
      'nameEn': 'Beni Suef',
      'order': 16
    },
    {'id': 'minya', 'nameAr': 'المنيا', 'nameEn': 'Minya', 'order': 17},
    {'id': 'asyut', 'nameAr': 'أسيوط', 'nameEn': 'Asyut', 'order': 18},
    {'id': 'sohag', 'nameAr': 'سوهاج', 'nameEn': 'Sohag', 'order': 19},
    {'id': 'qena', 'nameAr': 'قنا', 'nameEn': 'Qena', 'order': 20},
    {'id': 'luxor', 'nameAr': 'الأقصر', 'nameEn': 'Luxor', 'order': 21},
    {'id': 'aswan', 'nameAr': 'أسوان', 'nameEn': 'Aswan', 'order': 22},
    {
      'id': 'redsea',
      'nameAr': 'البحر الأحمر',
      'nameEn': 'Red Sea',
      'order': 23
    },
    {
      'id': 'newvalley',
      'nameAr': 'الوادي الجديد',
      'nameEn': 'New Valley',
      'order': 24
    },
    {'id': 'matrouh', 'nameAr': 'مطروح', 'nameEn': 'Matrouh', 'order': 25},
    {
      'id': 'northsinai',
      'nameAr': 'شمال سيناء',
      'nameEn': 'North Sinai',
      'order': 26
    },
    {
      'id': 'southsinai',
      'nameAr': 'جنوب سيناء',
      'nameEn': 'South Sinai',
      'order': 27
    },
  ];

  // دالة تهيئة البيانات (لأول مرة فقط)
  Future<void> _seedGovernorates() async {
    setState(() => _isSeeding = true);
    try {
      final batch = _db.batch();
      for (var gov in _all27Governorates) {
        final docRef = _db.collection('governorates').doc(gov['id']);
        batch.set(docRef, {
          'id': gov['id'],
          'nameAr': gov['nameAr'],
          'nameEn': gov['nameEn'],
          'order': gov['order'],
          'isActive': true, // تفعيل الكل افتراضياً
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ تم إضافة الـ 27 محافظة بنجاح'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('❌ فشل التهيئة: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  // دالة تغيير حالة التفعيل
  Future<void> _toggleStatus(String docId, bool currentStatus) async {
    try {
      await _db.collection('governorates').doc(docId).update({
        'isActive': !currentStatus,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('إدارة المحافظات',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('governorates').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          // 1. حالة التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. حالة عدم وجود بيانات (نعرض زر التهيئة)
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.map_outlined,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('لم يتم تهيئة المحافظات بعد',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSeeding ? null : _seedGovernorates,
                    icon: _isSeeding
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.download),
                    label: Text(
                        _isSeeding ? 'جاري التهيئة...' : 'تهيئة الـ 27 محافظة'),
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(250, 50)),
                  ),
                ],
              ),
            );
          }

          // 3. عرض القائمة
          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final isActive = data['isActive'] as bool? ?? true;
              final nameAr = data['nameAr'] ?? 'غير معروف';
              final nameEn = data['nameEn'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: SwitchListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  activeThumbColor: theme.colorScheme.primary,
                  title: Text(nameAr,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text(nameEn,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  value: isActive,
                  onChanged: (val) => _toggleStatus(docs[index].id, isActive),
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isActive
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.location_city,
                      color: isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
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
