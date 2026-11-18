// lib/features/admin/screens/admin_reports_screen.dart
// [v1.1 — 2026-11-12] — RADIO DEPRECATION FIX:
//   - Replaced deprecated `Radio` (groupValue/onChanged) with a simple Icon.
//   - The whole tile remains clickable via InkWell.onTap, so functionality
//     is preserved. No behavioral changes.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/moderation_service.dart';
import '../../../models/moderation_log_model.dart';
import '../../../models/rating_model.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final ModerationService _service = ModerationService();
  ReportStatus? _filterStatus = ReportStatus.pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة البلاغات'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterRow(theme),
        ),
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: _service.watchReports(status: _filterStatus),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'حدث خطأ: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              return _ReportCard(
                report: reports[index],
                onTap: () => _openReviewSheet(reports[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterRow(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: YaBaladiDesignTokens.primaryBlue,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(theme, 'قيد الانتظار', ReportStatus.pending),
            const SizedBox(width: 8),
            _filterChip(theme, 'تم الحل', ReportStatus.resolved),
            const SizedBox(width: 8),
            _filterChip(theme, 'تم التجاهل', ReportStatus.dismissed),
            const SizedBox(width: 8),
            _filterChip(theme, 'الكل', null),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(ThemeData theme, String label, ReportStatus? status) {
    final selected = _filterStatus == status;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: selected ? YaBaladiDesignTokens.primaryBlue : Colors.white,
          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          fontSize: 12,
        ),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _filterStatus = status),
      backgroundColor: Colors.white.withValues(alpha: 0.15),
      selectedColor: Colors.white,
      side: BorderSide(
        color: selected ? Colors.white : Colors.white.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _filterStatus == ReportStatus.pending
                  ? 'لا توجد بلاغات معلقة'
                  : 'لا توجد بلاغات في هذا التصنيف',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ستظهر هنا جميع البلاغات الواردة من المستخدمين.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openReviewSheet(ReportModel report) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ReportReviewSheet(report: report),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Report Card
// ═══════════════════════════════════════════════════════════════

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  Color _statusColor() {
    switch (report.status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.reviewed:
        return Colors.blue;
      case ReportStatus.dismissed:
        return Colors.grey;
      case ReportStatus.resolved:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _statusColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      report.status.labelAr,
                      style: TextStyle(
                        color: _statusColor(),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      report.reason.labelAr,
                      style: YaBaladiTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (report.createdAt != null)
                    Text(
                      _formatDate(report.createdAt!),
                      style: YaBaladiTypography.caption.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              if (report.reasonNote != null &&
                  report.reasonNote!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  report.reasonNote!,
                  style: YaBaladiTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 14, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      report.reporterName ?? 'مستخدم مجهول',
                      style: YaBaladiTypography.caption.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) {
      return 'منذ ${diff.inMinutes} د';
    }
    if (diff.inHours < 24) {
      return 'منذ ${diff.inHours} س';
    }
    return '${d.day}/${d.month}';
  }
}

// ═══════════════════════════════════════════════════════════════
// Review Sheet
// ═══════════════════════════════════════════════════════════════

class _ReportReviewSheet extends StatefulWidget {
  final ReportModel report;
  const _ReportReviewSheet({required this.report});

  @override
  State<_ReportReviewSheet> createState() => _ReportReviewSheetState();
}

class _ReportReviewSheetState extends State<_ReportReviewSheet> {
  final ModerationService _service = ModerationService();
  final TextEditingController _noteController = TextEditingController();
  ModerationAction _selectedAction = ModerationAction.dismissed;
  bool _saving = false;
  RatingModel? _rating;
  bool _loadingRating = true;
  String? _ratingLoadError;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadRating() async {
    setState(() {
      _loadingRating = true;
      _ratingLoadError = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('ratings')
          .doc(widget.report.ratingId)
          .get();
      if (!mounted) {
        return;
      }
      if (!doc.exists) {
        setState(() {
          _loadingRating = false;
          _ratingLoadError = 'التقييم لم يعد موجوداً (ربما حُذف نهائياً)';
        });
        return;
      }
      setState(() {
        _rating = RatingModel.fromFirestore(doc);
        _loadingRating = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loadingRating = false;
        _ratingLoadError = 'تعذر تحميل التقييم: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = widget.report.status == ReportStatus.pending;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Column(
          children: [
            _buildHeader(theme),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildReasonSection(theme),
                  const SizedBox(height: 16),
                  _buildRatingPreview(theme),
                  if (isPending) ...[
                    const SizedBox(height: 24),
                    _buildActionSelector(theme),
                    const SizedBox(height: 16),
                    _buildNoteField(theme),
                    const SizedBox(height: 24),
                    _buildSubmitButton(theme),
                  ] else ...[
                    const SizedBox(height: 16),
                    _buildResolutionInfo(theme),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مراجعة البلاغ',
                  style: YaBaladiTypography.headingLabel.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.report.reason.labelAr,
                  style: YaBaladiTypography.caption.copyWith(
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

  Widget _buildReasonSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag_outlined,
                  size: 16, color: theme.colorScheme.error),
              const SizedBox(width: 6),
              Text(
                'سبب البلاغ',
                style: YaBaladiTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.report.reason.descriptionAr,
            style: YaBaladiTypography.bodySmall.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (widget.report.reasonNote != null &&
              widget.report.reasonNote!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '"${widget.report.reasonNote}"',
                style: YaBaladiTypography.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRatingPreview(ThemeData theme) {
    if (_loadingRating) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_ratingLoadError != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _ratingLoadError!,
          style: YaBaladiTypography.bodySmall.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }
    final rating = _rating!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'التقييم المبلَّغ عنه',
                style: YaBaladiTypography.labelMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              _buildStars(rating.overall),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person_outline,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                rating.userDisplayName,
                style: YaBaladiTypography.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rating.status,
                  style: YaBaladiTypography.caption.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          if (rating.body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.body,
              style: YaBaladiTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          (i + 1) <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
          color: (i + 1) <= rating ? Colors.amber : Colors.grey.shade300,
          size: 14,
        );
      }),
    );
  }

  Widget _buildActionSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الإجراء',
          style: YaBaladiTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        ...ModerationAction.values.map((action) {
          final selected = _selectedAction == action;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedAction = action),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // ✅ استبدال Radio (deprecated) بأيقونة بسيطة
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            action.labelAr,
                            style: YaBaladiTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            action.descriptionAr,
                            style: YaBaladiTypography.caption.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoteField(ThemeData theme) {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      maxLength: 300,
      decoration: const InputDecoration(
        labelText: 'ملاحظة القرار (مطلوبة)',
        hintText: 'اشرح سبب اتخاذ هذا الإجراء...',
        border: OutlineInputBorder(),
        counterText: '',
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return FilledButton.icon(
      onPressed: _saving ? null : _submit,
      icon: _saving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.check),
      label: Text(_saving ? 'جارٍ التنفيذ...' : 'تنفيذ القرار'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
      ),
    );
  }

  Widget _buildResolutionInfo(ThemeData theme) {
    final action = widget.report.resolutionActionKey != null
        ? ModerationActionExt.fromKey(widget.report.resolutionActionKey!)
        : null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'القرار المُتخذ',
            style: YaBaladiTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            action?.labelAr ?? 'غير معروف',
            style: YaBaladiTypography.bodyMedium,
          ),
          if (widget.report.resolutionNote != null) ...[
            const SizedBox(height: 6),
            Text(
              '"${widget.report.resolutionNote}"',
              style: YaBaladiTypography.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب كتابة ملاحظة توضح سبب القرار'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = context.read<AuthController>();
    final adminId = auth.user?.uid ?? '';
    if (adminId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول كأدمن'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await _service.reviewReport(
        reportId: widget.report.id,
        adminId: adminId,
        adminName: auth.displayName,
        action: _selectedAction,
        resolutionNote: _noteController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم تنفيذ الإجراء: ${_selectedAction.labelAr}'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
