// screens/admin/admin_permissions_screen.dart
// شاشة إدارة المشرفين وصلاحياتهم.
// الأدمن الأعلى يحدد الصلاحيات هنا، لكن التطبيق لا يعتبر اختيار الدور وحده
// تصريحًا أمنيًا؛ قواعد Firestore هي التي تمنع التنفيذ غير المصرح به.
import 'package:flutter/material.dart';
import '../../l10n/locale_controller.dart';
import '../../models/admin_permission_model.dart';
import '../../services/admin_permission_service.dart';
import '../../services/auth_service.dart';

class AdminPermissionsScreen extends StatefulWidget {
  const AdminPermissionsScreen({super.key});
  @override State<AdminPermissionsScreen> createState() => _AdminPermissionsScreenState();
}

class _AdminPermissionsScreenState extends State<AdminPermissionsScreen> {
  static const permissionKeys = <String>[
    'users.read', 'users.write', 'places.read', 'places.write', 'merchants.read',
    'merchants.write', 'events.write', 'offers.write', 'rewards.write',
    'subscriptions.write', 'notifications.write', 'complaints.write', 'support.read', 'support.write', 'reports.read',
  ];

  final service = AdminPermissionService();

  String label(String key, bool ar) {
    const arMap = {
      'users.read': 'مشاهدة المستخدمين', 'users.write': 'إدارة المستخدمين',
      'places.read': 'مشاهدة الأماكن', 'places.write': 'إدارة الأماكن',
      'merchants.read': 'مشاهدة مقدمي الخدمة', 'merchants.write': 'إدارة مقدمي الخدمة',
      'events.write': 'إدارة الفعاليات', 'offers.write': 'إدارة العروض',
      'rewards.write': 'إدارة المكافآت', 'subscriptions.write': 'إدارة الاشتراكات',
      'notifications.write': 'إدارة الإشعارات', 'complaints.write': 'إدارة الشكاوى', 'support.read': 'مشاهدة تذاكر الدعم', 'support.write': 'إدارة تذاكر الدعم',
      'reports.read': 'مشاهدة التقارير',
    };
    const enMap = {
      'users.read': 'View users', 'users.write': 'Manage users', 'places.read': 'View places',
      'places.write': 'Manage places', 'merchants.read': 'View service providers',
      'merchants.write': 'Manage service providers', 'events.write': 'Manage events',
      'offers.write': 'Manage offers', 'rewards.write': 'Manage rewards',
      'subscriptions.write': 'Manage subscriptions', 'notifications.write': 'Manage notifications',
      'complaints.write': 'Manage complaints', 'reports.read': 'View reports',
    };
    return (ar ? arMap : enMap)[key] ?? key;
  }

  Future<void> _edit(AdminPermissionProfile? old, bool ar) async {
    final uid = TextEditingController(text: old?.uid ?? '');
    final name = TextEditingController(text: old?.displayName ?? '');
    final email = TextEditingController(text: old?.email ?? '');
    var role = old?.role ?? 'custom';
    var active = old?.active ?? true;
    final selected = <String>{...old?.permissions ?? const []};

    await showDialog(context: context, builder: (dialogContext) => StatefulBuilder(builder: (_, setDialog) => AlertDialog(
      title: Text(old == null ? (ar ? 'إضافة مشرف إداري' : 'Add moderator') : (ar ? 'تعديل المشرف الإداري' : 'Edit moderator')),
      content: SizedBox(width: 430, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: uid, decoration: InputDecoration(labelText: ar ? 'UID' : 'UID')),
        TextField(controller: name, decoration: InputDecoration(labelText: ar ? 'الاسم' : 'Name')),
        TextField(controller: email, decoration: InputDecoration(labelText: ar ? 'البريد' : 'Email')),
        DropdownButtonFormField<String>(value: role, items: const [
          DropdownMenuItem(value: 'manager', child: Text('Manager / مدير')),
          DropdownMenuItem(value: 'content_moderator', child: Text('Content / محتوى')),
          DropdownMenuItem(value: 'users_moderator', child: Text('Users / مستخدمون')),
          DropdownMenuItem(value: 'subscription_moderator', child: Text('Subscriptions / اشتراكات')),
          DropdownMenuItem(value: 'custom', child: Text('Custom / مخصص')),
        ], onChanged: (v) => setDialog(() => role = v ?? 'custom'), decoration: InputDecoration(labelText: ar ? 'الدور' : 'Role')),
        SwitchListTile(title: Text(ar ? 'نشط' : 'Active'), value: active, onChanged: (v) => setDialog(() => active = v)),
        const Divider(),
        Align(alignment: Alignment.centerRight, child: Text(ar ? 'الصلاحيات' : 'Permissions', style: const TextStyle(fontWeight: FontWeight.bold))),
        ...permissionKeys.map((key) => CheckboxListTile(dense: true, value: selected.contains(key), title: Text(label(key, ar)), onChanged: (v) => setDialog(() { if (v == true) { selected.add(key); } else { selected.remove(key); } }))),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(ar ? 'إلغاء' : 'Cancel')), FilledButton(onPressed: () async {
        if (uid.text.trim().isEmpty || email.text.trim().isEmpty) return;
        await service.saveProfile(AdminPermissionProfile(uid: uid.text.trim(), displayName: name.text.trim(), email: email.text.trim(), role: role, permissions: selected.toList(), active: active));
        if (dialogContext.mounted) Navigator.pop(dialogContext);
      }, child: Text(ar ? 'حفظ' : 'Save'))],
    )));
  }

  @override Widget build(BuildContext context) {
    final ar = LocaleController.of(context).locale.languageCode == 'ar';
    return FutureBuilder<bool>(
      future: AuthService().hasAdminClaim(),
      builder: (context, claimSnapshot) {
        if (claimSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (claimSnapshot.data != true) {
          return Scaffold(
            appBar: AppBar(title: Text(ar ? 'صلاحيات الإدارة' : 'Admin permissions')),
            body: Center(child: Text(ar ? 'هذه الصفحة متاحة للأدمن الأعلى فقط.' : 'This page is available to the super admin only.')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(ar ? 'صلاحيات الإدارة' : 'Admin permissions'), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
          floatingActionButton: FloatingActionButton(onPressed: () => _edit(null, ar), child: const Icon(Icons.person_add)),
          body: StreamBuilder<List<AdminPermissionProfile>>(stream: service.watchProfiles(), builder: (_, snap) {
        final profiles = snap.data ?? [];
        if (profiles.isEmpty) return Center(child: Text(ar ? 'لا توجد حسابات مشرفين' : 'No moderators configured'));
        return ListView.builder(padding: const EdgeInsets.all(12), itemCount: profiles.length, itemBuilder: (_, i) {
          final p = profiles[i];
          return Card(child: ListTile(leading: Icon(p.active ? Icons.admin_panel_settings : Icons.block), title: Text(p.displayName.isEmpty ? p.email : p.displayName), subtitle: Text('${p.role} • ${p.permissions.length} ${ar ? 'صلاحية' : 'permissions'}'), trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(p, ar))));
        });
          }),
        );
      },
    );
  }
}

