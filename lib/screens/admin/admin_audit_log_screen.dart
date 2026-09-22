import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/audit_log_service.dart';
import '../../services/auth_service.dart';

class AdminAuditLogScreen extends StatelessWidget {
  const AdminAuditLogScreen({super.key});

  String _date(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal().toString();
    return 'وقت غير متاح';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل النشاط'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: AuthService().hasAdminClaim(),
        builder: (context, claim) => FutureBuilder<Map<String, dynamic>?>(
          future: AuthService().getModeratorProfile(),
          builder: (context, profile) {
            if (claim.connectionState == ConnectionState.waiting ||
                profile.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final isAdmin = claim.data == true;
            final permissions =
                List<String>.from(profile.data?['permissions'] ?? const []);
            final canAudit =
                isAdmin || permissions.contains('*') || permissions.contains('audit.read');
            if (!canAudit) {
              return const Center(child: Text('لا تملك صلاحية مشاهدة سجل النشاط.'));
            }

            final service = AuditLogService();
            final stream = isAdmin
                ? service.watch()
                : service.watchMyActivity();

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد أنشطة مسجلة.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final data = docs[index].data();
                    final details = data['details'];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(data['action']?.toString() ?? 'عملية'),
                        subtitle: Text(
                          'المنفذ: ${data['actorUid'] ?? '-'}\n'
                          'النوع: ${data['targetType'] ?? '-'}\n'
                          'المعرف: ${data['targetId'] ?? '-'}\n'
                          'الوقت: ${_date(data['createdAt'])}'
                          '${details is Map && details.isNotEmpty ? '\nالتفاصيل: $details' : ''}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
