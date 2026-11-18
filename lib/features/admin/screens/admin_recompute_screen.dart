// lib/features/admin/screens/admin_recompute_screen.dart
// [v1.0 — 2026-11-12] — ADMIN RECOMPUTE SCREEN:
//   - One-tap "recompute all" with progress bar and final report.
//   - Safe: skips places without ratings.
//   - Admin-only (Firestore rules already enforce moderation_logs writes).

import 'package:flutter/material.dart';

import '../../../core/services/aggregate_recompute_service.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';

class AdminRecomputeScreen extends StatefulWidget {
  const AdminRecomputeScreen({super.key});

  @override
  State<AdminRecomputeScreen> createState() => _AdminRecomputeScreenState();
}

class _AdminRecomputeScreenState extends State<AdminRecomputeScreen> {
  final AggregateRecomputeService _service = AggregateRecomputeService();

  bool _running = false;
  int _processed = 0;
  int _total = 0;
  RecomputeResult? _result;
  String? _error;

  Future<void> _run() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد إعادة الحساب'),
        content: const Text(
          'سيتم إعادة حساب إحصاءات كل الأماكن من التقييمات الخام، '
          'مع تطبيق تقادم الحداثة وضبط الثقة.\n\n'
          'العملية قد تستغرق بضع دقائق. لا يمكن التراجع عنها، لكنها آمنة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(c, true),
            icon: const Icon(Icons.refresh),
            label: const Text('ابدأ'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    setState(() {
      _running = true;
      _processed = 0;
      _total = 0;
      _result = null;
      _error = null;
    });

    try {
      final result = await _service.recomputeAll(
        batchSize: 10,
        onProgress: (processed, total) {
          if (mounted) {
            setState(() {
              _processed = processed;
              _total = total;
            });
          }
        },
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _running = false;
        _result = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إعادة الحساب — ${result.processed} مكان محدّث'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _running = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعادة حساب الإحصائيات'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── شرح ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue.shade800, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'لماذا هذه الخطوة؟',
                          style: YaBaladiTypography.headingLabel.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'الأماكن التي قُيّمت قبل تفعيل نظام "الأوزان الذكية" لا تحتوي على '
                      'adjustedScore أو sampleQuality. هذه الأداة تُعيد حساب كل شيء '
                      'من التقييمات الخام، فتظهر شارة الثقة في البطاقات، '
                      'ويعمل الترتيب بـ"الأعلى جودة" بشكل صحيح.',
                      style: YaBaladiTypography.bodySmall.copyWith(
                        color: Colors.blue.shade900,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── الأزرار ───
              if (!_running && _result == null) ...[
                FilledButton.icon(
                  onPressed: _run,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('ابدأ إعادة الحساب'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: YaBaladiDesignTokens.primaryBlue,
                  ),
                ),
              ],

              // ─── حالة الجري ───
              if (_running) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _total > 0
                            ? 'جارٍ المعالجة: $_processed / $_total'
                            : 'جارٍ التحميل...',
                        style: YaBaladiTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (_total > 0) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _processed / _total,
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ─── نتيجة ───
              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green.shade700, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'اكتملت العملية بنجاح',
                            style: YaBaladiTypography.headingLabel.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _resultRow('تم تحديثها', '${_result!.processed} مكان'),
                      _resultRow('تم تخطيها (بلا تقييمات)',
                          '${_result!.skipped} مكان'),
                      if (_result!.failed > 0)
                        _resultRow('فشلت', '${_result!.failed} مكان',
                            color: Colors.red.shade900),
                      _resultRow(
                          'الزمن', '${_result!.elapsed.inSeconds} ثانية'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _result = null;
                      _processed = 0;
                      _total = 0;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('تشغيل مرة أخرى'),
                ),
              ],

              // ─── خطأ ───
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    'خطأ: $_error',
                    style: YaBaladiTypography.bodySmall.copyWith(
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ─── ملاحظة ───
              Text(
                'ملاحظة تقنية: العملية تحفظ النتائج دفعة بعد دفعة. '
                'إذا أغلقت الشاشة في المنتصف، ما تم حفظه يبقى محفوظاً. '
                'يمكنك إعادة التشغيل من البداية بأمان.',
                style: YaBaladiTypography.caption.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: YaBaladiTypography.bodySmall.copyWith(
                color: Colors.green.shade800,
              ),
            ),
          ),
          Text(
            value,
            style: YaBaladiTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
