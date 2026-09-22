import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  Future<int> _count(String collection, {String? field, dynamic value}) async {
    var query = FirebaseFirestore.instance.collection(collection);
    final result = field == null
        ? await query.count().get()
        : await query.where(field, isEqualTo: value).count().get();
    return result.count ?? 0;
  }

  Future<String> _buildReport() async {
    final entries = <String, Future<int>>{
      'الأماكن': _count('places'),
      'الفعاليات': _count('events', field: 'isPublished', value: true),
      'العروض': _count('offers', field: 'active', value: true),
      'المكافآت': _count('rewards', field: 'active', value: true),
      'التقييمات': _count('ratings'),
    };
    final values = <String, int>{};
    for (final entry in entries.entries) {
      values[entry.key] = await entry.value;
    }
    return [
      'تقرير يا بلدي',
      'تاريخ الإنشاء: ${DateTime.now().toLocal()}',
      ...values.entries.map((e) => '${e.key}: ${e.value}'),
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: AuthService().getModeratorProfile(),
        builder: (context, profile) {
          if (profile.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return FutureBuilder<bool>(
            future: AuthService().hasAdminClaim(),
            builder: (context, claim) {
              if (claim.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final isAdmin = claim.data == true;
              final permissions =
                  List<String>.from(profile.data?['permissions'] ?? const []);
              final can = (String p) =>
                  isAdmin || permissions.contains('*') || permissions.contains(p);
              if (!can('reports.read')) {
                return const Center(child: Text('لا تملك صلاحية مشاهدة التقارير.'));
              }

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.assessment_outlined),
                        title: const Text('التقرير التشغيلي الموحد'),
                        subtitle: const Text(
                          'ملخص للأماكن والفعاليات والعروض والمكافآت والتقييمات.',
                        ),
                        trailing: const Icon(Icons.chevron_left),
                        onTap: () async {
                          final report = await _buildReport();
                          if (!context.mounted) return;
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('التقرير التشغيلي'),
                              content: SingleChildScrollView(child: SelectableText(report)),
                              actions: [
                                if (can('reports.export'))
                                  TextButton(
                                    onPressed: () async {
                                      await Clipboard.setData(
                                          ClipboardData(text: report));
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                    child: const Text('نسخ / تصدير'),
                                  ),
                                if (can('reports.print'))
                                  const TextButton(
                                    onPressed: null,
                                    child: Text('الطباعة متاحة حسب صلاحية reports.print'),
                                  ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('إغلاق'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isAdmin
                          ? 'الأدمن الأعلى يرى البيانات الإدارية الكاملة المتاحة له.'
                          : 'يعرض التقرير البيانات التي تسمح بها صلاحيات حسابك ونطاقه.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
