// lib/features/merchant/screens/manage_offer_screen.dart
// [v1.0 — 2026-11-02] — MERCHANT OFFER MANAGEMENT
//   - Allows merchants to create, edit, or disable an offer.
//   - Validates title and expiry date.
//   - Saves 'offerCreatedAt' to ensure correct sorting in AllOffersScreen.
//   - Uses serverTimestamp for accurate syncing.

// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageOfferScreen extends StatefulWidget {
  final String placeId;
  final Map<String, dynamic>
      placeData; // نمرر بيانات المكان لتعبئة الحقول مسبقاً

  const ManageOfferScreen({
    super.key,
    required this.placeId,
    required this.placeData,
  });

  @override
  State<ManageOfferScreen> createState() => _ManageOfferScreenState();
}

class _ManageOfferScreenState extends State<ManageOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _detailsController;

  bool _hasActiveOffer = false;
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // تعبئة البيانات السابقة إن وجدت
    _titleController = TextEditingController(
        text: widget.placeData['offerTitle']?.toString() ?? '');
    _detailsController = TextEditingController(
        text: widget.placeData['offerDetails']?.toString() ?? '');
    _hasActiveOffer = widget.placeData['hasActiveOffer'] == true;

    final expiryTimestamp = widget.placeData['offerExpiryDate'] as Timestamp?;
    _expiryDate = expiryTimestamp?.toDate();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  // ✅ دالة اختيار تاريخ الانتهاء
  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate:
          _expiryDate ?? now.add(const Duration(days: 7)), // افتراضي أسبوع
      firstDate: now, // لا يمكن اختيار تاريخ في الماضي
      lastDate: now.add(const Duration(days: 365)), // حتى سنة قادمة
      helpText: 'اختر تاريخ انتهاء العرض',
      cancelText: 'إلغاء',
      confirmText: 'موافق',
    );

    if (pickedDate != null) {
      setState(() {
        // نضيف ساعة 23:59:59 ليكون العرض صالحاً حتى نهاية اليوم المختار
        _expiryDate = DateTime(
            pickedDate.year, pickedDate.month, pickedDate.day, 23, 59, 59);
      });
    }
  }

  // ✅ دالة الحفظ في Firebase
  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasActiveOffer && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار تاريخ انتهاء العرض أولاً'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final Map<String, dynamic> updateData = {
        'hasActiveOffer': _hasActiveOffer,
        'offerTitle': _hasActiveOffer
            ? _titleController.text.trim()
            : FieldValue.delete(),
        'offerDetails': _hasActiveOffer
            ? _detailsController.text.trim()
            : FieldValue.delete(),
        'offerExpiryDate': _hasActiveOffer && _expiryDate != null
            ? Timestamp.fromDate(_expiryDate!)
            : FieldValue.delete(),
      };

      // ✅ إضافة وقت الإنشاء فقط إذا كان العرض جديداً أو تم تفعيله للتو
      if (_hasActiveOffer && widget.placeData['hasActiveOffer'] != true) {
        updateData['offerCreatedAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.placeId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasActiveOffer
                ? '✅ تم حفظ ونشر العرض بنجاح'
                : 'تم إيقاف العرض'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context); // العودة للشاشة السابقة بعد الحفظ
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
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
        title: const Text('إدارة العرض الترويجي'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── مفتاح التفعيل ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasActiveOffer
                      ? Colors.green.shade50
                      : theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _hasActiveOffer
                        ? Colors.green.shade200
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _hasActiveOffer
                          ? Icons.check_circle
                          : Icons.pause_circle_filled,
                      color: _hasActiveOffer ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفعيل العرض',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _hasActiveOffer
                                ? 'العرض نشط ويظهر للمستخدمين'
                                : 'العرض متوقف حالياً',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _hasActiveOffer
                                  ? Colors.green.shade800
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _hasActiveOffer,
                      activeColor: Colors.green,
                      onChanged: (val) {
                        setState(() => _hasActiveOffer = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── حقول الإدخال (تظهر فقط إذا كان العرض نشطاً) ───
              if (_hasActiveOffer) ...[
                Text('عنوان العرض',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'مثال: خصم 20% بمناسبة الافتتاح',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon:
                        const Icon(Icons.local_offer, color: Colors.deepOrange),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty
                      ? 'يرجى كتابة عنوان العرض'
                      : null,
                ),
                const SizedBox(height: 20),
                Text('تفاصيل العرض (اختياري)',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailsController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'اكتب شروط العرض أو تفاصيل إضافية...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description, color: Colors.deepOrange),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('تاريخ الانتهاء',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickExpiryDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _expiryDate == null
                            ? Colors.red.shade300
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month,
                            color: Colors.deepOrange.shade700),
                        const SizedBox(width: 12),
                        Text(
                          _expiryDate == null
                              ? 'اختر تاريخ انتهاء العرض'
                              : 'ينتهي في: ${_expiryDate!.year}/${_expiryDate!.month}/${_expiryDate!.day}',
                          style: TextStyle(
                            color: _expiryDate == null
                                ? Colors.red.shade700
                                : theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],

              // ─── زر الحفظ ───
              FilledButton.icon(
                onPressed: _isSaving ? null : _saveOffer,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ التغييرات'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
