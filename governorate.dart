// models/governorate.dart
//
// نموذج المحافظة الحقيقي في النظام.
// السبب في فصله عن CityInfo القديم: التوسع على مستوى الجمهورية يحتاج
// فصل المحافظة عن المدينة/المنطقة. لا تستخدم governorateId مكان cityId
// في المستقبل عندما نضيف مدنًا ومناطق داخل المحافظة.

class GovernorateInfo {
  final String id;
  final String nameAr;
  final String nameEn;

  const GovernorateInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
  });

  String nameFor(String lang) => lang == 'en' ? nameEn : nameAr;

  factory GovernorateInfo.fromMap(String id, Map<String, dynamic> map) {
    return GovernorateInfo(
      id: id,
      nameAr: map['name_ar'] ?? '',
      nameEn: map['name_en'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name_ar': nameAr,
        'name_en': nameEn,
      };
}

// توافق مؤقت مع الكود القديم؛ لا تستخدم CityInfo في ملفات جديدة.
typedef CityInfo = GovernorateInfo;
