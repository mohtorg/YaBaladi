// lib/features/admin/screens/audit_log_management_screen.dart
// [v3.0.1 — LINTER FIX + FULL SYSTEM EVENT LOGGING]
//   - FIXED: Unused 'admin' variable in _handleAction.
//   - ADDED: logSystemEvent() for archive, unarchive, soft delete, restore, hard delete.
//   - KEPT: All v3.0.0 features (4 tabs, stats, batch clear).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/audit_log_service.dart';
import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';

class AuditLogManagementScreen extends StatefulWidget {
  const AuditLogManagementScreen({super.key});

  @override
  State<AuditLogManagementScreen> createState() =>
      _AuditLogManagementScreenState();
}

class _AuditLogManagementScreenState extends State<AuditLogManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'all';
  String _filterSeverity = 'all';

  // ─── الإحصائيات ───
  bool _loadingStats = true;
  int _totalLogs = 0;
  int _todayLogs = 0;
  int _criticalLogs = 0;
  int _adminLogs = 0;
  int _moderatorLogs = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
    _searchCtrl.addListener(() {
      if (mounted) {
        setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    if (mounted) setState(() => _loadingStats = true);
    try {
      final fs = FirebaseFirestore.instance.collection('audit_logs');
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // نستثني السجلات المحذوفة من الإحصائيات
      final totalCount =
          await fs.where('isDeleted', isEqualTo: false).count().get();
      final todayCount = await fs
          .where('isDeleted', isEqualTo: false)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .count()
          .get();

      final recentSnap = await fs
          .where('isDeleted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      int critical = 0;
      int admin = 0;
      int moderator = 0;

      for (final doc in recentSnap.docs) {
        final data = doc.data();
        final severity = (data['severity'] ?? 'medium').toString();
        final role = (data['actorRole'] ?? 'admin').toString();

        if (severity == 'critical') critical++;
        if (role == 'moderator') {
          moderator++;
        } else {
          admin++;
        }
      }

      if (mounted) {
        setState(() {
          _totalLogs = totalCount.count ?? 0;
          _todayLogs = todayCount.count ?? 0;
          _criticalLogs = critical;
          _adminLogs = admin;
          _moderatorLogs = moderator;
          _loadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('إدارة سجل التدقيق',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white),
            tooltip: 'إفراغ السجل بالكامل',
            onPressed: _confirmClearAll,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'تحديث الإحصائيات',
            onPressed: () {
              _loadStatistics();
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'السجلات'),
            Tab(icon: Icon(Icons.archive), text: 'الأرشيف'),
            Tab(icon: Icon(Icons.delete_outline), text: 'سلة المهملات'),
            Tab(icon: Icon(Icons.analytics), text: 'الإحصائيات'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogsTab(isArchive: false, isTrash: false),
          _buildLogsTab(isArchive: true, isTrash: false),
          _buildLogsTab(isArchive: false, isTrash: true),
          _buildStatsTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TABS 1, 2, 3: LOGS / ARCHIVE / TRASH
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLogsTab({required bool isArchive, required bool isTrash}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الأدمن أو المكان أو الإجراء...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterRole,
                      decoration: const InputDecoration(
                        labelText: 'الصلاحية',
                        isDense: true,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('الكل')),
                        DropdownMenuItem(value: 'admin', child: Text('أدمن')),
                        DropdownMenuItem(
                            value: 'moderator', child: Text('مشرف')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _filterRole = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _filterSeverity,
                      decoration: const InputDecoration(
                        labelText: 'الأهمية',
                        isDense: true,
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('الكل')),
                        DropdownMenuItem(value: 'critical', child: Text('حرج')),
                        DropdownMenuItem(value: 'high', child: Text('عالي')),
                        DropdownMenuItem(value: 'medium', child: Text('متوسط')),
                        DropdownMenuItem(value: 'low', child: Text('منخفض')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _filterSeverity = val);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('audit_logs')
                .where('isArchived', isEqualTo: isArchive)
                .where('isDeleted', isEqualTo: isTrash)
                .orderBy('timestamp', descending: true)
                .limit(200)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                    child: Text('خطأ: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)));
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // الفلترة محلياً (البحث)
              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final role = (data['actorRole'] ?? 'admin').toString();
                final severity = (data['severity'] ?? 'medium').toString();

                if (_filterRole != 'all' && role != _filterRole) return false;
                if (_filterSeverity != 'all' && severity != _filterSeverity) {
                  return false;
                }

                if (_searchQuery.isNotEmpty) {
                  final searchable = [
                    data['performedBy'] ?? '',
                    data['action'] ?? '',
                    data['targetName'] ?? '',
                    data['details'] ?? '',
                  ].join(' ').toLowerCase();
                  if (!searchable.contains(_searchQuery)) return false;
                }
                return true;
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          isTrash
                              ? Icons.delete_outline
                              : isArchive
                                  ? Icons.archive
                                  : Icons.history,
                          size: 72,
                          color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                          isTrash
                              ? 'سلة المهملات فارغة'
                              : isArchive
                                  ? 'الأرشيف فارغ'
                                  : 'لا توجد سجلات مطابقة',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final log = docs[index].data() as Map<String, dynamic>;
                  final logId = docs[index].id;
                  return _buildLogCard(log, logId, isArchive, isTrash);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLogCard(
      Map<String, dynamic> log, String logId, bool isArchive, bool isTrash) {
    final severity = (log['severity'] ?? 'medium').toString();
    final severityColor = _getSeverityColor(severity);
    final action = log['action'] ?? '—';
    final target = log['targetName'] ?? '—';
    final actorName = log['performedBy'] ?? 'غير معروف';
    final actorRole = (log['actorRole'] ?? 'admin').toString() == 'moderator'
        ? 'مشرف'
        : 'أدمن';
    final details = log['details'] ?? '';
    final timestamp = _formatTimestamp(log['timestamp']);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            BorderSide(color: severityColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showLogDetails(log),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getSeverityLabel(severity),
                      style: TextStyle(
                        fontSize: 10,
                        color: severityColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      action,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (val) =>
                        _handleAction(val, logId, isArchive, isTrash),
                    itemBuilder: (ctx) => [
                      if (!isArchive && !isTrash) ...[
                        const PopupMenuItem(
                          value: 'archive',
                          child: Row(children: [
                            Icon(Icons.archive, size: 18),
                            SizedBox(width: 8),
                            Text('أرشفة')
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف', style: TextStyle(color: Colors.red))
                          ]),
                        ),
                      ],
                      if (isArchive) ...[
                        const PopupMenuItem(
                          value: 'unarchive',
                          child: Row(children: [
                            Icon(Icons.unarchive, size: 18),
                            SizedBox(width: 8),
                            Text('استعادة')
                          ]),
                        ),
                      ],
                      if (isTrash) ...[
                        const PopupMenuItem(
                          value: 'restore',
                          child: Row(children: [
                            Icon(Icons.restore, size: 18, color: Colors.green),
                            SizedBox(width: 8),
                            Text('استعادة',
                                style: TextStyle(color: Colors.green))
                          ]),
                        ),
                        const PopupMenuItem(
                          value: 'hard_delete',
                          child: Row(children: [
                            Icon(Icons.delete_forever,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('حذف نهائي',
                                style: TextStyle(color: Colors.red))
                          ]),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                target,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (details.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  details,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('$actorName ($actorRole)',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time,
                      size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(timestamp,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── تنفيذ إجراءات السجل ───
  Future<void> _handleAction(
      String action, String logId, bool isArchive, bool isTrash) async {
    final admin = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (action == 'archive') {
        await AuditLogService.archiveLog(logId);
        await AuditLogService.logSystemEvent(
          action: 'أرشفة سجل تدقيق',
          adminName: admin.displayName,
          details: 'معرف السجل: $logId',
        );
        messenger.showSnackBar(const SnackBar(
            content: Text('تمت الأرشفة'), backgroundColor: Colors.green));
      } else if (action == 'unarchive') {
        await AuditLogService.unarchiveLog(logId);
        await AuditLogService.logSystemEvent(
          action: 'استعادة سجل من الأرشيف',
          adminName: admin.displayName,
          details: 'معرف السجل: $logId',
        );
        messenger.showSnackBar(const SnackBar(
            content: Text('تمت الاستعادة من الأرشيف'),
            backgroundColor: Colors.green));
      } else if (action == 'delete') {
        await AuditLogService.softDeleteLog(logId);
        await AuditLogService.logSystemEvent(
          action: 'حذف سجل تدقيق (ناعم)',
          adminName: admin.displayName,
          details: 'معرف السجل: $logId',
        );
        messenger.showSnackBar(const SnackBar(
            content: Text('تم النقل لسلة المهملات'),
            backgroundColor: Colors.orange));
      } else if (action == 'restore') {
        await AuditLogService.restoreLog(logId);
        await AuditLogService.logSystemEvent(
          action: 'استعادة سجل من سلة المهملات',
          adminName: admin.displayName,
          details: 'معرف السجل: $logId',
        );
        messenger.showSnackBar(const SnackBar(
            content: Text('تمت الاستعادة'), backgroundColor: Colors.green));
      } else if (action == 'hard_delete') {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('حذف نهائي'),
            content: const Text(
                'هل أنت متأكد؟ لا يمكن التراجع عن هذا الإجراء مطلقاً.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('إلغاء')),
              FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('حذف نهائي')),
            ],
          ),
        );
        if (confirm == true) {
          await AuditLogService.hardDeleteLog(logId);
          await AuditLogService.logSystemEvent(
            action: 'حذف سجل تدقيق نهائي',
            adminName: admin.displayName,
            details: 'معرف السجل: $logId',
          );
          if (mounted) {
            messenger.showSnackBar(const SnackBar(
                content: Text('تم الحذف النهائي'),
                backgroundColor: Colors.red));
          }
        }
      }
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  // ─── إفراغ السجل بالكامل ───
  Future<void> _confirmClearAll() async {
    final admin = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final textCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
          SizedBox(width: 8),
          Text('إفراغ السجل')
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'سيتم نقل جميع السجلات النشطة إلى سلة المهملات. اكتب "تأكيد" للمتابعة.'),
            const SizedBox(height: 16),
            TextField(
              controller: textCtrl,
              decoration: const InputDecoration(
                hintText: 'اكتب تأكيد هنا...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (textCtrl.text.trim() == 'تأكيد') {
                Navigator.pop(c, true);
              } else {
                messenger.showSnackBar(const SnackBar(
                    content: Text('كلمة التأكيد غير صحيحة'),
                    backgroundColor: Colors.red));
              }
            },
            child: const Text('إفراغ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final count = await AuditLogService.clearAllLogs();
      if (mounted) {
        await AuditLogService.logSystemEvent(
          action: 'إفراغ سجل التدقيق بالكامل',
          adminName: admin.displayName,
          details: 'تم نقل $count سجل إلى سلة المهملات.',
        );
        messenger.showSnackBar(SnackBar(
            content: Text('تم إفراغ السجل ($count سجل)'),
            backgroundColor: Colors.green));
        _loadStatistics();
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 4: STATISTICS
  // ═══════════════════════════════════════════════════════════════
  Widget _buildStatsTab() {
    if (_loadingStats) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadStatistics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatCard(
            title: 'إجمالي السجلات النشطة',
            value: _totalLogs,
            color: Colors.blue,
            icon: Icons.history,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'سجلات اليوم',
                  value: _todayLogs,
                  color: Colors.green,
                  icon: Icons.today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'أحداث حرجة',
                  value: _criticalLogs,
                  color: Colors.red,
                  icon: Icons.warning_amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('توزيع السجلات حسب الصلاحية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildRoleBar('أدمن', _adminLogs, _totalLogs, Colors.blue),
          _buildRoleBar('مشرف', _moderatorLogs, _totalLogs, Colors.purple),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'ملاحظة: الإحصائيات محسوبة من آخر 500 سجل نشط (لا تشمل الأرشيف أو سلة المهملات).',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ───
  void _showLogDetails(Map<String, dynamic> log) {
    final severity = (log['severity'] ?? 'medium').toString();
    final actorRole = (log['actorRole'] ?? 'admin').toString() == 'moderator'
        ? 'مشرف'
        : 'أدمن';

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.security, color: Colors.blue),
          SizedBox(width: 8),
          Text('تفاصيل السجل', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الإجراء', log['action'] ?? '—'),
              _buildDetailRow('الفاعل', log['performedBy'] ?? '—'),
              _buildDetailRow('الصلاحية', actorRole),
              _buildDetailRow('UID الفاعل', log['actorId'] ?? '—'),
              _buildDetailRow('الهدف', log['targetName'] ?? '—'),
              _buildDetailRow('الأهمية', _getSeverityLabel(severity)),
              if ((log['details'] ?? '').isNotEmpty)
                _buildDetailRow('التفاصيل', log['details']),
              _buildDetailRow('الوقت', _formatTimestamp(log['timestamp'])),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label:',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text('$value',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBar(String label, int count, int total, Color color) {
    final ratio = total > 0 ? (count / total).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Text('$count ($percent%)',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.blue.shade700;
      case 'low':
        return Colors.green.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getSeverityLabel(String severity) {
    switch (severity) {
      case 'critical':
        return 'حرج';
      case 'high':
        return 'عالي';
      case 'medium':
        return 'متوسط';
      case 'low':
        return 'منخفض';
      default:
        return 'عادي';
    }
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '—';
    try {
      final date = (ts as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }
}
