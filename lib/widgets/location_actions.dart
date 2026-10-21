// lib/widgets/location_actions.dart
// [v2.0 — 2026-10-20] — Elegant single-button design with map pin icon.

import 'package:flutter/material.dart';
import '../services/map_service.dart';

/// زر أنيق على شكل "Pill" مع دبوس خريطة.
/// يناسب البطاقات والشاشات التفصيلية.
class LocationActions extends StatelessWidget {
  final double lat;
  final double lng;
  final String? label;
  final bool large;

  const LocationActions({
    super.key,
    required this.lat,
    required this.lng,
    this.label,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final displayLabel = label ?? 'الخريطة';
    final hPad = large ? 18.0 : 12.0;
    final vPad = large ? 10.0 : 7.0;
    final iconSize = large ? 20.0 : 16.0;
    final fontSize = large ? 14.0 : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => MapService.openLocation(lat, lng),
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 0.95),
                primary.withValues(alpha: 0.65),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: Colors.white, size: iconSize),
              SizedBox(width: large ? 6 : 4),
              Text(
                displayLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// نسخة مصغرة للأيقونة فقط (تُستخدم في AppBar).
class LocationActionIcon extends StatelessWidget {
  final double lat;
  final double lng;

  const LocationActionIcon({
    super.key,
    required this.lat,
    required this.lng,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'افتح على الخريطة',
      icon: const Icon(Icons.location_on),
      onPressed: () => MapService.openLocation(lat, lng),
    );
  }
}
