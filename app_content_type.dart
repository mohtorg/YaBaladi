// models/app_content_type.dart
//
// يحدد طبيعة السجل، منفصلًا عن category.
// category تصف "ما هو؟"، بينما contentType يحدد "كيف تديره المنصة؟".
// هذا الفصل مهم عند التوسع: الفعالية والحديقة ومقدم الخدمة قد تشترك
// في نفس الجمهور والخصائص، لكن لكل منها دورة تشغيل مختلفة.

class AppContentType {
  final String id;
  final String labelAr;
  final String labelEn;

  const AppContentType({
    required this.id,
    required this.labelAr,
    required this.labelEn,
  });

  String labelFor(String lang) => lang == 'en' ? labelEn : labelAr;

  static const publicPlace = AppContentType(
    id: 'public_place',
    labelAr: 'مكان عام',
    labelEn: 'Public Place',
  );

  static const garden = AppContentType(
    id: 'garden',
    labelAr: 'حديقة / متنزه',
    labelEn: 'Garden / Park',
  );

  static const event = AppContentType(
    id: 'event',
    labelAr: 'فعالية',
    labelEn: 'Event',
  );

  static const serviceProvider = AppContentType(
    id: 'service_provider',
    labelAr: 'مقدم خدمة',
    labelEn: 'Service Provider',
  );

  static const all = [publicPlace, garden, event, serviceProvider];

  static AppContentType? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}
