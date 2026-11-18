// lib/features/admin/screens/owner_claim_requests_screen.dart
// [v1.0 — 2026-11-12] — OWNER CLAIM REQUESTS SCREEN.
//   - Lists pending claims.
//   - Approve → sets place.ownerId, upgrades user to merchant.
//   - Reject → requires a note.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/owner_claim_service.dart';
import '../../../models/owner_claim_request_model.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';

class OwnerClaimRequestsScreen extends StatefulWidget {
  const OwnerClaimRequestsScreen({super.key});

  @override
  State<OwnerClaimRequestsScreen> createState() =>
      _OwnerClaimRequestsScreenState();
}

class _OwnerClaimRequestsScreenState extends State<OwnerClaimRequestsScreen> {
  final OwnerClaimService _service = OwnerClaimService();
  ClaimStatus? _filterStatus = ClaimStatus.pending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات استلام المكان'),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFilterRow(theme),
        ),
      ),
      body: StreamBuilder<List<OwnerClaimRequestModel>>(
        stream: _service.watchClaims(status: _filterStatus),
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
          final claims = snapshot.data ?? [];

          if (claims.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: claims.length,
            itemBuilder: (context, index) {
              return _ClaimCard(
                claim: claims[index],
                onApprove: () => _approve(claims[index]),
                onReject: () => _reject(claims[index]),
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
            _filterChip(theme, 'قيد الانتظار', ClaimStatus.pending),
            const SizedBox(width: 8),
            _filterChip(theme, 'تمت الموافقة', ClaimStatus.approved),
            const SizedBox(width: 8),
            _filterChip(theme, 'مرفوض', ClaimStatus.rejected),
            const SizedBox(width: 8),
            _filterChip(theme, 'الكل', null),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(ThemeData theme, String label, ClaimStatus? status) {
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
              _filterStatus == ClaimStatus.pending
                  ? 'لا توجد طلبات استلام معلقة'
                  : 'لا توجد طلبات في هذا التصنيف',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(OwnerClaimRequestModel claim) async {
    final auth = context.read<AuthController>();
    final adminId = auth.user?.uid ?? '';
    if (adminId.isEmpty) {
      _showSnack('يجب تسجيل الدخول كأدمن', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد الموافقة'),
        content: Text(
          'هل أنت متأكد من الموافقة على طلب "${claim.userDisplayName}" '
          'لاستلام إدارة "${claim.placeName}"؟\n\n'
          'سيتم تعيينه كمالك المكان وترقية دوره إلى تاجر.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(c, true),
            icon: const Icon(Icons.check),
            label: const Text('موافقة'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.approveClaim(
        claimId: claim.id,
        adminId: adminId,
        adminName: auth.displayName,
      );
      if (mounted) {
        _showSnack('تمت الموافقة على الطلب بنجاح', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('فشل: $e', isError: true);
    }
  }

  Future<void> _reject(OwnerClaimRequestModel claim) async {
    final auth = context.read<AuthController>();
    final adminId = auth.user?.uid ?? '';
    if (adminId.isEmpty) {
      _showSnack('يجب تسجيل الدخول كأدمن', isError: true);
      return;
    }

    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('رفض الطلب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'سبب رفض طلب "${claim.userDisplayName}"؟',
              style: YaBaladiTypography.bodyMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'اشرح سبب الرفض...',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('إلغاء'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يجب كتابة سبب الرفض'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(c, true);
            },
            icon: const Icon(Icons.close),
            label: const Text('رفض'),
          ),
        ],
      ),
    );

    final reason = reasonController.text.trim();
    reasonController.dispose();

    if (confirmed != true) return;

    try {
      await _service.rejectClaim(
        claimId: claim.id,
        adminId: adminId,
        adminName: auth.displayName,
        reason: reason,
      );
      if (mounted) {
        _showSnack('تم رفض الطلب', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnack('فشل: $e', isError: true);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final OwnerClaimRequestModel claim;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ClaimCard({
    required this.claim,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = claim.status == ClaimStatus.pending;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
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
                    color: _statusColor(claim.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    claim.status.labelAr,
                    style: TextStyle(
                      color: _statusColor(claim.status),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (claim.createdAt != null)
                  Text(
                    _formatDate(claim.createdAt!),
                    style: YaBaladiTypography.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              claim.placeName,
              style: YaBaladiTypography.headingLabel.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${claim.userDisplayName} • ${claim.userEmail}',
                    style: YaBaladiTypography.bodySmall.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (claim.notes != null && claim.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  claim.notes!,
                  style: YaBaladiTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('رفض'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(color: Colors.red.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('موافقة'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.pending:
        return Colors.orange;
      case ClaimStatus.approved:
        return Colors.green;
      case ClaimStatus.rejected:
        return Colors.red;
    }
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
