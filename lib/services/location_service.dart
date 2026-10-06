import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// نتيجة تحديد الموقع.
class LocationData {
  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.governorateAr,
    required this.governorateEn,
  });

  final double latitude;
  final double longitude;
  final String governorateAr;
  final String governorateEn;
}

/// خدمة الموقع: صلاحيات + جلب الإحداثيات + تحديد المحافظة (من 27 محافظة).
class LocationService {
  LocationService._();

  /// مراكز المحافظات المصرية الـ 27 (lat, lng) + الاسم عربي/إنجليزي.
  static const List<_Gov> _governorates = [
    _Gov('القاهرة', 'Cairo', 30.0444, 31.2357),
    _Gov('الجيزة', 'Giza', 30.0131, 31.2089),
    _Gov('الإسكندرية', 'Alexandria', 31.2001, 29.9187),
    _Gov('الدقهلية', 'Dakahlia', 31.0409, 31.3785),
    _Gov('البحر الأحمر', 'Red Sea', 26.0000, 33.8000),
    _Gov('البحيرة', 'Beheira', 30.8481, 30.3436),
    _Gov('الفيوم', 'Fayoum', 29.3084, 30.8428),
    _Gov('الغربية', 'Gharbia', 30.8754, 31.0335),
    _Gov('الإسماعيلية', 'Ismailia', 30.5965, 32.2715),
    _Gov('المنوفية', 'Menoufia', 30.5972, 30.9876),
    _Gov('المنيا', 'Minya', 28.1099, 30.7503),
    _Gov('القليوبية', 'Qalyubia', 30.4260, 31.1897),
    _Gov('الوادي الجديد', 'New Valley', 25.4497, 30.5455),
    _Gov('السويس', 'Suez', 29.9668, 32.5498),
    _Gov('أسوان', 'Aswan', 24.0889, 32.8998),
    _Gov('أسيوط', 'Assiut', 27.1809, 31.1837),
    _Gov('بني سويف', 'Beni Suef', 29.0661, 31.0994),
    _Gov('بورسعيد', 'Port Said', 31.2653, 32.3019),
    _Gov('دمياط', 'Damietta', 31.4165, 31.8133),
    _Gov('جنوب سيناء', 'South Sinai', 28.5000, 34.0000),
    _Gov('كفر الشيخ', 'Kafr El Sheikh', 31.1107, 30.9388),
    _Gov('مطروح', 'Matrouh', 31.3543, 27.2373),
    _Gov('الأقصر', 'Luxor', 25.6872, 32.6396),
    _Gov('قنا', 'Qena', 26.1551, 32.7160),
    _Gov('شمال سيناء', 'North Sinai', 31.1333, 33.8000),
    _Gov('سوهاج', 'Sohag', 26.5591, 31.6957),
    _Gov('الشرقية', 'Sharqia', 30.5877, 31.5020),
  ];

  /// يفحص إذا خدمة الموقع مفعّلة على الجهاز.
  static Future<bool> isServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  /// يطلب صلاحية الموقع (إذا لم تُمنح بعد).
  /// يعيد `true` لو ممنوحة، `false` لو مرفوضة.
  static Future<bool> requestPermission() async {
    var perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// يجلب الموقع الحالي ويحدّد المحافظة.
  /// يعيد `null` لو الخدمة معطّلة أو الصلاحية مرفوضة.
  static Future<LocationData?> getCurrentLocation() async {
    try {
      // 1. تأكد إن خدمة الموقع مفعّلة
      if (!await isServiceEnabled()) {
        debugPrint('LocationService: services disabled');
        return null;
      }

      // 2. اطلب الصلاحية
      if (!await requestPermission()) {
        debugPrint('LocationService: permission denied');
        return null;
      }

      // 3. اجلب الموقع (API الحديث — geolocator 13.x)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // 4. حدّد المحافظة الأقرب
      final gov = _nearestGovernorate(pos.latitude, pos.longitude);

      return LocationData(
        latitude: pos.latitude,
        longitude: pos.longitude,
        governorateAr: gov.nameAr,
        governorateEn: gov.nameEn,
      );
    } catch (e) {
      debugPrint('LocationService: error $e');
      return null;
    }
  }

  /// يجد المحافظة الأقرب بالإحداثيات (Haversine distance).
  static _Gov _nearestGovernorate(double lat, double lng) {
    _Gov nearest = _governorates.first;
    double minDist = double.infinity;

    for (final gov in _governorates) {
      final d = _haversine(lat, lng, gov.lat, gov.lng);
      if (d < minDist) {
        minDist = d;
        nearest = gov;
      }
    }
    return nearest;
  }

  /// المسافة بالكيلومترات بين نقطتين (Haversine).
  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // نصف قطر الأرض بالكم
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}

/// بيانات محافظة.
class _Gov {
  const _Gov(this.nameAr, this.nameEn, this.lat, this.lng);

  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;
}