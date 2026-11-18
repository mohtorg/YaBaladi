// lib/features/trip/screens/my_trips_screen.dart
//
// [v2.0 - DARK THEME CONSISTENCY]
//   - UPDATED: Dark theme (#0F172A) matching the entire trip flow.
//   - FIXED: "خطط رحلة جديدة" now navigates to planner via GoRouter
//     instead of Navigator.pop (which could exit the app in tab context).
//   - IMPROVED: Empty state, error state, and section headers restyled.
//   - KEPT: Auth check, controller wiring, and navigation logic.

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

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
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
    if (trip.id.isNotEmpty) {
      unawaited(context.push(RoutePaths.tripDetailedPath(trip.id)));
      return;
    }

    // Fallback (rare case: missing id)
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
    final ctrl = context.watch<TripPlansController>();
    final auth = context.watch<AuthController>();
    final uid = auth.uid;
    final signedIn = auth.isLoggedIn;

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
            icon: const Icon(Icons.refresh, color: Colors.white70),
            tooltip: 'تحديث',
            onPressed: signedIn ? () => ctrl.load(uid, force: true) : null,
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(ctrl, uid, signedIn),
      ),
    );
  }

  Widget _buildBody(
    TripPlansController ctrl,
    String uid,
    bool signedIn,
  ) {
    // ─── Guest state ───
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
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'سجل الدخول لعرض رحلاتك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
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
              const Icon(
                Icons.cloud_off,
                size: 64,
                color: Color(0xFFEF4444),
              ),
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
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ctrl.load(uid, force: true),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                ),
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
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد رحلات بعد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'خطط رحلتك الأولى الآن!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  // ✅ GoRouter: explicit route, works from tab context.
                  context.push('/trips/planner');
                },
                icon: const Icon(Icons.add),
                label: const Text('خطط رحلة جديدة'),
                style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
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
      color: const Color(0xFF0EA5E9),
      backgroundColor: const Color(0xFF1E293B),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (activeTrips.isNotEmpty) ...[
            const _SectionHeader(
              icon: Icons.play_circle_outline,
              title: 'الرحلات النشطة',
              count: 0,
            ),
            ...activeTrips.map((trip) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TripCard(
                    trip: trip,
                    onTap: () => _openTrip(trip),
                  ),
                )),
          ],
          if (completedTrips.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
              icon: Icons.history,
              title: 'الرحلات المكتملة',
              count: completedTrips.length,
            ),
            ...completedTrips.map((trip) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TripCard(
                    trip: trip,
                    onTap: () => _openTrip(trip),
                  ),
                )),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0EA5E9)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0EA5E9),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
