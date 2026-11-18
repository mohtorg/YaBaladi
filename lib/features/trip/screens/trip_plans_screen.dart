// lib/features/trip/screens/trip_plans_screen.dart
//
// [v6.2 - ASYNC GAP FIX]
//   - FIXED: `context.read<TripPlansController>()` was called after an `await`.
//            Now captured before `showDialog`.
//   - FIXED: Added braces to `if` statements in `_arabicStops` for linter compliance.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/trip_plan.dart';
import '../controllers/trip_plans_controller.dart';

class TripPlansScreen extends StatefulWidget {
  const TripPlansScreen({super.key});

  @override
  State<TripPlansScreen> createState() => _TripPlansScreenState();
}

class _TripPlansScreenState extends State<TripPlansScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      if (auth.isLoggedIn) {
        context.read<TripPlansController>().load(auth.uid);
      }
    });
  }

  /// Arabic pluralization for "X stops".
  String _arabicStops(int n) {
    if (n == 1) {
      return 'محطة واحدة';
    }
    if (n == 2) {
      return 'محطتان';
    }
    if (n >= 3 && n <= 10) {
      return '$n محطات';
    }
    return '$n محطة';
  }

  Future<void> _deleteTrip(TripPlan trip) async {
    final messenger = ScaffoldMessenger.of(context);
    // ✅ Fix: Capture controller before the async gap (showDialog)
    final ctrl = context.read<TripPlansController>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'حذف الرحلة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذه الرحلة نهائياً؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ctrl.delete(trip.id);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'تم حذف الرحلة بنجاح'
              : 'فشل الحذف: ${ctrl.error ?? "خطأ غير معروف"}',
        ),
        backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final ctrl = context.watch<TripPlansController>();

    if (!auth.isLoggedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'رحلاتي',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                const Text(
                  'يرجى تسجيل الدخول لعرض رحلاتك',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'رحلاتي',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt, color: Colors.white),
            tooltip: 'رحلة جديدة',
            onPressed: () => context.push('/trips/planner'),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(child: _buildBody(ctrl, auth.uid)),
    );
  }

  Widget _buildBody(TripPlansController ctrl, String uid) {
    // ─── Loading ───
    if (ctrl.isLoading && ctrl.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0EA5E9)),
      );
    }

    // ─── Error ───
    if (ctrl.hasError && ctrl.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: Color(0xFFEF4444)),
              const SizedBox(height: 16),
              const Text(
                'تعذّر تحميل الرحلات',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                ctrl.error ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => ctrl.load(uid, force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9)),
              ),
            ],
          ),
        ),
      );
    }

    // ─── Empty ───
    final allTrips = ctrl.plans;
    if (allTrips.isEmpty) return _buildEmptyState();

    // ─── Filter ───
    final filtered = _filter == 'all'
        ? allTrips
        : allTrips.where((t) => t.status.code == _filter).toList();

    return Column(
      children: [
        // ─── Filter chips ───
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'الكل', allTrips.length),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'draft',
                  'مسودة',
                  allTrips.where((t) => t.status == TripStatus.draft).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'active',
                  'نشطة',
                  allTrips.where((t) => t.status == TripStatus.active).length,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'completed',
                  'مكتملة',
                  allTrips
                      .where((t) => t.status == TripStatus.completed)
                      .length,
                ),
              ],
            ),
          ),
        ),

        // ─── Trips list ───
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF0EA5E9),
            backgroundColor: const Color(0xFF1E293B),
            onRefresh: () => ctrl.load(uid, force: true),
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: Text(
                            'لا توجد رحلات في هذه الحالة',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final trip = filtered[index];
                      return _TripCard(
                        trip: trip,
                        stopsLabel: _arabicStops(trip.stopCount),
                        onDelete: () => _deleteTrip(trip),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label, int count) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(
        count > 0 ? '$label ($count)' : label,
        style: const TextStyle(fontSize: 12),
      ),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: const Color(0xFF0EA5E9),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      side: BorderSide(
        color: selected
            ? const Color(0xFF0EA5E9)
            : Colors.white.withValues(alpha: 0.1),
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.white70,
        fontWeight: selected ? FontWeight.bold : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 100,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'لا توجد رحلات محفوظة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ التخطيط لرحلتك القادمة، واكتشف أجمل الأماكن في محافظتك.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/trips/planner'),
              icon: const Icon(Icons.explore),
              label: const Text(
                'إنشاء رحلة جديدة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(250, 55),
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Trip Card (Dark)
// ═══════════════════════════════════════════════════════════════

class _TripCard extends StatelessWidget {
  final TripPlan trip;
  final String stopsLabel;
  final VoidCallback onDelete;

  const _TripCard({
    required this.trip,
    required this.stopsLabel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (trip.status) {
      TripStatus.active => const Color(0xFF10B981),
      TripStatus.completed => const Color(0xFF0EA5E9),
      TripStatus.cancelled => const Color(0xFFEF4444),
      TripStatus.draft => const Color(0xFFF59E0B),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/trips/detailed/${trip.id}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        trip.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        trip.status.labelAr,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Text(
                      trip.dateRangeLabel,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.timer_outlined,
                        size: 14, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Text(
                      trip.durationType.labelAr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Text(
                      stopsLabel,
                      style: const TextStyle(
                        color: Color(0xFF0EA5E9),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.directions_car_outlined,
                        size: 16, color: Color(0xFF0EA5E9)),
                    const SizedBox(width: 6),
                    Text(
                      trip.transportMode.labelAr,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Color(0xFFEF4444), size: 20),
                      onPressed: onDelete,
                      tooltip: 'حذف الرحلة',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
