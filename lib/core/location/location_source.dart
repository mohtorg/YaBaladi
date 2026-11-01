// lib/core/location/location_source.dart
//
// [v1.0 — 2026-10-19] — Wave 5.5c: LocationSource enum (ADR-5)

enum LocationSource {
  gps, // دقة عالية — قد يتأخر
  network, // دقة منخفضة — أسرع
  lastKnown, // فوري (قد يكون قديماً)
  manual, // اختيار محافظة يدوي
  onlineSearch, // بحث نصي عبر Nominatim
}

extension LocationSourceX on LocationSource {
  String get labelAr {
    switch (this) {
      case LocationSource.gps:
        return 'GPS (الأدق)';
      case LocationSource.network:
        return 'الشبكة (الأسرع)';
      case LocationSource.lastKnown:
        return 'آخر موقع معروف';
      case LocationSource.manual:
        return 'اختيار يدوي';
      case LocationSource.onlineSearch:
        return 'بحث بالاسم';
    }
  }

  String get subtitleAr {
    switch (this) {
      case LocationSource.gps:
        return 'قد يستغرق بضع ثوان';
      case LocationSource.network:
        return 'Wi-Fi / بيانات الجوال';
      case LocationSource.lastKnown:
        return 'فوري — قد يكون قديماً';
      case LocationSource.manual:
        return 'من قائمة المحافظات';
      case LocationSource.onlineSearch:
        return 'اكتب اسم مدينتك أو حيّك';
    }
  }
}
