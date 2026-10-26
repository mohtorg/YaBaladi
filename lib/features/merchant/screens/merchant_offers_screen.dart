// lib/features/merchant/screens/merchant_offers_screen.dart
//
// [v3.0 — 2026-10-26] — ARCHITECTURE: No-index query, Local sort, Full CRUD

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
  List<Map<String, dynamic>> _offers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  // ✅ جلب البيانات بدون فهارس (No Indexes Required)
  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final placeId = context.read<AuthController>().placeId;
      if (placeId == null) {
        setState(() {
          _isLoading = false;
          _error = 'لا يوجد مكان مرتبط بحسابك.';
        });
        return;
      }

      // استعلام بسيط جداً (بدون orderBy)
      final snap = await _db
          .collection('offers')
          .where('placeId', isEqualTo: placeId)
          .get();

      final loadedOffers = snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // ✅ الفرز محلياً (بدلاً من orderBy في Firebase)
      loadedOffers.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // الأحدث أولاً
      });

      setState(() {
        _offers = loadedOffers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'فشل تحميل العروض: $e';
      });
    }
  }

  // ✅ إضافة عرض جديد
  Future<void> _addOffer() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة عرض جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'عنوان العرض',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'تفاصيل العرض',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: discountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'نسبة الخصم (%)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('نشر العرض'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (titleCtrl.text.trim().isEmpty) return;

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
      _loadOffers(); // إعادة التحميل
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
      _loadOffers();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('عروضي'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadOffers,
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addOffer,
        icon: const Icon(Icons.add),
        label: const Text('عرض جديد'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.orange),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOffers,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_offers.isEmpty) {
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // مسافة للزر العائم
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        final offer = _offers[index];
        final discount = offer['discount'] as int? ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_offer, color: Colors.purple),
            ),
            title: Text(
              offer['title'] as String? ?? 'بدون عنوان',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((offer['description'] as String? ?? '').isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      offer['description'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (discount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text(
                        'خصم $discount%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.zero,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('حذف العرض'),
                    content: const Text('هل أنت متأكد من حذف هذا العرض؟'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteOffer(offer['id'] as String);
                        },
                        style:
                            FilledButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('حذف'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
