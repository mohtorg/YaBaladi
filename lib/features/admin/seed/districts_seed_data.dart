// lib/features/admin/seed/districts_seed_data.dart
// [v1.0 — 2026-10-29] — Wave 17: بيانات أولية لأحياء المحافظات

/// بيانات أولية قابلة للتوسع لكل محافظة.
/// المفتاح: docId الخاص بالمحافظة في Firestore.
/// القيمة: قائمة الأحياء.
///
/// ملاحظة: `nameAr` خالٍ من كلمة "حي" (مثل "الشرق" لا "حي الشرق")
/// لتتسق مع باقي بيانات المشروع (المحافظات، التصنيفات).
class DistrictsSeedData {
  DistrictsSeedData._();

  static const Map<String, List<Map<String, String>>> _data = {
    'portsaid': [
      {'nameAr': 'الشرق', 'nameEn': 'Al-Sharq'},
      {'nameAr': 'العرب', 'nameEn': 'Al-Arab'},
      {'nameAr': 'المناخ', 'nameEn': 'Al-Manakh'},
      {'nameAr': 'الزهور', 'nameEn': 'Al-Zuhur'},
      {'nameAr': 'الضواحي', 'nameEn': 'Al-Dawahi'},
      {'nameAr': 'الجنوب', 'nameEn': 'Al-Janoub'},
      {'nameAr': 'بورفؤاد', 'nameEn': 'Port Fuad'},
      {'nameAr': 'غرب', 'nameEn': 'West'},
    ],
    // يمكن إضافة محافظات أخرى لاحقاً بنفس البنية.
  };

  /// يعيد قائمة الأحياء لمحافظة معينة، أو `null` إذا لم تكن متوفرة.
  static List<Map<String, String>>? forGovernorate(String docId) {
    return _data[docId];
  }
}
