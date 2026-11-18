// lib/features/trip/screens/trip_bag_screen.dart
//
// [v2.0 - DARK THEME + BUG FIXES]
//   - FIXED: ScaffoldMessenger crash in _showClearConfirmation (captured before pop).
//   - FIXED: placeId type safety (cast to String explicitly).
//   - FIXED: Ink splash warning on Card (added clipBehavior).
//   - IMPROVED: Dark theme (#0F172A) matching entire trip flow.
//   - IMPROVED: _shareTrip now has mounted checks.
//   - KEPT: All logic, share feature, and navigation.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/trip_bag_controller.dart';
import '../../../features/places/screens/place_details_screen.dart';

class TripBagScreen extends StatelessWidget {
  const TripBagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bag = context.watch<TripBagController>();

    if (!bag.isInitialized) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'سلة الرحلة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (bag.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              tooltip: 'مشاركة الرحلة',
              onPressed: () => _shareTrip(context, bag.bagItems),
            ),
          if (bag.itemCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.white),
              tooltip: 'تفريغ السلة',
              onPressed: () => _showClearConfirmation(context, bag),
            ),
        ],
      ),
      body: SafeArea(
        child: bag.isEmpty
            ? _buildEmptyState(context)
            : Column(
                children: [
                  // ─── Counter ───
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${bag.itemCount} ${bag.itemCount == 1 ? "مكان" : "أماكن"}',
                            style: const TextStyle(
                              color: Color(0xFF0EA5E9),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'جاهز للتخطيط',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ─── Places List ───
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: bag.itemCount,
                      itemBuilder: (context, index) {
                        final place = bag.bagItems[index];
                        return _buildTripCard(context, place, bag);
                      },
                    ),
                  ),

                  // ─── Bottom Button ───
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      border: Border(
                        top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push('/trips/planner', extra: bag.bagItems);
                        },
                        icon: const Icon(Icons.rocket_launch, size: 22),
                        label: Text(
                          'إنشاء رحلة (${bag.itemCount} أماكن)',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: const Color(0xFF0EA5E9),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TRIP CARD
  // ═══════════════════════════════════════════════════════════════

  Widget _buildTripCard(
      BuildContext context, Map<String, dynamic> place, TripBagController bag) {
    final name = (place['name'] ?? 'مكان').toString();
    final category = (place['categoryName'] ?? 'تصنيف').toString();
    final governorate = (place['governorate'] ?? '').toString();
    // ✅ Type safety: cast to String
    final placeId = place['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      // ✅ Material for ink splash
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (placeId.isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PlaceDetailsScreen(placeId: placeId),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 55,
                  height: 55,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.place,
                    color: Color(0xFF0EA5E9),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.category,
                              size: 13, color: Color(0xFF0EA5E9)),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          if (governorate.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.location_on,
                                size: 13, color: Color(0xFF0EA5E9)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                governorate,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
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
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Color(0xFFEF4444), size: 22),
                  tooltip: 'إزالة من الرحلة',
                  onPressed: () {
                    if (placeId.isNotEmpty) bag.removePlace(placeId);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 72,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'سلتك فارغة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف بعض الأماكن إلى سلتك لتبدأ التخطيط لرحلتك القادمة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.explore),
              label: const Text('اكتشف أماكن'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 50),
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // CLEAR CONFIRMATION  [BUG FIXED]
  // ═══════════════════════════════════════════════════════════════

  void _showClearConfirmation(BuildContext context, TripBagController bag) {
    // ✅ Capture messenger BEFORE the dialog
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'تفريغ السلة',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إزالة جميع الأماكن من رحلتك؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            onPressed: () {
              bag.clearBag();
              Navigator.pop(dialogCtx);
              // ✅ Use captured messenger (dialogCtx is now dead)
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('تم تفريغ السلة'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444)),
            child: const Text('تفريغ الكل'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARE TRIP
  // ═══════════════════════════════════════════════════════════════

  Future<void> _shareTrip(
      BuildContext context, List<Map<String, dynamic>> places) async {
    if (places.isEmpty) return;

    // ✅ Capture messenger BEFORE await
    final messenger = ScaffoldMessenger.of(context);

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

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('تعذّر فتح واتساب')),
        );
      }
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('خطأ في المشاركة: $e')),
      );
    }
  }
}
