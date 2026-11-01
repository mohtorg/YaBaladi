// lib/features/trip/screens/wizard/wizard_container_screen.dart
//
// [v3.5 — 2026-10-28] — HARDENED: Safe governorate access in _saveTrip

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../controllers/trip_bag_controller.dart';

class WizardContainerScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialPlaces;

  const WizardContainerScreen({super.key, this.initialPlaces});

  @override
  State<WizardContainerScreen> createState() => _WizardContainerScreenState();
}

class _WizardContainerScreenState extends State<WizardContainerScreen> {
  int _currentStep = 0;
  late List<Map<String, dynamic>> _selectedPlaces;

  String _transport = 'car';
  String _companions = 'family';
  DateTimeRange? _dateRange;

  Map<String, dynamic>? _aiResult;
  bool _aiLoading = false;
  bool _saving = false;

  final List<String> _stepTitles = [
    'تأكيد الأماكن',
    'وسيلة الانتقال',
    'الرفقة',
    'التواريخ',
    'توليد الرحلة',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPlaces != null && widget.initialPlaces!.isNotEmpty) {
      _selectedPlaces = List.from(widget.initialPlaces!);
    } else {
      final bag = context.read<TripBagController>();
      _selectedPlaces = List.from(bag.bagItems);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الرحلة'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          _buildStepIndicator(theme),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'الخطوة ${_currentStep + 1} من ${_stepTitles.length}: ${_stepTitles[_currentStep]}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildStepContent(theme)),
          _buildNavButtons(theme),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: List.generate(_stepTitles.length, (i) {
          final isCompleted = i < _currentStep;
          final isActive = i == _currentStep;
          final color = (isCompleted || isActive)
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant;

          return Expanded(
            child: Row(
              children: [
                if (i > 0) Expanded(child: Container(height: 2, color: color)),
                GestureDetector(
                  onTap: () {
                    if (i <= _currentStep) {
                      setState(() => _currentStep = i);
                    }
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: color),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isActive
                                    ? Colors.white
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                ),
                if (i < _stepTitles.length - 1)
                  Expanded(child: Container(height: 2, color: color)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildPlacesStep(theme);
      case 1:
        return _buildTransportStep(theme);
      case 2:
        return _buildCompanionsStep(theme);
      case 3:
        return _buildDatesStep(theme);
      case 4:
        return _buildAIStep(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildPlacesStep(ThemeData theme) {
    if (_selectedPlaces.isEmpty) {
      return const Center(child: Text('لا توجد أماكن محددة'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selectedPlaces.length,
      itemBuilder: (context, index) {
        final place = _selectedPlaces[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(place['name'] ?? 'مكان'),
            subtitle: Text(place['categoryName'] ?? ''),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  _selectedPlaces.removeAt(index);
                  _aiResult = null;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransportStep(ThemeData theme) {
    final options = [
      {'key': 'car', 'label': 'سيارة خاصة', 'icon': Icons.directions_car},
      {
        'key': 'walking',
        'label': 'مشي على الأقدام',
        'icon': Icons.directions_walk
      },
      {
        'key': 'transit',
        'label': 'مواصلات عامة',
        'icon': Icons.directions_transit
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: options.map((o) {
        final isSelected = _transport == o['key'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Icon(o['icon'] as IconData,
                size: 28, color: isSelected ? theme.colorScheme.primary : null),
            title: Text(o['label'] as String,
                style:
                    TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
            onTap: () {
              setState(() {
                _transport = o['key'] as String;
                _aiResult = null;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCompanionsStep(ThemeData theme) {
    final options = [
      {'key': 'family', 'label': 'عائلية', 'emoji': '👨‍👩‍👧‍👦'},
      {'key': 'couple', 'label': 'زوجية', 'emoji': '👩‍❤️‍👨'},
      {'key': 'solo', 'label': 'فردية', 'emoji': '🧑‍💼'},
      {'key': 'with_kids', 'label': 'مع أطفال', 'emoji': '👨‍👩‍👧'},
      {'key': 'kids_only', 'label': 'أطفال فقط', 'emoji': '🧒'},
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: options.map((o) {
        final isSelected = _companions == o['key'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: ListTile(
            leading: Text(o['emoji']!, style: const TextStyle(fontSize: 30)),
            title: Text(o['label']!,
                style:
                    TextStyle(fontWeight: isSelected ? FontWeight.bold : null)),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                : null,
            onTap: () {
              setState(() {
                _companions = o['key'] as String;
                _aiResult = null;
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatesStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: ListTile(
              leading:
                  Icon(Icons.calendar_today, color: theme.colorScheme.primary),
              title: const Text('تاريخ بدء الرحلة'),
              subtitle: Text(
                _dateRange == null
                    ? 'لم يتم الاختيار'
                    : _fmt(_dateRange!.start),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () async {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateRange?.start ?? today,
                  firstDate: today,
                  lastDate: today.add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _aiResult = null;
                    if (_dateRange != null && picked.isAfter(_dateRange!.end)) {
                      _dateRange = DateTimeRange(start: picked, end: picked);
                    } else if (_dateRange != null) {
                      _dateRange =
                          DateTimeRange(start: picked, end: _dateRange!.end);
                    } else {
                      _dateRange = DateTimeRange(start: picked, end: picked);
                    }
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.event, color: theme.colorScheme.primary),
              title: const Text('تاريخ انتهاء الرحلة'),
              subtitle: Text(
                _dateRange == null ? 'لم يتم الاختيار' : _fmt(_dateRange!.end),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              onTap: () async {
                if (_dateRange == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('يرجى اختيار تاريخ البدء أولاً')),
                  );
                  return;
                }
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dateRange!.end,
                  firstDate: _dateRange!.start,
                  lastDate: _dateRange!.start.add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _dateRange =
                        DateTimeRange(start: _dateRange!.start, end: picked);
                    _aiResult = null;
                  });
                }
              },
            ),
          ),
          if (_dateRange != null) ...[
            const SizedBox(height: 24),
            Chip(
              label: Text(
                'مدة الرحلة: ${_dateRange!.duration.inDays + 1} أيام',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer),
              ),
              backgroundColor: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAIStep(ThemeData theme) {
    if (_aiLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 4)),
            const SizedBox(height: 24),
            Text('✨ جاري تحليل رحلتك...',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (_aiResult == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome,
                  size: 80, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('جاهز للتوليد!',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('سنقوم بتوليد رحلة مثالية بناءً على اختياراتك',
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _generateTrip,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('✨ توليد الرحلة'),
                style: FilledButton.styleFrom(minimumSize: const Size(280, 55)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: theme.colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.check_circle,
                        size: 32, color: theme.colorScheme.primary),
                    TextButton.icon(
                      onPressed: () => setState(() => _currentStep = 0),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('تعديل'),
                      style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary),
                    ),
                  ],
                ),
                Text('رحلتك جاهزة!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statItem('${_aiResult!['totalStops']}', 'محطة'),
                    _statItem('${_aiResult!['days']}', 'أيام'),
                    _statItem('${_aiResult!['totalHours']}', 'ساعة'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...(_aiResult!['schedule'] as List)
            .map((day) => _buildDayCard(theme, day)),
        if ((_aiResult!['suggestions'] as List).isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.tips_and_updates, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text('نصائح ذكية',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 8),
                  ...(_aiResult!['suggestions'] as List).map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child:
                            Text('• $s', style: const TextStyle(fontSize: 13)),
                      )),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _saving ? null : _saveTrip,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.save),
          label: Text(_saving ? 'جارٍ الحفظ...' : 'حفظ الرحلة'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(55),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _currentStep = 0),
          icon: const Icon(Icons.edit, size: 20),
          label: const Text('تعديل الاختيارات', style: TextStyle(fontSize: 16)),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(55),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _statItem(String value, String label) {
    return Column(children: [
      Text(value,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(fontSize: 12)),
    ]);
  }

  Widget _buildDayCard(ThemeData theme, Map<String, dynamic> day) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(child: Text('${day['day']}')),
              const SizedBox(width: 8),
              Text('اليوم ${day['day']}',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('~${day['estimatedHours']} ساعة',
                  style: theme.textTheme.bodySmall),
            ]),
            const Divider(),
            ...(day['stops'] as List).map((s) => ListTile(
                  dense: true,
                  leading: Icon(Icons.place, color: theme.colorScheme.primary),
                  title: Text(s['name'] ?? 'مكان'),
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _generateTrip() async {
    if (_dateRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('يرجى اختيار التواريخ أولاً'),
            backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _aiLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    final days = _dateRange!.duration.inDays + 1;
    final stops = _selectedPlaces;
    final stopsPerDay = (stops.length / days).ceil();

    final double durationPerStop = _companions == 'kids_only'
        ? 1.0
        : _companions == 'family'
            ? 2.0
            : _companions == 'with_kids'
                ? 1.5
                : _companions == 'couple'
                    ? 1.5
                    : 1.0;

    final double travelPerHop = _transport == 'walking'
        ? 0.5
        : _transport == 'transit'
            ? 0.4
            : 0.3;

    final schedule = <Map<String, dynamic>>[];
    int idx = 0;
    for (int d = 0; d < days; d++) {
      final dayStops = <Map<String, dynamic>>[];
      for (int s = 0; s < stopsPerDay && idx < stops.length; s++) {
        dayStops.add(stops[idx]);
        idx++;
      }
      if (dayStops.isNotEmpty) {
        final hours = (dayStops.length * durationPerStop) +
            ((dayStops.length - 1) * travelPerHop);
        schedule.add({
          'day': d + 1,
          'stops': dayStops,
          'estimatedHours': hours.toStringAsFixed(1),
        });
      }
    }

    final tips = <String>[];
    if (_companions == 'family' || _companions == 'with_kids') {
      tips.add('👨‍👩‍👧‍👦 ابدأ صباحاً لتجنب الزحام');
      tips.add('🍔 خصص وقتاً للطعام والراحة');
    }
    if (_companions == 'couple') tips.add('💕 الأماكن المفتوحة رائعة لرحلتك');
    if (_transport == 'walking' && stops.length > 4)
      tips.add('🚶‍♂️ الرحلة مشي، فكر في تقسيمها على يومين');
    if (stops.length > 6) tips.add('☕ خذ استراحة بين المحطات');

    if (mounted) {
      setState(() {
        _aiResult = {
          'totalStops': stops.length,
          'days': days,
          'totalHours': (stops.length * durationPerStop +
                  (stops.length - 1) * travelPerHop)
              .toStringAsFixed(1),
          'schedule': schedule,
          'suggestions': tips,
        };
        _aiLoading = false;
      });
    }
  }

  Future<void> _saveTrip() async {
    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'يرجى تسجيل الدخول';

      // ✅ التحصين: استخدام دالة آمنة لقراءة governorate
      final safeGov = _selectedPlaces.isEmpty
          ? 'مصر'
          : (_selectedPlaces.first['governorate']?.toString() ?? 'مصر');

      await FirebaseFirestore.instance.collection('trip_plans').add({
        'userId': user.uid,
        'title': 'رحلة إلى $safeGov',
        'transportMode': _transport,
        'companions': _companions,
        'startDate': Timestamp.fromDate(_dateRange!.start),
        'endDate': Timestamp.fromDate(_dateRange!.end),
        'stops': _selectedPlaces
            .map((p) => {'placeId': p['id'], 'name': p['name']})
            .toList(),
        'status': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
      });

      context.read<TripBagController>().clearBag();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('🎉 تم حفظ الرحلة!'),
              backgroundColor: Colors.green),
        );
        context.go('/trips');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildNavButtons(ThemeData theme) {
    if (_currentStep == _stepTitles.length - 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('السابق'),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: () {
              if (_currentStep == 3 && _dateRange == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('يرجى اختيار تاريخ البدء والانتهاء'),
                      backgroundColor: Colors.red),
                );
                return;
              }
              setState(() => _currentStep++);
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('التالي'),
          ),
        ),
      ]),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
