import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/web_print_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  bool _loading = true;
  String? _error;
  String _report = '';
  bool _canExport = false;
  bool _canPrint = false;
  bool _isAdmin = false;

  Future<Query<Map<String, dynamic>>> _scopedQuery(
    String collection,
    Map<String, dynamic> profile,
  ) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(collection);
    final scope = Map<String, dynamic>.from(profile['scope'] ?? const {});
    if (scope['all'] == true) return query;
    final governorates = List<String>.from(scope['governorateIds'] ?? const []);
    final cities = List<String>.from(scope['cityIds'] ?? const []);
    final categories = List<String>.from(scope['categoryIds'] ?? const []);
    final groups = List<String>.from(scope['groupIds'] ?? const []);
    if (governorates.isEmpty && cities.isEmpty && categories.isEmpty && groups.isEmpty) {
      return query.where('__ya_baladi_no_scope__', isEqualTo: '__denied__');
    }
    if (governorates.isNotEmpty) query = query.where('governorateId', whereIn: governorates);
    if (cities.isNotEmpty) query = query.where('cityId', whereIn: cities);
    if (categories.isNotEmpty) query = query.where('category', whereIn: categories);
    if (groups.isNotEmpty) query = query.where('groupId', whereIn: groups);
    return query;
  }

  Future<int> _countScoped(String collection, Map<String, dynamic> profile, {String? field, dynamic value}) async {
    var query = await _scopedQuery(collection, profile);
    if (field != null) query = query.where(field, isEqualTo: value);
    final result = await query.count().get();
    return result.count ?? 0;
  }

  Future<String> _buildReport(Map<String, dynamic> profile) async {
    final values = <String, int>{
      'الأماكن': await _countScoped('places', profile),
      'الفعاليات المنشورة': await _countScoped('events', profile, field: 'isPublished', value: true),
      'العروض النشطة': await _countScoped('offers', profile, field: 'active', value: true),
      'المكافآت النشطة': await _countScoped('rewards', profile, field: 'active', value: true),
      'التقييمات': await _countScoped('ratings', profile),
    };
    final scope = Map<String, dynamic>.from(profile['scope'] ?? const {});
    return [
      'تقرير يا بلدي — التقرير التشغيلي الموحد',
      'تاريخ الإنشاء: ${DateTime.now().toLocal()}',
      scope['all'] == true ? 'النطاق: جميع البيانات المصرح بها' : 'النطاق: وفق تفويض الحساب',
      '',
      ...values.entries.map((e) => '${e.key}: ${e.value}'),
    ].join('\n');
  }

  Future<void> _loadReport() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = AuthService();
      final isAdmin = await auth.hasAdminClaim();
      final profile = await auth.getModeratorProfile();
      final permissions = List<String>.from(profile?['permissions'] ?? const []);
      bool can(String p) => isAdmin || permissions.contains('*') || permissions.contains(p);
      if (!can('reports.read')) throw StateError('لا تملك صلاحية مشاهدة التقارير.');
      final effectiveProfile = profile ?? {'scope': {'all': true}};
      final report = await _buildReport(effectiveProfile);
      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _canExport = can('reports.export');
        _canPrint = can('reports.print');
        _report = report;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() { super.initState(); _loadReport(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير'), backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, textAlign: TextAlign.center))
                : Column(children: [
                    Card(child: ListTile(
                      leading: const Icon(Icons.assessment_outlined),
                      title: Text(_isAdmin ? 'تقرير الأدمن' : 'تقرير المشرف'),
                      subtitle: const Text('التقرير يلتزم بصلاحيات الحساب ونطاقه.'),
                    )),
                    const SizedBox(height: 12),
                    Expanded(child: Card(child: SingleChildScrollView(padding: const EdgeInsets.all(18), child: SelectableText(_report)))),
                    const SizedBox(height: 12),
                    Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                      if (_canPrint) FilledButton.icon(
                        onPressed: () => printReport(title: 'تقرير يا بلدي', content: _report),
                        icon: const Icon(Icons.print_outlined), label: const Text('طباعة التقرير'),
                      ),
                      if (_canExport) OutlinedButton.icon(
                        onPressed: () => downloadReport(filename: 'ya_baladi_report.txt', content: _report),
                        icon: const Icon(Icons.download_outlined), label: const Text('تصدير التقرير'),
                      ),
                      OutlinedButton.icon(onPressed: _loadReport, icon: const Icon(Icons.refresh), label: const Text('تحديث')),
                    ]),
                  ]),
      ),
    );
  }
}
