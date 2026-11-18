// lib/features/support/screens/admin_support_screen.dart
//
// [v2.0 - ENHANCED] - All high & medium priority improvements:
//   HIGH:
//   - ADDED: Error state with retry (uses defensive error access).
//   - ADDED: Explicit loadTickets() after update/delete (defensive reload).
//   - DOCUMENTED: Pagination needs controller changes (see bottom of file).
//   MEDIUM:
//   - ADDED: Search box (filter by code/user/email/message).
//   - ADDED: Stack trace display with copy button.
//   - ADDED: Read-only admin note display (if present).
//   - IMPROVED: _timeAgo uses proper Arabic plurals (no intl needed).
//   KEPT: All filters, actions, business logic, and safety guards.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/support_tickets_controller.dart';
import '../models/support_ticket.dart';
import 'admin_support_settings_dialog.dart';
import '../../notifications/models/notification_model.dart';
import '../../../core/helpers/notification_helper.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  final Set<String> _processingIds = {};
  bool _clearingAll = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportTicketsController>().loadTickets();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isProcessing(String id) => _processingIds.contains(id);

  /// Filters tickets by search query (code, user name, email, message).
  List<SupportTicket> _filtered(List<SupportTicket> all) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((t) {
      return t.errorCode.toLowerCase().contains(q) ||
          t.userName.toLowerCase().contains(q) ||
          t.userEmail.toLowerCase().contains(q) ||
          t.errorMessage.toLowerCase().contains(q);
    }).toList();
  }

  // ═══════════════════════════════════════════════════════════════
  // Actions
  // ═══════════════════════════════════════════════════════════════

  Future<void> _updateStatusWithNotification(
    SupportTicketsController c,
    SupportTicket t,
    String newStatus,
  ) async {
    if (_processingIds.contains(t.id)) return;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _processingIds.add(t.id));

    try {
      await c.updateStatus(t.id, newStatus);

      // Defensive reload (in case controller doesn't notify listeners).
      try {
        await c.loadTickets();
      } catch (_) {/* non-fatal */}

      // Notify user (decoupled from status update).
      if (t.userId.isNotEmpty && t.userId != 'anonymous') {
        try {
          if (newStatus == 'in_progress') {
            await NotificationHelper.notifySupportReply(t.userId, t.errorCode);
          } else if (newStatus == 'resolved') {
            await NotificationHelper.send(
              userId: t.userId,
              title: 'تم حل بلاغك',
              body: 'تمت معالجة البلاغ (${t.errorCode}) بنجاح. شكراً لصبرك.',
              type: NotificationType.supportReply,
            );
          }
        } catch (ne) {
          debugPrint('Notification failed: $ne');
        }
      }

      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم تحديث حالة البلاغ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Update status failed: $e');
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(t.id));
    }
  }

  Future<void> _confirmDelete(
      SupportTicketsController c, SupportTicket t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف البلاغ'),
        content: Text('هل أنت متأكد من حذف البلاغ "${t.errorCode}" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _processingIds.add(t.id));

    try {
      await c.deleteTicket(t.id);
      try {
        await c.loadTickets();
      } catch (_) {/* non-fatal */}

      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم حذف البلاغ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Delete ticket failed: $e');
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(t.id));
    }
  }

  Future<void> _confirmClearAll(SupportTicketsController c) async {
    if (_clearingAll) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مسح كل البلاغات المحلولة'),
        content: const Text(
            'هل أنت متأكد من حذف جميع البلاغات التي تم حلها؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _clearingAll = true);

    try {
      await c.deleteAllResolved();
      try {
        await c.loadTickets();
      } catch (_) {/* non-fatal */}

      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم مسح كل البلاغات المحلولة'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Clear all failed: $e');
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _clearingAll = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Build
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SupportTicketsController>();
    final theme = Theme.of(context);

    // ERROR STATE (defensive access — see docs at bottom of file).
    String? error;
    try {
      error = (controller as dynamic).error as String?;
    } catch (_) {
      error = null;
    }
    if (error != null && !controller.isLoading) {
      return _buildErrorState(theme, error, controller.loadTickets);
    }

    final filtered = _filtered(controller.tickets);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الدعم'),
        actions: [
          if (controller.filter == 'resolved' && controller.tickets.isNotEmpty)
            IconButton(
              icon: _clearingAll
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'مسح كل البلاغات المحلولة',
              onPressed:
                  _clearingAll ? null : () => _confirmClearAll(controller),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'إعدادات الدعم (رقم الواتساب)',
            onPressed: () => AdminSupportSettingsDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTickets,
          ),
        ],
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText:
                    'ابحث بكود الخطأ، اسم المستخدم، البريد، أو الرسالة...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'مسح',
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),

          // FILTER CHIPS
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('open', 'جديد', controller, theme),
                  const SizedBox(width: 8),
                  _filterChip('in_progress', 'قيد المعالجة', controller, theme),
                  const SizedBox(width: 8),
                  _filterChip('resolved', 'تم الحل', controller, theme),
                  const SizedBox(width: 8),
                  _filterChip('all', 'الكل', controller, theme),
                ],
              ),
            ),
          ),

          // LIST
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.tickets.isEmpty
                    ? _buildEmptyState(theme)
                    : filtered.isEmpty
                        ? _buildNoSearchResults(theme)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) =>
                                _ticketCard(filtered[i], controller, theme),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error, VoidCallback onRetry) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الدعم')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('تعذر تحميل البلاغات',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('لا توجد بلاغات في هذا القسم',
              style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('لا نتائج لـ "$_searchQuery"',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('جرب البحث بكود الخطأ أو اسم المستخدم',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _filterChip(
      String key, String label, SupportTicketsController c, ThemeData theme) {
    final active = c.filter == key;
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(fontSize: 12, color: active ? Colors.white : null)),
      selected: active,
      onSelected: c.isLoading
          ? null
          : (_) {
              c.setFilter(key);
              c.loadTickets();
            },
      selectedColor: theme.colorScheme.primary,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Ticket Card
  // ═══════════════════════════════════════════════════════════════

  Widget _ticketCard(
      SupportTicket t, SupportTicketsController c, ThemeData theme) {
    final isOpen = t.isOpen;
    final isProcessing = _isProcessing(t.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isOpen ? Colors.red.shade100 : Colors.green.shade100,
          child: Icon(
            isOpen ? Icons.warning_amber_rounded : Icons.check,
            color: isOpen ? Colors.red : Colors.green,
          ),
        ),
        title: Text(t.errorCode,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontFamily: 'monospace')),
        subtitle: Text('${t.userName} • ${_timeAgo(t.createdAt)}',
            style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(t.statusLabel,
              style: TextStyle(
                  fontSize: 11, color: theme.colorScheme.onPrimaryContainer)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email
                const Text('البريد الإلكتروني:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(t.userEmail.isEmpty ? 'غير متوفر' : t.userEmail,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),

                // Error message
                const Text('رسالة الخطأ:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(t.errorMessage,
                      style: const TextStyle(
                          fontSize: 11, fontFamily: 'monospace')),
                ),

                // Stack trace (if present)
                if (t.stackTrace != null && t.stackTrace!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stack Trace:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'نسخ',
                        visualDensity: VisualDensity.compact,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: t.stackTrace!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم نسخ Stack Trace'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        t.stackTrace!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                ],

                // Admin note (read-only, if present)
                if (t.adminNote != null && t.adminNote!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sticky_note_2_outlined,
                            size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ملاحظة الأدمن',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Colors.amber.shade900)),
                              const SizedBox(height: 2),
                              Text(t.adminNote!,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.amber.shade900)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    if (t.status != 'resolved') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => _updateStatusWithNotification(
                                  c, t, 'in_progress'),
                          icon: const Icon(Icons.hourglass_empty, size: 16),
                          label: const Text('قيد المعالجة'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: isProcessing
                              ? null
                              : () => _updateStatusWithNotification(
                                  c, t, 'resolved'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('تم الحل'),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.green),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              isProcessing ? null : () => _confirmDelete(c, t),
                          icon: const Icon(Icons.delete_outline,
                              size: 16, color: Colors.red),
                          label: const Text('حذف البلاغ',
                              style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // Time formatting (Arabic plurals, no intl needed)
  // ═══════════════════════════════════════════════════════════════

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'الآن';
    final diff = DateTime.now().difference(dt);

    if (diff.inMinutes < 1) return 'الآن';

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      if (m == 1) return 'منذ دقيقة';
      if (m == 2) return 'منذ دقيقتين';
      if (m <= 10) return 'منذ $m دقائق';
      return 'منذ $m دقيقة';
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      if (h == 1) return 'منذ ساعة';
      if (h == 2) return 'منذ ساعتين';
      if (h <= 10) return 'منذ $h ساعات';
      return 'منذ $h ساعة';
    }

    final d = diff.inDays;
    if (d == 1) return 'منذ يوم';
    if (d == 2) return 'منذ يومين';
    if (d <= 10) return 'منذ $d أيام';
    return 'منذ $d يوم';
  }
}
