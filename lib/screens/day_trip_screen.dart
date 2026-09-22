// screens/day_trip_screen.dart
//
// المرحلة الأولى من "رحلة اليوم": واجهة فعلية مرتبطة ببيانات Firestore الحالية.
// لا ندّعي هنا وجود محرك ذكي للرحلات قبل بناء بيانات الساعات والمسافات والأحداث.
// المستخدم يختار اهتمامًا، ثم يرى الأماكن المنشورة المتاحة في المحافظة.
// هذه الشاشة هي الأساس الذي سيُطوّر لاحقًا إلى مخطط رحلة زمني كامل.

import 'package:flutter/material.dart';
import '../models/place.dart';
import '../models/place_categories.dart';
import '../services/place_service.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  @override
  void didUpdateWidget(covariant DayTripScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cityId != widget.cityId) _loadPlaces();
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
        _error = 'تعذر تحميل الأماكن حاليًا.';
        _loading = false;
      });
    }
  }

  List<Place> get _filteredPlaces {
    if (_selectedCategory == null) return _places;
    return _places.where((place) => place.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlaces = _filteredPlaces;

    return Scaffold(
      appBar: AppBar(
        title: const Text('رحلة اليوم'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPlaces,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'ابدأ يومك من هنا',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'اختر اهتمامك الآن. سنبني لاحقًا رحلة زمنية كاملة حسب الوقت والمسافة والميزانية وساعات العمل.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: 'الكل',
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
                message: 'لا توجد أماكن منشورة متاحة لهذا الاختيار حاليًا.',
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
                      child: Text('${place.category} • ${place.rating.toStringAsFixed(1)} ⭐'),
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
              OutlinedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
            ],
          ],
        ),
      ),
    );
  }
}
