// lib/features/admin/screens/place_detail_screen.dart
// [v1.8 — 2026-11-01] — EXCELLENCE BADGE: Added admin toggle for isExcellence.
//   - ADDED: Switch to grant/revoke excellence badge manually.
//   - KEPT: All existing block/unblock, delete, and view logic.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/helpers/location_url_helper.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../theme/design_tokens.dart';
import '../../notifications/services/notification_helper.dart';
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

  // ✅ دالة جديدة: تفعيل/إلغاء شارة التميز
  Future<void> _toggleExcellence(bool newValue) async {
    setState(() => _updating = true);
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .update({
        'isExcellence': newValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSnack(newValue ? '🌟 تم منح شارة التميز' : 'تم إلغاء شارة التميز',
          newValue ? Colors.green : Colors.orange);
    } catch (e) {
      _showSnack('❌ خطأ: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _showBlockDialog(Map<String, dynamic> data) async {
    final reasonCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.block, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('حظر النشاط', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'سيتم إخفاء هذا المكان فوراً من التطبيق. يرجى كتابة سبب الحظر لإبلاغ التاجر.',
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                decoration: InputDecoration(
                  labelText: 'سبب الحظر (مطلوب)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  hintText: 'مثال: صور غير لائقة، نشاط غير قانوني...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () {
              if (reasonCtrl.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى كتابة سبب الحظر'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تأكيد الحظر'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _updating = true);
      try {
        final String reason = reasonCtrl.text.trim();
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .update({
          'isActive': false,
          'banReason': reason,
          'bannedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

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

  Future<void> _showUnblockDialog(Map<String, dynamic> data) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('فك الحظر', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'هل أنت متأكد من فك حظر هذا النشاط؟ '
            'سيظهر المكان للجميع مرة أخرى، وسيتم مسح سبب الحظر نهائياً.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('فك الحظر'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _updating = true);
      try {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .update({
          'isActive': true,
          'banReason': FieldValue.delete(),
          'bannedAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text('تأكيد الحذف', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'هل أنت متأكد من حذف هذا المكان نهائياً؟ هذا الإجراء لا يمكن التراجع عنه.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
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
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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

  Future<void> _launchUrl(String url) async {
    if (url.trim().isEmpty) return;
    final opened = await LocationUrlHelper.open(url);
    if (!opened) _showSnack('لا يمكن فتح الرابط', Colors.orange);
  }

  String _getPriceText(int level) {
    switch (level) {
      case 1:
        return 'اقتصادي (\$)';
      case 2:
        return 'متوسط (\$\$)';
      case 3:
        return 'مرتفع (\$\$\$)';
      case 4:
        return 'فاخر (\$\$\$\$)';
      default:
        return 'غير محدد';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('إدارة المكان',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
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
                  strokeWidth: 2.5,
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

          final isExcellence = FirestoreUtils.boolOf(data, 'isExcellence');

          final priceLevel = FirestoreUtils.intOf(data, 'priceLevel');
          final businessEmail = FirestoreUtils.stringOf(data, 'businessEmail');
          final website = FirestoreUtils.stringOf(data, 'website');
          final facebookPage = FirestoreUtils.stringOf(data, 'facebookPage');
          final geoZoneName = FirestoreUtils.stringOf(data, 'geoZoneName');
          final city = FirestoreUtils.stringOf(data, 'city');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(data, rating, reviewCount, geoZoneName, city),

              if (!isActive && banReason.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade200, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.block,
                            color: Colors.red.shade700, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'هذا النشاط محظور',
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'السبب: $banReason',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 13,
                                height: 1.4,
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

              if (isActive) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _updating ? null : () => _showBlockDialog(data),
                  icon: const Icon(Icons.block, color: Colors.red, size: 20),
                  label: const Text(
                    'حظر النشاط نهائياً',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.red.withValues(alpha: 0.5), width: 1.5),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: Colors.red.withValues(alpha: 0.05),
                  ),
                ),
              ],

              if (!isActive && banReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _updating ? null : () => _showUnblockDialog(data),
                  icon: const Icon(Icons.lock_open,
                      color: Colors.white, size: 20),
                  label: const Text(
                    'فك الحظر وإعادة التفعيل',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ],

              // ✅ قسم التحكم في شارة التميز
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: SwitchListTile(
                  title: const Text(
                    'شارة التميز (Excellence Badge)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'تفعيل يدوي يمنح المكان شارة ذهبية مميزة',
                    style: TextStyle(fontSize: 12),
                  ),
                  secondary: Icon(
                    isExcellence
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    color: isExcellence ? Colors.amber : Colors.grey,
                    size: 28,
                  ),
                  value: isExcellence,
                  onChanged: _updating ? null : _toggleExcellence,
                  activeThumbColor: Colors.amber,
                ),
              ),

              const SizedBox(height: 16),

              if (priceLevel > 0 ||
                  businessEmail.isNotEmpty ||
                  website.isNotEmpty ||
                  facebookPage.isNotEmpty) ...[
                _buildRichDetailsSection(
                    priceLevel, businessEmail, website, facebookPage),
                const SizedBox(height: 16),
              ],

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
              const SizedBox(height: 32),

              FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddPlaceScreen(placeId: widget.placeId),
                    ),
                  );
                },
                icon: const Icon(Icons.edit, size: 20),
                label: const Text('تعديل المكان',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: FilledButton.styleFrom(
                  backgroundColor: YaBaladiDesignTokens.primaryBlue,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),

              const SizedBox(height: 12),

              OutlinedButton.icon(
                onPressed: _deletePlace,
                icon: const Icon(Icons.delete_outline,
                    color: Colors.red, size: 20),
                label: const Text('حذف المكان',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Colors.red.withValues(alpha: 0.5), width: 1.5),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    Map<String, dynamic> data,
    double rating,
    int reviewCount,
    String geoZoneName,
    String city,
  ) {
    final isExcellence = FirestoreUtils.boolOf(data, 'isExcellence') ||
        (rating >= 4.5 && reviewCount >= 10);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            YaBaladiDesignTokens.primaryBlue,
            YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.8),
            const Color(0xFF1E88E5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  FirestoreUtils.stringOf(data, 'nameAr', 'بدون اسم'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (isExcellence)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 20),
                ),
            ],
          ),
          if (FirestoreUtils.stringOf(data, 'nameEn').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              FirestoreUtils.stringOf(data, 'nameEn'),
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8), fontSize: 15),
            ),
          ],
          if (geoZoneName.isNotEmpty || city.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(Icons.location_on,
                    color: Colors.white.withValues(alpha: 0.9), size: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 80,
                  ),
                  child: Text(
                    [geoZoneName, city].where((s) => s.isNotEmpty).join(' • '),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  FirestoreUtils.stringOf(data, 'categoryId', '—'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    Text('($reviewCount)',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRichDetailsSection(
      int priceLevel, String email, String website, String facebook) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      YaBaladiDesignTokens.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: YaBaladiDesignTokens.primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'بيانات إضافية',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Color(0xFF2D3748)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade100, height: 1),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (priceLevel > 0)
                _buildInfoChip(Icons.attach_money,
                    'السعر: ${_getPriceText(priceLevel)}', Colors.green),
              if (email.isNotEmpty)
                _buildInfoChip(Icons.email, email, Colors.orange,
                    onTap: () => _launchUrl('mailto:$email')),
              if (website.isNotEmpty)
                _buildInfoChip(Icons.public, website, Colors.purple,
                    onTap: () => _launchUrl(website)),
              if (facebook.isNotEmpty)
                _buildInfoChip(Icons.facebook, 'صفحة الفيسبوك', Colors.blue,
                    onTap: () => _launchUrl(facebook)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color,
      {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width - 100,
              ),
              child: Text(
                label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 13.5),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
