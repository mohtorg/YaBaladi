// models/egypt_governorates.dart
// قائمة المحافظات المصرية كبيانات مرجعية للتوسع الوطني.
// مهم: هذه القائمة لا تعني أن كل محافظة منشورة؛ حالة التفعيل والنشر تُدار
// من بيانات المحتوى لاحقًا. بورسعيد هي نقطة الإطلاق الحالية.

import 'governorate.dart';

class EgyptGovernorates {
  static const String activeGovernorateId = 'port_said';

  static const List<GovernorateInfo> all = [
    GovernorateInfo(id: 'cairo', nameAr: 'القاهرة', nameEn: 'Cairo'),
    GovernorateInfo(id: 'alexandria', nameAr: 'الإسكندرية', nameEn: 'Alexandria'),
    GovernorateInfo(id: 'port_said', nameAr: 'بورسعيد', nameEn: 'Port Said'),
    GovernorateInfo(id: 'suez', nameAr: 'السويس', nameEn: 'Suez'),
    GovernorateInfo(id: 'dakahlia', nameAr: 'الدقهلية', nameEn: 'Dakahlia'),
    GovernorateInfo(id: 'sharqia', nameAr: 'الشرقية', nameEn: 'Sharqia'),
    GovernorateInfo(id: 'qalyubia', nameAr: 'القليوبية', nameEn: 'Qalyubia'),
    GovernorateInfo(id: 'kafr_el_sheikh', nameAr: 'كفر الشيخ', nameEn: 'Kafr El Sheikh'),
    GovernorateInfo(id: 'gharbia', nameAr: 'الغربية', nameEn: 'Gharbia'),
    GovernorateInfo(id: 'monufia', nameAr: 'المنوفية', nameEn: 'Monufia'),
    GovernorateInfo(id: 'beheira', nameAr: 'البحيرة', nameEn: 'Beheira'),
    GovernorateInfo(id: 'ismailia', nameAr: 'الإسماعيلية', nameEn: 'Ismailia'),
    GovernorateInfo(id: 'damietta', nameAr: 'دمياط', nameEn: 'Damietta'),
    GovernorateInfo(id: 'giza', nameAr: 'الجيزة', nameEn: 'Giza'),
    GovernorateInfo(id: 'faiyum', nameAr: 'الفيوم', nameEn: 'Faiyum'),
    GovernorateInfo(id: 'beni_suef', nameAr: 'بني سويف', nameEn: 'Beni Suef'),
    GovernorateInfo(id: 'minya', nameAr: 'المنيا', nameEn: 'Minya'),
    GovernorateInfo(id: 'asyut', nameAr: 'أسيوط', nameEn: 'Asyut'),
    GovernorateInfo(id: 'sohag', nameAr: 'سوهاج', nameEn: 'Sohag'),
    GovernorateInfo(id: 'qena', nameAr: 'قنا', nameEn: 'Qena'),
    GovernorateInfo(id: 'luxor', nameAr: 'الأقصر', nameEn: 'Luxor'),
    GovernorateInfo(id: 'aswan', nameAr: 'أسوان', nameEn: 'Aswan'),
    GovernorateInfo(id: 'red_sea', nameAr: 'البحر الأحمر', nameEn: 'Red Sea'),
    GovernorateInfo(id: 'new_valley', nameAr: 'الوادي الجديد', nameEn: 'New Valley'),
    GovernorateInfo(id: 'matrouh', nameAr: 'مطروح', nameEn: 'Matrouh'),
    GovernorateInfo(id: 'north_sinai', nameAr: 'شمال سيناء', nameEn: 'North Sinai'),
    GovernorateInfo(id: 'south_sinai', nameAr: 'جنوب سيناء', nameEn: 'South Sinai'),
  ];

  static GovernorateInfo? getById(String id) {
    for (final governorate in all) {
      if (governorate.id == id) return governorate;
    }
    return null;
  }
}
