// lib/features/trip/screens/trip_planner_screen.dart
//
// [v3.4.3 - MAP KEYS FIX]
//   - FIXED: Handled both camelCase and snake_case for bag items.
//   - FIXED: Missing place names and incorrect icons due to null fields.

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
import '../../../models/governorate_config.dart';
import '../../../models/trip_plan.dart';
import '../../../repositories/governorates_repository.dart';
import '../../../services/trip_planner_service.dart';
import '../controllers/trip_bag_controller.dart';
import '../controllers/trip_plans_controller.dart';
import 'trip_overview_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialPlaces;

  const TripPlannerScreen({super.key, this.initialPlaces});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  int _currentStep = 0;
  String _governorateId = '';
  TripDurationType _durationType = TripDurationType.fullDay;

  final Set<String> _interests = {};

  TripTransportMode _transportMode = TripTransportMode.driving;

  TripPlan? _generatedPlan;
  bool _generating = false;
  bool _saving = false;

  double? _genStartLat;
  double? _genStartLng;

  final _titleController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<Map<String, dynamic>> _bagItems = [];
  bool _isBagMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _detectInitialState();
    });
  }

  void _detectInitialState() {
    final browsing = context.read<BrowsingLocationController>().browsing;
    final bag = context.read<TripBagController>().bagItems;

    if (widget.initialPlaces != null && widget.initialPlaces!.isNotEmpty) {
      _bagItems = widget.initialPlaces!;
      _isBagMode = true;
    } else if (bag.isNotEmpty) {
      _bagItems = bag;
      _isBagMode = true;
    }

    if (_isBagMode) {
      String? govName;
      for (final item in _bagItems) {
        // دعم كلا الصيغتين للحقل
        final g = (item['governorate'] ?? item['gov'] ?? item['governorate_id'])
            ?.toString()
            .trim();
        if (g != null && g.isNotEmpty) {
          govName = g;
          break;
        }
      }

      final gov = govName != null
          ? kEgyptGovernorates.firstWhere(
              (g) => g.nameAr == govName || g.id == govName,
              orElse: () => browsing,
            )
          : browsing;
      _governorateId = gov.id;

      if (_bagItems.length <= 2) {
        _durationType = TripDurationType.halfDay;
      } else if (_bagItems.length <= 5) {
        _durationType = TripDurationType.fullDay;
      } else {
        _durationType = TripDurationType.weekend;
      }
    } else {
      _governorateId = browsing.id;
    }

    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  String get _govName => governorateById(_governorateId)?.nameAr ?? 'المحافظة';

  String _arabicCount(
      int n, String singular, String dual, String plural, String accusative) {
    if (n == 1) return '1 $singular';
    if (n == 2) return '2 $dual';
    if (n >= 3 && n <= 10) return '$n $plural';
    return '$n $accusative';
  }

  Future<void> _next() async {
    if (_generating || _saving) return;

    if (_currentStep == 0) {
      setState(() {
        _currentStep = 1;
        _generating = true;
      });
      await _generateTrip();
    } else if (_currentStep < 2) {
      setState(() => _currentStep++);
    }
  }

  void _back() {
    if (_generating || _saving) return;
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

  Future<void> _generateTrip() async {
    final placesCtrl = context.read<PlacesController>();
    final browsingCtrl = context.read<BrowsingLocationController>();
    final messenger = ScaffoldMessenger.of(context);

    if (placesCtrl.allPlacesRaw.isEmpty) {
      await placesCtrl.load();
    }

    if (placesCtrl.allPlacesRaw.isEmpty) {
      if (!mounted) return;
      setState(() => _generating = false);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تعذر تحميل الأماكن. تحقق من الاتصال.'),
          backgroundColor: Colors.orange,
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

    final priorityIds = _bagItems
        .map((p) => (p['id'] ?? p['placeId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    var plan = TripPlannerService.generateTrip(
      allPlaces: placesCtrl.allPlacesRaw,
      governorateId: _governorateId,
      durationType: _durationType,
      interests: _interests,
      transportMode: _transportMode,
      startLat: startLat,
      startLng: startLng,
      priorityPlaceIds: priorityIds,
    );

    // ✅ التعديل الجذري: قراءة البيانات من السلة بشكل آمن يدعم كلا الصيغتين
    if (_isBagMode && _bagItems.isNotEmpty) {
      final customStops = _bagItems.map((item) {
        return TripStop(
          placeId: (item['id'] ?? item['placeId'] ?? '').toString(),
          placeNameAr: (item['nameAr'] ?? item['name_ar'] ?? '').toString(),
          placeNameEn: (item['nameEn'] ?? item['name_en'] ?? '').toString(),
          categoryId:
              (item['categoryId'] ?? item['category_id'] ?? '').toString(),
          lat: ((item['lat'] ?? item['latitude']) as num?)?.toDouble() ?? 0.0,
          lng: ((item['lng'] ?? item['longitude']) as num?)?.toDouble() ?? 0.0,
          rating: ((item['rating'] ?? item['average_rating']) as num?)
                  ?.toDouble() ??
              0.0,
          reviewCount: ((item['reviewCount'] ?? item['review_count']) as num?)
                  ?.toInt() ??
              0,
          plannedDurationMin:
              (item['duration'] ?? item['plannedDurationMin']) as int? ?? 60,
        );
      }).toList();

      plan = plan.copyWith(
        stops: customStops,
        totalDistanceKm: _recalcDistance(
          customStops,
          originLat: startLat,
          originLng: startLng,
        ),
        totalDurationMin: _recalcDuration(customStops),
      );
    }

    if (!mounted) return;
    setState(() {
      _generatedPlan = plan;
      _generating = false;
      _genStartLat = startLat;
      _genStartLng = startLng;
      if (_titleController.text.isEmpty) {
        _titleController.text = 'رحلة إلى $_govName';
      }
    });
  }

  Future<void> _openPlacePicker() async {
    if (_generatedPlan == null) return;
    final auth = context.read<AuthController>();
    final result = await context.push<List<TripStop>>(
      RoutePaths.tripPlacePicker,
      extra: {
        'initialStops': _generatedPlan!.stops,
        'governorateId': _governorateId,
        'governorateNameAr': _generatedPlan!.governorateNameAr,
        'maxStops': _durationType.maxStops,
        'userId': auth.uid,
      },
    );
    if (result == null || !mounted) return;

    final updated = _generatedPlan!.copyWith(
      stops: result,
      totalDistanceKm: _recalcDistance(result,
          originLat: _genStartLat, originLng: _genStartLng),
      totalDurationMin: _recalcDuration(result),
    );
    setState(() => _generatedPlan = updated);
  }

  double _recalcDistance(List<TripStop> stops,
      {double? originLat, double? originLng}) {
    if (stops.isEmpty) return 0;
    double total = 0.0;
    double? prevLat = originLat;
    double? prevLng = originLng;

    for (final s in stops) {
      if (prevLat != null && prevLng != null) {
        total += _haversine(prevLat, prevLng, s.lat, s.lng);
      }
      prevLat = s.lat;
      prevLng = s.lng;
    }
    return total;
  }

  int _recalcDuration(List<TripStop> stops) {
    return stops.fold<int>(0, (sum, s) => sum + (s.plannedDurationMin ?? 0));
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

  Future<void> _save() async {
    if (_generatedPlan == null || _generatedPlan!.isEmpty) return;

    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!auth.isLoggedIn) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
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
      userId: auth.uid,
      title: _titleController.text.trim().isEmpty
          ? 'رحلة جديدة'
          : _titleController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      durationType: _durationType,
      status: TripStatus.active,
    );

    final ok = await tripCtrl.save(toSave);

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الرحلة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => TripOverviewScreen(plan: toSave)),
        );
      }
    } else {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(tripCtrl.error ?? 'تعذر الحفظ'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _onClose,
        ),
        title: const Text(
          'خطط لرحلتك',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepper(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          final isDone = index < _currentStep;
          final isCurrent = index == _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isDone || isCurrent
                        ? const Color(0xFF0EA5E9)
                        : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text('${index + 1}',
                            style: TextStyle(
                                color:
                                    isCurrent ? Colors.white : Colors.white54,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                if (index < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: isDone
                          ? const Color(0xFF0EA5E9)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStepPreferences();
      case 1:
        return _buildStepItinerary();
      case 2:
        return _buildStepSave();
      default:
        return const SizedBox();
    }
  }

  Widget _buildStepPreferences() {
    final bagCountText = _arabicCount(
      _bagItems.length,
      'مكان',
      'مكانان',
      'أماكن',
      'مكاناً',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isBagMode
                ? 'وجدنا $bagCountText في سلتك'
                : 'إلى أين تريد أن تذهب؟',
            style: const TextStyle(
                color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _isBagMode
                ? 'رحلة في $_govName. كيف تريد أن تكون؟'
                : 'اختر المحافظة لتبدأ التخطيط.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
          ),
          if (!_isBagMode) ...[
            const SizedBox(height: 24),
            const Text('المحافظة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<List<GovernorateConfig>>(
              stream: GovernoratesRepository.instance.watchActiveGovernorates(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF0EA5E9)));
                }
                final govs = snapshot.data!;
                if (govs.isEmpty) {
                  return const Text('لا توجد محافظات فعالة',
                      style: TextStyle(color: Colors.orange));
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _governorateId.isNotEmpty &&
                              govs.any((g) => g.docId == _governorateId)
                          ? _governorateId
                          : govs.first.docId,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1E293B),
                      style: const TextStyle(color: Colors.white),
                      items: govs
                          .map((g) => DropdownMenuItem(
                              value: g.docId, child: Text(g.nameAr)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _governorateId = v);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 32),
          const Text('المدة والتواريخ',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _pickCustomDates,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _startDate != null
                      ? const Color(0xFF0EA5E9).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _startDate != null
                        ? const Color(0xFF0EA5E9)
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      color: _startDate != null
                          ? const Color(0xFF0EA5E9)
                          : Colors.white54,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _startDate != null
                                ? '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month}'
                                : 'تحديد تواريخ الرحلة (اختياري)',
                            style: TextStyle(
                              color: _startDate != null
                                  ? Colors.white
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (_startDate != null)
                            Text(
                              'مدة الرحلة: ${_endDate!.difference(_startDate!).inDays + 1} أيام',
                              style: const TextStyle(
                                  color: Color(0xFF0EA5E9), fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    if (_startDate != null)
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Colors.white54),
                        onPressed: () => setState(() {
                          _startDate = null;
                          _endDate = null;
                          _durationType = TripDurationType.fullDay;
                        }),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_startDate == null) ...[
            Row(
              children: [
                Expanded(
                  child: _buildDurationCard(
                    label: 'نصف يوم',
                    subtitle: '~4 ساعات',
                    type: TripDurationType.halfDay,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDurationCard(
                    label: 'يوم كامل',
                    subtitle: '~8 ساعات',
                    type: TripDurationType.fullDay,
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تم استنتاج مدة الرحلة تلقائياً بناءً على التواريخ المختارة.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('وسيلة النقل',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: TripTransportMode.values.map((t) {
              final isSelected = _transportMode == t;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => setState(() => _transportMode = t),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF0EA5E9).withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF0EA5E9)
                                  : Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              t == TripTransportMode.driving
                                  ? Icons.directions_car
                                  : t == TripTransportMode.walking
                                      ? Icons.directions_walk
                                      : Icons.directions_bus,
                              color: isSelected
                                  ? const Color(0xFF0EA5E9)
                                  : Colors.white54,
                            ),
                            const SizedBox(height: 8),
                            Text(t.labelAr,
                                style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard({
    required String label,
    required String subtitle,
    required TripDurationType type,
  }) {
    final isSelected = _durationType == type && _startDate == null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() {
          _durationType = type;
          _startDate = null;
          _endDate = null;
        }),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF0EA5E9).withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected
                    ? const Color(0xFF0EA5E9)
                    : Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 15),
                  textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickCustomDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF0EA5E9),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final days = picked.end.difference(picked.start).inDays + 1;
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;

        if (days == 1) {
          _durationType = TripDurationType.fullDay;
        } else {
          _durationType = TripDurationType.weekend;
        }
      });
    }
  }

  Widget _buildStepItinerary() {
    if (_generating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0EA5E9)),
            SizedBox(height: 24),
            Text('نقوم بتجهيز أفضل ترتيب لرحلتك...',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      );
    }

    if (_generatedPlan == null || _generatedPlan!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.explore_off, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text('لم نجد أماكن كافية',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _back,
                icon: const Icon(Icons.tune),
                label: const Text('تعديل الخيارات'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final days = _generatedPlan!.stopsByDay;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: days.length,
            itemBuilder: (context, dayIndex) {
              final dayStops = days[dayIndex];
              return _buildDayCard(dayIndex + 1, dayStops);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: _openPlacePicker,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            label: const Text('تعديل الأماكن يدوياً',
                style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white24),
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDayCard(int dayNumber, List<TripStop> stops) {
    final stopsLabel =
        _arabicCount(stops.length, 'محطة', 'محطتان', 'محطات', 'محطة');

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'اليوم $dayNumber',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const Spacer(),
                Text(
                  stopsLabel,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          ...stops.asMap().entries.map((entry) {
            final stopIndex = entry.key;
            final stop = entry.value;
            final isLast = stopIndex == stops.length - 1;
            final durationLabel = _arabicCount(stop.plannedDurationMin ?? 60,
                'دقيقة', 'دقيقتان', 'دقائق', 'دقيقة');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF0EA5E9)),
                          ),
                          child: Center(
                            child: Text('${stopIndex + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stop.placeNameAr.isEmpty
                                  ? 'مكان بدون اسم'
                                  : stop.placeNameAr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.schedule,
                                    size: 14, color: Colors.white54),
                                const SizedBox(width: 4),
                                Text(durationLabel,
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12)),
                                const SizedBox(width: 16),
                                const Icon(Icons.star,
                                    size: 14, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(stop.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                        color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepSave() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('اللمسات الأخيرة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('أضف عنواناً لرحلتك',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'عنوان الرحلة',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
              prefixIcon:
                  const Icon(Icons.edit_outlined, color: Color(0xFF0EA5E9)),
            ),
          ),
          const SizedBox(height: 24),
          if (_startDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFF0EA5E9)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${_startDate!.day}/${_startDate!.month} - ${_endDate!.day}/${_endDate!.month} (${_endDate!.difference(_startDate!).inDays + 1} أيام)',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentStep == 2;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border:
            Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _generating || _saving ? null : _back,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('السابق'),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed:
                  (_generating || _saving) ? null : (isLast ? _save : _next),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _generating || _saving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      isLast
                          ? 'حفظ الرحلة'
                          : _currentStep == 0
                              ? 'توليد الرحلة'
                              : 'متابعة',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
