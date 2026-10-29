// lib/features/admin/screens/admin_dashboard_screen.dart
//
// [v9.4 — 2026-10-28] — CODE REVIEW & CLEANUP:
//   - Removed unused `theme` variable in _OverviewTabState
//   - Merged _buildMoreItem + _buildMoreAction (95% duplicate)
//   - Replaced nested switch statements with switch expressions
//   - KEPT: all functionality, all classes, all behavior identical

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/firestore_utils.dart';
import '../../../models/category.dart';
import '../../../repositories/categories_repository.dart';
import '../../../theme/design_tokens.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../support/controllers/support_tickets_controller.dart';
import '../../support/screens/admin_support_screen.dart';
import '../controllers/admin_stats_controller.dart';
import '../widgets/add_edit_category_dialog.dart';
import '../widgets/common_widgets.dart';
import 'add_place_screen.dart';
import 'filters_management_screen.dart';
import 'import_excel_screen.dart';
import 'merchant_requests_screen.dart';
import 'place_detail_screen.dart';
import 'place_statistics_screen.dart';
import 'review_statistics_screen.dart';
import 'user_statistics_screen.dart';
import 'governorates_management_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_statistics_screen.dart';

// ═══════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    _OverviewTab(), // 0
    _PlacesTab(), // 1
    _CategoriesTab(), // 2
    FiltersManagementScreen(), // 3
    MerchantRequestsScreen(), // 4
    _UsersTab(), // 5
    GovernoratesManagementScreen(), // 6
    AdminSupportScreen(), // 7
    _AuditLogsTab(), // 8
  ];

  int get _bottomNavIndex => switch (_selectedIndex) {
        0 => 0,
        1 => 1,
        4 => 2,
        7 => 3,
        _ => 4,
      };

  void _onBottomNavTapped(int index) {
    if (index == 4) {
      _showMoreMenu();
      return;
    }
    setState(() => _selectedIndex = switch (index) {
          0 => 0,
          1 => 1,
          2 => 4,
          3 => 7,
          _ => 0,
        });
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('المزيد من الأدوات',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildMoreItem(
                        context, 'التصنيفات', Icons.category, Colors.blue, () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 2);
                    }),
                    _buildMoreItem(
                        context, 'الفلاتر', Icons.tune, Colors.purple, () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 3);
                    }),
                    _buildMoreItem(
                        context, 'المستخدمون', Icons.people, Colors.green, () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 5);
                    }),
                    _buildMoreItem(
                        context, 'المحافظات', Icons.map, Colors.orange, () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 6);
                    }),
                    _buildMoreItem(
                        context, 'السجل', Icons.history, Colors.blueGrey, () {
                      Navigator.pop(context);
                      setState(() => _selectedIndex = 8);
                    }),
                    _buildMoreItem(
                        context, 'الإحصائيات', Icons.analytics, Colors.teal,
                        () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminStatisticsScreen()),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ دالة واحدة للعنصر (بعد دمج `_buildMoreItem` و `_buildMoreAction`)
  Widget _buildMoreItem(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supportCount = context.watch<SupportTicketsController>().openCount;

    return StreamBuilder<int>(
      stream: FirebaseFirestore.instance
          .collection('merchant_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .map((s) => s.docs.length),
      initialData: 0,
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: theme.colorScheme.surface,
            elevation: 1,
            title: Row(
              children: [
                Icon(Icons.admin_panel_settings,
                    color: YaBaladiDesignTokens.primaryBlue),
                const SizedBox(width: 8),
                const Flexible(
                    child:
                        Text('لوحة التحكم', overflow: TextOverflow.ellipsis)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.blueGrey),
                tooltip: 'إعدادات الأدمن',
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AdminSettingsScreen())),
              ),
              const _UserProfileMenu(),
            ],
          ),
          body: IndexedStack(index: _selectedIndex, children: _pages),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _bottomNavIndex,
            onTap: _onBottomNavTapped,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: YaBaladiDesignTokens.primaryBlue,
            unselectedItemColor: theme.colorScheme.onSurfaceVariant,
            items: [
              const BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard), label: 'الرئيسية'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.place), label: 'الأماكن'),
              BottomNavigationBarItem(
                  icon: _BadgeIcon(icon: Icons.assignment, count: pendingCount),
                  label: 'التجار'),
              BottomNavigationBarItem(
                  icon: _BadgeIcon(
                      icon: Icons.support_agent, count: supportCount),
                  label: 'الدعم'),
              const BottomNavigationBarItem(
                  icon: Icon(Icons.apps), label: 'المزيد'),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ALERT BANNER
// ═══════════════════════════════════════════════════════════════
class _SmartAlertBanner extends StatelessWidget {
  const _SmartAlertBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_tickets')
          .where('status', isEqualTo: 'open')
          .snapshots(),
      builder: (context, supportSnap) {
        final supportCount = supportSnap.data?.docs.length ?? 0;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('merchant_requests')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, merchantSnap) {
            final merchantCount = merchantSnap.data?.docs.length ?? 0;

            if (supportCount == 0 && merchantCount == 0) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active,
                      color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'لديك مهام معلقة تتطلب انتباهك',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                    ),
                  ),
                  if (supportCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('$supportCount دعم',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  if (supportCount > 0 && merchantCount > 0)
                    const SizedBox(width: 6),
                  if (merchantCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12)),
                      child: Text('$merchantCount تجار',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BADGE ICON
// ═══════════════════════════════════════════════════════════════
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;

  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);

    return Badge(
      label: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      backgroundColor: Colors.red,
      child: Icon(icon),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// OVERVIEW TAB
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
    // ✅ تم حذف `final theme = Theme.of(context);` لأنه غير مستخدم
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
                  const _SmartAlertBanner(),
                  Row(
                    children: [
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
                                builder: (_) => const UserStatisticsScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                                builder: (_) => const PlaceStatisticsScreen()),
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
                                builder: (_) => const ReviewStatisticsScreen()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(child: _PendingMerchantKpiCard()),
                    ],
                  ),
                  const SizedBox(height: 24),
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
// PENDING MERCHANT KPI CARD
// ═══════════════════════════════════════════════════════════════
class _PendingMerchantKpiCard extends StatelessWidget {
  const _PendingMerchantKpiCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('merchant_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        return AdminKpiCard(
          title: 'طلبات التجار',
          count: count,
          unit: 'طلب',
          icon: Icons.assignment,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MerchantRequestsScreen()),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PLACES TAB
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

      if (!mounted) return;
      setState(() {
        _places.clear();
        _places.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _initialLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        _places.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
        _hasMore = snapshot.docs.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تعذّر تحميل المزيد: $e'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('إدارة الأماكن',
                  style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface)),
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
                                builder: (_) => const AddPlaceScreen()));
                        if (!mounted) return;
                        _loadInitial();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('إضافة مكان'),
                      style: FilledButton.styleFrom(
                        backgroundColor: YaBaladiDesignTokens.primaryBlue,
                        foregroundColor: theme.colorScheme.onPrimary,
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
                                builder: (_) => const ImportExcelScreen()));
                        if (!mounted) return;
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
        Expanded(child: _buildList(theme, textTheme)),
      ],
    );
  }

  Widget _buildList(ThemeData theme, TextTheme textTheme) {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('❌ خطأ: $_error',
            style:
                textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
      );
    }
    if (_places.isEmpty) {
      return Center(
        child: Text('لا توجد أماكن بعد. ابدأ بـ "إضافة مكان" أو "استيراد CSV".',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
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
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(Icons.place,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              title: Text(
                FirestoreUtils.stringOf(data, 'nameAr',
                    FirestoreUtils.stringOf(data, 'name', 'بدون اسم')),
                style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface),
              ),
              subtitle: Text(
                '${data['categoryId'] ?? data['category'] ?? '—'} • ${data['governorate'] ?? '—'}',
                style: textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              trailing: Icon(Icons.arrow_forward_ios,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => PlaceDetailScreen(placeId: place.id)));
                if (!mounted) return;
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
// CATEGORIES TAB
// ═══════════════════════════════════════════════════════════════
class _CategoriesTab extends StatefulWidget {
  const _CategoriesTab();

  @override
  State<_CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<_CategoriesTab> {
  final CategoriesRepository _repo = CategoriesRepository();
  final TextEditingController _searchController = TextEditingController();

  String _query = '';
  List<Category> _lastSnapshot = const [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Category> _filter(List<Category> all) {
    final q = _query.trim().toLowerCase();
    final result = all.where((c) {
      if (q.isEmpty) return true;
      return c.id.toLowerCase().contains(q) ||
          c.nameAr.contains(q) ||
          c.nameEn.toLowerCase().contains(q) ||
          c.iconName.toLowerCase().contains(q);
    }).toList();
    result.sort((a, b) => a.order.compareTo(b.order));
    return result;
  }

  int _nextOrder() {
    if (_lastSnapshot.isEmpty) return 1;
    return _lastSnapshot.map((c) => c.order).reduce((a, b) => a > b ? a : b) +
        1;
  }

  Future<void> _openAdd() async {
    final saved = await AddEditCategoryDialog.show(
      context,
      repository: _repo,
      suggestedOrder: _nextOrder(),
    );
    if (saved == true && mounted) {
      _snack('تم إنشاء التصنيف بنجاح', success: true);
    }
  }

  Future<void> _openEdit(Category cat) async {
    final saved = await AddEditCategoryDialog.show(context,
        category: cat, repository: _repo);
    if (saved == true && mounted) {
      _snack('تم تحديث التصنيف', success: true);
    }
  }

  Future<void> _toggleActive(Category cat) async {
    try {
      await _repo.update(cat.id, {'isActive': !cat.isActive});
    } catch (e) {
      if (mounted) _snack('فشل التحديث: $e');
    }
  }

  Future<void> _toggleFeatured(Category cat) async {
    try {
      await _repo.update(cat.id, {'isFeatured': !cat.isFeatured});
    } catch (e) {
      if (mounted) _snack('فشل التحديث: $e');
    }
  }

  Future<void> _delete(Category cat) async {
    if (cat.placesCount > 0) {
      _snack(
          'لا يمكن حذف "${cat.nameAr}" — يحتوي على ${cat.placesCount} مكان. عطّله بدلاً من ذلك.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
            'هل تريد حذف "${cat.nameAr}" نهائياً؟\nلا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('إلغاء')),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(c, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _repo.delete(cat.id);
      if (mounted) _snack('تم حذف التصنيف', success: true);
    } catch (e) {
      if (mounted) _snack('فشل الحذف: $e');
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
        duration: Duration(seconds: success ? 2 : 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('إدارة التصنيفات',
                        style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface)),
                  ),
                  FilledButton.icon(
                    onPressed: _openAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('تصنيف جديد'),
                    style: FilledButton.styleFrom(
                      backgroundColor: YaBaladiDesignTokens.primaryBlue,
                      foregroundColor: theme.colorScheme.onPrimary,
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'ابحث بالاسم أو المعرف...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'مسح',
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Category>>(
            stream: _repo.watchAll(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 12),
                        Text('تعذر تحميل التصنيفات',
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('${snapshot.error}',
                            style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }
              final all = snapshot.data ?? const <Category>[];
              _lastSnapshot = all;
              final filtered = _filter(all);

              if (all.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined,
                            size: 72, color: theme.colorScheme.outline),
                        const SizedBox(height: 12),
                        Text('لا توجد تصنيفات بعد',
                            style: textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('ابدأ بإنشاء أول تصنيف',
                            style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _openAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('إنشاء تصنيف'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 8),
                        Text('لا نتائج لـ "$_query"',
                            style: textTheme.bodyMedium,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 300));
                },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final cat = filtered[i];
                    return _CategoryRowCard(
                      category: cat,
                      onEdit: () => _openEdit(cat),
                      onToggleActive: () => _toggleActive(cat),
                      onToggleFeatured: () => _toggleFeatured(cat),
                      onDelete: () => _delete(cat),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY ROW CARD
// ═══════════════════════════════════════════════════════════════
class _CategoryRowCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onToggleFeatured;
  final VoidCallback onDelete;

  const _CategoryRowCard({
    required this.category,
    required this.onEdit,
    required this.onToggleActive,
    required this.onToggleFeatured,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = category.color;
    final icon = category.icon;
    final isActive = category.isActive;
    final isFeatured = category.isFeatured;
    final canDelete = category.placesCount == 0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isActive ? accent : accent.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(category.nameAr,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? null
                                      : theme.colorScheme.outline),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isFeatured) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star,
                              size: 16, color: Colors.amber.shade700),
                        ],
                      ],
                    ),
                    Text(category.nameEn,
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _miniChip(theme, Icons.format_list_numbered,
                            '#${category.order}'),
                        _miniChip(theme, Icons.place_outlined,
                            '${category.placesCount} مكان',
                            highlight: category.placesCount > 0),
                        _miniChip(theme, Icons.tag, category.id),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: isActive,
                    onChanged: (_) => onToggleActive(),
                    activeTrackColor: accent.withValues(alpha: 0.5),
                    activeThumbColor: accent,
                  ),
                  Text(isActive ? 'نشط' : 'معطل',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: isActive ? accent : theme.colorScheme.outline,
                          fontWeight: isActive ? FontWeight.bold : null)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'خيارات',
                onSelected: (v) {
                  switch (v) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'featured':
                      onToggleFeatured();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 10),
                      Text('تعديل'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'featured',
                    child: Row(children: [
                      Icon(isFeatured ? Icons.star : Icons.star_border,
                          size: 18, color: isFeatured ? Colors.amber : null),
                      const SizedBox(width: 10),
                      Text(isFeatured ? 'إلغاء التمييز' : 'تمييز'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: canDelete,
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          size: 18,
                          color: canDelete
                              ? Colors.red
                              : theme.colorScheme.outline),
                      const SizedBox(width: 10),
                      Text(
                          canDelete
                              ? 'حذف'
                              : 'لا يمكن الحذف (${category.placesCount})',
                          style:
                              TextStyle(color: canDelete ? Colors.red : null)),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(ThemeData theme, IconData icon, String label,
      {bool highlight = false}) {
    final bg = highlight
        ? Colors.blue.shade50
        : theme.colorScheme.surfaceContainerHighest;
    final fg =
        highlight ? Colors.blue.shade900 : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: fg, fontWeight: highlight ? FontWeight.bold : null)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// USERS TAB
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
      if (!mounted) return;
      setState(() {
        _users.clear();
        _users.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == _pageSize;
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _users.addAll(snapshot.docs);
        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : _lastDoc;
        _hasMore = snapshot.docs.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('تعذّر تحميل المزيد: $e'),
            behavior: SnackBarBehavior.floating),
      );
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('إدارة المستخدمين',
                style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
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
                      final isAdmin = role == 'admin';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: theme.colorScheme.outlineVariant),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: CircleAvatar(
                            backgroundImage: data['photoUrl'] != null
                                ? NetworkImage(data['photoUrl'].toString())
                                : null,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            child: data['photoUrl'] == null
                                ? Icon(Icons.person,
                                    color: theme.colorScheme.onSurfaceVariant)
                                : null,
                          ),
                          title: Text(
                              FirestoreUtils.stringOf(
                                  data, 'displayName', 'مستخدم'),
                              style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface)),
                          subtitle: Text(
                              _maskEmail(
                                  FirestoreUtils.stringOf(data, 'email')),
                              style: textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                          trailing: Chip(
                            label: Text(role,
                                style: textTheme.labelSmall?.copyWith(
                                    color: isAdmin
                                        ? theme.colorScheme.onErrorContainer
                                        : theme.colorScheme.onSurfaceVariant)),
                            backgroundColor: isAdmin
                                ? theme.colorScheme.errorContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            side: BorderSide(
                                color: isAdmin
                                    ? theme.colorScheme.error
                                        .withValues(alpha: 0.4)
                                    : theme.colorScheme.outlineVariant),
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
    final messenger = ScaffoldMessenger.of(context);
    final newRole = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تعديل الصلاحية'),
        content: RadioGroup<String>(
          groupValue: currentRole,
          onChanged: (val) => Navigator.pop(c, val),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['member', 'merchant', 'moderator', 'admin']
                .map((role) =>
                    RadioListTile<String>(title: Text(role), value: role))
                .toList(),
          ),
        ),
      ),
    );
    if (newRole == null || newRole == currentRole) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': newRole});
      if (!mounted) return;
      messenger
          .showSnackBar(const SnackBar(content: Text('تم تحديث الصلاحية')));
      await _loadInitial();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('تعذّر تحديث الصلاحية: ${e.message ?? e.code}')),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// AUDIT LOGS TAB
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text('سجل التدقيق',
                style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface)),
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
                return Center(
                  child: Text('السجل فارغ أو حدث خطأ.',
                      style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final logs = snapshot.data!.docs;
              if (logs.isEmpty) {
                return Center(
                  child: Text('لا توجد سجلات بعد.',
                      style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                );
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
                    color: theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      leading: Icon(Icons.history,
                          color: theme.colorScheme.onSurfaceVariant),
                      title: Text('$action - $target',
                          style: textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.onSurface)),
                      subtitle: Text(
                          'بواسطة: $by • ${_formatTimestamp(log['timestamp'])}',
                          style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
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
// USER PROFILE MENU
// ═══════════════════════════════════════════════════════════════
class _UserProfileMenu extends StatelessWidget {
  const _UserProfileMenu();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();
    final photoUrl = auth.photoUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                ? NetworkImage(photoUrl)
                : null,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: (photoUrl == null || photoUrl.isEmpty)
                ? Icon(Icons.person,
                    size: 16, color: theme.colorScheme.onSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.error, size: 20),
            onPressed: () => auth.signOut(),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
    );
  }
}
