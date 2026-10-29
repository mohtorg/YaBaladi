// lib/features/support/screens/admin_support_screen.dart
//
// [v1.2 — 2026-10-28] — FIX: Add missing import for NotificationType

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/support_tickets_controller.dart';
import '../models/support_ticket.dart';
import 'admin_support_settings_dialog.dart';
import '../../notifications/models/notification_model.dart'; // ✅ استيراد مضاف للـ NotificationType
import '../../notifications/services/notification_helper.dart';

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupportTicketsController>().loadTickets();
    });
  }

  // ✅ دالة تحديث الحالة وإرسال الإشعار
  Future<void> _updateStatusWithNotification(
    SupportTicketsController c,
    SupportTicket t,
    String newStatus,
  ) async {
    await c.updateStatus(t.id, newStatus);

    if (t.userId.isNotEmpty && t.userId != 'anonymous') {
      if (newStatus == 'in_progress') {
        await NotificationHelper.notifySupportReply(t.userId, t.errorCode);
      } else if (newStatus == 'resolved') {
        await NotificationHelper.send(
          userId: t.userId,
          title: '✅ تم حل بلاغك',
          body: 'تمت معالجة البلاغ (${t.errorCode}) بنجاح. شكراً لصبرك.',
          type: NotificationType.supportReply, // ✅ الآن معرّف
        );
      }
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, SupportTicketsController c, SupportTicket t) async {
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
    if (ok == true) {
      await c.deleteTicket(t.id);
    }
  }

  Future<void> _confirmClearAll(
      BuildContext context, SupportTicketsController c) async {
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
    if (ok == true) {
      await c.deleteAllResolved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SupportTicketsController>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الدعم'),
        actions: [
          if (controller.filter == 'resolved' && controller.tickets.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              tooltip: 'مسح كل البلاغات المحلولة',
              onPressed: () => _confirmClearAll(context, controller),
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
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : controller.tickets.isEmpty
                    ? Center(
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
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: controller.tickets.length,
                        itemBuilder: (_, i) => _ticketCard(
                            controller.tickets[i], controller, theme, context),
                      ),
          ),
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
      onSelected: (_) {
        c.setFilter(key);
        c.loadTickets();
      },
      selectedColor: theme.colorScheme.primary,
    );
  }

  Widget _ticketCard(SupportTicket t, SupportTicketsController c,
      ThemeData theme, BuildContext context) {
    final isOpen = t.isOpen;
    return Card(
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
                const Text('📧 البريد:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(t.userEmail.isEmpty ? 'غير متوفر' : t.userEmail,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 12),
                const Text('📄 رسالة الخطأ:',
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (t.status != 'resolved') ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _updateStatusWithNotification(
                              c, t, 'in_progress'),
                          icon: const Icon(Icons.hourglass_empty, size: 16),
                          label: const Text('قيد المعالجة'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _updateStatusWithNotification(c, t, 'resolved'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('تم الحل'),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.green),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(context, c, t),
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

  String _timeAgo(DateTime? dt) {
    if (dt == null) return 'الآن';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
  }
}
