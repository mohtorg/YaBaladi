// models/governorate_visual_profile.dart
//
// طبقة الصور الخاصة بالمحافظة فوق الهوية الوطنية.
// السبب: الصورة المحلية يجب أن تكون قابلة للتغيير من لوحة الإدارة بدون
// إعادة إصدار التطبيق، مع حفظ مصدر الصورة وبيانات الترخيص والائتمان.
// لا تضع روابط صور عشوائية أو صورًا مأخوذة من الإنترنت دون إثبات حق الاستخدام.

class GovernorateVisualProfile {
  final String governorateId;
  final String heroImageUrl;
  final List<String> galleryImageUrls;
  final String credit;
  final String sourceUrl;
  final String license;
  final String photographer;
  final bool usageApproved;
  final bool published;

  const GovernorateVisualProfile({
    required this.governorateId,
    this.heroImageUrl = '',
    this.galleryImageUrls = const [],
    this.credit = '',
    this.sourceUrl = '',
    this.license = '',
    this.photographer = '',
    this.usageApproved = false,
    this.published = false,
  });

  factory GovernorateVisualProfile.fromMap(
    String governorateId,
    Map<String, dynamic> map,
  ) {
    return GovernorateVisualProfile(
      governorateId: governorateId,
      heroImageUrl: (map['heroImageUrl'] ?? '').toString(),
      galleryImageUrls: List<String>.from(map['galleryImageUrls'] ?? const []),
      credit: (map['credit'] ?? '').toString(),
      sourceUrl: (map['sourceUrl'] ?? '').toString(),
      license: (map['license'] ?? '').toString(),
      photographer: (map['photographer'] ?? '').toString(),
      usageApproved: map['usageApproved'] == true,
      published: map['published'] == true,
    );
  }

  Map<String, dynamic> toMap() => {
        'heroImageUrl': heroImageUrl.trim(),
        'galleryImageUrls': galleryImageUrls,
        'credit': credit.trim(),
        'sourceUrl': sourceUrl.trim(),
        'license': license.trim(),
        'photographer': photographer.trim(),
        'usageApproved': usageApproved,
        'published': published,
      };
}
