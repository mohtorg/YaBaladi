// screens/map_places_screen.dart
// هذه الشاشة محفوظة كمسار تقني داخلي للخريطة الجغرافية عند الحاجة.
// لا تُعرض في الشاشة الرئيسية أو شريط التنقل؛ القرار الحالي هو أن تكون الخرائط
// الجغرافية مرتبطة بسياق المكان/الرحلة بعد اعتماد مزود الخرائط وسياسة المفاتيح.
// لا تضف SDK خرائط أو تغيّر Gradle من هنا دون قرار معماري موثق.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../theme/app_colors.dart';

class MapPlacesScreen extends StatefulWidget {
  final String cityId;
  const MapPlacesScreen({super.key, this.cityId = 'port_said'});

  @override
  State<MapPlacesScreen> createState() => _MapPlacesScreenState();
}

class _MapPlacesScreenState extends State<MapPlacesScreen> {
  late Future<List<Place>> _future;

  @override
  void initState() { super.initState(); _future = PlaceService().getPlacesByCity(widget.cityId); }

  Future<void> _openMap(Place place) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${place.latitude},${place.longitude}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح الخريطة.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخريطة'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: FutureBuilder<List<Place>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Center(child: Text('تعذر تحميل الأماكن على الخريطة.'));
          final places = snapshot.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: places.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final place = places[index];
              return Card(child: ListTile(leading: const Icon(Icons.location_on, color: AppColors.primary), title: Text(place.nameAr), subtitle: Text('${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}'), trailing: IconButton(icon: const Icon(Icons.directions), tooltip: 'فتح الخريطة', onPressed: () => _openMap(place))));
            },
          );
        },
      ),
    );
  }
}
