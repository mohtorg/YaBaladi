// lib/features/trip/screens/active_stop_screen.dart
//
// [v2.1 — 2026-11-15] — VERIFIED: Clean file, no linter issues, no address formatting needed.
// [v2.0 - UI CONSISTENCY + SMART MAPPING]
//   - ADDED: Dark theme matching the trip flow (Planner + Overview).
//   - ADDED: Friendly Arabic category label + icon (was showing raw ID).
//   - ADDED: Entrance animation (fade + slide) on the header.
//   - ADDED: SafeArea for the visited button.
//   - FIXED: Empty English name / notes handled gracefully.
//   - KEPT: pop(true) logic, LocationActions, and stop data usage.

import 'package:flutter/material.dart';
import '../../../models/trip_plan.dart';
import '../../../widgets/location_actions.dart';

class ActiveStopScreen extends StatelessWidget {
  final TripStop stop;
  const ActiveStopScreen({super.key, required this.stop});

  /// Maps a category ID to a friendly Arabic label, icon, and color.
  ({String label, IconData icon, Color color}) _categoryMeta() {
    final id = stop.categoryId.toLowerCase();
    if (id.contains('rest')) {
      return (
        label: 'مطعم',
        icon: Icons.restaurant,
        color: const Color(0xFFF59E0B)
      );
    }
    if (id.contains('cafe')) {
      return (
        label: 'مقهى',
        icon: Icons.local_cafe,
        color: const Color(0xFFA16207)
      );
    }
    if (id.contains('pharm')) {
      return (
        label: 'صيدلية',
        icon: Icons.local_pharmacy,
        color: const Color(0xFF10B981)
      );
    }
    if (id.contains('hosp')) {
      return (
        label: 'مستشفى',
        icon: Icons.local_hospital,
        color: const Color(0xFFEF4444)
      );
    }
    if (id.contains('shop')) {
      return (
        label: 'تسوق',
        icon: Icons.shopping_bag,
        color: const Color(0xFFA855F7)
      );
    }
    if (id.contains('hotel')) {
      return (label: 'فندق', icon: Icons.hotel, color: const Color(0xFF6366F1));
    }
    if (id.contains('land')) {
      return (
        label: 'معلم',
        icon: Icons.account_balance,
        color: const Color(0xFFF59E0B)
      );
    }
    if (id.contains('ent')) {
      return (
        label: 'ترفيه',
        icon: Icons.attractions,
        color: const Color(0xFFEC4899)
      );
    }
    return (label: 'مكان', icon: Icons.place, color: const Color(0xFF14B8A6));
  }

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta();
    final hasEnglish = stop.placeNameEn.trim().isNotEmpty;
    final hasNotes = stop.notes?.trim().isNotEmpty ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          stop.placeNameAr,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Animated Header ───
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 16 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildHeader(meta, hasEnglish),
              ),
              const SizedBox(height: 24),

              // ─── Notes Section ───
              const Text(
                'ملاحظات المحطة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      hasNotes
                          ? Icons.sticky_note_2_outlined
                          : Icons.info_outline,
                      color: Colors.white54,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hasNotes
                            ? stop.notes!
                            : 'لا توجد ملاحظات إضافية لهذه المحطة.',
                        style: TextStyle(
                          color: hasNotes ? Colors.white : Colors.white54,
                          fontSize: 14,
                          height: 1.5,
                          fontStyle:
                              hasNotes ? FontStyle.normal : FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Location Actions ───
              Center(
                child: LocationActions(
                  lat: stop.lat,
                  lng: stop.lng,
                  large: true,
                ),
              ),
              const SizedBox(height: 40),

              // ─── Visited Button ───
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_circle, size: 24),
                  label: const Text(
                    'لقد وصلت / تمت الزيارة',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      ({String label, IconData icon, Color color}) meta, bool hasEnglish) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(meta.icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            stop.placeNameAr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hasEnglish) ...[
            const SizedBox(height: 4),
            Text(
              stop.placeNameEn,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                icon: Icons.star,
                label:
                    '${stop.rating.toStringAsFixed(1)} (${stop.reviewCount})',
                color: Colors.amber.shade300,
              ),
              _HeaderChip(
                icon: meta.icon,
                label: meta.label,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}