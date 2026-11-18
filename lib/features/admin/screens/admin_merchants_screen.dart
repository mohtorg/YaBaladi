// lib/features/admin/screens/admin_merchants_screen.dart
// [v2.3.0 — SEVERITY ADDED]
//   - ADDED: severity 'high' (ban), 'medium' (unban), 'critical' (delete).
//   - KEPT: All v2.2.0 logic, context captures, UI intact.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/audit_log_service.dart';
import '../../auth/controllers/auth_controller.dart';

class AdminMerchantsScreen extends StatefulWidget {
  const AdminMerchantsScreen({super.key});

  @override
  State<AdminMerchantsScreen> createState() => _AdminMerchantsScreenState();
}

class _AdminMerchantsScreenState extends State<AdminMerchantsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filter = 'all'; // all | banned

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('إدارة حسابات التجار',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
      ),
      body: Column(
        children: [
          // ─── شريط البحث ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو البريد...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                isDense: true,
              ),
            ),
          ),

          // ─── الفلاتر ───
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('all', 'الكل', theme),
                const SizedBox(width: 8),
                _buildFilterChip('banned', 'محظور', theme),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── القائمة ───
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'merchant')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _buildEmptyState(theme, 'لا توجد حسابات تجار مسجلة');
                }

                // الفلترة محلياً
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final name =
                      (data['displayName'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final query = _searchCtrl.text.trim().toLowerCase();
                  final isBanned = data['isBanned'] == true;

                  if (_filter == 'banned' && !isBanned) return false;

                  if (query.isNotEmpty) {
                    return name.contains(query) || email.contains(query);
                  }
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return _buildEmptyState(
                      theme, 'لا توجد نتائج مطابقة للفلتر الحالي');
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data();
                    return _MerchantUserCard(userId: doc.id, data: data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, ThemeData theme) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              size: 80, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(text, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// بطاقة التاجر (المستخدم)
// ═══════════════════════════════════════════════════════════════
class _MerchantUserCard extends StatelessWidget {
  final String userId;
  final Map<String, dynamic> data;

  const _MerchantUserCard({required this.userId, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isBanned = data['isBanned'] == true;
    final name = data['displayName'] ?? 'بدون اسم';
    final email = data['email'] ?? 'لا يوجد بريد';
    final photoUrl = data['photoUrl'];

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: isBanned
                ? Colors.red.shade300
                : theme.colorScheme.outlineVariant,
            width: isBanned ? 1.5 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── الاسم + الحالة ───
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: isBanned
                      ? Colors.red.shade50
                      : theme.colorScheme.primaryContainer,
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Icon(Icons.person,
                          color:
                              isBanned ? Colors.red : theme.colorScheme.primary)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(email,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBanned ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: (isBanned ? Colors.red : Colors.green)
                            .withValues(alpha: 0.3)),
                  ),
                  child: Text(isBanned ? 'محظور' : 'نشط',
                      style: TextStyle(
                          color: isBanned
                              ? Colors.red.shade800
                              : Colors.green.shade800,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── الإجراءات ───
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteDialog(context),
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.red, size: 18),
                    label: const Text('حذف الحساب',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: Colors.red.withValues(alpha: 0.5))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _toggleBan(context, isBanned),
                    icon: Icon(isBanned ? Icons.check_circle : Icons.block,
                        size: 18),
                    label: Text(isBanned ? 'فك الحظر' : 'حظر'),
                    style: FilledButton.styleFrom(
                        backgroundColor: isBanned ? Colors.green : Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── تنفيذ الحظر / فك الحظر ───
  Future<void> _toggleBan(BuildContext context, bool currentStatus) async {
    final admin = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(currentStatus ? 'فك الحظر' : 'حظر الحساب'),
        content: Text(currentStatus
            ? 'هل تريد فك حظر هذا التاجر؟ سيتمكن من الدخول مجدداً.'
            : 'هل أنت متأكد من حظر هذا التاجر؟ لن يتمكن من إضافة أماكن أو عروض جديدة.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: currentStatus ? Colors.green : Colors.red),
            child: Text(currentStatus ? 'فك الحظر' : 'تأكيد الحظر'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isBanned': !currentStatus,
      });

      // ✅ تسجيل الإجراء مع severity مناسبة
      await AuditLogService.logAction(
        action: currentStatus ? 'فك حظر تاجر' : 'حظر تاجر',
        adminName: admin.displayName,
        target: data['displayName'] ?? 'تاجر',
        details: 'تم ${currentStatus ? 'فك' : 'تفعيل'} الحظر للحساب',
        severity: currentStatus ? 'medium' : 'high',
      );

      messenger.showSnackBar(SnackBar(
          content: Text(
              currentStatus ? '✅ تم فك الحظر بنجاح' : '🚫 تم حظر الحساب بنجاح'),
          backgroundColor: currentStatus ? Colors.green : Colors.red));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── تنفيذ حذف الحساب ───
  Future<void> _showDeleteDialog(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final admin = context.read<AuthController>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 10),
          Text('حذف حساب التاجر')
        ]),
        content: const Text(
            'هل أنت متأكد من حذف هذا الحساب نهائياً؟ سيتم حذف الوثيقة من قاعدة البيانات (لن يتمكن من تسجيل الدخول). الأماكن المرتبطة به قد تبقى كبيانات يتيمة.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الحساب'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .delete();

        // ✅ تسجيل الإجراء مع severity 'critical'
        await AuditLogService.logAction(
          action: 'حذف حساب تاجر',
          adminName: admin.displayName,
          target: data['displayName'] ?? 'تاجر',
          severity: 'critical',
        );

        messenger.showSnackBar(const SnackBar(
            content: Text('✅ تم حذف حساب التاجر بنجاح'),
            backgroundColor: Colors.green));
      } catch (e) {
        messenger.showSnackBar(
            SnackBar(content: Text('❌ خطأ: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
