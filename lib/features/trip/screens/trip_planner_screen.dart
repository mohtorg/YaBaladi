// lib/features/trip/screens/trip_planner_screen.dart
//
// [v2.0.2 — 2026-10-18] — Lint fixes for strict analyze
//   - FIX: unawaited() + MaterialPageRoute<void> for Navigator
//   - ADDED: import 'dart:async'
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/location/browsing_location_controller.dart';
import '../../../core/location/egypt_governorates.dart';
import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/places/controllers/places_controller.dart';
import '../../../models/trip_plan.dart';
import '../../../services/trip_planner_service.dart';
import '../controllers/trip_plans_controller.dart';
import 'trip_overview_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  static const int _totalSteps = 4;

  int _currentStep = 0;
  String _governorateId = kDefaultGovernorate.id;

  TripDurationType _durationType = TripDurationType.fullDay;
  Set<String> _interests = {};
  TripTransportMode _transportMode = TripTransportMode.driving;

  TripPlan? _generatedPlan;
  bool _generating = false;

  final _titleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final browsing = context.read<BrowsingLocationController>().browsing;
      setState(() => _governorateId = browsing.id);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String _headerSubtitle() {
    final gov = governorateById(_governorateId);
    final govName = gov?.nameAr ?? '';
    final durLabel = _durationType.labelAr;
    if (govName.isEmpty) return durLabel;
    return '$govName • $durLabel';
  }

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> _next() async {
    if (_generating || _saving) return;

    if (_currentStep == 1) {
      final hasPlan = _generatedPlan != null && _generatedPlan!.isNotEmpty;
      setState(() {
        _currentStep = 2;
        if (!hasPlan) _generating = true;
      });
      if (!hasPlan) {
        await _generateTrip(skipGuard: true);
      }
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      _onClose();
    }
  }

  void _onClose() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // GENERATION
  // ═══════════════════════════════════════════════════════════════

  Future<void> _generateTrip({bool skipGuard = false}) async {
    if (!skipGuard && _generating) return;
    if (!_generating) setState(() => _generating = true);

    final placesCtrl = context.read<PlacesController>();
    final browsingCtrl = context.read<BrowsingLocationController>();
    final messenger = ScaffoldMessenger.of(context);

    for (var attempt = 1; attempt <= 3; attempt++) {
      if (placesCtrl.allPlacesRaw.isNotEmpty &&
          placesCtrl.mode == PlacesMode.all) {
        break;
      }

      await placesCtrl.load();
      if (!mounted) return;

      if (placesCtrl.allPlacesRaw.isNotEmpty) break;

      if (attempt < 3) {
        await Future<void>.delayed(Duration(seconds: attempt * 2));
        if (!mounted) return;
      }
    }

    if (placesCtrl.allPlacesRaw.isEmpty) {
      if (!mounted) return;
      setState(() => _generating = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'تعذر تحميل الأماكن. تحقق من الاتصال ثم أعد المحاولة',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      return;
    }

    final governorate = governorateById(_governorateId) ?? kDefaultGovernorate;

    final isCurrentGov = browsingCtrl.browsing.id == _governorateId;
    final physical = browsingCtrl.physicalAddress;
    final startLat = isCurrentGov && physical?.lat != null
        ? physical!.lat!
        : governorate.lat;
    final startLng = isCurrentGov && physical?.lng != null
        ? physical!.lng!
        : governorate.lng;

    final plan = TripPlannerService.generateTrip(
      allPlaces: placesCtrl.allPlacesRaw,
      governorateId: _governorateId,
      durationType: _durationType,
      interests: _interests,
      transportMode: _transportMode,
      startLat: startLat,
      startLng: startLng,
    );

    if (!mounted) return;
    setState(() {
      _generatedPlan = plan;
      _generating = false;
      if (_titleController.text.isEmpty) {
        _titleController.text = plan.title;
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // PLACE PICKER
  // ═══════════════════════════════════════════════════════════════

  Future<void> _openPlacePicker() async {
    if (_generatedPlan == null) return;

    final auth = context.read<AuthController>();
    final uid = auth.uid ?? 'guest';

    final result = await context.push<List<TripStop>>(
      RoutePaths.tripPlacePicker,
      extra: {
        'initialStops': _generatedPlan!.stops,
        'governorateId': _governorateId,
        'governorateNameAr': _generatedPlan!.governorateNameAr,
        'maxStops': _durationType.maxStops,
        'userId': uid,
      },
    );

    if (result == null || !mounted) return;

    final updated = _generatedPlan!.copyWith(
      stops: result,
      totalDistanceKm: _recalcDistance(result),
      totalDurationMin: _recalcDuration(result),
    );

    setState(() => _generatedPlan = updated);
  }

  double _recalcDistance(List<TripStop> stops) {
    if (stops.length < 2) return 0;
    var total = 0.0;
    for (var i = 1; i < stops.length; i++) {
      total += _haversine(
        stops[i - 1].lat,
        stops[i - 1].lng,
        stops[i].lat,
        stops[i].lng,
      );
    }
    return total;
  }

  int _recalcDuration(List<TripStop> stops) {
    return stops.fold<int>(
      0,
      (sum, s) => sum + (s.plannedDurationMin ?? 0),
    );
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _save() async {
    if (_generatedPlan == null || _generatedPlan!.isEmpty) return;

    final auth = context.read<AuthController>();
    final uid = auth.uid;
    final messenger = ScaffoldMessenger.of(context);

    if (uid == null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('يجب تسجيل الدخول لحفظ الرحلة'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    final tripCtrl = context.read<TripPlansController>();

    setState(() => _saving = true);

    final toSave = _generatedPlan!.copyWith(
      userId: uid,
      title: _titleController.text.trim().isEmpty
          ? _generatedPlan!.title
          : _titleController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      status: TripStatus.active,
    );

    final ok = await tripCtrl.save(toSave);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ الرحلة'),
            duration: Duration(seconds: 2),
          ),
        );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        // ✅ explicit type args + unawaited to satisfy strict lints
        unawaited(
          Navigator.of(context).pushReplacement<void, void>(
            MaterialPageRoute<void>(
              builder: (context) => TripOverviewScreen(plan: toSave),
            ),
          ),
        );
      }
    } else {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(tripCtrl.error ?? 'تعذّر الحفظ'),
            backgroundColor: Colors.red.shade700,
          ),
        );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _onClose,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'خطط رحلتك',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              _headerSubtitle(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        toolbarHeight: 64,
      ),
      body: Column(
        children: [
          _StepIndicator(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStep(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _Step1Governorate(
          governorateId: _governorateId,
          onChanged: (id) => setState(() => _governorateId = id),
        );
      case 1:
        return _Step2Preferences(
          durationType: _durationType,
          transportMode: _transportMode,
          interests: _interests,
          onDurationChanged: (d) => setState(() => _durationType = d),
          onTransportChanged: (t) => setState(() => _transportMode = t),
          onInterestsChanged: (s) => setState(() => _interests = s),
        );
      case 2:
        return _Step3Preview(
          plan: _generatedPlan,
          generating: _generating,
          onRegenerate: () => _generateTrip(),
          onEditManually: _openPlacePicker,
        );
      case 3:
        return _Step4Save(
          plan: _generatedPlan,
          titleController: _titleController,
          startDate: _startDate,
          endDate: _endDate,
          onTitleChanged: () => setState(() {}),
          onDateRangeChanged: (start, end) => setState(() {
            _startDate = start;
            _endDate = end;
            if (start != null && end != null) {
              final days = end.difference(start).inDays + 1;
              _durationType = tripDurationFromDays(days);
            }
          }),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBottomBar() {
    final theme = Theme.of(context);
    final isLast = _currentStep == _totalSteps - 1;
    final canProceed = _canProceed();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: _generating || _saving ? null : _back,
                  child: const Text('السابق'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: isLast
                  ? FilledButton.icon(
                      onPressed: (_saving || !canProceed) ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, size: 18),
                      label: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ الرحلة'),
                    )
                  : FilledButton.icon(
                      onPressed:
                          (_generating || !canProceed) ? null : () => _next(),
                      icon: _generating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.arrow_forward, size: 18),
                      label: Text(_currentStep == 2 ? 'متابعة' : 'التالي'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canProceed() {
    switch (_currentStep) {
      case 0:
        return _governorateId.isNotEmpty;
      case 1:
        return true;
      case 2:
        return _generatedPlan != null &&
            _generatedPlan!.isNotEmpty &&
            !_generating;
      case 3:
        return _titleController.text.trim().isNotEmpty;
      default:
        return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP INDICATOR
// ═══════════════════════════════════════════════════════════════

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final isDone = i < currentStep;
          final isCurrent = i == currentStep;

          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone || isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
                if (i < totalSteps - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 1 — GOVERNORATE
// ═══════════════════════════════════════════════════════════════

class _Step1Governorate extends StatelessWidget {
  const _Step1Governorate({
    required this.governorateId,
    required this.onChanged,
  });

  final String governorateId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final browsingCtrl = context.watch<BrowsingLocationController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'أين تريد أن ترحل؟',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'اختر المحافظة التي تريد استكشافها',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        if (browsingCtrl.hasPhysicalLocation)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: ListTile(
              leading: Icon(
                Icons.my_location,
                color: theme.colorScheme.primary,
              ),
              title: const Text(
                'استخدام موقعي الحالي',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(browsingCtrl.browsing.nameAr),
              trailing: governorateId == browsingCtrl.browsing.id
                  ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                  : null,
              onTap: () => onChanged(browsingCtrl.browsing.id),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'أو اختر محافظة',
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kEgyptGovernorates.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final gov = kEgyptGovernorates[i];
              final isSelected = gov.id == governorateId;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(gov.nameAr),
                subtitle: Text(gov.nameEn),
                selected: isSelected,
                onTap: () => onChanged(gov.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 2 — PREFERENCES
// ═══════════════════════════════════════════════════════════════

class _Step2Preferences extends StatelessWidget {
  const _Step2Preferences({
    required this.durationType,
    required this.transportMode,
    required this.interests,
    required this.onDurationChanged,
    required this.onTransportChanged,
    required this.onInterestsChanged,
  });

  final TripDurationType durationType;
  final TripTransportMode transportMode;
  final Set<String> interests;
  final ValueChanged<TripDurationType> onDurationChanged;
  final ValueChanged<TripTransportMode> onTransportChanged;
  final ValueChanged<Set<String>> onInterestsChanged;

  static const List<({String id, String label, IconData icon})>
      _interestOptions = [
    (id: 'landmarks', label: 'معالم', icon: Icons.account_balance),
    (id: 'restaurants', label: 'مطاعم', icon: Icons.restaurant),
    (id: 'cafes', label: 'كافيهات', icon: Icons.local_cafe),
    (id: 'beaches', label: 'شواطئ', icon: Icons.beach_access),
    (id: 'shopping', label: 'تسوق', icon: Icons.shopping_bag),
    (id: 'hotels', label: 'فنادق', icon: Icons.hotel),
    (id: 'parks', label: 'حدائق', icon: Icons.park),
    (id: 'family', label: 'عائلي', icon: Icons.family_restroom),
    (id: 'events', label: 'فعاليات', icon: Icons.event),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'كيف تريد رحلتك؟',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'كم من الوقت؟',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        RadioGroup<TripDurationType>(
          groupValue: durationType,
          onChanged: (v) {
            if (v != null) onDurationChanged(v);
          },
          child: Column(
            children: TripDurationType.values.map((d) {
              return RadioListTile<TripDurationType>(
                value: d,
                title: Text(d.labelAr),
                subtitle: Text(d.subtitleAr),
                contentPadding: EdgeInsets.zero,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'وسيلة النقل',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TripTransportMode>(
          segments: [
            for (final m in TripTransportMode.values)
              ButtonSegment(
                value: m,
                label: Text(m.labelAr),
              ),
          ],
          selected: {transportMode},
          onSelectionChanged: (s) => onTransportChanged(s.first),
        ),
        const SizedBox(height: 20),
        Text(
          'ما يهمك؟',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'اختياري — اتركه فارغاً لرحلة متنوعة',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _interestOptions.map((opt) {
            final isSelected = interests.contains(opt.id);
            return FilterChip(
              avatar: Icon(
                opt.icon,
                size: 18,
                color: isSelected
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
              label: Text(opt.label),
              selected: isSelected,
              onSelected: (v) {
                final next = Set<String>.from(interests);
                if (v) {
                  next.add(opt.id);
                } else {
                  next.remove(opt.id);
                }
                onInterestsChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 3 — PREVIEW
// ═══════════════════════════════════════════════════════════════

class _Step3Preview extends StatelessWidget {
  const _Step3Preview({
    required this.plan,
    required this.generating,
    required this.onRegenerate,
    required this.onEditManually,
  });

  final TripPlan? plan;
  final bool generating;
  final VoidCallback onRegenerate;
  final VoidCallback onEditManually;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (generating) {
      return const Padding(
        padding: EdgeInsets.all(60),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جارٍ توليد رحلتك…'),
          ],
        ),
      );
    }

    if (plan == null || plan!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.explore_off_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد أماكن كافية',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'جرّب تقليل الاهتمامات أو اختيار محافظة أخرى',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onRegenerate,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'رحلتك المقترحة',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          plan!.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.place_outlined,
                label: 'محطات',
                value: '${plan!.stopCount}',
              ),
              _StatItem(
                icon: Icons.route_outlined,
                label: 'المسافة',
                value: '${plan!.totalDistanceKm.toStringAsFixed(0)} كم',
              ),
              _StatItem(
                icon: Icons.schedule,
                label: 'المدة',
                value: plan!.durationLabel,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'خط سير الرحلة',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...plan!.stops.asMap().entries.map((entry) {
          final idx = entry.key;
          final stop = entry.value;
          return _StopPreviewCard(
            index: idx + 1,
            stop: stop,
            isLast: idx == plan!.stops.length - 1,
          );
        }),
        const SizedBox(height: 16),
        if (plan!.isNotEmpty)
          FilledButton.icon(
            onPressed: onEditManually,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('اختر يدوياً'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onRegenerate,
          icon: const Icon(Icons.refresh),
          label: const Text('إعادة التوليد'),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _StopPreviewCard extends StatelessWidget {
  const _StopPreviewCard({
    required this.index,
    required this.stop,
    required this.isLast,
  });

  final int index;
  final TripStop stop;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = stop.plannedArrival;
    final timeLabel = time == null
        ? '--:--'
        : '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 48,
                  color: theme.colorScheme.outlineVariant,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timeLabel,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stop.placeNameAr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 12,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        stop.rating.toStringAsFixed(1),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${stop.plannedDurationMin ?? 0} د',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STEP 4 — SAVE
// ═══════════════════════════════════════════════════════════════

class _Step4Save extends StatelessWidget {
  const _Step4Save({
    required this.plan,
    required this.titleController,
    required this.startDate,
    required this.endDate,
    required this.onTitleChanged,
    required this.onDateRangeChanged,
  });

  final TripPlan? plan;
  final TextEditingController titleController;
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onTitleChanged;
  final void Function(DateTime? start, DateTime? end) onDateRangeChanged;

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart = startDate ?? now;
    final initialEnd = endDate ?? initialStart;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: initialStart,
        end: initialEnd,
      ),
      helpText: 'اختر فترة الرحلة',
      saveText: 'حفظ',
      cancelText: 'إلغاء',
      confirmText: 'تأكيد',
      errorFormatText: 'صيغة تاريخ غير صحيحة',
      errorInvalidText: 'تاريخ غير صالح',
      errorInvalidRangeText: 'تاريخ البداية بعد النهاية',
      fieldStartHintText: 'من',
      fieldEndHintText: 'إلى',
      fieldStartLabelText: 'تاريخ البدء',
      fieldEndLabelText: 'تاريخ الانتهاء',
    );

    if (picked != null) {
      onDateRangeChanged(picked.start, picked.end);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasRange = startDate != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'اللمسة الأخيرة',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'أضف عنواناً وتواريخ لرحلتك',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: titleController,
          onChanged: (_) => onTitleChanged(),
          decoration: const InputDecoration(
            labelText: 'عنوان الرحلة',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.edit_outlined),
          ),
          maxLength: 60,
        ),
        const SizedBox(height: 12),
        Text(
          '📅 متى ستسافر؟',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'حدّد تاريخ البدء والانتهاء (اختياري)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: hasRange
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => _pickDateRange(context),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'فترة الرحلة',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasRange)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          tooltip: 'مسح',
                          onPressed: () => onDateRangeChanged(null, null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!hasRange)
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'اضغط لاختيار تواريخ البدء والانتهاء',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DateBox(
                                label: 'من',
                                date: startDate!,
                                formatDate: _formatDate,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(
                                Icons.arrow_forward,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            Expanded(
                              child: _DateBox(
                                label: 'إلى',
                                date: endDate ?? startDate!,
                                formatDate: _formatDate,
                              ),
                            ),
                          ],
                        ),
                        if (endDate != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${endDate!.difference(startDate!).inDays + 1} أيام',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 14,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'اضغط للتعديل',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (plan != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملخص',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'المحافظة',
                  value: plan!.governorateNameAr,
                ),
                _SummaryRow(
                  label: 'المدة',
                  value: plan!.durationType.labelAr,
                ),
                _SummaryRow(
                  label: 'وسيلة النقل',
                  value: plan!.transportMode.labelAr,
                ),
                _SummaryRow(
                  label: 'المحطات',
                  value: '${plan!.stopCount}',
                ),
                _SummaryRow(
                  label: 'المسافة الإجمالية',
                  value: '${plan!.totalDistanceKm.toStringAsFixed(0)} كم',
                ),
                _SummaryRow(
                  label: 'الوقت الإجمالي',
                  value: plan!.durationLabel,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DATE BOX
// ═══════════════════════════════════════════════════════════════

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.date,
    required this.formatDate,
  });

  final String label;
  final DateTime date;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            formatDate(date),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
