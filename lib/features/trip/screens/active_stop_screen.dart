// lib/features/trip/screens/active_stop_screen.dart
//
// [v2.0 — 2026-10-18] — Clipboard-based URL sharing
//   - CHANGED: dart:html → Clipboard (works on Web, Mobile, and Tests)
//   - FIX: flutter test لا يفشل بعد الآن
//   - NOTE: in production, replace with url_launcher after pub get
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../models/trip_plan.dart';

class ActiveStopScreen extends StatefulWidget {
  final TripStop stop;
  const ActiveStopScreen({super.key, required this.stop});

  @override
  State<ActiveStopScreen> createState() => _ActiveStopScreenState();
}

class _ActiveStopScreenState extends State<ActiveStopScreen> {
  bool _copying = false;

  Future<void> _copyMapsLink() async {
    if (_copying) return;
    setState(() => _copying = true);

    final stop = widget.stop;
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${stop.lat},${stop.lng}';

    try {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'تم نسخ رابط Google Maps — الصقه في المتصفح',
                  style: TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _copying = false);
    }
  }

  Future<void> _copyOsmLink() async {
    try {
      await Clipboard.setData(
        const ClipboardData(
          text: 'https://www.openstreetmap.org/copyright',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نسخ رابط OpenStreetMap'),
          duration: Duration(seconds: 2),
        ),
      );
    } on Exception {
      // الصامت — لا نريد إزعاج المستخدم
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stop = widget.stop;
    final point = LatLng(stop.lat, stop.lng);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'أنت في الطريق',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 15,
                minZoom: 10,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.mohtorg.yabaladi',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 60,
                      height: 60,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 50,
                      ),
                    ),
                  ],
                ),
                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: _copyOsmLink,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stop.placeNameAr,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (stop.plannedDurationMin != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 18,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${stop.plannedDurationMin} دقيقة',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _copying ? null : _copyMapsLink,
                          icon: _copying
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.navigation, size: 28),
                          label: Text(
                            _copying
                                ? 'جارٍ النسخ…'
                                : 'انسخ رابط التوجيه (Google Maps)',
                            style: const TextStyle(fontSize: 18),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: Colors.blue.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.pop(context, true),
                          icon: const Icon(Icons.check_circle, size: 28),
                          label: const Text(
                            'لقد وصلت للمكان',
                            style: TextStyle(fontSize: 20),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            backgroundColor: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
