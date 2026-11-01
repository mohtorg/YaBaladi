// lib/features/places/screens/near_me_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/place_card.dart';
import '../../../core/utils/distance_helper.dart';
import '../../../core/services/zone_service.dart'; // ✅ استيراد خدمة الأحياء

class NearMeScreen extends StatefulWidget {
  const NearMeScreen({super.key});

  @override
  State<NearMeScreen> createState() => _NearMeScreenState();
}

class _NearMeScreenState extends State<NearMeScreen> {
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;
  String _currentZoneName = 'جاري تحديد المنطقة...'; // ✅ متغير لحفظ اسم الحي

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _error = 'خدمة الموقع غير مفعلة';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'تم رفض صلاحية الموقع';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = 'صلاحية الموقع مرفوضة نهائياً';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      // ✅ جلب اسم المنطقة بناءً على الإحداثيات
      final zoneName = await ZoneService()
          .getZoneName(position.latitude, position.longitude);

      setState(() {
        _currentPosition = position;
        _currentZoneName = zoneName ?? 'منطقة غير معروفة';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطأ في جلب الموقع: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الأقرب إليك')),
      body: Column(
        children: [
          // ✅ شريط يعرض الحي الحالي للمستخدم
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Row(
              children: [
                Icon(Icons.my_location,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'أنت الآن في: $_currentZoneName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // قائمة الأماكن
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('places')
                  .where('isActive', isEqualTo: true)
                  .where('location', isNotEqualTo: null)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('لا توجد أماكن قريبة حالياً'));
                }

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final locA = (a.data() as Map)['location'] as GeoPoint?;
                  final locB = (b.data() as Map)['location'] as GeoPoint?;
                  if (locA == null || locB == null) return 0;
                  final distA = DistanceHelper.calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      locA.latitude,
                      locA.longitude);
                  final distB = DistanceHelper.calculateDistance(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                      locB.latitude,
                      locB.longitude);
                  return distA.compareTo(distB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final loc = data['location'] as GeoPoint?;
                    final distance = loc != null
                        ? DistanceHelper.calculateDistance(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            loc.latitude,
                            loc.longitude)
                        : null;
                    final images = (data['imageUrls'] as List?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [];

                    return PlaceCard(
                      placeId: docs[index].id,
                      nameAr: data['nameAr'] ?? data['name'] ?? 'بدون اسم',
                      nameEn: data['nameEn'] ?? '',
                      imageUrl: images.isNotEmpty ? images.first : null,
                      rating:
                          (data['averageRating'] as num?)?.toDouble() ?? 0.0,
                      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
                      categoryId: data['categoryId'],
                      geoZoneName: data['geoZoneName'],
                      city: data['city'],
                      governorate: data['governorate'],
                      address: data['address'],
                      distanceInKm: distance,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
