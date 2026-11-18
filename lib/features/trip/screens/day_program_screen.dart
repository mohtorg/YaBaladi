// lib/features/trip/screens/day_program_screen.dart
//
// [v3.0 - DARK THEME CONSISTENCY]
//   - UPDATED: Dark theme (#0F172A) matching Planner/Overview/ActiveStop.
//   - UPDATED: Glassmorphism timeline cards with subtle borders.
//   - UPDATED: Animated progress bar and visited state transitions.
//   - FIXED: Timeline connector now visible on dark background.
//   - KEPT: All progress tracking, reset logic, and stop navigation.

import 'package:flutter/material.dart';

import '../../../models/trip_plan.dart';
import '../../../models/trip_progress.dart';
import '../../../services/trip_progress_service.dart';
import 'active_stop_screen.dart';

class DayProgramScreen extends StatefulWidget {
  final TripPlan plan;
  final int dayIndex;
  final List<TripStop> dayStops;

  const DayProgramScreen({
    super.key,
    required this.plan,
    required this.dayIndex,
    required this.dayStops,
  });

  @override
  State<DayProgramScreen> createState() => _DayProgramScreenState();
}

class _DayProgramScreenState extends State<DayProgramScreen> {
  final Set<String> _visitedPlaceIds = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await TripProgressService.load(widget.plan.id);
    if (!mounted) return;
    setState(() {
      _visitedPlaceIds.addAll(progress?.visitedPlaceIds ?? {});
      _loaded = true;
    });
  }

  Future<void> _markVisited(String placeId) async {
    setState(() => _visitedPlaceIds.add(placeId));
    await TripProgressService.save(
      TripProgress(
        tripId: widget.plan.id,
        visitedPlaceIds: _visitedPlaceIds,
        lastVisitedPlaceId: placeId,
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _resetProgress() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title:
            const Text('إعادة تعيين؟', style: TextStyle(color: Colors.white)),
        content: const Text('سيتم مسح علامات الزيارة. متابعة؟',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await TripProgressService.clear(widget.plan.id);
    if (!mounted) return;
    setState(() => _visitedPlaceIds.clear());
  }

  bool get _allVisited =>
      widget.dayStops.every((s) => _visitedPlaceIds.contains(s.placeId));

  int get _visitedCount =>
      widget.dayStops.where((s) => _visitedPlaceIds.contains(s.placeId)).length;

  Future<void> _openStop(TripStop stop) async {
    final arrived = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ActiveStopScreen(stop: stop),
      ),
    );
    if (arrived == true) await _markVisited(stop.placeId);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            'برنامج اليوم ${widget.dayIndex + 1}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(
            child: CircularProgressIndicator(color: Color(0xFF0EA5E9))),
      );
    }

    final stops = widget.dayStops;
    final progressValue = stops.isEmpty ? 0.0 : _visitedCount / stops.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'برنامج اليوم ${widget.dayIndex + 1}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt, color: Colors.white70),
            tooltip: 'إعادة تعيين التقدم',
            onPressed: _visitedPlaceIds.isEmpty ? null : _resetProgress,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Progress Bar ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _allVisited
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _allVisited ? Icons.emoji_events : Icons.timeline,
                          color: _allVisited
                              ? const Color(0xFF10B981)
                              : const Color(0xFF0EA5E9),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _allVisited
                              ? 'أكملت كل محطات اليوم!'
                              : 'أنجزت $_visitedCount من ${stops.length} محطات',
                          style: TextStyle(
                            color: _allVisited
                                ? const Color(0xFF10B981)
                                : Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _allVisited
                              ? const Color(0xFF10B981).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_visitedCount / ${stops.length}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _allVisited
                                ? const Color(0xFF10B981)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progressValue),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _allVisited
                                ? const Color(0xFF10B981)
                                : const Color(0xFF0EA5E9),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // ─── Stops List ───
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                itemCount: stops.length,
                itemBuilder: (context, index) {
                  final stop = stops[index];
                  final isVisited = _visitedPlaceIds.contains(stop.placeId);
                  return _TimelineStopCard(
                    stop: stop,
                    index: index,
                    isLast: index == stops.length - 1,
                    isVisited: isVisited,
                    onGo: () => _openStop(stop),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TIMELINE STOP CARD
// ═══════════════════════════════════════════════════════════════

class _TimelineStopCard extends StatelessWidget {
  const _TimelineStopCard({
    required this.stop,
    required this.index,
    required this.isLast,
    required this.isVisited,
    required this.onGo,
  });

  final TripStop stop;
  final int index;
  final bool isLast;
  final bool isVisited;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Timeline Column ───
          SizedBox(
            width: 40,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isVisited
                        ? const Color(0xFF10B981)
                        : const Color(0xFF0EA5E9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isVisited
                                ? const Color(0xFF10B981)
                                : const Color(0xFF0EA5E9))
                            .withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: isVisited
                        ? const Icon(Icons.check, color: Colors.white, size: 22)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // ─── Card Content ───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isVisited
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVisited
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.placeNameAr,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        decoration:
                            isVisited ? TextDecoration.lineThrough : null,
                        color: isVisited ? Colors.white54 : Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: isVisited
                              ? Colors.white38
                              : const Color(0xFF0EA5E9),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${stop.plannedDurationMin ?? 60} دقيقة',
                          style: TextStyle(
                            fontSize: 14,
                            color: isVisited ? Colors.white38 : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber
                              .withValues(alpha: isVisited ? 0.3 : 1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stop.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 14,
                            color: isVisited ? Colors.white38 : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!isVisited)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onGo,
                          icon: const Icon(Icons.navigation, size: 20),
                          label: const Text('اذهب إلى هنا',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: const Color(0xFF0EA5E9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle,
                                color: Color(0xFF10B981), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'تمت الزيارة بنجاح',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
