// lib/features/trip/screens/trip_overview_screen.dart
//
// [v1.3 — 2026-10-18] — CRITICAL FIX: import day_program_screen.dart
//   - FIX: كان import 'day_program_screen.dart' مفقوداً → compile error
//   - VERIFIED: كل الـ imports موجودة
import 'package:flutter/material.dart';

import '../../../models/trip_plan.dart';
import '../../../models/trip_progress.dart';
import '../../../services/trip_progress_service.dart';
import 'day_program_screen.dart'; // ✅ هذا هو السطر المفقود

class TripOverviewScreen extends StatefulWidget {
  final TripPlan plan;
  const TripOverviewScreen({super.key, required this.plan});

  @override
  State<TripOverviewScreen> createState() => _TripOverviewScreenState();
}

class _TripOverviewScreenState extends State<TripOverviewScreen> {
  TripProgress? _progress;

  int get _numberOfDays =>
      widget.plan.durationType == TripDurationType.weekend ? 2 : 1;

  List<List<TripStop>> get _stopsByDay {
    if (_numberOfDays == 1) return [widget.plan.stops];
    final perDay = (widget.plan.stops.length / _numberOfDays).ceil();
    return [
      widget.plan.stops.take(perDay).toList(),
      widget.plan.stops.skip(perDay).toList(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final p = await TripProgressService.load(widget.plan.id);
    if (!mounted) return;
    setState(() => _progress = p);
  }

  Future<void> _openDay(int i, List<TripStop> dayStops) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DayProgramScreen(
          plan: widget.plan,
          dayIndex: i,
          dayStops: dayStops,
        ),
      ),
    );
    // بعد العودة من اليوم، أعد تحميل التقدم
    await _loadProgress();
  }

  int _visitedInDay(List<TripStop> dayStops) {
    if (_progress == null) return 0;
    return dayStops.where((s) => _progress!.isVisited(s.placeId)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stopsByDay = _stopsByDay;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'رحلتك',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ─── بطاقة الرحلة ───
          Card(
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.plan.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        widget.plan.governorateNameAr,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        '$_numberOfDays ${_numberOfDays == 1 ? "يوم" : "أيام"}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'اختر اليوم لبدء البرنامج:',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // ─── بطاقات الأيام ───
          ...List.generate(stopsByDay.length, (i) {
            final dayStops = stopsByDay[i];
            final totalMin = dayStops.fold<int>(
              0,
              (sum, s) => sum + (s.plannedDurationMin ?? 0),
            );
            final hours = (totalMin / 60).toStringAsFixed(1);
            final visited = _visitedInDay(dayStops);
            final isDayComplete = visited == dayStops.length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openDay(i, dayStops),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDayComplete ? Colors.green : theme.dividerColor,
                      width: isDayComplete ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: isDayComplete
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: isDayComplete
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 36,
                                    )
                                  : Text(
                                      '${i + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اليوم ${i + 1}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${dayStops.length} محطات • ~$hours ساعات',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      if (visited > 0) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: visited / dayStops.length,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            isDayComplete
                                ? '✅ مكتمل'
                                : '$visited / ${dayStops.length} مزار',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDayComplete
                                  ? Colors.green
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
