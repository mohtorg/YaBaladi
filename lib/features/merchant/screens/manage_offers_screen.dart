// lib/features/merchant/screens/manage_offers_screen.dart
// [v2.1 — FIXED] — CONTEXT SAFETY & INK SPLASH FIXES:
//   - FIXED: Captured Navigator & ScaffoldMessenger before async gaps.
//   - FIXED: Wrapped date picker InkWell in Material to show ink splashes.
//   - KEPT: All offer logic, notifications, and UI design intact.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/helpers/notification_helper.dart';
import '../../../models/place.dart';
import '../../notifications/models/notification_model.dart';

class ManageOffersScreen extends StatefulWidget {
  final Place place;

  const ManageOffersScreen({super.key, required this.place});

  @override
  State<ManageOffersScreen> createState() => _ManageOffersScreenState();
}

class _ManageOffersScreenState extends State<ManageOffersScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _detailsCtrl;

  late bool _hasActiveOffer;
  DateTime? _expiryDate;
  bool _sendNotification = true;
  bool _isSaving = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();

    // ✅ نحمّل البيانات فقط إذا كان العرض نشطاً (لتجنب عرض بيانات قديمة)
    final bool wasActive = widget.place.hasActiveOffer;
    _hasActiveOffer = wasActive;

    _titleCtrl = TextEditingController(
      text: wasActive ? (widget.place.offerTitle ?? '') : '',
    );
    _detailsCtrl = TextEditingController(
      text: wasActive ? (widget.place.offerDetails ?? '') : '',
    );

    // ✅ لا نحمّل التاريخ إلا إذا كان العرض نشطاً وتاريخه في المستقبل
    if (wasActive) {
      final expiry = widget.place.offerExpiryDate;
      _expiryDate =
          (expiry != null && expiry.isAfter(DateTime.now())) ? expiry : null;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────
  // طلب تفعيل الميزة من الأدمن
  // ─────────────────────────────────────────────────────────
  Future<void> _requestPermission() async {
    if (widget.place.id.isEmpty) {
      _showError('معرّف المكان غير صالح');
      return;
    }

    // ✅ تأمين السياق
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isRequesting = true);
    try {
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update({'offerRequestPending': true});

      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ تم إرسال طلب التفعيل للإدارة'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('❌ فشل الطلب: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // اختيار تاريخ الانتهاء
  // ─────────────────────────────────────────────────────────
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

    if (picked != null) {
      // ✅ 23:59:59 ليبقى العرض صالحاً طوال اليوم المختار
      setState(() => _expiryDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            23,
            59,
            59,
          ));
    }
  }

  // ─────────────────────────────────────────────────────────
  // بناء بيانات Firestore (مفصولة للوضوح والاختبار)
  // ─────────────────────────────────────────────────────────
  Map<String, dynamic> _buildOfferData() {
    final data = <String, dynamic>{
      'hasActiveOffer': _hasActiveOffer,
    };

    if (_hasActiveOffer) {
      // ✅ حالة التفعيل: نحفظ القيم الفعلية
      data['offerTitle'] = _titleCtrl.text.trim();
      data['offerDetails'] = _detailsCtrl.text.trim();
      data['offerExpiryDate'] = Timestamp.fromDate(_expiryDate!);

      // ✅ نضيف/نجدد offerCreatedAt في كل مرة يتم فيها التفعيل
      data['offerCreatedAt'] = FieldValue.serverTimestamp();
    } else {
      // ✅ حالة الإيقاف: حذف فعلي (وليس null) للحقول
      data['offerTitle'] = FieldValue.delete();
      data['offerDetails'] = FieldValue.delete();
      data['offerExpiryDate'] = FieldValue.delete();
      data['offerCreatedAt'] = FieldValue.delete();
    }

    return data;
  }

  // ─────────────────────────────────────────────────────────
  // الحفظ
  // ─────────────────────────────────────────────────────────
  Future<void> _saveOffer() async {
    if (!_formKey.currentState!.validate()) return;

    // تحقق: التفعيل يتطلب تاريخ انتهاء
    if (_hasActiveOffer && _expiryDate == null) {
      _showError('يرجى تحديد تاريخ انتهاء العرض');
      return;
    }

    // تحقق: المكان موجود
    if (widget.place.id.isEmpty) {
      _showError('معرّف المكان غير صالح');
      return;
    }

    // ✅ تأمين السياق
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _isSaving = true);

    try {
      // ✅ بناء البيانات وحفظها
      final data = _buildOfferData();
      await FirebaseFirestore.instance
          .collection('places')
          .doc(widget.place.id)
          .update(data);

      // ✅ إرسال الإشعار فقط عند التفعيل (وإذا اختار التاجر ذلك)
      if (_sendNotification && _hasActiveOffer) {
        await _triggerNotifications();
      }

      if (!mounted) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_hasActiveOffer
              ? '✅ تم حفظ العرض وإرسال الإشعار بنجاح'
              : '✅ تم إيقاف العرض وحذف بياناته'),
          backgroundColor: Colors.green,
        ),
      );

      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('❌ فشل الحفظ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // إرسال الإشعارات
  // ─────────────────────────────────────────────────────────
  Future<void> _triggerNotifications() async {
    try {
      final title = '🔥 عرض جديد من ${widget.place.nameAr}!';
      final body = _titleCtrl.text.trim();

      await NotificationHelper.send(
        userId: 'all',
        title: title,
        body: body,
        type: NotificationType.newOffer,
        route: '/home/place/${widget.place.id}',
        data: {'placeId': widget.place.id},
      );
    } catch (e) {
      debugPrint('❌ Error in _triggerNotifications: $e');
      // لا نُفشل العملية الأساسية بسبب خطأ الإشعار
    }
  }

  // ─────────────────────────────────────────────────────────
  // أدوات مساعدة
  // ─────────────────────────────────────────────────────────
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─────────────────────────────────────────────────────────
  // واجهة المستخدم
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ─── شاشة القفل (الميزة غير مفعلة من الأدمن) ───
    if (!widget.place.isOfferFeatureEnabled) {
      return _buildLockedScreen(theme);
    }

    // ─── واجهة إدارة العرض ───
    return _buildEditScreen(theme);
  }

  // شاشة القفل
  Widget _buildLockedScreen(ThemeData theme) {
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'طلبك قيد المراجعة من قبل الإدارة.',
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: _isRequesting ? null : _requestPermission,
                  icon: _isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: const Text('طلب تفعيل ميزة العروض'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 50),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // واجهة التعديل
  Widget _buildEditScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'إدارة العروض',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // بطاقة إرشادية
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
              title: const Text(
                'تفعيل العرض الترويجي',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle:
                  const Text('سيظهر العرض في صفحة مكانك وفي قائمة العروض.'),
              value: _hasActiveOffer,
              activeThumbColor: theme.colorScheme.primary,
              onChanged: (val) => setState(() => _hasActiveOffer = val),
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(),
            const SizedBox(height: 16),

            // الحقول (تظهر فقط عند التفعيل)
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

              // اختيار التاريخ (تم تغليفه بـ Material لحل مشكلة الـ Ink Splash)
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _pickExpiryDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.blueGrey),
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
              ),
              const SizedBox(height: 16),

              // إرسال الإشعارات
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
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
