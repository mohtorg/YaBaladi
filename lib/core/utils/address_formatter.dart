// lib/core/utils/address_formatter.dart
// [v1.0 — 2026-11-17] — CENTRAL ADDRESS FORMATTER:
//   حل مركزي لجميع مشاكل عرض العنوان (بورسعيد - بورسعيد، الشارع مفقود، إلخ)
//   - Rejects invalid district values (same as governorate, empty, placeholder).
//   - Adds "حي " prefix automatically.
//   - Supports 3 display modes: full, medium, short.
//   - `smart` picks the best source (DB → GPS → Fallback) automatically.

/// وضع عرض العنوان.
enum AddressMode {
  /// "شارع الجمهورية - حي الشرق - بورسعيد"
  full,

  /// "حي الشرق - بورسعيد"
  medium,

  /// "حي الشرق" (أو "بورسعيد" فقط إذا لم نجد حياً حقيقياً)
  short,
}

abstract final class AddressFormatter {
  AddressFormatter._();

  /// Placeholder values التي لا يجب اعتبارها أحياءً حقيقية.
  static const Set<String> _placeholders = {
    'منطقة غير معروفة',
    'وسط المدينة',
    'غير محدد',
    'غير معروف',
  };

  /// هل هذه القيمة "حي حقيقي" وليست مرادفة للمحافظة؟
  ///
  /// ترفض: null، فارغ، نفس اسم المحافظة، "محافظة X"، الـ placeholders.
  static bool isRealDistrict(String? value, String? governorate) {
    if (value == null) {
      return false;
    }
    final v = value.trim();
    if (v.isEmpty) {
      return false;
    }
    if (_placeholders.contains(v)) {
      return false;
    }
    if (governorate != null) {
      final g = governorate.trim();
      if (g.isNotEmpty) {
        if (v == g) {
          return false;
        }
        if (v == 'محافظة $g') {
          return false;
        }
      }
    }
    return true;
  }

  /// يضيف بادئة "حي " تلقائياً إذا لم تكن موجودة.
  static String normalizeDistrict(String? district) {
    final d = district?.trim() ?? '';
    if (d.isEmpty) {
      return d;
    }
    if (d.startsWith('حي ') ||
        d.startsWith('مدينة ') ||
        d.startsWith('مركز ')) {
      return d;
    }
    if (d.startsWith('حي')) {
      return 'حي ${d.substring(2).trim()}';
    }
    return 'حي $d';
  }

  /// تنسيق كامل: "الشارع - الحي - المحافظة".
  ///
  /// - يتجاهل الحقول الفارغة.
  /// - يرفض تكرار اسم المحافظة كحي.
  static String full({
    String? address,
    String? district,
    String? governorate,
  }) {
    final parts = <String>[];

    final addr = address?.trim() ?? '';
    if (addr.isNotEmpty) {
      parts.add(addr);
    }

    if (isRealDistrict(district, governorate)) {
      parts.add(normalizeDistrict(district));
    }

    final gov = governorate?.trim() ?? '';
    if (gov.isNotEmpty) {
      parts.add(gov);
    }

    return parts.join(' - ');
  }

  /// تنسيق متوسط: "الحي - المحافظة".
  static String medium({
    String? district,
    String? governorate,
  }) {
    final parts = <String>[];

    if (isRealDistrict(district, governorate)) {
      parts.add(normalizeDistrict(district));
    }

    final gov = governorate?.trim() ?? '';
    if (gov.isNotEmpty) {
      parts.add(gov);
    }

    return parts.join(' - ');
  }

  /// تنسيق قصير: "الحي" فقط (أو "المحافظة" كحل أخير).
  static String short({
    String? district,
    String? governorate,
  }) {
    if (isRealDistrict(district, governorate)) {
      return normalizeDistrict(district);
    }
    final gov = governorate?.trim() ?? '';
    if (gov.isNotEmpty) {
      return gov;
    }
    return 'موقع غير معروف';
  }

  /// تنسيق ذكي: يختار أفضل مصدر للحي تلقائياً.
  ///
  /// الترتيب: `dbDistrict` (geo_zones) → `gpsDistrict` (Nominatim) → fallback.
  static String smart({
    String? address,
    String? dbDistrict,
    String? gpsDistrict,
    String? governorate,
    AddressMode mode = AddressMode.full,
  }) {
    // اختيار أفضل حي متاح
    String? district;
    if (isRealDistrict(dbDistrict, governorate)) {
      district = dbDistrict;
    } else if (isRealDistrict(gpsDistrict, governorate)) {
      district = gpsDistrict;
    }

    switch (mode) {
      case AddressMode.full:
        return full(
          address: address,
          district: district,
          governorate: governorate,
        );
      case AddressMode.medium:
        return medium(
          district: district,
          governorate: governorate,
        );
      case AddressMode.short:
        return short(
          district: district,
          governorate: governorate,
        );
    }
  }
}
