// screens/admin/admin_support_tickets_screen.dart
// ============================================================
// الفكرة:
// هذه شاشة تشغيلية لفريق الدعم داخل لوحة الإدارة. التذكرة لا تُعرض
// إلا للمشرف الذي يملك support.read، وتغيير حالتها يحتاج support.write
// كما تفرض Firestore Rules. لذلك لا نعتمد على إخفاء الزر كحماية أمنية.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../l10n/locale_controller.dart';
import '../../services/auth_service.dart';

class AdminSupportTicketsScreen extends StatefulWidget {
  const AdminSupportTicketsScreen({super.key});

  @override
  State<AdminSupportTicketsScreen> createState() => _AdminSupportTicketsScreenState();
}

class _AdminSupportTicketsScreenState extends State<AdminSupportTicketsScreen> {
  String _status = 'all';

  Stream<QuerySnapshot<Map<String, dynamic>>> _stream() {
    var query = FirebaseFirestore.instance.collection('support_tickets').orderBy('createdAt', descending: true);
    if (_status != 'all') query = query.where('status', isEqualTo: _status);
    return query.snapshots();
  }

  Future<void> _updateStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('support_tickets').doc(id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final ar = LocaleController.of(context).locale.languageCode == 'ar';
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService().getModeratorProfile(),
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final permissions = List<String>.from(profile?['permissions'] ?? const []);
        final canRead = AuthService().currentUser != null && permissions.contains('support.read');
        final canWrite = AuthService().currentUser != null && permissions.contains('support.write');
        return Scaffold(
          appBar: AppBar(
            title: Text(ar ? 'دعم المستخدمين' : 'User Support'),
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
          ),
          body: FutureBuilder<bool>(
            future: AuthService().hasAdminClaim(),
            builder: (context, claimSnapshot) {
              final allowed = claimSnapshot.data == true || canRead || permissions.contains('*');
              if (!allowed) return Center(child: Text(ar ? 'لا تملك صلاحية مشاهدة تذاكر الدعم.' : 'You do not have permission to view support tickets.'));
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      decoration: InputDecoration(labelText: ar ? 'تصفية الحالة' : 'Filter status', border: const OutlineInputBorder()),
                      items: [
                        DropdownMenuItem(value: 'all', child: Text(ar ? 'كل التذاكر' : 'All tickets')),
                        DropdownMenuItem(value: 'new', child: Text(ar ? 'جديدة' : 'New')),
                        DropdownMenuItem(value: 'in_progress', child: Text(ar ? 'قيد المعالجة' : 'In progress')),
                        DropdownMenuItem(value: 'replied', child: Text(ar ? 'تم الرد' : 'Replied')),
                        DropdownMenuItem(value: 'closed', child: Text(ar ? 'مغلقة' : 'Closed')),
                      ],
                      onChanged: (v) => setState(() => _status = v ?? 'all'),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _stream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) return Center(child: Text('${ar ? 'تعذر تحميل التذاكر' : 'Unable to load tickets'}\n${snapshot.error}'));
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) return Center(child: Text(ar ? 'لا توجد تذاكر في هذه الحالة.' : 'No tickets in this status.'));
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                          itemCount: docs.length,
                          itemBuilder: (_, i) {
                            final d = docs[i];
                            final data = d.data();
                            final status = data['status'] as String? ?? 'new';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ExpansionTile(
                                leading: const CircleAvatar(child: Icon(Icons.support_agent)),
                                title: Text(data['subject'] as String? ?? (ar ? 'بدون عنوان' : 'No subject'), style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${_statusLabel(status, ar)} • ${data['userId'] ?? ''}'),
                                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                                children: [
                                  Align(alignment: Alignment.centerLeft, child: Text(data['details'] as String? ?? '')),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (claimSnapshot.data == true || canWrite || permissions.contains('*')) ...[
                                        _StatusButton(label: ar ? 'قيد المعالجة' : 'In progress', onTap: () => _updateStatus(d.id, 'in_progress')),
                                        _StatusButton(label: ar ? 'تم الرد' : 'Replied', onTap: () => _updateStatus(d.id, 'replied')),
                                        _StatusButton(label: ar ? 'إغلاق' : 'Close', onTap: () => _updateStatus(d.id, 'closed')),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _statusLabel(String status, bool ar) {
    const arMap = {'new': 'جديدة', 'in_progress': 'قيد المعالجة', 'replied': 'تم الرد', 'closed': 'مغلقة'};
    const enMap = {'new': 'New', 'in_progress': 'In progress', 'replied': 'Replied', 'closed': 'Closed'};
    return (ar ? arMap : enMap)[status] ?? status;
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StatusButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton(onPressed: onTap, child: Text(label));
}
