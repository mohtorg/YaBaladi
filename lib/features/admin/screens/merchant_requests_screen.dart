// lib/features/admin/screens/merchant_requests_screen.dart
//
// [v1.1 — 2026-10-28] — ADD: Send notifications on approve/reject

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/location/egypt_governorates.dart';
import '../../notifications/services/notification_helper.dart'; // ✅ استيراد جديد

class MerchantRequestsPage extends StatelessWidget {
  const MerchantRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات انضمام التجار')),
      body: const MerchantRequestsScreen(),
    );
  }
}

class MerchantRequestsScreen extends StatelessWidget {
  const MerchantRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'طلبات انضمام التجار',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('merchant_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count معلق',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('merchant_requests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('خطأ: ${snapshot.error}'));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt']
                      as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt']
                      as Timestamp?;
                  if (aTime == null) return 1;
                  if (bTime == null) return -1;
                  return bTime.compareTo(aTime);
                });

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 80,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد طلبات معلقة',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'جميع الطلبات تمت مراجعتها',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) =>
                    _MerchantRequestCard(doc: docs[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Request Card
// ═══════════════════════════════════════════════════════════════

class _MerchantRequestCard extends StatefulWidget {
  final QueryDocumentSnapshot doc;
  const _MerchantRequestCard({required this.doc});

  @override
  State<_MerchantRequestCard> createState() => _MerchantRequestCardState();
}

class _MerchantRequestCardState extends State<_MerchantRequestCard> {
  bool _isProcessing = false;
  Map<String, dynamic> get _data => widget.doc.data() as Map<String, dynamic>;

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text('هل تريد الموافقة على طلب "${_data['businessName']}"؟\n'
            'سيتم إنشاء المكان وترقية المستخدم إلى تاجر.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('موافقة'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final userId = _data['userId'] as String;
      final govId = _data['governorateId'] as String?;
      final gov = govId != null && govId.isNotEmpty
          ? kEgyptGovernorates.firstWhere(
              (g) => g.id == govId,
              orElse: () => kEgyptGovernorates.first,
            )
          : kEgyptGovernorates.first;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final placeRef = FirebaseFirestore.instance.collection('places').doc();
        tx.set(placeRef, {
          'nameAr': _data['placeNameAr'] ?? _data['businessName'],
          'nameEn': _data['placeNameEn'] ?? _data['businessName'],
          'description': '',
          'categoryId': _data['categoryId'] ?? '',
          'categories': <String>[],
          'governorate': gov.nameAr,
          'city': '',
          'address': _data['address'] ?? '',
          'phone': _data['businessPhone'] ?? _data['phone'] ?? '',
          'whatsapp': '',
          'location': _data['location'],
          'imageUrls': <String>[],
          'averageRating': 0.0,
          'reviewCount': 0,
          'isApproved': true,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'priceLevel': 1,
          'hasWifi': false,
          'hasParking': false,
          'hasRestroom': false,
          'hasAccessibility': false,
          'isFamilyFriendly': false,
          'isHalal': false,
          'hasDelivery': false,
          'hasReservation': false,
          'ownerId': userId,
          'isVerifiedMerchant': false,
          'requiresAdminReview': false,
        });

        final userRef =
            FirebaseFirestore.instance.collection('users').doc(userId);
        tx.update(userRef, {'role': 'merchant'});

        tx.update(widget.doc.reference, {
          'status': 'approved',
          'createdPlaceId': placeRef.id,
          'reviewedAt': FieldValue.serverTimestamp(),
        });
      });

      // ✅ إرسال إشعار للتاجر بعد نجاح المعاملة
      await NotificationHelper.notifyMerchantApproved(userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تمت الموافقة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سبب الرفض'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'اكتب السبب هنا...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, true);
            },
            child: const Text('رفض'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);

    try {
      final userId = _data['userId'] as String? ?? '';
      final reason = reasonCtrl.text.trim();

      await widget.doc.reference.update({
        'status': 'rejected',
        'adminNote': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // ✅ إرسال إشعار للتاجر بعد نجاح التحديث
      if (userId.isNotEmpty) {
        await NotificationHelper.notifyMerchantRejected(userId, reason);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم رفض الطلب'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final govId = _data['governorateId'] as String?;
    final govName = govId != null
        ? kEgyptGovernorates
            .firstWhere((g) => g.id == govId,
                orElse: () => kEgyptGovernorates.first)
            .nameAr
        : '—';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _data['businessName'] ?? 'بدون اسم',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('المالك: ${_data['fullName']} | الهاتف: ${_data['phone']}'),
            Text('المحافظة: $govName'),
            Text('العنوان: ${_data['address'] ?? '—'}'),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _approve,
                      child: const Text('موافقة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      child: const Text('رفض'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
