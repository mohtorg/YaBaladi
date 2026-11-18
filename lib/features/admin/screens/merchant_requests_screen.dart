// lib/features/admin/screens/merchant_requests_screen.dart
// [v3.4 — 2026-11-15] — LINTER FIX: Added curly braces to all single-line if statements.
// [v3.3 — SEVERITY ADDED]
//   - ADDED: severity 'medium' (approve) / 'high' (reject).
//   - KEPT: All v3.2 logic, transaction, notifications, context captures intact.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/helpers/notification_helper.dart';
import '../../../core/location/egypt_governorates.dart';
import '../../../core/services/audit_log_service.dart';
import '../../auth/controllers/auth_controller.dart';

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

    // ✅ دمج الـ StreamBuilders في واحد لتقليل استهلاك البيانات
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('merchant_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs.toList() ?? [];
        final count = docs.length;

        // ترتيب محلي بناءً على الوقت (الأحدث أولاً)
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] is Timestamp
              ? aData['createdAt'] as Timestamp
              : null;
          final bTime = bData['createdAt'] is Timestamp
              ? bData['createdAt'] as Timestamp
              : null;

          if (aTime == null && bTime == null) {
            return 0;
          }
          if (aTime == null) {
            return 1;
          }
          if (bTime == null) {
            return -1;
          }
          return bTime.compareTo(aTime);
        });

        return Column(
          children: [
            // ─── Header ───
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
                  if (snapshot.hasError)
                    const Icon(Icons.error, color: Colors.red)
                  else if (count > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                    ),
                ],
              ),
            ),

            // ─── Body ───
            Expanded(
              child: () {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'حدث خطأ في جلب البيانات:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 80,
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.5),
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
              }(),
            ),
          ],
        );
      },
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
    // ✅ Capture context-dependent objects BEFORE any await
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AuthController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content:
            Text('هل تريد الموافقة على طلب "${_data['businessName'] ?? ''}"؟\n'
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

    if (confirmed != true || !mounted) {
      return;
    }
    setState(() => _isProcessing = true);

    try {
      final userId = _data['userId']?.toString() ?? '';
      if (userId.isEmpty) {
        throw 'معرف المستخدم غير موجود';
      }

      final govId = _data['governorateId']?.toString();
      final gov = govId != null && govId.isNotEmpty
          ? kEgyptGovernorates.firstWhere(
              (g) => g.id == govId,
              orElse: () => kEgyptGovernorates.first,
            )
          : kEgyptGovernorates.first;

      String createdPlaceId = '';

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final placeRef = FirebaseFirestore.instance.collection('places').doc();
        createdPlaceId = placeRef.id;
        tx.set(placeRef, {
          'nameAr': _data['placeNameAr']?.toString() ??
              _data['businessName']?.toString() ??
              'بدون اسم',
          'nameEn': _data['placeNameEn']?.toString() ??
              _data['businessName']?.toString() ??
              '',
          'description': '',
          'categoryId': _data['categoryId']?.toString() ?? '',
          'categories': <String>[],
          'governorate': gov.nameAr,
          'city': '',
          'address': _data['address']?.toString() ?? '',
          'phone': _data['businessPhone']?.toString() ??
              _data['phone']?.toString() ??
              '',
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

      if (!mounted) {
        return;
      }
      setState(() => _isProcessing = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ تمت الموافقة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );

      // ─── سجل التدقيق عبر AuditLogService ───
      final businessName = _data['businessName']?.toString() ?? 'بدون اسم';
      await AuditLogService.logAction(
        action: 'قبول طلب انضمام تاجر',
        adminName: admin.displayName,
        target: businessName,
        details:
            'تم إنشاء مكان جديد (ID: $createdPlaceId) وترقية المستخدم ($userId) إلى تاجر | المحافظة: ${gov.nameAr}',
        severity: 'medium',
      );

      try {
        await NotificationHelper.notifyMerchantApproved(userId);
      } catch (e) {
        debugPrint('Failed to send approval notification: $e');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isProcessing = false);
      messenger.showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reject() async {
    final reasonCtrl = TextEditingController();
    // ✅ Capture context-dependent objects BEFORE any await
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AuthController>();

    try {
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
                if (reasonCtrl.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('رفض'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) {
        return;
      }
      setState(() => _isProcessing = true);

      final userId = _data['userId']?.toString() ?? '';
      final reason = reasonCtrl.text.trim();

      await widget.doc.reference.update({
        'status': 'rejected',
        'adminNote': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }
      setState(() => _isProcessing = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم رفض الطلب'),
          backgroundColor: Colors.orange,
        ),
      );

      // ─── سجل التدقيق عبر AuditLogService ───
      final businessName = _data['businessName']?.toString() ?? 'بدون اسم';
      await AuditLogService.logAction(
        action: 'رفض طلب انضمام تاجر',
        adminName: admin.displayName,
        target: businessName,
        details: 'المستخدم ($userId) | سبب الرفض: $reason',
        severity: 'high',
      );

      if (userId.isNotEmpty) {
        try {
          await NotificationHelper.notifyMerchantRejected(userId, reason);
        } catch (e) {
          debugPrint('Failed to send rejection notification: $e');
        }
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isProcessing = false);
      messenger.showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    } finally {
      reasonCtrl.dispose(); // ✅ التخلص من المتحكم لمنع تسريب الذاكرة
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final govId = _data['governorateId']?.toString();
    final govName = govId != null
        ? kEgyptGovernorates
            .firstWhere((g) => g.id == govId,
                orElse: () => kEgyptGovernorates.first)
            .nameAr
        : '—';

    return Card(
      clipBehavior: Clip.antiAlias, // ✅ يمنع تحذير الـ Ink Splash
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _data['businessName']?.toString() ?? 'بدون اسم',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // ✅ حماية النصوص الطويلة من الانهيار
            Text(
              'المالك: ${_data['fullName']?.toString() ?? 'غير محدد'} | الهاتف: ${_data['phone']?.toString() ?? 'غير محدد'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'المحافظة: $govName',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              'العنوان: ${_data['address']?.toString() ?? '—'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _approve,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: const Text('موافقة'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
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
