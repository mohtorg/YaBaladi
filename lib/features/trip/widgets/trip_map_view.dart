// lib/features/trip/widgets/trip_map_view.dart
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  void _fitBounds() {
    if (widget.stops.isEmpty) return;
    final points = widget.stops.map((s) => LatLng(s.lat, s.lng)).toList();
    if (points.length == 1) {
      _map.move(points.first, 14);
      return;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stops.isEmpty) {
      return const Center(child: Text('لا توجد إحداثيات للعرض'));
    }

    final points = widget.stops.map((s) => LatLng(s.lat, s.lng)).toList();
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: points.first,
            initialZoom: 13,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mohtorg.yabaladi',
            ),
            PolylineLayer(
              polylines: [
                Polyline(
                  points: points,
                  strokeWidth: 4,
                  color: cs.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
            MarkerLayer(
              markers: widget.stops.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final isCurrent = i == widget.currentIndex;

                return Marker(
                  point: LatLng(s.lat, s.lng),
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrent ? cs.primary : cs.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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
