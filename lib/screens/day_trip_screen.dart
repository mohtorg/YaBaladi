// screens/day_trip_screen.dart
//
// ط§ظ„ظ…ط±ط­ظ„ط© ط§ظ„ط£ظˆظ„ظ‰ ظ…ظ† "ط±ط­ظ„ط© ط§ظ„ظٹظˆظ…": ظˆط§ط¬ظ‡ط© ظپط¹ظ„ظٹط© ظ…ط±طھط¨ط·ط© ط¨ط¨ظٹط§ظ†ط§طھ Firestore ط§ظ„ط­ط§ظ„ظٹط©.
// ظ„ط§ ظ†ط¯ظ‘ط¹ظٹ ظ‡ظ†ط§ ظˆط¬ظˆط¯ ظ…ط­ط±ظƒ ط°ظƒظٹ ظ„ظ„ط±ط­ظ„ط§طھ ظ‚ط¨ظ„ ط¨ظ†ط§ط، ط¨ظٹط§ظ†ط§طھ ط§ظ„ط³ط§ط¹ط§طھ ظˆط§ظ„ظ…ط³ط§ظپط§طھ ظˆط§ظ„ط£ط­ط¯ط§ط«.
// ط§ظ„ظ…ط³طھط®ط¯ظ… ظٹط®طھط§ط± ط§ظ‡طھظ…ط§ظ…ظ‹ط§طŒ ط«ظ… ظٹط±ظ‰ ط§ظ„ط£ظ…ط§ظƒظ† ط§ظ„ظ…ظ†ط´ظˆط±ط© ط§ظ„ظ…طھط§ط­ط© ظپظٹ ط§ظ„ظ…ط­ط§ظپط¸ط©.
// ظ‡ط°ظ‡ ط§ظ„ط´ط§ط´ط© ظ‡ظٹ ط§ظ„ط£ط³ط§ط³ ط§ظ„ط°ظٹ ط³ظٹظڈط·ظˆظ‘ط± ظ„ط§ط­ظ‚ظ‹ط§ ط¥ظ„ظ‰ ظ…ط®ط·ط· ط±ط­ظ„ط© ط²ظ…ظ†ظٹ ظƒط§ظ…ظ„.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place.dart';
import '../models/place_categories.dart';
import '../services/place_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import 'place_details_screen.dart';

class DayTripScreen extends StatefulWidget {
  final String cityId;

  const DayTripScreen({super.key, this.cityId = 'port_said'});

  @override
  State<DayTripScreen> createState() => _DayTripScreenState();
}

class _DayTripScreenState extends State<DayTripScreen> {
  final PlaceService _placeService = PlaceService();
  String? _selectedCategory;
  bool _loading = true;
  String? _error;
  List<Place> _places = [];
  StreamSubscription<Position>? _locationSubscription;
  final LocationService _locationService = LocationService();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    _startLiveLocation();
  }

  @override
  void didUpdateWidget(covariant DayTripScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityId != widget.cityId) _loadPlaces();
  }

  void _startLiveLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.watchPosition(distanceFilterMeters: 25).listen((position) {
      if (!mounted) return;
      setState(() => _currentPosition = position);
    });
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final places = await _placeService.getPlacesByCity(widget.cityId);
      if (!mounted) return;
      setState(() {
        _places = places;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'طھط¹ط°ط± طھط­ظ…ظٹظ„ ط§ظ„ط£ظ…ط§ظƒظ† ط­ط§ظ„ظٹظ‹ط§.';
        _loading = false;
      });
    }
  }

  List<Place> get _filteredPlaces {
    final filtered = _selectedCategory == null
        ? List<Place>.from(_places)
        : _places.where((place) => place.category == _selectedCategory).toList();
    final position = _currentPosition;
    if (position == null) return filtered;
    filtered.sort((a, b) {
      final da = _locationService.distanceInKm(
        userLat: position.latitude,
        userLng: position.longitude,
        placeLat: a.latitude,
        placeLng: a.longitude,
      );
      final db = _locationService.distanceInKm(
        userLat: position.latitude,
        userLng: position.longitude,
        placeLat: b.latitude,
        placeLng: b.longitude,
      );
      return da.compareTo(db);
    });
    return filtered;
  }


  @override
  Widget build(BuildContext context) {
    final visiblePlaces = _filteredPlaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ط±ط­ظ„ط© ط§ظ„ظٹظˆظ…'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlaces,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'ط§ط¨ط¯ط£ ظٹظˆظ…ظƒ ظ…ظ† ظ‡ظ†ط§',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'ط§ط®طھط± ط§ظ‡طھظ…ط§ظ…ظƒ ط§ظ„ط¢ظ†. ط³ظ†ط¨ظ†ظٹ ظ„ط§ط­ظ‚ظ‹ط§ ط±ط­ظ„ط© ط²ظ…ظ†ظٹط© ظƒط§ظ…ظ„ط© ط­ط³ط¨ ط§ظ„ظˆظ‚طھ ظˆط§ظ„ظ…ط³ط§ظپط© ظˆط§ظ„ظ…ظٹط²ط§ظ†ظٹط© ظˆط³ط§ط¹ط§طھ ط§ظ„ط¹ظ…ظ„.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: 'ط§ظ„ظƒظ„',
                    selected: _selectedCategory == null,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  ...PlaceCategories.all.take(12).map(
                    (category) => _CategoryChip(
                      label: category.labelAr,
                      selected: _selectedCategory == category.id,
                      onTap: () => setState(() => _selectedCategory = category.id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _MessageCard(message: _error!, onRetry: _loadPlaces)
            else if (visiblePlaces.isEmpty)
              const _MessageCard(
                message: 'ظ„ط§ طھظˆط¬ط¯ ط£ظ…ط§ظƒظ† ظ…ظ†ط´ظˆط±ط© ظ…طھط§ط­ط© ظ„ظ‡ط°ط§ ط§ظ„ط§ط®طھظٹط§ط± ط­ط§ظ„ظٹظ‹ط§.',
              )
            else
              ...visiblePlaces.map(
                (place) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 68,
                        height: 68,
                        child: place.imageUrl.isEmpty
                            ? const ColoredBox(
                                color: Color(0xFFEAF0F7),
                                child: Icon(Icons.place),
                              )
                            : Image.network(place.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    title: Text(place.nameAr, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(_currentPosition == null
                          ? '${place.category} â€¢ ${place.rating.toStringAsFixed(1)} â­گ'
                          : '${place.category} â€¢ ${place.rating.toStringAsFixed(1)} â­گ â€¢ ${_locationService.distanceInKm(userLat: _currentPosition!.latitude, userLng: _currentPosition!.longitude, placeLat: place.latitude, placeLng: place.longitude).toStringAsFixed(1)} ظƒظ…'),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place)),
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({required this.label, required this.selected, required this.onTap});


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _MessageCard({required this.message, this.onRetry});


  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.explore_off, size: 42, color: Colors.grey),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: const Text('ط¥ط¹ط§ط¯ط© ط§ظ„ظ…ط­ط§ظˆظ„ط©')),
            ],
          ],
        ),
      ),
    );
  }
}

