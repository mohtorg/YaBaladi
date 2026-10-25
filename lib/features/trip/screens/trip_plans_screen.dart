// lib/features/trip/screens/trip_plans_screen.dart
//
// [v1.0 — 2026-10-23] — Restored as the trips-tab root (TripPlansScreen)
//   - FIX: الملف كان نسخة طبق الأصل من trip_planner_screen.dart (يعرّف
//          TripPlannerScreen)، بينما app_router.dart يستدعي TripPlansScreen
//          ⇒ خطأ ترجمة. أصبح الملف يعرّف TripPlansScreen: قائمة رحلات المستخدم
//          (النشطة / المكتملة) لتبويب «رحلتي» (RoutePaths.trips).
//   - FIX: زر «خطط رحلة جديدة» في الحالة الفارغة كان يستدعي Navigator.pop()
//          وهو بلا أثر في جذر التبويب ⇒ صار يفتح المعالج RoutePaths.tripPlanner.
//   - KEPT: بقية الواجهة والسلوك كما في MyTripsScreen دون تغيير.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/trip_plan.dart';
import '../controllers/trip_plans_controller.dart';
import '../widgets/trip_card.dart';
import 'trip_overview_screen.dart';
import 'trip_summary_screen.dart';

class TripPlansScreen extends StatefulWidget {
  const TripPlansScreen({super.key});

  @override
  State<TripPlansScreen> createState() => _TripPlansScreenState();
}

class _TripPlansScreenState extends State<TripPlansScreen> {
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

  void _openTrip(TripPlan trip) {
    // ✅ Wave 5.4: افتح الشاشة التفصيلية (Timeline بالساعات)
    if (trip.id.isNotEmpty) {
      unawaited(context.push(RoutePaths.tripDetailedPath(trip.id)));
      return;
    }

    // fallback نادر — عند غياب id
    final targetScreen = trip.status == TripStatus.completed
        ? TripSummaryScreen(plan: trip)
        : TripOverviewScreen(plan: trip);
    unawaited(
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => targetScreen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ctrl = context.watch<TripPlansController>();
    final auth = context.watch<AuthController>();
    final uid = auth.uid;
    final signedIn = auth.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رحلاتي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'تحديث',
            onPressed: signedIn ? () => ctrl.load(uid, force: true) : null,
          ),
        ],
      ),
      body: _buildBody(ctrl, uid, signedIn, theme),
    );
  }

  Widget _buildBody(
    TripPlansController ctrl,
    String uid,
    bool signedIn,
    ThemeData theme,
  ) {
    // ─── غير مسجل الدخول (الزائر uid == 'guest') ───
    if (!signedIn) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 96,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'سجل الدخول لعرض رحلاتك',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ─── Loading ───
    if (ctrl.isLoading && ctrl.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // ─── Error ───
    if (ctrl.hasError && ctrl.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'تعذّر تحميل الرحلات',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                ctrl.error ?? '',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ctrl.load(uid, force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    // ─── Empty ───
    if (ctrl.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.map_outlined,
                size: 96,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'لا توجد رحلات بعد',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'خطط رحلتك الأولى الآن!',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () =>
                    unawaited(context.push(RoutePaths.tripPlanner)),
                icon: const Icon(Icons.add),
                label: const Text('خطط رحلة جديدة'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ─── List ───
    final activeTrips = ctrl.activePlans;
    final completedTrips = ctrl.completedPlans;

    return RefreshIndicator(
      onRefresh: () => ctrl.load(uid, force: true),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (activeTrips.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.play_circle_outline,
              title: 'الرحلات النشطة',
              count: activeTrips.length,
            ),
            ...activeTrips.map(
              (trip) => TripCard(
                trip: trip,
                onTap: () => _openTrip(trip),
              ),
            ),
          ],
          if (completedTrips.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
              icon: Icons.history,
              title: 'الرحلات المكتملة',
              count: completedTrips.length,
            ),
            ...completedTrips.map(
              (trip) => TripCard(
                trip: trip,
                onTap: () => _openTrip(trip),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.count,
  });

  final IconData icon;
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
