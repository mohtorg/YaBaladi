// lib/features/admin/screens/place_detail_screen.dart
//
// [v1.3 — 2026-10-28] — ADD: Send notifications on block/unblock

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/helpers/location_url_helper.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../theme/design_tokens.dart';
import '../../notifications/services/notification_helper.dart'; // ✅ استيراد جديد
import '../widgets/place_detail_sections.dart';
import 'add_place_screen.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;
  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _updating = false;

  Future<void> _toggleStatus(String field, bool newValue) async {
    setState(() => _updating = true);
    try {
      final updateData = <String, dynamic>{
        field: newValue,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // إذا تم تفعيل المكان (isActive = true)، نمسح سبب الحظر السابق
      if (field == 'isActive' && newValue == true) {
        updateData['banReason'] = FieldValue.delete();
        updateData['bannedAt'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .update(updateData);

      _showSnack('✅ تم التحديث', Colors.green);
    } catch (e) {
      _showSnack('❌ خطأ: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  // ✅ دالة الحظر: تطلب سبباً ثم توقف المكان وتُرسل إشعاراً
  Future<void> _showBlockDialog(Map<String, dynamic> data) async {
    final reasonCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red),
            SizedBox(width: 8),
            Text('حظر النشاط'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'سيتم إخفاء هذا المكان فوراً من التطبيق. يرجى كتابة سبب الحظر لإبلاغ التاجر.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'سبب الحظر (مطلوب)',
                border: OutlineInputBorder(),
                hintText: 'مثال: صور غير لائقة، نشاط غير قانوني...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('يرجى كتابة سبب الحظر')),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تأكيد الحظر'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _updating = true);
      try {
        final String reason = reasonCtrl.text.trim();

        // 1. تحديث قاعدة البيانات
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .update({
          'isActive': false,
          'banReason': reason,
          'bannedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. إرسال إشعار للتاجر
        final String ownerId = data['ownerId']?.toString() ?? '';
        final String placeName =
            FirestoreUtils.stringOf(data, 'nameAr', 'مكانك');
        if (ownerId.isNotEmpty) {
          await NotificationHelper.notifyPlaceBlocked(
              ownerId, placeName, reason);
        }

        if (mounted) {
          _showSnack('🚫 تم حظر النشاط بنجاح', Colors.red);
        }
      } catch (e) {
        if (mounted) _showSnack('❌ خطأ: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _updating = false);
      }
    }
  }

  // ✅ دالة فك الحظر: تعيد التفعيل وتمسح سبب الحظر وتُرسل إشعاراً
  Future<void> _showUnblockDialog(Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: Colors.green),
            SizedBox(width: 8),
            Text('فك الحظر'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من فك حظر هذا النشاط؟ '
          'سيظهر المكان للجميع مرة أخرى، وسيتم مسح سبب الحظر نهائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('فك الحظر'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _updating = true);
      try {
        // 1. تحديث قاعدة البيانات
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .update({
          'isActive': true,
          'banReason': FieldValue.delete(),
          'bannedAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // 2. إرسال إشعار للتاجر
        final String ownerId = data['ownerId']?.toString() ?? '';
        final String placeName =
            FirestoreUtils.stringOf(data, 'nameAr', 'مكانك');
        if (ownerId.isNotEmpty) {
          await NotificationHelper.notifyPlaceUnblocked(ownerId, placeName);
        }

        if (mounted) {
          _showSnack('✅ تم فك الحظر وإعادة التفعيل', Colors.green);
        }
      } catch (e) {
        if (mounted) _showSnack('❌ خطأ: $e', Colors.red);
      } finally {
        if (mounted) setState(() => _updating = false);
      }
    }
  }

  Future<void> _deletePlace() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
            'هل أنت متأكد من حذف هذا المكان نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .delete();
        if (mounted) Navigator.pop(context);
      } catch (e) {
        _showSnack('❌ خطأ: $e', Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _openOnMap(double lat, double lng) async {
    final url = LocationUrlHelper.mapUrl(lat: lat, lng: lng);
    final opened = await LocationUrlHelper.open(url);
    if (!opened) _showSnack('لا يمكن فتح الخريطة', Colors.orange);
  }

  Future<void> _openDirections(double lat, double lng) async {
    final url = LocationUrlHelper.directionsUrl(lat: lat, lng: lng);
    final opened = await LocationUrlHelper.open(url);
    if (!opened) _showSnack('لا يمكن فتح الاتجاهات', Colors.orange);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('إدارة المكان'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (_updating)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = FirestoreUtils.dataOf(snapshot.data!);
          final coords = FirestoreUtils.coordinatesOf(data);
          final tags = FirestoreUtils.stringListOf(data, 'tags');
          final rating = FirestoreUtils.doubleOf(data, 'averageRating');
          final reviewCount = FirestoreUtils.intOf(data, 'reviewCount');
          final isActive = FirestoreUtils.boolOf(data, 'isActive');
          final banReason = FirestoreUtils.stringOf(data, 'banReason');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(data, rating, reviewCount),

              // ✅ عرض سبب الحظر (إذا كان المكان محظوراً)
              if (!isActive && banReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.block, color: Colors.red.shade700, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'هذا النشاط محظور',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'السبب: $banReason',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              PlaceStatusSection(
                isActive: isActive,
                isApproved: FirestoreUtils.boolOf(data, 'isApproved'),
                updating: _updating,
                onToggle: _toggleStatus,
              ),

              // ✅ زر الحظر (يظهر فقط إذا كان المكان نشطاً)
              if (isActive) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _updating ? null : () => _showBlockDialog(data),
                  icon: const Icon(Icons.block, color: Colors.red),
                  label: const Text(
                    'حظر النشاط نهائياً',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red, width: 1.5),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              // ✅ زر فك الحظر (يظهر فقط إذا كان المكان محظوراً)
              if (!isActive && banReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _updating ? null : () => _showUnblockDialog(data),
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  label: const Text(
                    'فك الحظر وإعادة التفعيل',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              PlaceLocationSection(
                data: data,
                onOpenMap: () {
                  if (coords != null) _openOnMap(coords.lat, coords.lng);
                },
                onOpenDirections: () {
                  if (coords != null) _openDirections(coords.lat, coords.lng);
                },
              ),
              const SizedBox(height: 16),
              PlaceContactSection(data: data),
              const SizedBox(height: 16),
              PlaceServicesSection(data: data),
              const SizedBox(height: 16),
              PlaceTagsSection(tags: tags),
              const SizedBox(height: 24),

              // زر التعديل
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPlaceScreen(placeId: widget.placeId),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('تعديل المكان'),
                style: FilledButton.styleFrom(
                  backgroundColor: YaBaladiDesignTokens.primaryBlue,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),

              const SizedBox(height: 12),

              // زر الحذف النهائي
              OutlinedButton.icon(
                onPressed: _deletePlace,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('حذف المكان',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
      Map<String, dynamic> data, double rating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            YaBaladiDesignTokens.primaryBlue,
            YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            FirestoreUtils.stringOf(data, 'nameAr', 'بدون اسم'),
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          if (FirestoreUtils.stringOf(data, 'nameEn').isNotEmpty)
            Text(
              FirestoreUtils.stringOf(data, 'nameEn'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  FirestoreUtils.stringOf(data, 'categoryId', '—'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(rating.toStringAsFixed(1),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text('($reviewCount)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
