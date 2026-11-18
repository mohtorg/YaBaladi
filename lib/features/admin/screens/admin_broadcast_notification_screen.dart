// lib/features/admin/screens/admin_broadcast_notification_screen.dart
// [v2.2 — SEVERITY ADDED]
//   - ADDED: severity 'high' (allUsers) / 'medium' (merchants / regular users).
//   - KEPT: All v2.1 logic, UI, batches, and enriched details intact.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/audit_log_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notifications/models/notification_model.dart';

enum BroadcastTarget { allUsers, merchantsOnly, regularUsersOnly }

class AdminBroadcastNotificationScreen extends StatefulWidget {
  const AdminBroadcastNotificationScreen({super.key});

  @override
  State<AdminBroadcastNotificationScreen> createState() =>
      _AdminBroadcastNotificationScreenState();
}

class _AdminBroadcastNotificationScreenState
    extends State<AdminBroadcastNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  NotificationType _selectedType = NotificationType.systemAnnouncement;
  BroadcastTarget _selectedTarget = BroadcastTarget.allUsers;
  bool _isSending = false;
  bool _isTitleManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _autoFillTitle();
    _titleCtrl.addListener(() {
      if (_titleCtrl.text != _getSuggestedTitle()) {
        _isTitleManuallyEdited = true;
      }
      setState(() {});
    });
    _bodyCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  String _getEmojiForType(NotificationType type) {
    switch (type) {
      case NotificationType.systemAnnouncement:
        return '📢';
      case NotificationType.newOffer:
        return '🔥';
      case NotificationType.newReview:
        return '⭐';
      case NotificationType.merchantApproved:
        return '🎉';
      case NotificationType.merchantRejected:
        return '⚠️';
      case NotificationType.placeBlocked:
        return '🚫';
      case NotificationType.placeUnblocked:
        return '✅';
      case NotificationType.supportReply:
        return '📩';
    }
  }

  String _getSuggestedTitle() =>
      '${_getEmojiForType(_selectedType)} ${_getPlainTitle()}';

  String _getPlainTitle() {
    switch (_selectedType) {
      case NotificationType.systemAnnouncement:
        return 'إعلان هام من إدارة يا بلدي';
      case NotificationType.newOffer:
        return 'عرض جديد بانتظارك!';
      case NotificationType.newReview:
        return 'تمت إضافة تقييم جديد لمكانك';
      case NotificationType.merchantApproved:
        return 'مبروك! تمت الموافقة على انضمامك';
      case NotificationType.merchantRejected:
        return 'تحديث بخصوص طلب الانضمام';
      case NotificationType.placeBlocked:
        return 'تم إيقاف نشاطك التجاري مؤقتاً';
      case NotificationType.placeUnblocked:
        return 'تم إعادة تفعيل نشاطك التجاري';
      case NotificationType.supportReply:
        return 'رد جديد من فريق الدعم الفني';
    }
  }

  void _autoFillTitle() {
    if (!_isTitleManuallyEdited || _titleCtrl.text.isEmpty) {
      _titleCtrl.text = _getSuggestedTitle();
    }
  }

  Future<void> _sendToUsersInBatches(
      List<QueryDocumentSnapshot> users, String title, String body) async {
    const int batchSize = 400;
    for (var i = 0; i < users.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = users.skip(i).take(batchSize);
      for (final userDoc in chunk) {
        final notifRef =
            FirebaseFirestore.instance.collection('notifications').doc();
        batch.set(notifRef, {
          'userId': userDoc.id,
          'title': title,
          'body': body,
          'type': _selectedType.name,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'data': {},
        });
      }
      await batch.commit();
    }
  }

  Future<void> _sendBroadcast() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final admin = context.read<AuthController>();

    if (_selectedTarget == BroadcastTarget.allUsers &&
        (_selectedType == NotificationType.merchantApproved ||
            _selectedType == NotificationType.merchantRejected ||
            _selectedType == NotificationType.placeBlocked)) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه منطقي'),
          content: const Text(
              'أنت تحاول إرسال إشعار مخصص للتجار إلى "جميع المستخدمين". هل أنت متأكد؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نعم، أرسل للجميع')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSending = true);

    try {
      final title = _titleCtrl.text.trim();
      final body = _bodyCtrl.text.trim();
      int recipientCount = -1;

      if (_selectedTarget == BroadcastTarget.allUsers) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': 'all',
          'title': title,
          'body': body,
          'type': _selectedType.name,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'data': {},
        });
      } else if (_selectedTarget == BroadcastTarget.merchantsOnly) {
        final merchantsSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'merchant')
            .get();
        if (merchantsSnap.docs.isEmpty) {
          throw Exception('لا يوجد تجار مسجلون في النظام حالياً.');
        }
        await _sendToUsersInBatches(merchantsSnap.docs, title, body);
        recipientCount = merchantsSnap.docs.length;
      } else if (_selectedTarget == BroadcastTarget.regularUsersOnly) {
        final usersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .get();
        if (usersSnap.docs.isEmpty) {
          throw Exception('لا يوجد مستخدمون مسجلون في النظام حالياً.');
        }
        await _sendToUsersInBatches(usersSnap.docs, title, body);
        recipientCount = usersSnap.docs.length;
      }

      String targetLogName = 'جميع المستخدمين';
      if (_selectedTarget == BroadcastTarget.merchantsOnly) {
        targetLogName = 'جميع التجار';
      }
      if (_selectedTarget == BroadcastTarget.regularUsersOnly) {
        targetLogName = 'المستخدمون العاديون';
      }

      final recipientLabel =
          recipientCount == -1 ? 'كل المستخدمين' : '$recipientCount مستلم';
      final bodySnippet = body.length > 80 ? '${body.substring(0, 80)}…' : body;

      // ✅ severity: high لكل المستخدمين، medium للباقي
      final severity =
          _selectedTarget == BroadcastTarget.allUsers ? 'high' : 'medium';

      await AuditLogService.logAction(
        action: 'إرسال إشعار جماعي',
        adminName: admin.displayName,
        target: targetLogName,
        details:
            'العنوان: "$title" | النوع: ${_selectedType.arabicLabel} | المستلمون: $recipientLabel | مقتطف: $bodySnippet',
        severity: severity,
      );

      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الإشعارات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('إرسال إشعار',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('الفئة المستهدفة',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTargetCard(
                      theme,
                      target: BroadcastTarget.allUsers,
                      icon: Icons.people,
                      title: 'الجميع',
                      subtitle: 'كل المستخدمين',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTargetCard(
                      theme,
                      target: BroadcastTarget.merchantsOnly,
                      icon: Icons.storefront,
                      title: 'التجار',
                      subtitle: 'أصحاب الأماكن',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTargetCard(
                      theme,
                      target: BroadcastTarget.regularUsersOnly,
                      icon: Icons.person,
                      title: 'المستخدمون',
                      subtitle: 'الزوار العاديون',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('نوع الإشعار',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<NotificationType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                items: NotificationType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Text(_getEmojiForType(type),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Text(type.arabicLabel),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      _isTitleManuallyEdited = false;
                      _autoFillTitle();
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              Text('عنوان الإشعار',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  hintText: 'مثال: تحديث سياسة العروض',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.title),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'يرجى كتابة العنوان'
                    : null,
              ),
              const SizedBox(height: 20),
              Text('نص الرسالة',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'اكتب تفاصيل الرسالة هنا...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 60),
                    child: Icon(Icons.message),
                  ),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'يرجى كتابة نص الرسالة'
                    : null,
              ),
              const SizedBox(height: 24),
              Text('معاينة الإشعار',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildPreviewCard(theme),
              const SizedBox(height: 40),
              FilledButton.icon(
                onPressed: _isSending ? null : _sendBroadcast,
                icon: _isSending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: Text(_isSending ? 'جارٍ الإرسال...' : 'إرسال الإشعار'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: _selectedTarget == BroadcastTarget.allUsers
                      ? Colors.green
                      : _selectedTarget == BroadcastTarget.merchantsOnly
                          ? Colors.orange.shade700
                          : Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeData theme) {
    final hasTitle = _titleCtrl.text.isNotEmpty;
    final hasBody = _bodyCtrl.text.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_getEmojiForType(_selectedType),
                style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasTitle ? _titleCtrl.text : 'عنوان الإشعار سيظهر هنا',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: hasTitle ? Colors.black87 : Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  hasBody ? _bodyCtrl.text : 'نص الرسالة سيظهر هنا...',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasBody ? Colors.black54 : Colors.grey,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(
    ThemeData theme, {
    required BroadcastTarget target,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedTarget == target;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTarget = target;
            _isTitleManuallyEdited = false;
            _autoFillTitle();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isSelected ? color : theme.colorScheme.outlineVariant,
                width: isSelected ? 2 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 28,
                  color: isSelected ? color : theme.colorScheme.outline),
              const SizedBox(height: 8),
              Text(title,
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: isSelected ? color : null)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9, color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
