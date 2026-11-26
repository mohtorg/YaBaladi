// lib/features/rating/screens/rate_place_screen.dart
// [v6.1 — 2026-11-15] — UNUSED FIELD FIX + UX:
//   - Removed `_isUpdate` field (derived getter instead: `_existingReview != null`).
//   - Banner now shows the current rating value + last edit date (uses
//     `_existingReview.overall` and `_existingReview.updatedAt`).
//   - Uses a local alias in build() for field promotion.
//   - Phase 16 UX (banner + prefilled stars) preserved.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/rating_controller.dart';
import '../../../models/rating_model.dart';
import '../../../models/review_criterion_model.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';

class RatePlaceScreen extends StatefulWidget {
  final String placeId;
  final String placeName;
  final double placeLat;
  final double placeLng;
  final String categoryId;
  final String? pinObfuscated;
  final String? zoneId;

  const RatePlaceScreen({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.placeLat,
    required this.placeLng,
    required this.categoryId,
    this.pinObfuscated,
    this.zoneId,
  });

  @override
  State<RatePlaceScreen> createState() => _RatePlaceScreenState();
}

class _RatePlaceScreenState extends State<RatePlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bodyController = TextEditingController();
  final _pinController = TextEditingController();
  final _qrController = TextEditingController();
  final _bodyFocus = FocusNode();

  int _overall = 0;
  Map<String, int> _scores = {};

  List<ReviewCriterionModel> _criteria = [];
  bool _isLoadingCriteria = true;

  /// التقييم السابق إن وُجد (يُعرض في البانر + يُستخدم لملء الحقول).
  RatingModel? _existingReview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      context.read<RatingController>().reset();
      await _loadCriteria();
      await _loadExistingReview();
    });
  }

  Future<void> _loadCriteria() async {
    try {
      final generalSnap = await FirebaseFirestore.instance
          .collection('review_criteria')
          .where('isGeneral', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      final specificSnap = await FirebaseFirestore.instance
          .collection('review_criteria')
          .where('categoryId', isEqualTo: widget.categoryId)
          .where('isGeneral', isEqualTo: false)
          .where('isActive', isEqualTo: true)
          .get();

      final allDocs = [...generalSnap.docs, ...specificSnap.docs];
      final list =
          allDocs.map((d) => ReviewCriterionModel.fromFirestore(d)).toList();

      list.sort((a, b) {
        if (a.isGeneral != b.isGeneral) return a.isGeneral ? -1 : 1;
        return a.order.compareTo(b.order);
      });

      if (!mounted) return;
      setState(() {
        _criteria = list;
        for (var c in list) {
          _scores[c.fieldKey] = 0;
        }
        _isLoadingCriteria = false;
      });
    } catch (e) {
      debugPrint('Error loading criteria: $e');
      if (mounted) setState(() => _isLoadingCriteria = false);
    }
  }

  /// Phase 16: هل يوجد تقييم سابق منشور من هذا المستخدم؟
  Future<void> _loadExistingReview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('ratings')
          .where('placeId', isEqualTo: widget.placeId)
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'PUBLISHED')
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;

      final rating = RatingModel.fromFirestore(snap.docs.first);
      if (!mounted) return;

      setState(() {
        _existingReview = rating;
        _overall = rating.overall;
        for (final c in _criteria) {
          _scores[c.fieldKey] = rating.dimensions[c.fieldKey] ?? 0;
        }
        _bodyController.text = rating.body;
      });
    } catch (e) {
      debugPrint('Error loading existing review: $e');
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _pinController.dispose();
    _qrController.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  Future<void> _submit({bool skipDialog = false}) async {
    if (_overall == 0) {
      _showSnack('اختر التقييم العام أولًا', isError: true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    for (var c in _criteria) {
      if (c.isRequired && (_scores[c.fieldKey] ?? 0) == 0) {
        _showSnack('يرجى تقييم: ${c.nameAr} في التفاصيل', isError: true);
        return;
      }
    }

    final metadata = <String, dynamic>{};
    for (var c in _criteria) {
      metadata[c.fieldKey] = {
        'nameAr': c.nameAr,
        'descriptionAr': c.descriptionAr ?? '',
      };
    }

    final controller = context.read<RatingController>();
    final success = await controller.submit(
      placeId: widget.placeId,
      categoryId: widget.categoryId,
      placeLat: widget.placeLat,
      placeLng: widget.placeLng,
      zoneId: widget.zoneId,
      pinObfuscated: widget.pinObfuscated ?? '',
      overall: _overall,
      dimensions: _scores,
      dimensionsMetadata: metadata,
      body: _bodyController.text.trim(),
      userProvidedPin: _pinController.text.trim().isEmpty
          ? null
          : _pinController.text.trim(),
      userProvidedQr: _qrController.text.trim().isEmpty
          ? null
          : _qrController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      final result = controller.result;
      final message = _successMessageFor(
        result?.verificationMethod,
        isUpdate: result?.isUpdate ?? false,
      );
      _showSnack(message, isError: false);
      Navigator.pop(context, true);
      return;
    }

    final error = controller.error ?? 'فشل التحقق';
    if (!skipDialog && error.contains('خارج حدود المنطقة')) {
      await _showOutOfZoneDialog(error);
      return;
    }
    _showSnack(error, isError: true);
  }

  String _successMessageFor(String? method, {bool isUpdate = false}) {
    final prefix = isUpdate ? 'تم تحديث تقييمك' : 'تم نشر تقييمك';
    switch (method) {
      case 'QR':
        return '$prefix — موثّق بمسح رمز QR المكان ✅';
      case 'POLYGON_PIN':
      case 'POLYGON':
        return '$prefix — موثّق داخل حدود المنطقة';
      case 'GPS_PIN':
      case 'GPS':
        return '$prefix — موثّق بالموقع';
      case 'PIN':
        return '$prefix — موثّق برمز المكان';
      default:
        return '$prefix — شكرًا لك';
    }
  }

  Future<void> _showOutOfZoneDialog(String error) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خارج حدود المنطقة'),
        content: Text(
          '$error\n\n'
          'إذا كنت متأكدًا من وجودك في المكان، اضغط "تحديث موقعي" لإعادة القراءة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تحديث موقعي'),
          ),
        ],
      ),
    );
    if (retry == true && mounted) {
      await _submit(skipDialog: true);
    }
  }

  Future<void> _openDetailsSheet() async {
    if (_criteria.isEmpty) return;

    final pin = widget.pinObfuscated;
    final hasPin = pin != null && pin.isNotEmpty;

    final result = await showModalBottomSheet<_DetailsResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DetailsSheet(
        criteria: _criteria,
        initialScores: _scores,
        initialPin: _pinController.text,
        initialQr: _qrController.text,
        hasPin: hasPin,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _scores = result.scores;
        _pinController.text = result.pin;
        _qrController.text = result.qrPayload;
      });
    }
  }

  void _showSnack(String message, {required bool isError}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: YaBaladiTypography.bodyMedium.copyWith(
            color: colorScheme.onInverseSurface,
          ),
        ),
        backgroundColor:
            isError ? colorScheme.error : colorScheme.inverseSurface,
      ),
    );
  }

  String _formatDate(DateTime d) {
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y/$m/$day';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RatingController>();
    final isSubmitting = controller.isSubmitting;
    final colorScheme = Theme.of(context).colorScheme;

    // ✅ alias محلي — لأن الحقول غير final في State لا تُرقَّى (promote).
    final existingReview = _existingReview;
    final isUpdate = existingReview != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isUpdate ? 'تحديث التقييم' : 'قيّم المكان'),
      ),
      body: _isLoadingCriteria
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: YaBaladiDesignTokens.space4,
                vertical: YaBaladiDesignTokens.space5,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ✅ بانر التحديث — يعرض أيضاً التقييم الحالي + آخر تعديل
                    if (existingReview != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.teal.shade300),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.edit_note,
                                color: Colors.teal.shade800, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'لديك تقييم سابق لهذا المكان. أي تعديل ستحفظه الآن '
                                    'سيحل محل تقييمك القديم (مع الاحتفاظ بأرشيف داخلي).',
                                    style: YaBaladiTypography.caption.copyWith(
                                      color: Colors.teal.shade900,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.star_rounded,
                                          color: Colors.teal.shade700,
                                          size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${existingReview.overall}/5',
                                        style:
                                            YaBaladiTypography.caption.copyWith(
                                          color: Colors.teal.shade800,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.schedule,
                                          color: Colors.teal.shade700,
                                          size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        'آخر تعديل: ${_formatDate(existingReview.updatedAt)}',
                                        style:
                                            YaBaladiTypography.caption.copyWith(
                                          color: Colors.teal.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: YaBaladiDesignTokens.space4),
                    ],

                    Center(
                      child: Text(
                        widget.placeName,
                        style: YaBaladiTypography.headingSection.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space2),
                    Center(
                      child: Text(
                        'كيف كانت تجربتك؟',
                        style: YaBaladiTypography.bodyMedium.copyWith(
                          color: YaBaladiDesignTokens.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: YaBaladiDesignTokens.space6),
                    _StarRow(
                      value: _overall,
                      onChanged: isSubmitting
                          ? null
                          : (v) {
                              setState(() => _overall = v);
                              if (v > 0) {
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  if (mounted && _bodyFocus.canRequestFocus) {
                                    _bodyFocus.requestFocus();
                                  }
                                });
                              }
                            },
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: _overall == 0
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(
                                    height: YaBaladiDesignTokens.space6),
                                TextFormField(
                                  controller: _bodyController,
                                  focusNode: _bodyFocus,
                                  enabled: !isSubmitting,
                                  maxLines: 4,
                                  maxLength: 1000,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    hintText: 'شاركنا تجربتك (اختياري)...',
                                    counterText: '',
                                  ),
                                ),
                                if (_criteria.isNotEmpty) ...[
                                  const SizedBox(
                                      height: YaBaladiDesignTokens.space2),
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: TextButton.icon(
                                      onPressed: isSubmitting
                                          ? null
                                          : _openDetailsSheet,
                                      icon: const Icon(Icons.tune_rounded,
                                          size: 18),
                                      label: const Text('إضافة تفاصيل التقييم'),
                                    ),
                                  ),
                                ],
                                const SizedBox(
                                    height: YaBaladiDesignTokens.space4),
                                FilledButton(
                                  onPressed:
                                      isSubmitting ? null : () => _submit(),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(isUpdate
                                          ? 'تحديث التقييم'
                                          : 'نشر التقييم'),
                                ),
                                const SizedBox(
                                    height: YaBaladiDesignTokens.space3),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.lock_outline_rounded,
                                        size: 14,
                                        color:
                                            YaBaladiDesignTokens.textTertiary),
                                    const SizedBox(
                                        width: YaBaladiDesignTokens.space1),
                                    Text(
                                      'يتم التحقق من موقعك تلقائيًا',
                                      style: YaBaladiTypography.caption
                                          .copyWith(
                                              color: YaBaladiDesignTokens
                                                  .textTertiary),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Star row
// ═══════════════════════════════════════════════════════════════

class _StarRow extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;

  const _StarRow({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final star = i + 1;
        final filled = star <= value;
        return Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: YaBaladiDesignTokens.space1),
          child: InkResponse(
            onTap: onChanged == null ? null : () => onChanged!(star),
            radius: 32,
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: filled
                  ? YaBaladiDesignTokens.gold
                  : YaBaladiDesignTokens.grey400,
              size: 48,
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Details sheet (unchanged)
// ═══════════════════════════════════════════════════════════════

class _DetailsResult {
  final Map<String, int> scores;
  final String pin;
  final String qrPayload;

  const _DetailsResult({
    required this.scores,
    required this.pin,
    required this.qrPayload,
  });
}

class _DetailsSheet extends StatefulWidget {
  final List<ReviewCriterionModel> criteria;
  final Map<String, int> initialScores;
  final String initialPin;
  final String initialQr;
  final bool hasPin;

  const _DetailsSheet({
    required this.criteria,
    required this.initialScores,
    required this.initialPin,
    required this.initialQr,
    required this.hasPin,
  });

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  late Map<String, int> _scores;
  late final TextEditingController _pinController;
  late final TextEditingController _qrController;

  @override
  void initState() {
    super.initState();
    _scores = Map.from(widget.initialScores);
    _pinController = TextEditingController(text: widget.initialPin);
    _qrController = TextEditingController(text: widget.initialQr);
  }

  @override
  void dispose() {
    _pinController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: YaBaladiDesignTokens.space4,
        right: YaBaladiDesignTokens.space4,
        top: YaBaladiDesignTokens.space2,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            YaBaladiDesignTokens.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تفاصيل إضافية',
              style: YaBaladiTypography.headingSection
                  .copyWith(color: colorScheme.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: YaBaladiDesignTokens.space1),
            Text(
              'تساعد الآخرين على فهم تجربتك بشكل أعمق',
              style: YaBaladiTypography.bodySmall
                  .copyWith(color: YaBaladiDesignTokens.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: YaBaladiDesignTokens.space5),
            ...widget.criteria.map((c) {
              final val = _scores[c.fieldKey] ?? 0;
              return _dimRow(
                c.nameAr,
                c.descriptionAr,
                c.isRequired,
                val,
                (v) => setState(() => _scores[c.fieldKey] = v ?? 0),
              );
            }),
            const SizedBox(height: YaBaladiDesignTokens.space5),
            Text(
              'رمز QR للزيارة (توثيق الزيارة)',
              style: YaBaladiTypography.headingLabel
                  .copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space1),
            Text(
              'امسح أو الصق رمز QR الموجود في المكان لتأكيد زيارتك',
              style: YaBaladiTypography.caption
                  .copyWith(color: YaBaladiDesignTokens.textSecondary),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space2),
            TextFormField(
              controller: _qrController,
              textAlign: TextAlign.center,
              style: YaBaladiTypography.bodyMedium,
              decoration: const InputDecoration(
                hintText: 'YB-QR:v1:...',
                prefixIcon: Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
            if (widget.hasPin) ...[
              const SizedBox(height: YaBaladiDesignTokens.space5),
              Text(
                'رمز المكان',
                style: YaBaladiTypography.headingLabel
                    .copyWith(color: colorScheme.onSurface),
              ),
              const SizedBox(height: YaBaladiDesignTokens.space1),
              Text(
                'مكتوب عند الكاشير — يعطي تقييمك توثيقًا أقوى',
                style: YaBaladiTypography.caption
                    .copyWith(color: YaBaladiDesignTokens.textSecondary),
              ),
              const SizedBox(height: YaBaladiDesignTokens.space2),
              TextFormField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: YaBaladiTypography.headingSubsection,
                decoration: const InputDecoration(
                  hintText: '0000',
                  counterText: '',
                ),
              ),
            ],
            const SizedBox(height: YaBaladiDesignTokens.space5),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _DetailsResult(
                    scores: _scores,
                    pin: _pinController.text,
                    qrPayload: _qrController.text.trim(),
                  ),
                );
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dimRow(String label, String? description, bool isRequired, int value,
      ValueChanged<int?> onChanged) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: YaBaladiDesignTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$label ${isRequired ? "*" : ""}',
                  style: YaBaladiTypography.bodyMedium,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  final filled = value >= star;
                  return InkResponse(
                    onTap: () {
                      if (value == star) {
                        onChanged(null);
                      } else {
                        onChanged(star);
                      }
                    },
                    radius: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: filled
                            ? YaBaladiDesignTokens.gold
                            : YaBaladiDesignTokens.grey400,
                        size: 28,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              description,
              style: YaBaladiTypography.caption.copyWith(
                color: YaBaladiDesignTokens.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
