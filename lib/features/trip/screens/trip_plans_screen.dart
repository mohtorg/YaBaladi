// lib/features/trip/screens/trip_plans_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TripPlansScreen extends StatefulWidget {
  const TripPlansScreen({super.key});

  @override
  State<TripPlansScreen> createState() => _TripPlansScreenState();
}

class _TripPlansScreenState extends State<TripPlansScreen> {
  // بيانات تجريبية للرحلات المحفوظة
  final List<Map<String, dynamic>> _myTrips = [
    {
      'id': 'trip_1',
      'title': 'رحلة نهاية الأسبوع - بورسعيد',
      'date': '2026-10-25',
      'stops': 4,
      'duration': 'يوم كامل',
      'status': 'active', // active, completed, draft
    },
    {
      'id': 'trip_2',
      'title': 'جولة سياحية في القاهرة',
      'date': '2026-11-02',
      'stops': 6,
      'duration': 'نصف يوم',
      'status': 'draft',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('رحلاتي'),
        centerTitle: true,
      ),
      // ✅ زر عائم لإنشاء رحلة جديدة (يوجه لمسار الراوتر /trips/planner)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/trips/planner');
        },
        icon: const Icon(Icons.add_location_alt),
        label: const Text('رحلة جديدة'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: _myTrips.isEmpty
          ? _buildEmptyState(theme)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                  16, 16, 16, 80), // مسافة للزر العائم
              itemCount: _myTrips.length,
              itemBuilder: (context, index) {
                final trip = _myTrips[index];
                return _TripCard(trip: trip);
              },
            ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.map_outlined,
            size: 80,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد رحلات محفوظة',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اضغط على "رحلة جديدة" لبدء التخطيط.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ويدجت بطاقة الرحلة
// ═══════════════════════════════════════════════════════════════

class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = trip['status'] as String;

    // تحديد لون وحالة الرحلة
    Color statusColor;
    String statusText;
    switch (status) {
      case 'active':
        statusColor = Colors.green;
        statusText = 'نشطة';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'مكتملة';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'مسودة';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // التوجه لتفاصيل الرحلة عبر مسار الراوتر
          context.push('/trips/detailed/${trip['id']}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      trip['title'] as String,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trip['date'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    trip['duration'] as String,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${trip['stops']} محطات',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
