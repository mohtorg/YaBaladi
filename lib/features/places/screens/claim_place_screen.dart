// lib/features/places/screens/claim_place_screen.dart
// [v1.1 — 2026-11-12] — FIXES:
//   - Removed RegExp (deprecated) → split('\n').
//   - imageUrls is now passed to submitClaim (was unused).
//   - evidenceType / evidenceReference are now stored server-side.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/owner_claim_service.dart';
import '../../../models/owner_claim_request_model.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';

class ClaimPlaceScreen extends StatefulWidget {
  final String placeId;
  final String placeName;

  const ClaimPlaceScreen({
    super.key,
    required this.placeId,
    required this.placeName,
  });

  @override
  State<ClaimPlaceScreen> createState() => _ClaimPlaceScreenState();
}

class _ClaimPlaceScreenState extends State<ClaimPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _imageUrlsCtrl = TextEditingController();
  final OwnerClaimService _service = OwnerClaimService();

  EvidenceType _evidenceType = EvidenceType.commercialRegistration;
  bool _confirmTerms = false;
  bool _saving = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _refCtrl.dispose();
    _noteCtrl.dispose();
    _imageUrlsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (!_confirmTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب الموافقة على الإقرار قبل الإرسال'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final auth = context.read<AuthController>();
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول أولاً'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      // ✅ لا RegExp — نقسم على newline فقط
      final imageUrls = _imageUrlsCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      await _service.submitClaim(
        placeId: widget.placeId,
        placeName: widget.placeName,
        userId: user.uid,
        userDisplayName: auth.displayName,
        userEmail: user.email ?? '',
        businessPhone: _phoneCtrl.text.trim(),
        evidenceType: _evidenceType,
        evidenceReference:
            _refCtrl.text.trim().isEmpty ? null : _refCtrl.text.trim(),
        evidenceImageUrls: imageUrls,
        notes: _noteCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'تم إرسال طلبك بنجاح — سيتم مراجعته من فريق الإدارة وسنبلغك بالنتيجة.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('طلب استلام المكان'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── مكان ───
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storefront_outlined,
                          color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('المكان المطلوب استلامه',
                                style: YaBaladiTypography.caption.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            Text(
                              widget.placeName,
                              style: YaBaladiTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ─── بيانات التواصل ───
                Text('بيانات التواصل',
                    style: YaBaladiTypography.headingLabel.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف (للتواصل) *',
                    hintText: '01012345678',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'مطلوب';
                    }
                    if (v.trim().length < 8) {
                      return 'رقم غير صحيح';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ─── نوع الدليل ───
                Text('نوع الدليل',
                    style: YaBaladiTypography.headingLabel.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                DropdownButtonFormField<EvidenceType>(
                  initialValue: _evidenceType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: EvidenceType.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.labelAr),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _evidenceType = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _refCtrl,
                  decoration: const InputDecoration(
                    labelText: 'رقم المرجع (اختياري)',
                    hintText: 'مثال: رقم السجل التجاري',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),

                // ─── تفاصيل الطلب ───
                Text('تفاصيل الطلب',
                    style: YaBaladiTypography.headingLabel.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'اشرح سبب استحقاقك للمكان *',
                    hintText:
                        'مثال: أنا مالك المكان منذ 2018، وهذا السجل التجاري...',
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 20) {
                      return 'يجب كتابة 20 حرفاً على الأقل';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _imageUrlsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'روابط صور الأدلة (اختياري)',
                    hintText: 'رابط لكل سطر — صور للمكان أو السجل',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'ملاحظة: يتم مراجعة الطلب من فريق الإدارة. قد يستغرق حتى 48 ساعة.',
                  style: YaBaladiTypography.caption
                      .copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),

                const SizedBox(height: 20),

                // ─── إقرار ───
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.amber.shade800, size: 18),
                          const SizedBox(width: 6),
                          Text('إقرار',
                              style: YaBaladiTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      CheckboxListTile(
                        value: _confirmTerms,
                        onChanged: (v) =>
                            setState(() => _confirmTerms = v ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(
                          'أُقر بأنني المالك الشرعي لهذا المكان، وأتحمل المسؤولية القانونية الكاملة عن صحة البيانات المقدمة. جميع التقييمات السابقة تبقى محفوظة ولا يمكنني تعديلها أو حذفها.',
                          style: YaBaladiTypography.bodySmall
                              .copyWith(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label:
                      Text(_saving ? 'جارٍ الإرسال...' : 'إرسال طلب الاستلام'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: YaBaladiDesignTokens.primaryBlue,
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
