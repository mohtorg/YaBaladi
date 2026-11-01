// lib/features/trip/screens/day_program_screen.dart
//
// [v2.0 — 2026-10-18] — Wave 3.3: Progress Persistence
//   NOTE: لا يستخدم url_launcher (خلافاً لـ active_stop_screen)

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
        title: const Text('إعادة تعيين؟'),
        content: const Text('سيتم مسح علامات الزيارة. متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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
        appBar: AppBar(
          title: Text(
            'برنامج اليوم ${widget.dayIndex + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final stops = widget.dayStops;
    final progressValue = stops.isEmpty ? 0.0 : _visitedCount / stops.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'برنامج اليوم ${widget.dayIndex + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'إعادة تعيين التقدم',
            onPressed: _visitedPlaceIds.isEmpty ? null : _resetProgress,
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progressValue,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  _allVisited ? Icons.celebration : Icons.timeline,
                  color: _allVisited ? Colors.green : theme.colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _allVisited
                        ? '🎉 أكملت كل محطات اليوم!'
                        : 'أنجزت $_visitedCount من ${stops.length} محطات',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _allVisited ? Colors.green : null,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _allVisited
                        ? Colors.green.withValues(alpha: 0.15)
                        : theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_visitedCount / ${stops.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _allVisited
                          ? Colors.green
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
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
    );
  }
}

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
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isVisited ? Colors.green : theme.colorScheme.primary,
                    shape: BoxShape.circle,
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
                    child: Container(width: 2, color: theme.dividerColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Card(
                elevation: isVisited ? 0 : 2,
                color: isVisited
                    ? theme.colorScheme.surfaceContainerHighest
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.placeNameAr,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          decoration:
                              isVisited ? TextDecoration.lineThrough : null,
                          color: isVisited
                              ? theme.colorScheme.onSurfaceVariant
                              : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 20, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            '${stop.plannedDurationMin ?? 60} دقيقة',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!isVisited)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: onGo,
                            icon: const Icon(Icons.navigation, size: 24),
                            label: const Text(
                              'اذهب إلى هنا',
                              style: TextStyle(fontSize: 18),
                            ),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'تمت الزيارة بنجاح',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
          ),
        ],
      ),
    );
  }
}
