// lib/features/admin/screens/admin_offer_requests_screen.dart
//
// [v1.4 — AUDIT LOG INTEGRATION]
//   - ADDED: AuditLogService.logAction after successful approve/reject.
//   - ADDED: context.read<AuthController>() captured BEFORE await (async gap safe).
//   - ADDED: severity 'medium' (approve) / 'high' (reject).
//   - FIXED: Uses state `mounted` after messenger capture (linter-safe).
//   - KEPT: All v1.3 UX/performance enhancements intact.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/audit_log_service.dart';
import '../../auth/controllers/auth_controller.dart';

class AdminOfferRequestsScreen extends StatefulWidget {
  const AdminOfferRequestsScreen({super.key});

  @override
  State<AdminOfferRequestsScreen> createState() =>
      _AdminOfferRequestsScreenState();
}

class _AdminOfferRequestsScreenState extends State<AdminOfferRequestsScreen> {
  // تتبع الطلبات التي يتم معالجتها حالياً لمنع النقر المتكرر
  final Set<String> _processingIds = {};

  Future<void> _updateRequest(BuildContext context, String placeId,
      String placeName, bool isApproved) async {
    // ✅ Capture context-dependent objects BEFORE any await
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AuthController>();

    // نافذة تأكيد قبل التنفيذ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isApproved ? 'تأكيد الموافقة' : 'تأكيد الرفض'),
        content: Text(
          isApproved
              ? 'هل أنت متأكد من تفعيل ميزة العروض لـ "$placeName"؟'
              : 'هل أنت متأكد من رفض طلب "$placeName"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: isApproved ? Colors.green : Colors.red,
            ),
            child: Text(isApproved ? 'موافقة' : 'رفض'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingIds.add(placeId));

    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(placeId)
          .update({
        'isOfferFeatureEnabled': isApproved,
        'offerRequestPending': false,
      });

      // ─── سجل التدقيق عبر AuditLogService ───
      await AuditLogService.logAction(
        action:
            isApproved ? 'الموافقة على طلب تفعيل عروض' : 'رفض طلب تفعيل عروض',
        adminName: admin.displayName,
        target: placeName,
        details:
            'placeId: $placeId | ${isApproved ? "تم تفعيل ميزة العروض" : "تم رفض الطلب"}',
        severity: isApproved ? 'medium' : 'high',
      );

      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                isApproved ? '✅ تم الموافقة وتفعيل العروض' : '❌ تم رفض الطلب'),
            backgroundColor: isApproved ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(placeId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('طلبات تفعيل العروض',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .where('offerRequestPending', isEqualTo: true)
            .limit(100) // ✅ حماية للأداء
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text('لا توجد طلبات جديدة حالياً',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final placeId = docs[index].id;
              final name = data['nameAr']?.toString() ?? 'مكان غير مسمى';
              final ownerId = data['ownerId']?.toString() ?? 'غير معروف';

              final isProcessing = _processingIds.contains(placeId);

              return Card(
                clipBehavior: Clip.antiAlias, // ✅ لمنع خروج تأثير الضغط
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
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.storefront,
                                color: theme.colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'طلب تفعيل ميزة العروض والخصومات',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'معرف المالك: $ownerId',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.outline),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => _updateRequest(
                                      context, placeId, name, false),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                              ),
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.red))
                                  : const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: isProcessing
                                  ? null
                                  : () => _updateRequest(
                                      context, placeId, name, true),
                              style: FilledButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Text('موافقة'),
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
