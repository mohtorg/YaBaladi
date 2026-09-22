// services/location_service.dart
//
// ============================================================
// الفكرة من الملف ده:
// خدمة مسؤولة عن حاجتين بس:
// 1) الحصول على موقع المستخدم الحالي (بعد أخذ إذنه بشكل صحيح)
// 2) حساب المسافة بالكيلومتر بين المستخدم وأي مكان في التطبيق
// أي شاشة محتاجة "الأقرب مني" هتستخدم الخدمة دي بدل ما تكرر
// نفس منطق طلب الإذن في كل مكان
// ============================================================

import 'package:geolocator/geolocator.dart';

class LocationService {
  // ------------------------------------------------------------
  // الفكرة: قبل ما نجيب موقع المستخدم، لازم نتأكد من 3 حاجات بالترتيب:
  // (أ) خدمة الموقع في الموبايل مفعّلة أصلاً (GPS شغال)
  // (ب) المستخدم إدّى إذن الوصول للموقع للتطبيق
  // (ج) لو رفض الإذن قبل كده "نهائيًا"، نوجهه للإعدادات بدل ما نكرر الطلب بلاش
  // الدالة بترجع null لو أي خطوة فشلت، عشان الشاشة تقدر تتعامل مع الحالة دي بهدوء
  // ------------------------------------------------------------
  Future<LocationResult> getCurrentLocation() async {
    // الخطوة أ: هل GPS مفعّل في الموبايل أصلاً؟
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure('خدمة الموقع مقفولة في موبايلك، فعّلها من الإعدادات');
    }

    // الخطوة ب: هل عندنا إذن بالفعل؟ لو لأ، نطلبه دلوقتي
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.failure('محتاجين إذن الموقع عشان نوريك الأقرب ليك');
      }
    }

    // الخطوة ج: رفض نهائي سابق - المستخدم لازم يفعّله يدويًا من إعدادات الموبايل
    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure('الإذن مرفوض بشكل دائم، فعّله من إعدادات التطبيق');
    }

    // كل حاجة تمام - نجيب الموقع فعليًا
    final position = await Geolocator.getCurrentPosition();
    return LocationResult.success(position);
  }

  // ------------------------------------------------------------
  // الفكرة: حساب المسافة "الفعلية" بالكيلومتر بين نقطتين على الخريطة
  // (مش مجرد فرق بسيط بين أرقام الإحداثيات - دي معادلة جغرافية صحيحة)
  // Geolocator بتوفرها جاهزة، إحنا بس بنحولها من متر لكيلومتر ونقرّبها
  // ------------------------------------------------------------
  double distanceInKm({
    required double userLat,
    required double userLng,
    required double placeLat,
    required double placeLng,
  }) {
    final meters = Geolocator.distanceBetween(userLat, userLng, placeLat, placeLng);
    return meters / 1000;
  }
}

// ------------------------------------------------------------
// الفكرة: بدل ما نرجّع Position عادي (وممكن يبقى null لأسباب كتير مختلفة)،
// بنرجّع كائن واضح فيه: هل نجحنا؟ لو لأ ليه؟ ولو نجحنا، فين بالظبط؟
// ده بيسهّل على أي شاشة تعرض رسالة واضحة للمستخدم بدل رسالة عامة غامضة
// ------------------------------------------------------------
class LocationResult {
  final bool isSuccess;
  final Position? position;
  final String? errorMessage;

  LocationResult._({required this.isSuccess, this.position, this.errorMessage});

  factory LocationResult.success(Position position) =>
      LocationResult._(isSuccess: true, position: position);

  factory LocationResult.failure(String message) =>
      LocationResult._(isSuccess: false, errorMessage: message);
}
