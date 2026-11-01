// lib/features/merchant/screens/add_branch_screen.dart
//
// [v1.0 — 2026-11-01] — ADD BRANCH SCREEN
//   - Allows merchant to add a sub-branch inheriting main branch data.
//   - Saves to Firestore with parentId and isBranch = true.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/place.dart';
import '../../../core/services/zone_service.dart';

class AddBranchScreen extends StatefulWidget {
  final Place mainBranch;

  const AddBranchScreen({super.key, required this.mainBranch});

  @override
  State<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends State<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _isSaving = false;
  bool _isFetchingLocation = false;
  String _fetchedZoneName = '';

  @override
  void initState() {
    super.initState();
    // نسخ البيانات الأساسية من المركز الرئيسي كقيم افتراضية
    _phoneCtrl.text = widget.mainBranch.phone;
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'خدمة الموقع (GPS) غير مفعلة في الهاتف';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'تم رفض صلاحية الوصول للموقع';
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw 'صلاحية الموقع مرفوضة نهائياً من إعدادات الهاتف';
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final zoneName = await ZoneService()
          .getZoneName(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _latCtrl.text = position.latitude.toStringAsFixed(6);
          _lngCtrl.text = position.longitude.toStringAsFixed(6);
          _fetchedZoneName = zoneName ?? 'غير معروف';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ تم جلب الموقع: $_fetchedZoneName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  Future<void> _saveBranch() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول أولاً')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final lat = double.parse(_latCtrl.text.trim());
      final lng = double.parse(_lngCtrl.text.trim());
      final geoPoint = GeoPoint(lat, lng);

      // نسخ الخصائص من المركز الرئيسي
      final branchData = {
        // البيانات المنسوخة
        'nameAr': widget.mainBranch.nameAr,
        'nameEn': widget.mainBranch.nameEn,
        'description': widget.mainBranch.description,
        'categoryId': widget.mainBranch.categoryId,
        'categories': widget.mainBranch.categories,
        'governorate': widget.mainBranch.governorate,
        'city': widget.mainBranch.city,
        'imageUrls': widget.mainBranch.imageUrls,
        'hasWifi': widget.mainBranch.hasWifi,
        'hasParking': widget.mainBranch.hasParking,
        'hasRestroom': widget.mainBranch.hasRestroom,
        'hasAccessibility': widget.mainBranch.hasAccessibility,
        'isFamilyFriendly': widget.mainBranch.isFamilyFriendly,
        'isHalal': widget.mainBranch.isHalal,
        'hasDelivery': widget.mainBranch.hasDelivery,
        'hasReservation': widget.mainBranch.hasReservation,
        'priceLevel': widget.mainBranch.priceLevel,
        'tags': widget.mainBranch.tags,
        'website': widget.mainBranch.website,
        'facebookPage': widget.mainBranch.facebookPage,
        'businessEmail': widget.mainBranch.businessEmail,
        'workingHours': widget.mainBranch.workingHours,

        // البيانات الخاصة بالفرع
        'address': _addressCtrl.text.trim(),
        'location': geoPoint,
        'latitude': lat,
        'longitude': lng,
        'phone': _phoneCtrl.text.trim(),
        'businessPhone': _phoneCtrl.text.trim(),
        'geoZoneName': _fetchedZoneName,
        'ownerId': auth.uid,
        'isBranch': true,
        'parentId': widget.mainBranch.id,
        'isApproved': true, // الموافقة تلقائياً للفروع التابعة لتاجر معتمد
        'isActive': true,
        'averageRating': 0.0,
        'reviewCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'requiresAdminReview': false,
      };

      await FirebaseFirestore.instance.collection('places').add(branchData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إضافة الفرع بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل الحفظ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('إضافة فرع جديد'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بانر تعريفي
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: theme.colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'سيتم نسخ جميع بيانات المركز الرئيسي تلقائياً. يرجى إدخال العنوان والموقع الجديد للفرع فقط.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // اسم الفرع (يمكن تعديله أو تركه فارغاً ليأخذ اسم المركز)
            TextFormField(
              initialValue: '${widget.mainBranch.nameAr} - فرع',
              decoration: const InputDecoration(
                labelText: 'اسم الفرع (اختياري)',
                prefixIcon: Icon(Icons.storefront),
                border: OutlineInputBorder(),
              ),
              onSaved: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  // يمكن إضافة اسم مخصص للفرع لاحقاً
                }
              },
            ),
            const SizedBox(height: 16),

            // رقم الهاتف
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم هاتف الفرع',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'رقم الهاتف مطلوب' : null,
            ),
            const SizedBox(height: 16),

            // العنوان
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'العنوان التفصيلي',
                hintText: 'الشارع، الحي، علامة مميزة...',
                prefixIcon: Icon(Icons.map),
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'العنوان مطلوب' : null,
            ),
            const SizedBox(height: 16),

            // زر جلب الموقع
            ElevatedButton.icon(
              onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
              icon: _isFetchingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: const Text('تحديد موقعي الحالي'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // إحداثيات
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'خط العرض',
                      prefixIcon: Icon(Icons.north),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'خط الطول',
                      prefixIcon: Icon(Icons.east),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'مطلوب' : null,
                  ),
                ),
              ],
            ),
            if (_fetchedZoneName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green.shade800, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'الحي: $_fetchedZoneName',
                        style: TextStyle(
                            color: Colors.green.shade900,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // زر الحفظ
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveBranch,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ الفرع'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
