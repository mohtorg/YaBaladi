// lib/features/trip/screens/trip_overview_screen.dart
//
// [v1.3.2 — 2026-10-19] — Wave 5.5.1: إصلاح dead null-checks + off-by-one
//   - FIX [71:35]: plan.title غير nullable ⇒ استبدال ?? بـ isEmpty check
//   - FIX [107:50]: plan.stopsByDay[i] غير nullable ⇒ إزالة ?? const []
//   - FIX منطقي (خطير): stopsByDay 0-indexed، safeDay 1-indexed
//          ⇒ dayIndex = safeDay - 1 (كان يعرض اليوم الخطأ أو يرمي RangeError)
//   - ADD: حماية totalDays == 0 (clamp(1, 0) يرمي ArgumentError)
//   - ADD: حماية stopsByDay.isEmpty (Empty State + تجنب RangeError)
//   - ADD: حماية dayIndex ضد stopsByDay.length < totalDays
//   - KEPT: زر "عرض التفاصيل" في AppBar + FAB + Day selector
//
// [v1.3.1 — 2026-10-19] — import path + TimelineView signature
// [v1.3   — 2026-10-19] — Wave 5.5.1: زر "عرض التفاصيل"

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../models/trip_plan.dart';
import '../widgets/timeline/timeline_view.dart';

class TripOverviewScreen extends StatefulWidget {
  final TripPlan plan;

  const TripOverviewScreen({super.key, required this.plan});

  @override
  State<TripOverviewScreen> createState() => _TripOverviewScreenState();
}

class _TripOverviewScreenState extends State<TripOverviewScreen> {
  /// اليوم المختار — **1-indexed** (يوم 1، يوم 2، ...)
  /// يُقابل `stopsByDay[safeDay - 1]` (0-indexed)
  int _selectedDay = 1;

  // ── الانتقال إلى الشاشة التفصيلية ──
  void _openDetailed() {
    final id = widget.plan.id;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا يمكن عرض التفاصيل: معرف الرحلة غير متوفر'),
        ),
      );
      return;
    }
    // context.push → Future<T?> لكن fire-and-forget مقبول:
    // المستخدم ينتقل فورًا؛ لا حاجة لانتظار اكتمال التنقل.
    context.push(RoutePaths.tripDetailedPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final theme = Theme.of(context);

    // ── محددات آمنة ──
    final totalDays = plan.totalDays;
    final hasStops = plan.stopsByDay.isNotEmpty;

    // [v1.3.2] clamp(1, 0) يرمي ArgumentError ⇒ guard totalDays > 0
    final safeDay = totalDays > 0 ? _selectedDay.clamp(1, totalDays) : 1;

    // [v1.3.2] stopsByDay 0-indexed، safeDay 1-indexed ⇒ dayIndex = safeDay - 1
    //          + حماية ضد stopsByDay.length < totalDays
    final dayIndex =
        hasStops ? (safeDay - 1).clamp(0, plan.stopsByDay.length - 1) : 0;

    // [v1.3.2] title غير nullable ⇒ isEmpty بدل ??
    final displayTitle = plan.title.isEmpty ? 'رحلتي إلى بورسعيد' : plan.title;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملخص الرحلة'),
        actions: [
          // ← زر "عرض التفاصيل" (Wave 5.5.1)
          IconButton(
            tooltip: 'عرض التفاصيل',
            icon: const Icon(Icons.article_outlined),
            onPressed: _openDetailed,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Header: عنوان + عدد الأيام ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayTitle,
                    style: theme.textTheme.titleLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$totalDays أيام',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),

          // ── Day selector (فقط إذا > 1 يوم + توجد محطات) ──
          if (totalDays > 1 && hasStops)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: totalDays,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final day = i + 1;
                  final selected = day == safeDay;
                  return ChoiceChip(
                    label: Text('اليوم $day'),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDay = day),
                  );
                },
              ),
            ),

          // ── Timeline أو Empty State ──
          Expanded(
            child: hasStops
                ? TimelineView(
                    stops: plan.stopsByDay[dayIndex],
                    transportMode: plan.transportMode,
                  )
                : _EmptyStopsView(theme: theme),
          ),
        ],
      ),

      // ← زر عائم بديل للوصول السريع (Wave 5.5.1)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDetailed,
        icon: const Icon(Icons.timeline),
        label: const Text('عرض التفاصيل'),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE — رحلة بلا محطات
// ═══════════════════════════════════════════════════════════════

class _EmptyStopsView extends StatelessWidget {
  const _EmptyStopsView({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد محطات في هذه الرحلة',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'قد تكون الخطة فارغة أو لم تُحفظ بعد',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
