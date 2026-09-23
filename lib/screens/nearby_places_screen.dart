// screens/nearby_places_screen.dart
// الغرض: ترتيب الأماكن المنشورة حسب المسافة من موقع المستخدم الحالي.
// الأمان والخصوصية: الموقع لا يُحفظ في Firestore هنا؛ يستخدم محليًا للفرز فقط.
// إذا رفض المستخدم صلاحية الموقع، لا نخترع مسافة ونطلب منه تفعيلها أو نعرض القائمة العامة.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../services/location_service.dart';
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
  StreamSubscription<Position>? _locationSubscription;
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _load();
    _startLiveLocation();
  }

  void _startLiveLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.watchPosition(distanceFilterMeters: 20).listen((position) {
      if (!mounted || _items.isEmpty) return;
      final updated = _items
          .map((item) => _NearbyPlace(
                item.place,
                _locationService.distanceInKm(
                  userLat: position.latitude,
                  userLng: position.longitude,
                  placeLat: item.place.latitude,
                  placeLng: item.place.longitude,
                ),
              ))
          .toList()
        ..sort((a, b) => (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity));
      setState(() {
        _items = updated;
        _message = null;
      });
    });
  }

  Future<void> _load() async {
    setState(() { _loading = true; _message = null; });
    try {
      final lang = LocaleController.of(context).locale.languageCode;
      final places = await PlaceService().getPlacesByCity(widget.cityId);
      final result = await LocationService().getCurrentLocation(allowCached: true);
      if (!result.isSuccess || result.position == null) {
        if (!mounted) return;
        setState(() {
          _items = places.map((p) => _NearbyPlace(p, null)).toList();
          _message = AppStrings.of('location_unavailable_nearby', lang);
          _loading = false;
        });
        return;
      }
      final position = result.position!;
      final items = places
          .map((p) => _NearbyPlace(
                p,
                LocationService().distanceInKm(
                  userLat: position.latitude,
                  userLng: position.longitude,
                  placeLat: p.latitude,
                  placeLng: p.longitude,
                ),
              ))
          .toList()
        ..sort((a, b) => (a.distanceKm ?? double.infinity).compareTo(b.distanceKm ?? double.infinity));
      if (!mounted) return;
      setState(() {
        _items = items;
        _message = result.source == LocationSource.cached || result.source == LocationSource.lastKnown
            ? AppStrings.of('location_offline_cached', lang)
            : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _message = AppStrings.of('location_unavailable_nearby', LocaleController.of(context).locale.languageCode); _loading = false; });
    }
  }


  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

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
