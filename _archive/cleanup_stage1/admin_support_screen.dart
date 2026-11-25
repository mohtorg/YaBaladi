// lib/features/admin/screens/admin_support_screen.dart
// [v1.0 — NEW: Full support ticket management + audit logging]
//   - FEATURES: List / search / filter by status / view details
//   - ACTIONS: Reply, change status, delete single, delete all resolved
//   - AUDIT: Reply (low) | Change status (medium) | Delete (high) | Bulk delete (high)
//   - DATA: Flexible schema (accepts multiple field-name variants)
//   - SAFETY: context.read<AuthController> captured before every await

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/audit_log_service.dart';
import '../../auth/controllers/auth_controller.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'open';
  final Set<String> _processingIds = {};
  bool _deletingResolved = false;

  static const Map<String, String> _statusLabels = {
    'open': 'مفتوحة',
    'in_progress': 'قيد المعالجة',
    'resolved': 'محلولة',
    'closed': 'مغلقة',
  };

  static const Map<String, Color> _statusColors = {
    'open': Colors.red,
    'in_progress': Colors.orange,
    'resolved': Colors.green,
    'closed': Colors.grey,
  };

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _statusLabel(String status) => _statusLabels[status] ?? status;
  Color _statusColor(String status) => _statusColors[status] ?? Colors.blueGrey;

  // ═══════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _changeStatus(_TicketData ticket, String newStatus) async {
    if (newStatus == ticket.status) return;

    // ✅ Capture before any await
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AuthController>();

    setState(() => _processingIds.add(ticket.id));

    try {
      final updates = <String, dynamic>{'status': newStatus};
      if (newStatus == 'resolved') {
        updates['resolvedAt'] = FieldValue.serverTimestamp();
      } else if (ticket.status == 'resolved') {
        updates['resolvedAt'] = FieldValue.delete();
      }

      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(ticket.id)
          .update(updates);

      // ─── سجل التدقيق ───
      await AuditLogService.logAction(
        action: 'تغيير حالة تذكرة دعم',
        adminName: admin.displayName,
        target: ticket.subject,
        details:
            'من "${_statusLabel(ticket.status)}" إلى "${_statusLabel(newStatus)}"',
        severity: 'medium',
      );

      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('✅ تم تحديث الحالة'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(ticket.id));
    }
  }

  Future<void> _sendReply(_TicketData ticket, String replyText) async {
    final text = replyText.trim();
    if (text.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AuthController>();

    setState(() => _processingIds.add(ticket.id));

    try {
      final updates = <String, dynamic>{
        'adminReply': text,
        'adminRepliedAt': FieldValue.serverTimestamp(),
        'adminRepliedBy': admin.displayName,
      };
      // نقل تلقائي من "مفتوحة" إلى "قيد المعالجة"
      if (ticket.status == 'open') {
        updates['status'] = 'in_progress';
      }

      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(ticket.id)
          .update(updates);

      final snippet = text.length > 60 ? '${text.substring(0, 60)}…' : text;
      await AuditLogService.logAction(
        action: 'الرد على تذكرة دعم',
        adminName: admin.displayName,
        target: ticket.subject,
        details: 'مقتطف: $snippet',
        severity: 'low',
      );

      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('✅ تم إرسال الرد'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(ticket.id));
    }
  }

  Future<void> _deleteTicket(_TicketData ticket) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AuthController>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف تذكرة'),
        content: Text(
            'هل تريد حذف تذكرة "${ticket.subject}" نهائياً؟\nلا يمكن التراجع.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _processingIds.add(ticket.id));

    try {
      await FirebaseFirestore.instance
          .collection('support_tickets')
          .doc(ticket.id)
          .delete();

      await AuditLogService.logAction(
        action: 'حذف تذكرة دعم',
        adminName: admin.displayName,
        target: ticket.subject,
        details: 'userId: ${ticket.userId} | status: ${ticket.status}',
        severity: 'high',
      );

      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('✅ تم حذف التذكرة'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(ticket.id));
    }
  }

  Future<void> _deleteAllResolved() async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AuthController>();

    // جلب المحلولة لمعرفة العدد
    List<QueryDocumentSnapshot> resolvedDocs = [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('support_tickets')
          .where('status', isEqualTo: 'resolved')
          .get();
      resolvedDocs = snap.docs;
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('❌ خطأ: $e'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!mounted) return;

    if (resolvedDocs.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('لا توجد تذاكر محلولة للحذف')));
      return;
    }

    final count = resolvedDocs.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف كل التذاكر المحلولة'),
        content:
            Text('هل تريد حذف $count تذكرة محلولة نهائياً؟\nلا يمكن التراجع.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف $count'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() => _deletingResolved = true);

    try {
      // حذف على دفعات (batch) بحد أقصى 500
      const batchSize = 500;
      for (var i = 0; i < resolvedDocs.length; i += batchSize) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in resolvedDocs.skip(i).take(batchSize)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await AuditLogService.logAction(
        action: 'حذف كل التذاكر المحلولة',
        adminName: admin.displayName,
        target: 'تذاكر الدعم',
        details: 'تم حذف $count تذكرة محلولة',
        severity: 'high',
      );

      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('✅ تم حذف $count تذكرة'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('❌ خطأ: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _deletingResolved = false);
    }
  }

  void _openDetailsDialog(_TicketData ticket) {
    final replyCtrl = TextEditingController(text: ticket.adminReply ?? '');

    showDialog(
      context: context,
      builder: (ctx) => _TicketDetailsDialog(
        ticket: ticket,
        replyCtrl: replyCtrl,
        statusLabel: _statusLabel,
        statusColor: _statusColor,
        onReply: (text) {
          Navigator.pop(ctx);
          _sendReply(ticket, text);
        },
        onChangeStatus: (newStatus) {
          Navigator.pop(ctx);
          _changeStatus(ticket, newStatus);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _deleteTicket(ticket);
        },
      ),
    ).then((_) => replyCtrl.dispose());
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('تذاكر الدعم الفني',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: _deletingResolved
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_sweep_outlined),
            tooltip: 'حذف كل المحلولة',
            onPressed: _deletingResolved ? null : _deleteAllResolved,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('support_tickets')
            .orderBy('createdAt', descending: true)
            .limit(200)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('خطأ: ${snapshot.error}', textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTickets =
              snapshot.data!.docs.map((d) => _TicketData.from(d)).toList();

          final counts = <String, int>{'all': allTickets.length};
          for (final t in allTickets) {
            counts[t.status] = (counts[t.status] ?? 0) + 1;
          }

          final filtered = allTickets.where((t) {
            if (_filterStatus != 'all' && t.status != _filterStatus) {
              return false;
            }
            if (_searchQuery.isNotEmpty) {
              final s = '${t.userName} ${t.userEmail} ${t.subject} ${t.message}'
                  .toLowerCase();
              if (!s.contains(_searchQuery)) return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو الموضوع أو النص...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildStatusChip('all', 'الكل', counts['all'] ?? 0, theme),
                    _buildStatusChip(
                        'open', 'مفتوحة', counts['open'] ?? 0, theme),
                    _buildStatusChip('in_progress', 'قيد المعالجة',
                        counts['in_progress'] ?? 0, theme),
                    _buildStatusChip(
                        'resolved', 'محلولة', counts['resolved'] ?? 0, theme),
                    _buildStatusChip(
                        'closed', 'مغلقة', counts['closed'] ?? 0, theme),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState(theme, counts)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) =>
                            _buildTicketCard(filtered[index], theme),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(
      String value, String label, int count, ThemeData theme) {
    final selected = _filterStatus == value;
    final color =
        value == 'all' ? theme.colorScheme.primary : _statusColor(value);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          '$label${count > 0 ? " ($count)" : ""}',
          style: const TextStyle(fontSize: 12),
        ),
        selected: selected,
        onSelected: (_) => setState(() => _filterStatus = value),
        selectedColor: color,
        labelStyle: TextStyle(
          color: selected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _buildTicketCard(_TicketData ticket, ThemeData theme) {
    final isProcessing = _processingIds.contains(ticket.id);
    final statusColor = _statusColor(ticket.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: isProcessing ? null : () => _openDetailsDialog(ticket),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.15),
                    child: Icon(Icons.support_agent, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ticket.subject,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ticket.userName,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _statusLabel(ticket.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (ticket.message.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  ticket.message,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (ticket.adminReply != null &&
                  ticket.adminReply!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.reply, size: 14, color: Colors.green.shade700),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'الرد: ${ticket.adminReply}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.access_time,
                      size: 12, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(ticket.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  if (isProcessing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      'عرض التفاصيل',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Map<String, int> counts) {
    final allEmpty = (counts['all'] ?? 0) == 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              allEmpty ? Icons.inbox_outlined : Icons.filter_alt_off_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              allEmpty ? 'لا توجد تذاكر دعم' : 'لا توجد نتائج مطابقة',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              allEmpty
                  ? 'لم يتم استقبال أي تذاكر بعد'
                  : 'جرّب تغيير الفلتر أو البحث',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════
// DETAIL DIALOG
// ═══════════════════════════════════════════════════════════════

class _TicketDetailsDialog extends StatelessWidget {
  final _TicketData ticket;
  final TextEditingController replyCtrl;
  final void Function(String) onReply;
  final void Function(String) onChangeStatus;
  final VoidCallback onDelete;
  final String Function(String) statusLabel;
  final Color Function(String) statusColor;

  const _TicketDetailsDialog({
    required this.ticket,
    required this.replyCtrl,
    required this.onReply,
    required this.onChangeStatus,
    required this.onDelete,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.support_agent, color: statusColor(ticket.status)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ticket.subject,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _row('من', ticket.userName),
            if (ticket.userEmail.isNotEmpty) _row('البريد', ticket.userEmail),
            if (ticket.userId.isNotEmpty) _row('UID', ticket.userId),
            _row('الحالة', statusLabel(ticket.status)),
            if (ticket.createdAt != null)
              _row(
                'التاريخ',
                '${ticket.createdAt!.day}/${ticket.createdAt!.month}/${ticket.createdAt!.year}',
              ),
            const Divider(height: 20),
            const Text('الرسالة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(ticket.message, style: const TextStyle(fontSize: 12)),
            ),
            if (ticket.adminReply != null && ticket.adminReply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('ردك السابق:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(ticket.adminReply!,
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
            const SizedBox(height: 16),
            const Text('تغيير الحالة:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ['open', 'in_progress', 'resolved', 'closed'].map((s) {
                final selected = ticket.status == s;
                return ChoiceChip(
                  label: Text(statusLabel(s),
                      style: const TextStyle(fontSize: 11)),
                  selected: selected,
                  onSelected: selected ? null : (_) => onChangeStatus(s),
                  selectedColor: statusColor(s),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : null,
                    fontWeight: selected ? FontWeight.bold : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('الرد:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 4),
            TextField(
              controller: replyCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'اكتب ردك هنا...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('حذف'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
        FilledButton(
          onPressed: () => onReply(replyCtrl.text),
          child: const Text('إرسال الرد'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text('$label:',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TICKET DATA HELPER
// ═══════════════════════════════════════════════════════════════

class _TicketData {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String subject;
  final String message;
  final String status;
  final String? adminReply;
  final DateTime? createdAt;

  const _TicketData({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.subject,
    required this.message,
    required this.status,
    required this.adminReply,
    required this.createdAt,
  });

  factory _TicketData.from(QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    DateTime? parseTs(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return _TicketData(
      id: doc.id,
      userId: (d['userId'] ?? '').toString(),
      userName: (d['userName'] ?? d['name'] ?? d['displayName'] ?? 'غير معروف')
          .toString(),
      userEmail: (d['userEmail'] ?? d['email'] ?? '').toString(),
      subject: (d['subject'] ?? d['title'] ?? 'بدون موضوع').toString(),
      message: (d['message'] ?? d['description'] ?? d['body'] ?? '').toString(),
      status: (d['status'] ?? 'open').toString(),
      adminReply: d['adminReply']?.toString(),
      createdAt: parseTs(d['createdAt']),
    );
  }
}
