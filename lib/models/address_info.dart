// lib/models/address_info.dart
//
// [v1.1 — 2026-10-18] — Defensive Casting + Consistency
//   - FIX: json['address'] defensive cast (is Map check بدل as Map?)
//     → لا يرمي لو كانت Nominatim تُرجع Address كـ Map<dynamic, dynamic>
//   - FIX: address['state'] / suburb / city_district / county / neighbourhood
//     defensive casts (is String check)
//   - FIX: json['display_name'] defensive cast
//   - NEW: copyWith(), ==, hashCode — للاتساق مع باقي النماذج
//   - NEW: toJson() / fromJson() — للتخزين المؤقت (SharedPreferences)
//   - DOC: Nominatim field mapping موثق
//
// [v1.0 — 2026-10-14] — G4.2-c-4: Address info model
//   - نموذج للعنوان المُستخرَج من Reverse Geocoding (Nominatim).

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

  // ═══════════════════════════════════════════════════════════════
  // DISPLAY
  // ═══════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════
  // PARSING FROM NOMINATIM
  // ═══════════════════════════════════════════════════════════════

  /// من JSON Nominatim.
  ///
  /// **Nominatim field mapping (مصر):**
  /// - `state`          → المحافظة (governorate)
  /// - `suburb`         → الحي (district) — أدق
  /// - `city_district`  → المنطقة
  /// - `neighbourhood`  → الحي الصغير
  /// - `county`         → المنطقة الأوسع (fallback)
  ///
  /// **defensive casting:** يستخدم `is String` بدل `as String?`
  /// لتفادي `TypeError` عند بيانات قديمة/غير متوقعة.
  factory AddressInfo.fromNominatim(
    Map<String, dynamic> json, {
    required double lat,
    required double lng,
  }) {
    // defensive: address قد تكون Map<dynamic, dynamic> أو غير موجودة
    final rawAddress = json['address'];
    if (rawAddress is! Map) {
      return AddressInfo(lat: lat, lng: lng);
    }
    final address = Map<String, dynamic>.from(rawAddress);

    // defensive: governorate
    final rawGov = address['state'];
    final governorate =
        rawGov is String && rawGov.trim().isNotEmpty ? rawGov.trim() : null;

    // defensive: district (suburb → city_district → neighbourhood → county)
    String? pickDistrict() {
      final keys = ['suburb', 'city_district', 'neighbourhood', 'county'];
      for (final key in keys) {
        final raw = address[key];
        if (raw is String && raw.trim().isNotEmpty) return raw.trim();
      }
      return null;
    }

    final district = pickDistrict();

    // defensive: display_name
    final rawDisplay = json['display_name'];
    final displayName =
        rawDisplay is String && rawDisplay.isNotEmpty ? rawDisplay : null;

    return AddressInfo(
      governorate: governorate,
      district: district,
      displayName: displayName,
      lat: lat,
      lng: lng,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SERIALIZATION (للـ cache)
  // ═══════════════════════════════════════════════════════════════

  /// من JSON محلي (SharedPreferences cache).
  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      governorate: json['governorate'] as String?,
      district: json['district'] as String?,
      displayName: json['displayName'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }

  /// إلى JSON (SharedPreferences cache).
  Map<String, dynamic> toJson() => {
        if (governorate != null) 'governorate': governorate,
        if (district != null) 'district': district,
        if (displayName != null) 'displayName': displayName,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  // ═══════════════════════════════════════════════════════════════
  // COPY WITH + EQUALITY
  // ═══════════════════════════════════════════════════════════════

  AddressInfo copyWith({
    String? governorate,
    String? district,
    String? displayName,
    double? lat,
    double? lng,
  }) =>
      AddressInfo(
        governorate: governorate ?? this.governorate,
        district: district ?? this.district,
        displayName: displayName ?? this.displayName,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressInfo &&
          other.governorate == governorate &&
          other.district == district &&
          other.displayName == displayName &&
          other.lat == lat &&
          other.lng == lng;

  @override
  int get hashCode => Object.hash(governorate, district, displayName, lat, lng);

  @override
  String toString() => 'AddressInfo($shortLabel, lat=$lat, lng=$lng)';
}
