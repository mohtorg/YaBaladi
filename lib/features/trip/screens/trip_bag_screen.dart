// lib/features/trip/screens/trip_bag_screen.dart
//
// [v1.3 — 2026-11-01] — UI ENHANCEMENT & SHARE FEATURE
//   - KEPT: All original TripBagController logic (clearBag, bagItems, etc.)
//   - KEPT: Navigation to '/trips/planner' and '/home'.
//   - ADDED: WhatsApp Share button in AppBar.
//   - ADDED: Navigation to PlaceDetailsScreen on tap.
//   - ADDED: Confirmation dialog before clearing the bag.
//   - IMPROVED: Card design and empty state UI.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/trip_bag_controller.dart';
import '../../../features/places/screens/place_details_screen.dart';
import '../../../theme/design_tokens.dart';

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
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: YaBaladiDesignTokens.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('سلة الرحلة',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: YaBaladiDesignTokens.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          // ✅ زر مشاركة الرحلة (WhatsApp)
          if (bag.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'مشاركة الرحلة',
              onPressed: () => _shareTrip(bag.bagItems),
            ),
          // ✅ زر تفريغ السلة
          if (bag.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: 'تفريغ السلة',
              onPressed: () => _showClearConfirmation(context, bag),
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
                      return _buildTripCard(context, theme, place, bag);
                    },
                  ),
                ),
                // زر إنشاء الرحلة (الأصلي الخاص بك)
                Container(
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(
                        top: BorderSide(
                            color: theme.colorScheme.outlineVariant)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      )
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        // ✅ التعديل: تمرير عناصر السلة في extra كما في الكود الأصلي
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

  // ✅ تصميم بطاقة المكان المحسنة
  Widget _buildTripCard(BuildContext context, ThemeData theme,
      Map<String, dynamic> place, TripBagController bag) {
    final name = place['name'] ?? 'مكان';
    final category = place['categoryName'] ?? 'تصنيف';
    final governorate = place['governorate'] ?? '';
    final placeId = place['id'];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          if (placeId != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlaceDetailsScreen(placeId: placeId),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // أيقونة المكان
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.place,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              // تفاصيل المكان
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category,
                            size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (governorate.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on,
                              size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              governorate,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // زر الحذف
              IconButton(
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
                tooltip: 'إزالة من الرحلة',
                onPressed: () => bag.removePlace(placeId),
              ),
            ],
          ),
        ),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.shopping_bag_outlined,
                  size: 80, color: theme.colorScheme.primary),
            ),
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
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: YaBaladiDesignTokens.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ دالة تأكيد تفريغ السلة
  void _showClearConfirmation(BuildContext context, TripBagController bag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفريغ السلة'),
        content:
            const Text('هل أنت متأكد من رغبتك في إزالة جميع الأماكن من رحلتك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              bag.clearBag();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تفريغ السلة')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('تفريغ الكل'),
          ),
        ],
      ),
    );
  }

  // ✅ دالة مشاركة الرحلة
  Future<void> _shareTrip(List<Map<String, dynamic>> places) async {
    if (places.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('🗺️ *رحلتي المقترحة* (عبر تطبيق يا بلدي)');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    for (int i = 0; i < places.length; i++) {
      final p = places[i];
      buffer.writeln('${i + 1}. ${p['name']} (${p['categoryName']})');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('حمّل تطبيق "يا بلدي" واكتشف المزيد من الأماكن!');

    final text = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('https://wa.me/?text=$text');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
