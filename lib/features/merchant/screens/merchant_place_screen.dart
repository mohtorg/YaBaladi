// lib/features/merchant/screens/merchant_place_screen.dart
// [v1.5.1 — 2026-11-12] — LINTER FIX:
//   - Removed unused `_placeCategoryId` field. `_selectedCategory` already
//     holds the same information.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../models/location_hierarchy_models.dart';
import '../../../models/place_aggregate_model.dart';
import '../../../models/review_criterion_model.dart';
import '../../../repositories/location_repository.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../rating/services/pin_service.dart';

class MerchantPlaceScreen extends StatefulWidget {
  final String? placeId;

  const MerchantPlaceScreen({super.key, this.placeId});

  @override
  State<MerchantPlaceScreen> createState() => _MerchantPlaceScreenState();
}

class _MerchantPlaceScreenState extends State<MerchantPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationRepo = LocationRepository();

  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isLoading = false;
  bool _isInitializing = true;
  String? _generatedPin;

  List<DistrictModel> _districtsList = [];
  List<ZoneModel> _zonesList = [];
  String? _selectedDistrictId;
  String? _selectedZoneId;

  String _selectedCategory = 'restaurants';

  // ✅ بيانات الإحصاءات
  List<ReviewCriterionModel> _placeCriteria = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final districts = await _locationRepo.getDistricts('portsaid');
    if (mounted) {
      setState(() {
        _districtsList = districts;
        if (districts.isNotEmpty && widget.placeId == null) {
          _selectedDistrictId = districts.first.id;
          _fetchZones(districts.first.id);
        }
      });
    }

    if (widget.placeId != null) {
      await _loadPlaceData();
    } else {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _fetchZones(String districtId) async {
    setState(() {
      _zonesList = [];
      _selectedZoneId = null;
    });
    final zones = await _locationRepo.getZones(districtId);
    if (mounted) {
      setState(() {
        _zonesList = zones;
        if (zones.isNotEmpty) {
          _selectedZoneId = zones.first.id;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaceData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameArController.text = data['nameAr'] ?? '';
          _nameEnController.text = data['nameEn'] ?? '';
          _descController.text = data['description'] ?? '';
          _addressController.text = data['address'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _whatsappController.text = data['whatsapp'] ?? '';

          final loc = data['location'] as GeoPoint?;
          if (loc != null) {
            _latController.text = loc.latitude.toString();
            _lngController.text = loc.longitude.toString();
          }

          _selectedCategory = data['categoryId'] ?? 'restaurants';
          _selectedDistrictId = data['districtId']?.toString();
          _selectedZoneId = data['zoneId']?.toString();

          final pinObfuscated = data['pin_obfuscated'];
          if (pinObfuscated != null) {
            _generatedPin = 'موجود ومفعل';
          }
        });

        // ✅ جلب المعايير للتصنيف (لإحصاءات التقييم)
        await _loadPlaceCriteria(_selectedCategory);

        if (_selectedDistrictId != null) {
          await _fetchZones(_selectedDistrictId!);
          if (mounted) {
            setState(() {
              _selectedZoneId = data['zoneId']?.toString();
            });
          }
        }
      }
    } catch (e) {
      _showSnack('خطأ في تحميل البيانات: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  /// يجلب معايير التصنيف (عام + خاص) لعرض الأسماء العربية للإحصاءات.
  Future<void> _loadPlaceCriteria(String categoryId) async {
    try {
      final generalSnap = await FirebaseFirestore.instance
          .collection('review_criteria')
          .where('isGeneral', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      final specificSnap = await FirebaseFirestore.instance
          .collection('review_criteria')
          .where('categoryId', isEqualTo: categoryId)
          .where('isGeneral', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .get();

      final allDocs = [...generalSnap.docs, ...specificSnap.docs];
      final list =
          allDocs.map((d) => ReviewCriterionModel.fromFirestore(d)).toList();

      list.sort((a, b) {
        if (a.isGeneral != b.isGeneral) {
          return a.isGeneral ? -1 : 1;
        }
        return a.order.compareTo(b.order);
      });

      if (mounted) {
        setState(() => _placeCriteria = list);
      }
    } catch (e) {
      debugPrint('Error loading criteria: $e');
    }
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = context.read<AuthController>().user;
    if (user == null) {
      _showSnack('يجب تسجيل الدخول أولاً', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final double? lat = double.tryParse(_latController.text);
      final double? lng = double.tryParse(_lngController.text);

      final selectedDistrict = _districtsList.firstWhere(
          (d) => d.id == _selectedDistrictId,
          orElse: () => throw 'اختر الحي');
      final selectedZone = _zonesList.firstWhere((z) => z.id == _selectedZoneId,
          orElse: () => throw 'اختر المنطقة');

      final placeData = {
        'nameAr': _nameArController.text.trim(),
        'nameEn': _nameEnController.text.trim(),
        'description': _descController.text.trim(),
        'categoryId': _selectedCategory,
        'districtId': _selectedDistrictId,
        'districtName': selectedDistrict.nameAr,
        'zoneId': _selectedZoneId,
        'zoneName': selectedZone.nameAr,
        'governorate': 'بورسعيد',
        'city': selectedDistrict.nameAr,
        'geoZoneName': selectedZone.nameAr,
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        if (lat != null && lng != null) 'location': GeoPoint(lat, lng),
        'ownerId': user.uid,
        'isActive': true,
        'isApproved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.placeId == null) {
        placeData['createdAt'] = FieldValue.serverTimestamp();
        placeData['averageRating'] = 0.0;
        placeData['reviewCount'] = 0;

        final docRef = await FirebaseFirestore.instance
            .collection('places')
            .add(placeData);

        final newPin = PinService.generatePin();
        final obfuscatedPin =
            PinService.obfuscate(placeId: docRef.id, pin: newPin);

        await docRef.update({'pin_obfuscated': obfuscatedPin});

        setState(() {
          _generatedPin = newPin;
        });

        _showSnack('تم إنشاء المكان بنجاح! رمز التوثيق الخاص بك هو: $newPin',
            isError: false);
      } else {
        await FirebaseFirestore.instance
            .collection('places')
            .doc(widget.placeId)
            .update(placeData);
        _showSnack('تم تحديث بيانات المكان بنجاح', isError: false);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnack('حدث خطأ أثناء الحفظ: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: YaBaladiTypography.bodyMedium.copyWith(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // إحصاءات التقييم (Read-Only)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildStatsSection(ThemeData theme) {
    if (widget.placeId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('place_aggregates')
          .doc(widget.placeId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        if (!snapshot.data!.exists) {
          return _buildEmptyStatsCard(theme);
        }

        final agg = PlaceAggregateModel.fromFirestore(snapshot.data!);
        if (agg.totalRatings == 0) {
          return _buildEmptyStatsCard(theme);
        }

        final Map<String, ReviewCriterionModel> criteriaMap = {
          for (final c in _placeCriteria) c.fieldKey: c,
        };

        final entries = agg.dimensionAverages.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final top = entries.take(5).toList();

        return Container(
          margin: const EdgeInsets.only(bottom: YaBaladiDesignTokens.space6),
          padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius:
                BorderRadius.circular(YaBaladiDesignTokens.radiusLarge),
            border:
                Border.all(color: theme.colorScheme.outlineVariant, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.analytics_outlined,
                        size: 20, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'إحصاءات التقييم',
                      style: YaBaladiTypography.headingSubsection.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface),
                    ),
                  ),
                  _buildConfidenceChip(theme, agg.sampleQuality),
                ],
              ),
              const SizedBox(height: YaBaladiDesignTokens.space4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            agg.averageOverall.toStringAsFixed(1),
                            style: YaBaladiTypography.display.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 40,
                            ),
                          ),
                          Text(
                            ' / 5',
                            style: YaBaladiTypography.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: List.generate(5, (i) {
                          final filled = (i + 1) <= agg.averageOverall;
                          final halfFilled =
                              !filled && (i + 0.5) <= agg.averageOverall;
                          return Icon(
                            filled
                                ? Icons.star_rounded
                                : (halfFilled
                                    ? Icons.star_half_rounded
                                    : Icons.star_outline_rounded),
                            color: filled || halfFilled
                                ? Colors.amber
                                : Colors.grey.shade300,
                            size: 20,
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(width: YaBaladiDesignTokens.space4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${agg.totalRatings} تقييم',
                          style: YaBaladiTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (agg.lastComputedAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'آخر تحديث: ${_formatShortDate(agg.lastComputedAt!)}',
                            style: YaBaladiTypography.caption.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (top.isNotEmpty) ...[
                const SizedBox(height: YaBaladiDesignTokens.space4),
                const Divider(height: 1),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                Text(
                  'أبرز المعايير',
                  style: YaBaladiTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: YaBaladiDesignTokens.space2),
                ...top.map((entry) {
                  final criterion = criteriaMap[entry.key];
                  final label = criterion?.nameAr ?? entry.key;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: YaBaladiTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildMiniBar(theme, entry.value),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 26,
                          child: Text(
                            entry.value.toStringAsFixed(1),
                            style: YaBaladiTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyStatsCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: YaBaladiDesignTokens.space6),
      padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(YaBaladiDesignTokens.radiusLarge),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics_outlined,
              color: theme.colorScheme.onSurfaceVariant, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'لا توجد تقييمات بعد',
                  style: YaBaladiTypography.headingLabel.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ستظهر إحصاءات التقييم هنا بمجرد أن يقيّم الزوار مكانك.',
                  style: YaBaladiTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceChip(ThemeData theme, double quality) {
    final Color bg;
    final Color fg;
    final String label;

    if (quality >= 0.75) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
      label = 'ثقة عالية';
    } else if (quality >= 0.4) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
      label = 'ثقة متوسطة';
    } else {
      bg = Colors.grey.shade100;
      fg = Colors.grey.shade700;
      label = 'ثقة منخفضة';
    }

    final pct = (quality * 100).round().clamp(0, 100);

    return Tooltip(
      message: 'يعكس مستوى الثقة في البيانات ($pct%)',
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(
              '$label ($pct%)',
              style: TextStyle(
                color: fg,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniBar(ThemeData theme, double value) {
    final pct = (value / 5.0).clamp(0.0, 1.0);
    return SizedBox(
      width: 60,
      height: 6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: pct,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
      ),
    );
  }

  String _formatShortDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(title: const Text('جاري التحميل...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
            widget.placeId == null ? 'إضافة مكان جديد' : 'تعديل بيانات المكان'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatsSection(theme),
                _buildSectionTitle('البيانات الأساسية'),
                TextFormField(
                  controller: _nameArController,
                  decoration: const InputDecoration(
                      labelText: 'اسم المكان (بالعربية) *'),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                TextFormField(
                  controller: _nameEnController,
                  decoration: const InputDecoration(
                      labelText: 'اسم المكان (بالإنجليزية)'),
                ),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                DropdownButtonFormField<String>(
                  key: ValueKey('cat_$_selectedCategory'),
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(labelText: 'التصنيف *'),
                  items: const [
                    DropdownMenuItem(value: 'restaurants', child: Text('مطعم')),
                    DropdownMenuItem(value: 'cafes', child: Text('مقهى')),
                    DropdownMenuItem(
                        value: 'pharmacies', child: Text('صيدلية')),
                    DropdownMenuItem(value: 'shopping', child: Text('تسوق')),
                  ],
                  onChanged: (v) => setState(() => _selectedCategory = v!),
                ),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'وصف المكان'),
                  maxLines: 3,
                ),
                const SizedBox(height: YaBaladiDesignTokens.space6),
                _buildSectionTitle('الموقع الجغرافي'),
                TextFormField(
                  controller: _addressController,
                  decoration:
                      const InputDecoration(labelText: 'العنوان التفصيلي *'),
                  validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                ),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                DropdownButtonFormField<String>(
                  key: ValueKey('dist_$_selectedDistrictId'),
                  initialValue: _selectedDistrictId,
                  decoration: const InputDecoration(labelText: 'الحي *'),
                  items: _districtsList
                      .map((d) =>
                          DropdownMenuItem(value: d.id, child: Text(d.nameAr)))
                      .toList(),
                  validator: (v) => v == null ? 'اختر الحي' : null,
                  onChanged: (val) {
                    setState(() => _selectedDistrictId = val);
                    if (val != null) {
                      _fetchZones(val);
                    }
                  },
                ),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                DropdownButtonFormField<String>(
                  key: ValueKey('zone_$_selectedZoneId'),
                  initialValue: _selectedZoneId,
                  decoration: const InputDecoration(labelText: 'المنطقة *'),
                  items: _zonesList
                      .map((z) =>
                          DropdownMenuItem(value: z.id, child: Text(z.nameAr)))
                      .toList(),
                  validator: (v) => v == null ? 'اختر المنطقة' : null,
                  onChanged: _selectedDistrictId != null
                      ? (val) {
                          setState(() => _selectedZoneId = val);
                        }
                      : null,
                ),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latController,
                        decoration:
                            const InputDecoration(labelText: 'خط العرض (Lat)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: YaBaladiDesignTokens.space3),
                    Expanded(
                      child: TextFormField(
                        controller: _lngController,
                        decoration:
                            const InputDecoration(labelText: 'خط الطول (Lng)'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: YaBaladiDesignTokens.space2),
                Text(
                  'ملاحظة: إدخال الإحداثيات بدقة يسهل على المستخدمين التحقق من التواجد وتقييم المكان.',
                  style: YaBaladiTypography.caption
                      .copyWith(color: YaBaladiDesignTokens.textSecondary),
                ),
                const SizedBox(height: YaBaladiDesignTokens.space6),
                _buildSectionTitle('بيانات التواصل'),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: YaBaladiDesignTokens.space3),
                TextFormField(
                  controller: _whatsappController,
                  decoration: const InputDecoration(labelText: 'رقم الواتساب'),
                  keyboardType: TextInputType.phone,
                ),
                if (_generatedPin != null) ...[
                  const SizedBox(height: YaBaladiDesignTokens.space6),
                  Container(
                    padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(
                          YaBaladiDesignTokens.radiusMedium),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.verified_user,
                            color: Colors.green.shade800, size: 40),
                        const SizedBox(height: YaBaladiDesignTokens.space2),
                        Text(
                          'رمز التوثيق الخاص بمكانك (PIN)',
                          style: YaBaladiTypography.headingSubsection
                              .copyWith(color: Colors.green.shade900),
                        ),
                        const SizedBox(height: YaBaladiDesignTokens.space1),
                        Text(
                          _generatedPin!,
                          style: YaBaladiTypography.display.copyWith(
                            color: Colors.green.shade900,
                            letterSpacing: 8,
                          ),
                        ),
                        const SizedBox(height: YaBaladiDesignTokens.space2),
                        Text(
                          'قم بطباعة هذا الرقم ووضعه عند الكاشير. سيساعد هذا العملاء على توثيق تقييماتهم.',
                          textAlign: TextAlign.center,
                          style: YaBaladiTypography.bodySmall
                              .copyWith(color: Colors.green.shade800),
                        ),
                        const SizedBox(height: YaBaladiDesignTokens.space3),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _generatedPin!));
                            _showSnack('تم نسخ الرمز', isError: false);
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ الرمز'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green.shade800,
                            side: BorderSide(color: Colors.green.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: YaBaladiDesignTokens.space8),
                FilledButton.icon(
                  onPressed: _isLoading ? null : _savePlace,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded),
                  label: Text(_isLoading ? 'جاري الحفظ...' : 'حفظ البيانات'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: YaBaladiDesignTokens.space6),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: YaBaladiDesignTokens.space3),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: YaBaladiDesignTokens.space2),
          Text(
            title,
            style: YaBaladiTypography.headingSubsection.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
