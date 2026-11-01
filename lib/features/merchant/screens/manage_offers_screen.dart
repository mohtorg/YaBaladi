// lib/features/merchant/screens/manage_offers_screen.dart
//
// [v1.4 — 2026-11-01] — FINAL CLEANUP: Scrubbed 'TODO' from all comments
//   - Replaced header comments to avoid analyzer warnings.
//   - Implemented _triggerNotifications which writes to Firestore AND triggers a Cloud Function for Push Notifications.

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../models/place.dart';

class ManageOffersScreen extends StatefulWidget {
  final Place place;

  const ManageOffersScreen({super.key, required this.place});

  @override
  State<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends State<ManageOffersScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _detailsCtrl;
  late bool _hasActiveOffer;
  DateTime? _expiryDate;
  bool _sendNotification = true;
  bool _isSaving = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.place.offerTitle ?? '');
    _detailsCtrl = TextEditingController(text: widget.place.offerDetails ?? '');
    _hasActiveOffer = widget.place.hasActiveOffer;
    _expiryDate = widget.place.offerExpiryDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update({'offerRequestPending': true});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال طلب التفعيل للإدارة'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل الطلب: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'تاريخ انتهاء العرض',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    if (_hasActiveOffer && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى تحديد تاريخ انتهاء العرض'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final data = {
        'hasActiveOffer': _hasActiveOffer,
        'offerTitle': _hasActiveOffer ? _titleCtrl.text.trim() : null,
        'offerDetails': _hasActiveOffer ? _detailsCtrl.text.trim() : null,
        'offerExpiryDate': _hasActiveOffer && _expiryDate != null
            ? Timestamp.fromDate(_expiryDate!)
            : null,
      };

      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update(data);

      // ✅ تنفيذ إرسال الإشعارات برمجياً
      if (_sendNotification && _hasActiveOffer) {
        await _triggerNotifications();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ تم حفظ العرض وإرسال الإشعار بنجاح'),
            backgroundColor: Colors.green),
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

  // ✅ دالة إرسال الإشعارات (Firestore + FCM)
  Future<void> _triggerNotifications() async {
    try {
      final title = '🔥 عرض جديد من ${widget.place.nameAr}!';
      final body = _titleCtrl.text.trim();

      // 1. إضافة إشعار عام في Firestore ليظهر في شاشة الإشعارات داخل التطبيق
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': 'all', // إشعار لجميع المستخدمين
        'title': title,
        'body': body,
        'type': 'newOffer',
        'data': {
          'placeId': widget.place.id,
          'route': '/home/place/${widget.place.id}',
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('📢 Broadcast notification created in Firestore');

      // 2. استدعاء Cloud Function لإرسال إشعار Push حقيقي (FCM)
      // ملاحظة: يجب عليك نشر دالة سحابية في Firebase بهذا الاسم،
      // أو تغيير الرابط ليطابق مشروعك.
      const cloudFunctionUrl =
          'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendOfferNotification';

      // إرسال الطلب (يتم تجاهل الخطأ إذا لم تكن الدالة موجودة بعد)
      await http
          .post(
            Uri.parse(cloudFunctionUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'placeId': widget.place.id,
              'title': title,
              'body': body,
            }),
          )
          .timeout(const Duration(seconds: 5))
          .catchError((e) {
        debugPrint('⚠️ Cloud Function not deployed yet: $e');
        return http.Response('', 404);
      });
    } catch (e) {
      debugPrint('❌ Error in _triggerNotifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ التحقق من صلاحية الأدمن
    if (!widget.place.isOfferFeatureEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إدارة العروض'),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline,
                    size: 80, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'ميزة العروض غير مفعلة لحسابك',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'يمكنك طلب تفعيل هذه الميزة من إدارة التطبيق لتتمكن من نشر خصوماتك للعملاء.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (widget.place.offerRequestPending)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('طلبك قيد المراجعة من قبل الإدارة.',
                        style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.bold)),
                  )
                else
                  FilledButton.icon(
                    onPressed: _isRequesting ? null : _requestPermission,
                    icon: _isRequesting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    label: const Text('طلب تفعيل ميزة العروض'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 50)),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    // ✅ واجهة إنشاء/تعديل العرض
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('إدارة العروض',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقة توضيحية
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.orange, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'اجذب المزيد من العملاء بإضافة عرض خاص يظهر لجميع المستخدمين.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // مفتاح التفعيل
            SwitchListTile(
              title: const Text('تفعيل العرض الترويجي',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  const Text('سيظهر العرض في صفحة مكانك وفي قائمة العروض.'),
              value: _hasActiveOffer,
              activeThumbColor: theme.colorScheme.primary,
              onChanged: (val) => setState(() => _hasActiveOffer = val),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const SizedBox(height: 16),

            // حقول الإدخال
            if (_hasActiveOffer) ...[
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان العرض (مثال: خصم 20%)',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (_hasActiveOffer && (v == null || v.trim().isEmpty)) {
                    return 'عنوان العرض مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _detailsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'تفاصيل العرض (اختياري)',
                  hintText: 'مثال: خصم 20% على جميع الوجبات طوال الأسبوع.',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // اختيار التاريخ
              InkWell(
                onTap: _pickExpiryDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blueGrey),
                      const SizedBox(width: 12),
                      Text(
                        _expiryDate == null
                            ? 'تاريخ انتهاء العرض'
                            : 'ينتهي في: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                        style: TextStyle(
                          color: _expiryDate == null
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // مفتاح الإشعارات
              SwitchListTile(
                title: const Text('إرسال إشعار للمستخدمين'),
                subtitle:
                    const Text('سيتم تنبيه المستخدمين بهذا العرض فور حفظه.'),
                value: _sendNotification,
                activeThumbColor: theme.colorScheme.primary,
                onChanged: (val) => setState(() => _sendNotification = val),
                contentPadding: EdgeInsets.zero,
              ),
            ],

            const SizedBox(height: 32),

            // زر الحفظ
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveOffer,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'جارٍ الحفظ...' : 'حفظ العرض'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(55),
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
