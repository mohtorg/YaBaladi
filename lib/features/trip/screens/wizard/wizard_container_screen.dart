// lib/features/trip/screens/wizard/wizard_container_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WizardContainerScreen extends StatefulWidget {
  const WizardContainerScreen({super.key});

  @override
  State<WizardContainerScreen> createState() => _WizardContainerScreenState();
}

class _WizardContainerScreenState extends State<WizardContainerScreen> {
  int _currentStep = 0;

  // بيانات تجريبية للخطوات
  final List<String> _steps = [
    'اختيار المحافظة',
    'اختيار المحطات',
    'تأكيد الرحلة',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تخطيط رحلة جديدة'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/trips'),
        ),
      ),
      body: Column(
        children: [
          // ─── شريط التقدم ───
          LinearProgressIndicator(
            value: (_currentStep + 1) / _steps.length,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: theme.colorScheme.primary,
            minHeight: 6,
          ),
          const SizedBox(height: 16),
          Text(
            'الخطوة ${_currentStep + 1} من ${_steps.length}: ${_steps[_currentStep]}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // ─── محتوى الخطوة ───
          Expanded(
            child: _buildStepContent(theme),
          ),

          // ─── أزرار التنقل ───
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_currentStep > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('السابق'),
                  ),
                const Spacer(),
                if (_currentStep < _steps.length - 1)
                  FilledButton(
                    onPressed: () => setState(() => _currentStep++),
                    child: const Text('التالي'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () {
                      // إتمام الرحلة
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('🎉 تم حفظ الرحلة بنجاح!')),
                      );
                      context.go('/trips');
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('حفظ الرحلة'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    switch (_currentStep) {
      case 0:
        return _buildGovernorateStep();
      case 1:
        return _buildPlacesStep();
      case 2:
        return _buildConfirmStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildGovernorateStep() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        _buildOptionCard('بورسعيد', Icons.location_city),
        _buildOptionCard('القاهرة', Icons.location_city),
        _buildOptionCard('الإسكندرية', Icons.location_city),
        _buildOptionCard('الأقصر', Icons.location_city),
      ],
    );
  }

  Widget _buildPlacesStep() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('سيتم فتح الخريطة لاختيار المحطات'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // الانتقال لشاشة اختيار المحطات عبر مسار الراوتر
              context.push('/trips/planner/picker', extra: {
                'governorateId': 'portsaid',
                'governorateNameAr': 'بورسعيد',
                'maxStops': 8,
                'userId': 'guest',
              });
            },
            child: const Text('فتح الخريطة'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStep() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text('راجعت بياناتك، جاهز للحفظ!'),
        ],
      ),
    );
  }

  Widget _buildOptionCard(String title, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_left),
        onTap: () => setState(() => _currentStep++),
      ),
    );
  }
}
