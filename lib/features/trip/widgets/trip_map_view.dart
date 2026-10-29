// lib/features/trip/widgets/trip_map_view.dart
//
// [v2.4 — 2026-10-19] — FALLBACK: No external clustering package.
//   - Uses pure flutter_map MarkerLayer (stable, no dependency conflicts).
//   - Adds slight visual offset to overlapping pins so they don't hide each other.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/trip_plan.dart';

class TripMapView extends StatefulWidget {
  final List<TripStop> stops;
  final int currentIndex;

  const TripMapView({
    super.key,
    required this.stops,
    this.currentIndex = 0,
  });

  @override
  State<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<TripMapView> {
  final MapController _map = MapController();

  List<LatLng> get _validPoints {
    return widget.stops
        .where((s) =>
            s.lat.isFinite &&
            s.lng.isFinite &&
            !(s.lat == 0 && s.lng == 0) &&
            s.lat.abs() <= 90 &&
            s.lng.abs() <= 180)
        .map((s) => LatLng(s.lat, s.lng))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitBounds();
    });
  }

  void _fitBounds() {
    final points = _validPoints;
    if (points.isEmpty) return;

    if (points.length == 1) {
      _map.move(points.first, 14);
      return;
    }

    // حماية: التأكد من أن النقاط ليست متطابقة تماماً
    final first = points.first;
    final allSame = points.every(
      (p) => p.latitude == first.latitude && p.longitude == first.longitude,
    );

    if (allSame) {
      _map.move(first, 14);
      return;
    }

    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(50),
        maxZoom: 15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = _validPoints;
    final cs = Theme.of(context).colorScheme;

    if (points.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد إحداثيات صالحة للعرض',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // بناء العلامات مع إزاحة طفيفة لمنع الاختفاء التام
    final markers = <Marker>[];
    final usedPoints = <LatLng>{};

    for (var i = 0; i < widget.stops.length; i++) {
      final s = widget.stops[i];
      if (!s.lat.isFinite || !s.lng.isFinite || (s.lat == 0 && s.lng == 0)) {
        continue;
      }

      var point = LatLng(s.lat, s.lng);

      // إذا كان هناك علامة أخرى في نفس الإحداثيات تقريباً، أزحها قليلاً
      if (usedPoints.contains(point)) {
        final offset = 0.0001 * (i + 1);
        point = LatLng(point.latitude + offset, point.longitude + offset);
      }
      usedPoints.add(point);

      final isCurrent = i == widget.currentIndex;
      markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: Tooltip(
            message: s.placeNameAr,
            child: Container(
              decoration: BoxDecoration(
                color: isCurrent ? cs.primary : cs.secondary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: points.first,
            initialZoom: 13,
            minZoom: 5,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mohtorg.yabaladi',
            ),
            if (points.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: points,
                    strokeWidth: 4,
                    color: cs.primary.withValues(alpha: 0.6),
                  ),
                ],
              ),
            // ✅ MarkerLayer الأساسي (مستقر ولا يحتاج حزم إضافية)
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            onPressed: _fitBounds,
            child: const Icon(Icons.center_focus_strong),
          ),
        ),
      ],
    );
  }
}
