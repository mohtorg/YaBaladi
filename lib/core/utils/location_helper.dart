// lib/core/utils/location_helper.dart

class LocationHelper {
  /// دالة لتجميع أجزاء العنوان وتجاهل الحقول الفارغة
  static String formatLocation({
    String? geoZoneName,
    String? city,
    String? governorate,
    String? address,
  }) {
    final parts = [geoZoneName, city, governorate]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();

    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }

    // إذا لم توجد منطقة أو مدينة، نعرض العنوان التفصيلي كبديل
    if (address != null && address.trim().isNotEmpty) {
      return address.trim();
    }

    return 'موقع غير محدد';
  }
}
