// lib/features/trip/screens/wizard/wizard_container_screen.dart
//
// [v1.2.2 — 2026-10-19] — Wave 5.5: إصلاح نهائي لـ go_router pushReplacement
//   - FIX: context.pushReplacement في هذه البيئة:
//          توقيعه void Function(String, {Object? extra}) — 0 type params، إرجاع void.
//          ⇒ إزالة <void, void> نهائيًا + لا unawaited + لا // ignore
//   - KEEP: Navigator.of(context).pushReplacement<void, void> مع unawaited
//          (Flutter SDK: 2 type params، Future<void?> — يُقبَل من unawaited)
//   - KEEP: import 'dart:async' (مستخدم في unawaited)
//
// [v1.2.1 — 2026-10-19] — محاولة أولى (غير مكتملة)
// [v1.2   — 2026-10-18] — Wave 5.4: Trip Detailed Screen navigation
// [v1.1   — 2026-10-18] — Wave 5.3: Wizard Container
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/location/browsing_location_controller.dart';
import '../../../../core/location/egypt_governorates.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../models/companion_type.dart';
import '../../../../models/trip_plan.dart';
import '../../../../services/trip_planner_service.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../places/controllers/places_controller.dart';
import '../../controllers/trip_plans_controller.dart';
import '../../screens/trip_overview_screen.dart'; // fallback only
import '../../widgets/wizard_nav_bar.dart';
import '../../widgets/wizard_progress_bar.dart';
import 'step1_destination_screen.dart';
import 'step2_companions_screen.dart';
import 'step3_duration_screen.dart';
import 'step4_interests_screen.dart';
import 'step5_transport_screen.dart';
import 'step6_preview_screen.dart';

class WizardContainerScreen extends StatefulWidget {
  const WizardContainerScreen({super.key});

  @override
  State<WizardContainerScreen> createState() => _WizardContainerScreenState();
}

class _WizardContainerScreenState extends State<WizardContainerScreen> {
  static const int _totalSteps = 6;

  static const List<WizardStepConfig> _steps = [
    WizardStepConfig(labelAr: 'الوجهة', icon: Icons.place),
    WizardStepConfig(labelAr: 'الرفاق', icon: Icons.people),
    WizardStepConfig(labelAr: 'المدة', icon: Icons.schedule),
    WizardStepConfig(labelAr: 'الاهتمامات', icon: Icons.interests),
    WizardStepConfig(labelAr: 'النقل', icon: Icons.directions_car),
    WizardStepConfig(labelAr: 'المعاينة', icon: Icons.check_circle),
  ];

  late final PageController _pageController;
  int _currentStep = 0;

  String? _governorateId;
  CompanionType _companion = CompanionType.family;
  TripDurationType _durationType = TripDurationType.fullDay;
  Set<String> _interests = {};
  TripTransportMode _transportMode = TripTransportMode.driving;

  TripPlan? _generatedPlan;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final browsing = context.read<BrowsingLocationController>().browsing;
      setState(() => _governorateId = browsing.id);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _governorateId != null && _governorateId!.isNotEmpty;
      case 5:
        return _generatedPlan != null && !_generating;
      default:
        return true;
    }
  }

  Future<void> _goNext() async {
    if (!_canProceed) return;

    // عند مغادرة النقل → توليد الخطة قبل فتح المعاينة
    if (_currentStep == 4 && _generatedPlan == null) {
      await _generatePlan();
      if (!mounted || _generatedPlan == null) return;
    }

    if (_currentStep < _totalSteps - 1) {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _goPrev() async {
    if (_currentStep > 0) {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int page) => setState(() => _currentStep = page);

  // ═══════════════════════════════════════════════════════════════
  // GENERATE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _generatePlan() async {
    if (_generating || _governorateId == null) return;
    setState(() => _generating = true);

    final placesCtrl = context.read<PlacesController>();
    final browsingCtrl = context.read<BrowsingLocationController>();
    final messenger = ScaffoldMessenger.of(context);

    for (var attempt = 0; attempt < 3; attempt++) {
      if (placesCtrl.allPlacesRaw.isNotEmpty) break;
      await placesCtrl.load();
      if (!mounted) return;
    }

    if (placesCtrl.allPlacesRaw.isEmpty) {
      setState(() => _generating = false);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر تحميل الأماكن'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final gov = governorateById(_governorateId!) ?? kDefaultGovernorate;
    final isCurrentGov = browsingCtrl.browsing.id == _governorateId;
    final physical = browsingCtrl.physicalAddress;

    final plan = TripPlannerService.generateTrip(
      allPlaces: placesCtrl.allPlacesRaw,
      governorateId: _governorateId!,
      durationType: _durationType,
      interests: _interests,
      transportMode: _transportMode,
      startLat:
          isCurrentGov && physical?.lat != null ? physical!.lat! : gov.lat,
      startLng:
          isCurrentGov && physical?.lng != null ? physical!.lng! : gov.lng,
      companion: _companion,
    );

    if (!mounted) return;
    setState(() {
      _generatedPlan = plan;
      _generating = false;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // SAVE
  // ═══════════════════════════════════════════════════════════════

  Future<void> _savePlan() async {
    final plan = _generatedPlan;
    if (plan == null) return;

    final auth = context.read<AuthController>();
    final uid = auth.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجّل الدخول لحفظ الرحلة'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final tripCtrl = context.read<TripPlansController>();
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _generating = true);
    final ok = await tripCtrl.save(
      plan.copyWith(
        userId: uid,
        status: TripStatus.active,
      ),
    );
    if (!mounted) return;
    setState(() => _generating = false);

    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(tripCtrl.error ?? 'تعذر الحفظ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final saved = tripCtrl.selectedPlan ?? plan;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('✅ تم حفظ الرحلة'),
        backgroundColor: Colors.green,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // ─────────────────────────────────────────────────────────────
    // [v1.2.2] التوجيه النهائي — الشكل الصحيح لكل توقيع:
    //   • context.pushReplacement: void، 0 type params ⇒ استدعاء عارٍ
    //   • Navigator.pushReplacement: Future، 2 type params ⇒ unawaited
    // ─────────────────────────────────────────────────────────────
    if (saved.id.isNotEmpty) {
      context.pushReplacement(RoutePaths.tripDetailedPath(saved.id));
    } else {
      // fallback نادر — seed معطّل أو حفظ بلا id
      unawaited(
        Navigator.of(context).pushReplacement<void, void>(
          MaterialPageRoute<void>(
            builder: (_) => TripOverviewScreen(plan: saved),
          ),
        ),
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isLast = _currentStep == _totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'خطط رحلتك',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: WizardProgressBar(
            steps: _steps,
            currentIndex: _currentStep,
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Step1DestinationScreen(
            selectedGovernorateId: _governorateId,
            onChanged: (id) => setState(() => _governorateId = id),
          ),
          Step2CompanionsScreen(
            selected: _companion,
            onChanged: (c) => setState(() => _companion = c),
          ),
          Step3DurationScreen(
            selected: _durationType,
            onChanged: (d) => setState(() {
              _durationType = d;
              _generatedPlan = null;
            }),
          ),
          Step4InterestsScreen(
            selected: _interests,
            onChanged: (s) => setState(() {
              _interests = s;
              _generatedPlan = null;
            }),
          ),
          Step5TransportScreen(
            selected: _transportMode,
            onChanged: (t) => setState(() {
              _transportMode = t;
              _generatedPlan = null;
            }),
          ),
          Step6PreviewScreen(
            plan: _generatedPlan,
            generating: _generating,
            onSave: _savePlan,
            onRegenerate: _generatePlan,
          ),
        ],
      ),
      bottomNavigationBar: WizardNavBar(
        onPrev: _currentStep > 0 ? _goPrev : null,
        onNext: isLast
            ? (_generatedPlan != null && !_generating ? _savePlan : null)
            : _goNext,
        canProceed: _canProceed,
        isLoading: _generating,
        isLast: isLast,
        lastLabel: '💾 حفظ الرحلة',
      ),
    );
  }
}
