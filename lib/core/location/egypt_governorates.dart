// lib/core/location/egypt_governorates.dart
//
// [v1.0 — 2026-10-14] — G4.2-a: قائمة المحافظات المصرية الـ27

import 'dart:math' as math;

/// محافظة مصرية واحدة.
class EgyptGovernorate {
  const EgyptGovernorate({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.lat,
    required this.lng,
    this.isDefault = false,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final double lat;
  final double lng;
  final bool isDefault;

  @override
  String toString() => 'EgyptGovernorate($id, $nameAr)';
}

/// قائمة الـ27 محافظة — مرتَّبة حسب التسلسل الإداري الرسمي.
const List<EgyptGovernorate> kEgyptGovernorates = [
  EgyptGovernorate(
      id: 'cairo',
      nameAr: 'القاهرة',
      nameEn: 'Cairo',
      lat: 30.0444,
      lng: 31.2357,
      isDefault: true),
  EgyptGovernorate(
      id: 'giza', nameAr: 'الجيزة', nameEn: 'Giza', lat: 30.0131, lng: 31.2089),
  EgyptGovernorate(
      id: 'alexandria',
      nameAr: 'الإسكندرية',
      nameEn: 'Alexandria',
      lat: 31.2001,
      lng: 29.9187),
  EgyptGovernorate(
      id: 'dakahlia',
      nameAr: 'الدقهلية',
      nameEn: 'Dakahlia',
      lat: 31.0409,
      lng: 31.3785),
  EgyptGovernorate(
      id: 'red_sea',
      nameAr: 'البحر الأحمر',
      nameEn: 'Red Sea',
      lat: 26.0000,
      lng: 33.8000),
  EgyptGovernorate(
      id: 'beheira',
      nameAr: 'البحيرة',
      nameEn: 'Beheira',
      lat: 30.8481,
      lng: 30.3436),
  EgyptGovernorate(
      id: 'fayoum',
      nameAr: 'الفيوم',
      nameEn: 'Fayoum',
      lat: 29.3084,
      lng: 30.8428),
  EgyptGovernorate(
      id: 'gharbia',
      nameAr: 'الغربية',
      nameEn: 'Gharbia',
      lat: 30.8754,
      lng: 31.0335),
  EgyptGovernorate(
      id: 'ismailia',
      nameAr: 'الإسماعيلية',
      nameEn: 'Ismailia',
      lat: 30.5965,
      lng: 32.2715),
  EgyptGovernorate(
      id: 'menoufia',
      nameAr: 'المنوفية',
      nameEn: 'Menoufia',
      lat: 30.5972,
      lng: 30.9876),
  EgyptGovernorate(
      id: 'minya',
      nameAr: 'المنيا',
      nameEn: 'Minya',
      lat: 28.1099,
      lng: 30.7503),
  EgyptGovernorate(
      id: 'qalyubia',
      nameAr: 'القليوبية',
      nameEn: 'Qalyubia',
      lat: 30.4260,
      lng: 31.1897),
  EgyptGovernorate(
      id: 'new_valley',
      nameAr: 'الوادي الجديد',
      nameEn: 'New Valley',
      lat: 25.4497,
      lng: 30.5455),
  EgyptGovernorate(
      id: 'suez', nameAr: 'السويس', nameEn: 'Suez', lat: 29.9668, lng: 32.5498),
  EgyptGovernorate(
      id: 'aswan',
      nameAr: 'أسوان',
      nameEn: 'Aswan',
      lat: 24.0889,
      lng: 32.8998),
  EgyptGovernorate(
      id: 'assiut',
      nameAr: 'أسيوط',
      nameEn: 'Assiut',
      lat: 27.1809,
      lng: 31.1837),
  EgyptGovernorate(
      id: 'beni_suef',
      nameAr: 'بني سويف',
      nameEn: 'Beni Suef',
      lat: 29.0661,
      lng: 31.0994),
  EgyptGovernorate(
      id: 'port_said',
      nameAr: 'بورسعيد',
      nameEn: 'Port Said',
      lat: 31.2653,
      lng: 32.3019),
  EgyptGovernorate(
      id: 'damietta',
      nameAr: 'دمياط',
      nameEn: 'Damietta',
      lat: 31.4165,
      lng: 31.8133),
  EgyptGovernorate(
      id: 'south_sinai',
      nameAr: 'جنوب سيناء',
      nameEn: 'South Sinai',
      lat: 28.5000,
      lng: 34.0000),
  EgyptGovernorate(
      id: 'kafr_el_sheikh',
      nameAr: 'كفر الشيخ',
      nameEn: 'Kafr El Sheikh',
      lat: 31.1107,
      lng: 30.9388),
  EgyptGovernorate(
      id: 'matrouh',
      nameAr: 'مطروح',
      nameEn: 'Matrouh',
      lat: 31.3543,
      lng: 27.2373),
  EgyptGovernorate(
      id: 'luxor',
      nameAr: 'الأقصر',
      nameEn: 'Luxor',
      lat: 25.6872,
      lng: 32.6396),
  EgyptGovernorate(
      id: 'qena', nameAr: 'قنا', nameEn: 'Qena', lat: 26.1551, lng: 32.7160),
  EgyptGovernorate(
      id: 'north_sinai',
      nameAr: 'شمال سيناء',
      nameEn: 'North Sinai',
      lat: 31.1333,
      lng: 33.8000),
  EgyptGovernorate(
      id: 'sohag',
      nameAr: 'سوهاج',
      nameEn: 'Sohag',
      lat: 26.5591,
      lng: 31.6957),
  EgyptGovernorate(
      id: 'sharqia',
      nameAr: 'الشرقية',
      nameEn: 'Sharqia',
      lat: 30.5877,
      lng: 31.5020),
];

// ═══════════════════════════════════════════════════════════════
// HELPERS
// ═══════════════════════════════════════════════════════════════

/// المحافظة الافتراضية (القاهرة).
EgyptGovernorate get kDefaultGovernorate =>
    kEgyptGovernorates.firstWhere((g) => g.isDefault);

/// البحث بـ id — يُعيد `null` إن لم يوجد.
EgyptGovernorate? governorateById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final g in kEgyptGovernorates) {
    if (g.id == id) return g;
  }
  return null;
}

/// البحث بالاسم العربي — يُعيد `null` إن لم يوجد.
EgyptGovernorate? governorateByArName(String? nameAr) {
  if (nameAr == null || nameAr.isEmpty) return null;
  for (final g in kEgyptGovernorates) {
    if (g.nameAr == nameAr) return g;
  }
  return null;
}

/// هل [id] معرّف محافظة مصرية صحيح؟
bool isEgyptGovernorateId(String? id) =>
    id != null && kEgyptGovernorates.any((g) => g.id == id);

/// أقرب محافظة لإحداثيات [lat], [lng].
EgyptGovernorate nearestGovernorate(double lat, double lng) {
  EgyptGovernorate best = kEgyptGovernorates.first;
  double bestDist = double.infinity;

  for (final g in kEgyptGovernorates) {
    final d = _haversineKm(lat, lng, g.lat, g.lng);
    if (d < bestDist) {
      bestDist = d;
      best = g;
    }
  }
  return best;
}

// ─── Haversine ───
const double _earthRadiusKm = 6371.0;

double _haversineKm(double lat1, double lng1, double lat2, double lng2) {
  double rad(double d) => d * math.pi / 180.0;

  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return _earthRadiusKm * c;
}
