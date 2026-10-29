// lib/features/trip/screens/trip_plans_screen.dart
//
// [v5.0 — 2026-10-28] — MAJOR UPGRADE: Real-time StreamBuilder, AuthProvider integration, UI Polish

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../features/auth/controllers/auth_controller.dart';

class TripPlansScreen extends StatelessWidget {
  const TripPlansScreen({super.key});

  // ✅ دالة حذف الرحلة
  Future<void> _deleteTrip(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الرحلة'),
        content: const Text('هل أنت متأكد من حذف هذه الرحلة نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('trip_plans')
            .doc(id)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('🗑️ تم حذف الرحلة بنجاح')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ فشل الحذف: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthController>();

    // ✅ حماية: التأكد من تسجيل الدخول
    if (!auth.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('رحلاتي'), centerTitle: true),
        body: const Center(child: Text('يرجى تسجيل الدخول لعرض رحلاتك')),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'رحلاتي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt),
            tooltip: 'رحلة جديدة',
            onPressed: () => context.push('/trips/planner'),
            style: IconButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        // ✅ التحديث الفوري: أي تغيير في مجموعة trip_plans سيظهر فوراً
        stream: FirebaseFirestore.instance
            .collection('trip_plans')
            .where('userId', isEqualTo: auth.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('حدث خطأ في تحميل الرحلات: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState(theme, context);
          }

          // ترتيب الرحلات محلياً (الأحدث أولاً)
          final trips = docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList()
            ..sort((a, b) {
              final aT = a['createdAt'] as Timestamp?;
              final bT = b['createdAt'] as Timestamp?;
              if (aT == null) return 1;
              if (bT == null) return -1;
              return bT.compareTo(aT);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return _TripCard(
                trip: trip,
                onDelete: () => _deleteTrip(context, trip['id']),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined,
                size: 100, color: theme.colorScheme.outline),
            const SizedBox(height: 24),
            Text(
              'لا توجد رحلات محفوظة',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ التخطيط لرحلتك القادمة، واكتشف أجمل الأماكن في محافظتك.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.push('/trips/planner'),
              icon: const Icon(Icons.explore),
              label: const Text(
                'إنشاء رحلة جديدة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(250, 55),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// بطاقة الرحلة
// ═══════════════════════════════════════════════════════════════
class _TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  final VoidCallback onDelete;

  const _TripCard({required this.trip, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = trip['status']?.toString() ?? 'draft';

    Color statusColor;
    Color statusBgColor;
    String statusText;

    if (status == 'active') {
      statusColor = Colors.green.shade700;
      statusBgColor = Colors.green.shade50;
      statusText = 'نشطة';
    } else if (status == 'completed') {
      statusColor = Colors.blue.shade700;
      statusBgColor = Colors.blue.shade50;
      statusText = 'مكتملة';
    } else {
      statusColor = Colors.orange.shade800;
      statusBgColor = Colors.orange.shade50;
      statusText = 'مسودة';
    }

    final title = trip['title']?.toString() ?? 'رحلة بدون عنوان';
    final date = trip['date']?.toString() ?? 'غير محدد';

    String duration = 'غير محدد';
    if (trip['durationType'] == 'half_day') {
      duration = 'نصف يوم';
    } else if (trip['durationType'] == 'full_day') {
      duration = 'يوم كامل';
    } else if (trip['durationType'] == 'weekend') {
      duration = 'نهاية الأسبوع';
    }

    final stopsCount = (trip['stops'] as List?)?.length ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/trips/detailed/${trip['id']}'),
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
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.5)),
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
                    date,
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
                    duration,
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
                    '$stopsCount محطات',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onDelete,
                    tooltip: 'حذف الرحلة',
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
