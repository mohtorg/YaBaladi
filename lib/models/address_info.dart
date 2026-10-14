// lib/models/address_info.dart
//
// [v1.0 — 2026-10-14] — G4.2-c-4: Address info model
//   - نموذج للعنوان المُستخرَج من Reverse Geocoding (Nominatim).
//   - يُستخدم في BrowsingLocationController + WelcomeHeader.

class AddressInfo {
  const AddressInfo({
    this.governorate,
    this.district,
    this.displayName,
    this.lat,
    this.lng,
  });

  /// المحافظة — مثلاً "بورسعيد".
  final String? governorate;

  /// الحي/المنطقة — مثلاً "الشرق".
  final String? district;

  /// العنوان الكامل من Nominatim — "الشرق، بورسعيد، مصر".
  final String? displayName;

  /// الإحداثيات التي تم استخدامها.
  final double? lat;
  final double? lng;

  /// تسمية مختصرة للعرض: "بورسعيد - الشرق".
  String get shortLabel {
    final g = governorate?.trim();
    final d = district?.trim();

    if (g != null && g.isNotEmpty && d != null && d.isNotEmpty) {
      return '$g - $d';
    }
    if (g != null && g.isNotEmpty) return g;
    if (d != null && d.isNotEmpty) return d;
    return 'موقع غير معروف';
  }

  /// هل المعلومات كافية للعرض؟
  bool get hasData =>
      (governorate?.isNotEmpty ?? false) || (district?.isNotEmpty ?? false);

  /// من JSON Nominatim.
  factory AddressInfo.fromNominatim(
    Map<String, dynamic> json, {
    required double lat,
    required double lng,
  }) {
    final address = json['address'] as Map<String, dynamic>?;
    if (address == null) {
      return AddressInfo(lat: lat, lng: lng);
    }

    // Nominatim يُعيد حقولاً بأسماء مختلفة حسب المنطقة:
    // - state: المحافظة
    // - suburb, county, city_district: الحي/المنطقة
    final governorate = address['state'] as String?;
    final district = (address['suburb'] ??
        address['city_district'] ??
        address['county'] ??
        address['neighbourhood']) as String?;

    return AddressInfo(
      governorate: governorate,
      district: district,
      displayName: json['display_name'] as String?,
      lat: lat,
      lng: lng,
    );
  }

  @override
  String toString() => 'AddressInfo($shortLabel, lat=$lat, lng=$lng)';
}
