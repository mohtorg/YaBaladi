// lib/features/admin/screens/admin_dashboard_screen.dart
//
// [v7.0 — 2026-10-21] — Refactored with pagination + stats controller
//   - ADDED: AdminStatsController (aggregate queries)
//   - ADDED: Pagination for places and users
//   - ADDED: ScrollController with infinite scroll
//   - REMOVED: All _PlaceDetailScreen logic (moved to its own file)
//   - USES: Common widgets, FirestoreUtils

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/firestore_utils.dart';
import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_stats_controller.dart';
import '../widgets/common_widgets.dart';
import 'add_place_screen.dart';
import 'import_excel_screen.dart';
import 'place_detail_screen.dart';
import 'place_statistics_screen.dart';
import 'user_statistics_screen.dart';
import 'review_statistics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;
    const pages = [
      _OverviewTab(),
      _PlacesTab(),
      _UsersTab(),
      _AuditLogsTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings,
                color: YaBaladiDesignTokens.primaryBlue),
            const SizedBox(width: 8),
            const Text(
              'لوحة تحكم يا بلدي',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: const [_UserProfileMenu()],
      ),
      body: isDesktop
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (i) =>
                      setState(() => _selectedIndex = i),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  selectedIconTheme: IconThemeData(
                    color: YaBaladiDesignTokens.primaryBlue,
                  ),
                  selectedLabelTextStyle: TextStyle(
                    color: YaBaladiDesignTokens.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('الكل'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.place_outlined),
                      selectedIcon: Icon(Icons.place),
                      label: Text('الأماكن'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people),
                      label: Text('المستخدمون'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.history_outlined),
                      selectedIcon: Icon(Icons.history),
                      label: Text('السجل'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            )
          : IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: !isDesktop
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (i) => setState(() => _selectedIndex = i),
              selectedItemColor: YaBaladiDesignTokens.primaryBlue,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard), label: 'الكل'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.place), label: 'الأماكن'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.people), label: 'المستخدمون'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.history), label: 'السجل'),
              ],
            )
          : null,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Overview Tab
// ═══════════════════════════════════════════════════════════════
class _OverviewTab extends StatefulWidget {
  const _OverviewTab();

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  late final AdminStatsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AdminStatsController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<AdminStatsController>(
        builder: (context, ctrl, _) {
          if (ctrl.loading && !ctrl.stats.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: ctrl.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'نظرة عامة شاملة',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على أي بطاقة لعرض التفاصيل',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: AdminKpiCard(
                          title: 'إجمالي الأماكن',
                          count: ctrl.stats.totalPlaces,
                          unit: 'مكان',
                          icon: Icons.place,
                          color: Colors.blue,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PlaceStatisticsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminKpiCard(
                          title: 'المستخدمون',
                          count: ctrl.stats.totalUsers,
                          unit: 'مستخدم',
                          icon: Icons.people,
                          color: Colors.green,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserStatisticsScreen(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AdminKpiCard(
                          title: 'التقييمات',
                          count: ctrl.stats.totalReviews,
                          unit: 'تقييم',
                          icon: Icons.star,
                          color: Colors.amber,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReviewStatisticsScreen(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminKpiCard(
                          title: 'أماكن تنتظر الموافقة',
                          count: ctrl.stats.unapprovedPlaces,
                          unit: 'مكان',
                          icon: Icons.pending_actions,
                          color: Colors.orange,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('انتقل إلى تبويب "الأماكن" لمراجعتها'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const _CategoryDistributionChart(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Category Distribution (still uses .limit(100) for demo)
// ═══════════════════════════════════════════════════════════════
class _CategoryDistributionChart extends StatelessWidget {
  const _CategoryDistributionChart();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('places')
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('خطأ في جلب البيانات');
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final places = snapshot.data!.docs;
        if (places.isEmpty) return const Text('لا توجد بيانات لعرضها.');

        final Map<String, int> categoryCounts = {};
        for (var doc in places) {
          final data = FirestoreUtils.dataOfSnapshot(doc);
          final cat = data['categoryId'] ?? data['category'] ?? 'other';
          categoryCounts[cat.toString()] =
              (categoryCounts[cat.toString()] ?? 0) + 1;
        }
        final sortedEntries = categoryCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final maxCount =
            sortedEntries.isNotEmpty && sortedEntries.first.value > 0
                ? sortedEntries.first.value
                : 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع الأماكن حسب التصنيف',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(
                        entry.key,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value / maxCount,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            YaBaladiDesignTokens.primaryBlue,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.value}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Places Tab — with Pagination
// ═══════════════════════════════════════════════════════════════
class _PlacesTab extends StatefulWidget {
  const _PlacesTab();

  @override
  State<_PlacesTab> createState() => _PlacesTabState();
}

class _PlacesTabState extends State<_PlacesTab> {
  static const int _pageSize = 20;

  final List<QueryDocumentSnapshot> _places = [];
  final ScrollController _scroll = ScrollController();
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize)
          .get();

      setState(() {
        _places.clear();
        _places.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _initialLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _initialLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _lastDoc == null) return;
    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('places')
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();

      setState(() {
        _places.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
        _hasMore = snapshot.docs.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إدارة الأماكن',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddPlaceScreen(),
                          ),
                        );
                        _loadInitial();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة مكان'),
                      style: FilledButton.styleFrom(
                        backgroundColor: YaBaladiDesignTokens.primaryBlue,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ImportExcelScreen(),
                          ),
                        );
                        _loadInitial();
                      },
                      icon: const Icon(Icons.upload_file, size: 18),
                      label: const Text('استيراد CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: YaBaladiDesignTokens.primaryBlue,
                        side: const BorderSide(
                            color: YaBaladiDesignTokens.primaryBlue),
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child:
            Text('❌ خطأ: $_error', style: const TextStyle(color: Colors.red)),
      );
    }
    if (_places.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد أماكن بعد. ابدأ بـ "إضافة مكان" أو "استيراد CSV".',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: ListView.builder(
        controller: _scroll,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _places.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _places.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final place = _places[index];
          final data = FirestoreUtils.dataOfSnapshot(place);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: const Icon(Icons.place, color: Colors.blue),
              ),
              title: Text(
                FirestoreUtils.stringOf(data, 'nameAr',
                    FirestoreUtils.stringOf(data, 'name', 'بدون اسم')),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              subtitle: Text(
                '${data['categoryId'] ?? data['category'] ?? '—'} • ${data['governorate'] ?? '—'}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlaceDetailScreen(placeId: place.id),
                  ),
                );
                _loadInitial();
              },
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Users Tab — with Pagination
// ═══════════════════════════════════════════════════════════════
class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  static const int _pageSize = 20;

  final List<QueryDocumentSnapshot> _users = [];
  final ScrollController _scroll = ScrollController();
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .limit(_pageSize)
          .get();
      setState(() {
        _users.clear();
        _users.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _initialLoading = false;
      });
    } catch (e) {
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore || _lastDoc == null) return;
    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .startAfterDocument(_lastDoc!)
          .limit(_pageSize)
          .get();
      setState(() {
        _users.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
        _hasMore = snapshot.docs.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return '';
    final parts = email.split('@');
    final name = parts[0];
    if (name.isEmpty) return '@${parts[1]}';
    if (name.length == 1) return '*@${parts[1]}';
    return '${name[0]}***@${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('إدارة المستخدمين',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: _initialLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadInitial,
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _users.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _users.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final user = _users[index];
                      final data = FirestoreUtils.dataOfSnapshot(user);
                      final role =
                          FirestoreUtils.stringOf(data, 'role', 'member');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: CircleAvatar(
                            backgroundImage: data['photoUrl'] != null
                                ? NetworkImage(data['photoUrl'].toString())
                                : null,
                            child: data['photoUrl'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            FirestoreUtils.stringOf(
                                data, 'displayName', 'مستخدم'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            _maskEmail(FirestoreUtils.stringOf(data, 'email')),
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Chip(
                            label: Text(role,
                                style: const TextStyle(fontSize: 10)),
                            backgroundColor: role == 'admin'
                                ? Colors.red.shade50
                                : Colors.grey.shade100,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onTap: () =>
                              _showUserRoleDialog(context, user.id, role),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showUserRoleDialog(
      BuildContext context, String userId, String currentRole) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تعديل الصلاحية'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['member', 'merchant', 'moderator', 'admin']
              .map((role) => RadioListTile<String>(
                    title: Text(role),
                    value: role,
                    groupValue: currentRole,
                    onChanged: (val) => Navigator.pop(c, val),
                  ))
              .toList(),
        ),
      ),
    );
    if (newRole != null && newRole != currentRole) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': newRole});
      _loadInitial();
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Audit Logs Tab
// ═══════════════════════════════════════════════════════════════
class _AuditLogsTab extends StatelessWidget {
  const _AuditLogsTab();

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '—';
    try {
      final date = (ts as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('سجل التدقيق',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('audit_logs')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(
                  child: Text('السجل فارغ أو حدث خطأ.'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final logs = snapshot.data!.docs;
              if (logs.isEmpty) {
                return const Center(child: Text('لا توجد سجلات بعد.'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = FirestoreUtils.dataOfSnapshot(logs[index]);
                  final action = FirestoreUtils.stringOf(log, 'action', '—');
                  final target = FirestoreUtils.stringOf(log, 'targetName',
                      FirestoreUtils.stringOf(log, 'targetId'));
                  final by =
                      FirestoreUtils.stringOf(log, 'performedBy', 'غير معروف');
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      leading: const Icon(Icons.history, color: Colors.grey),
                      title: Text('$action - $target',
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        'بواسطة: $by • ${_formatTimestamp(log['timestamp'])}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// User Profile Menu
// ═══════════════════════════════════════════════════════════════
class _UserProfileMenu extends StatelessWidget {
  const _UserProfileMenu();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage:
                auth.photoUrl.isNotEmpty ? NetworkImage(auth.photoUrl) : null,
            child: auth.photoUrl.isEmpty
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red, size: 20),
            onPressed: () => auth.signOut(),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
    );
  }
}
