import 'package:flutter/material.dart';
import '../../models/team_member_model.dart';
import '../../services/auth_service.dart';
import '../../services/team_service.dart';
import 'admin_audit_log_screen.dart';
import 'admin_permissions_screen.dart';

class AdminTeamScreen extends StatelessWidget {
  const AdminTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final team = TeamService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('فريق يا بلدي'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<bool>(
        future: AuthService().hasAdminClaim(),
        builder: (context, claim) {
          if (claim.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService().getModeratorProfile(),
            builder: (context, profile) {
              if (profile.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final isSuperAdmin = claim.data == true;
              final permissions =
                  List<String>.from(profile.data?['permissions'] ?? const []);
              final can = (String p) =>
                  isSuperAdmin || permissions.contains('*') || permissions.contains(p);

              if (!isSuperAdmin && !can('team.read')) {
                return const Center(child: Text('لا تملك صلاحية مشاهدة فريق يا بلدي.'));
              }

              return StreamBuilder<List<TeamMember>>(
                stream: team.watchMembers(),
                builder: (context, snapshot) {
                  final members = snapshot.data ?? const <TeamMember>[];
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _TeamSummary(members: members),
                      const SizedBox(height: 16),
                      if (isSuperAdmin || can('team.write'))
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.admin_panel_settings),
                            title: const Text('إدارة الحسابات والصلاحيات'),
                            subtitle: const Text(
                              'إضافة وتعديل ملفات المشرفين وتحديد الصلاحيات والنطاق.',
                            ),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPermissionsScreen(),
                              ),
                            ),
                          ),
                        ),
                      if (isSuperAdmin || can('audit.read'))
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('سجل النشاط'),
                            subtitle: const Text(
                              'عرض العمليات الإدارية المسجلة حسب الصلاحية.',
                            ),
                            trailing: const Icon(Icons.chevron_left),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminAuditLogScreen(),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'أعضاء الفريق',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator()),
                      if (members.isEmpty && snapshot.connectionState != ConnectionState.waiting)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('لا توجد حسابات فريق مسجلة حاليًا.'),
                          ),
                        ),
                      ...members.map((member) => _MemberTile(member: member)),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TeamSummary extends StatelessWidget {
  final List<TeamMember> members;
  const _TeamSummary({required this.members});

  @override
  Widget build(BuildContext context) {
    final active = members.where((m) => m.active).length;
    return Row(
      children: [
        Expanded(child: _Metric(title: 'أعضاء الفريق', value: members.length.toString())),
        const SizedBox(width: 12),
        Expanded(child: _Metric(title: 'الحسابات النشطة', value: active.toString())),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String title;
  final String value;
  const _Metric({required this.title, required this.value});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
}

class _MemberTile extends StatelessWidget {
  final TeamMember member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Text(member.displayName.isEmpty
                ? '?'
                : member.displayName.substring(0, 1).toUpperCase()),
          ),
          title: Text(member.displayName.isEmpty ? member.email : member.displayName),
          subtitle: Text('${member.role} • ${member.permissions.length} صلاحية'),
          trailing: Chip(
            label: Text(member.active ? 'نشط' : 'موقوف'),
          ),
        ),
      );
}
