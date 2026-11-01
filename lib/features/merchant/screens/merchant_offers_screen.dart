// lib/features/merchant/screens/merchant_offers_screen.dart
//
// [v3.1 — 2026-10-28] — UX ENHANCEMENT: Real-time StreamBuilder, Form Validation, Toggle Active

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/controllers/auth_controller.dart';

class MerchantOffersScreen extends StatefulWidget {
  const MerchantOffersScreen({super.key});

  @override
  State<MerchantOffersScreen> createState() => _MerchantOffersScreenState();
}

class _MerchantOffersScreenState extends State<MerchantOffersScreen> {
  final _db = FirebaseFirestore.instance;

  // ✅ دالة إضافة عرض جديد مع نموذج (Form) متكامل
  Future<void> _addOffer() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة عرض جديد'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'عنوان العرض',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'يرجى إدخال عنوان العرض'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'تفاصيل العرض',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: discountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'نسبة الخصم (%)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return null; // اختياري
                    final num = int.tryParse(val);
                    if (num == null || num <= 0 || num > 100) {
                      return 'أدخل نسبة صحيحة (1-100)';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('نشر العرض'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final placeId = context.read<AuthController>().placeId;
      if (placeId == null) return;

      await _db.collection('offers').add({
        'placeId': placeId,
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'discount': int.tryParse(discountCtrl.text.trim()) ?? 0,
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم نشر العرض بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      // لا نحتاج لاستدعاء _loadOffers لأن الـ Stream سيتكفل بالتحديث
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل إضافة العرض: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ حذف عرض
  Future<void> _deleteOffer(String id) async {
    try {
      await _db.collection('offers').doc(id).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ تم حذف العرض')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل الحذف: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ تفعيل / تعطيل العرض
  Future<void> _toggleActive(String id, bool currentStatus) async {
    try {
      await _db.collection('offers').doc(id).update({'active': !currentStatus});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ فشل تغيير الحالة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final placeId = auth.placeId;

    return Scaffold(
      backgroundColor:
          theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      appBar: AppBar(
        title: const Text('إدارة العروض',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOffer,
        icon: const Icon(Icons.add),
        label: const Text('عرض جديد'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: placeId == null
          ? const Center(child: Text('لا يوجد مكان مرتبط بحسابك'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              // ✅ التحديث الفوري (بدون الحاجة لزر تحديث أو ترتيب في Firebase)
              stream: _db
                  .collection('offers')
                  .where('placeId', isEqualTo: placeId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ في تحميل العروض: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 80,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد عروض حالياً',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'أضف عرضاً لجذب المزيد من العملاء.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // ترتيب محلي (الأحدث أولاً)
                final offers = docs.map((doc) {
                  final data = doc.data();
                  data['id'] = doc.id;
                  return data;
                }).toList()
                  ..sort((a, b) {
                    final aT = a['createdAt'] as Timestamp?;
                    final bT = b['createdAt'] as Timestamp?;
                    if (aT == null) return 1;
                    if (bT == null) return -1;
                    return bT.compareTo(aT);
                  });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    final discount = offer['discount'] as int? ?? 0;
                    final isActive = offer['active'] as bool? ?? true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: isActive ? 2 : 0,
                      color: isActive
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isActive
                              ? theme.colorScheme.outlineVariant
                              : Colors.grey.shade400,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? theme.colorScheme.primary
                                            .withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.local_offer,
                                    color: isActive
                                        ? theme.colorScheme.primary
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        offer['title'] as String? ??
                                            'بدون عنوان',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isActive
                                              ? null
                                              : Colors.grey.shade700,
                                          decoration: isActive
                                              ? null
                                              : TextDecoration.lineThrough,
                                        ),
                                      ),
                                      if ((offer['description'] as String? ??
                                              '')
                                          .isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 4),
                                          child: Text(
                                            offer['description'] as String,
                                            style: theme.textTheme.bodySmall,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // زر تفعيل/تعطيل العرض
                                Switch.adaptive(
                                  value: isActive,
                                  onChanged: (_) => _toggleActive(
                                      offer['id'] as String, isActive),
                                  activeTrackColor: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                            if (discount > 0) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                          alpha: isActive ? 1.0 : 0.5),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'خصم $discount%',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('حذف العرض'),
                                          content: const Text(
                                              'هل أنت متأكد من حذف هذا العرض نهائياً؟'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx),
                                              child: const Text('إلغاء'),
                                            ),
                                            FilledButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                _deleteOffer(
                                                    offer['id'] as String);
                                              },
                                              style: FilledButton.styleFrom(
                                                  backgroundColor: Colors.red),
                                              child: const Text('حذف'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
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
