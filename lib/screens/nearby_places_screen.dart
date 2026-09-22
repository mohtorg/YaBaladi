// screens/nearby_places_screen.dart
// الغرض: ترتيب الأماكن المنشورة حسب المسافة من موقع المستخدم الحالي.
// الأمان والخصوصية: الموقع لا يُحفظ في Firestore هنا؛ يستخدم محليًا للفرز فقط.
// إذا رفض المستخدم صلاحية الموقع، لا نخترع مسافة ونطلب منه تفعيلها أو نعرض القائمة العامة.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../widgets/permission_explanation.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../theme/app_colors.dart';
import 'place_details_screen.dart';

class NearbyPlacesScreen extends StatefulWidget {
  final String cityId;
  const NearbyPlacesScreen({super.key, this.cityId = 'port_said'});

  @override
  State<NearbyPlacesScreen> createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen> {
  bool _loading = true;
  String? _message;
  List<_NearbyPlace> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _message = null; });
    try {
      final lang = LocaleController.of(context).locale.languageCode;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
      if (!mounted) return;
        final wantsToContinue = await showPermissionExplanation(context: context, lang: lang, titleKey: 'permission_location_title', bodyKey: 'permission_location_body');
        if (!wantsToContinue) {
          final places = await PlaceService().getPlacesByCity(widget.cityId);
          if (!mounted) return;
          setState(() { _items = places.map((p) => _NearbyPlace(p, null)).toList(); _message = AppStrings.of('permission_denied_location', lang); _loading = false; });
          return;
        }
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        final places = await PlaceService().getPlacesByCity(widget.cityId);
        if (!mounted) return;
        setState(() { _items = places.map((p) => _NearbyPlace(p, null)).toList(); _message = AppStrings.of('permission_denied_location', lang); _loading = false; });
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      final places = await PlaceService().getPlacesByCity(widget.cityId);
      final items = places.map((p) => _NearbyPlace(p, _distanceKm(position.latitude, position.longitude, p.latitude, p.longitude))).toList()..sort((a, b) => (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity));
      if (!mounted) return;
      setState(() { _items = items; _loading = false; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _message = 'تعذر تحديد موقعك حاليًا.'; _loading = false; });
    }
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const radius = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) + math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    return radius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _rad(double value) => value * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أماكن قريبة'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_message != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(_message!),
                      ),
                    ),
                  if (_items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(child: Text('لا توجد أماكن منشورة حاليًا.')),
                    )
                  else
                    ..._items.map(
                      (item) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(alpha: .10),
                            child: const Icon(Icons.place, color: AppColors.primary),
                          ),
                          title: Text(item.place.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            item.distanceKm == null
                                ? item.place.category
                                : '${item.distanceKm!.toStringAsFixed(1)} كم • ${item.place.category}',
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: item.place)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _NearbyPlace {
  final Place place;
  final double? distanceKm;
  const _NearbyPlace(this.place, this.distanceKm);
}
