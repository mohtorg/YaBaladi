// lib/core/location/location_source.dart
//
// [v1.1 — 2026-11-05] — MODERNIZED: Switched to Dart 3 switch expressions,
//                        added `isAutomatic` getter for UI logic.
// [v1.0 — 2026-10-19] — Wave 5.5c: LocationSource enum (ADR-5)

enum LocationSource {
  gps, // دقة عالية — قد يتأخر
  network, // دقة منخفضة — أسرع
  lastKnown, // فوري (قد يكون قديماً)
  manual, // اختيار محافظة يدوي
  onlineSearch, // بحث نصي عبر Nominatim
}

extension LocationSourceX on LocationSource {
  /// هل هذا المصدر يعتمد على القراءة التلقائية للجهاز/الشبكة؟
  /// (مفيد لإظهار أيقونات "تحديث تلقائي" في الواجهة).
  bool get isAutomatic => switch (this) {
        LocationSource.gps => true,
        LocationSource.network => true,
        LocationSource.lastKnown => true,
        LocationSource.manual => false,
        LocationSource.onlineSearch => false,
      };

  String get labelAr => switch (this) {
        LocationSource.gps => 'GPS (الأدق)',
        LocationSource.network => 'الشبكة (الأسرع)',
        LocationSource.lastKnown => 'آخر موقع معروف',
        LocationSource.manual => 'اختيار يدوي',
        LocationSource.onlineSearch => 'بحث بالاسم',
      };

  String get subtitleAr => switch (this) {
        LocationSource.gps => 'قد يستغرق بضع ثوان',
        LocationSource.network => 'Wi-Fi / بيانات الجوال',
        LocationSource.lastKnown => 'فوري — قد يكون قديماً',
        LocationSource.manual => 'من قائمة المحافظات',
        LocationSource.onlineSearch => 'اكتب اسم مدينتك أو حيّك',
      };
}
