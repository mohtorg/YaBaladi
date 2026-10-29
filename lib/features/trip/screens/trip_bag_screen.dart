// lib/features/trip/screens/trip_bag_screen.dart
//
// [v1.2 — 2026-10-27] — FIX: Pass bag items directly via extra

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../controllers/trip_bag_controller.dart';

class TripBagScreen extends StatelessWidget {
  const TripBagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bag = context.watch<TripBagController>();

    if (!bag.isInitialized) {
      return Scaffold(
        appBar: AppBar(
            title: const Text('سلة الرحلة',
                style: TextStyle(fontWeight: FontWeight.bold))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('سلة الرحلة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (bag.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              tooltip: 'تفريغ السلة',
              onPressed: () {
                bag.clearBag();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تفريغ السلة')),
                );
              },
            ),
        ],
      ),
      body: bag.isEmpty
          ? _buildEmptyState(context, theme)
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bag.itemCount,
                    itemBuilder: (context, index) {
                      final place = bag.bagItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.place,
                                color: theme.colorScheme.primary),
                          ),
                          title: Text(place['name'] ?? 'مكان',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(place['categoryName'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => bag.removePlace(place['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // ✅ التعديل: تمرير عناصر السلة في extra
                        context.push('/trips/planner', extra: bag.bagItems);
                      },
                      icon: const Icon(Icons.rocket_launch),
                      label: Text('إنشاء رحلة (${bag.itemCount} أماكن)'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(55),
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined,
                size: 100, color: theme.colorScheme.outline),
            const SizedBox(height: 24),
            Text('سلتك فارغة',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'أضف بعض الأماكن إلى سلتك لتبدأ التخطيط لرحلتك القادمة.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.explore),
              label: const Text('اكتشف أماكن'),
              style: FilledButton.styleFrom(minimumSize: const Size(200, 50)),
            ),
          ],
        ),
      ),
    );
  }
}
