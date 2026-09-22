// models/audience_tags.dart
// قائمة فئات الجمهور المتاحة لتصنيف الأماكن - ثابتة زي المحافظات بالظبط
// كل فئة هنا وصفية (معلومة عن المكان) مش قيدًا يستبعد المستخدم

import 'package:flutter/material.dart';

class AudienceTag {
  final String id;
  final String labelAr;
  final String labelEn;
  final IconData icon;

  const AudienceTag({
    required this.id,
    required this.labelAr,
    required this.labelEn,
    required this.icon,
  });

  String labelFor(String lang) => lang == 'en' ? labelEn : labelAr;
}

class AudienceTags {
  static const List<AudienceTag> all = [
    AudienceTag(id: 'family', labelAr: 'عائلي', labelEn: 'Family', icon: Icons.family_restroom),
    AudienceTag(id: 'kids_friendly', labelAr: 'مناسب للأطفال', labelEn: 'Kids Friendly', icon: Icons.child_care),
    AudienceTag(id: 'seniors', labelAr: 'كبار السن', labelEn: 'Seniors', icon: Icons.elderly),
    AudienceTag(id: 'accessible', labelAr: 'ذوو الاحتياجات الخاصة', labelEn: 'Accessible', icon: Icons.accessible),
    AudienceTag(id: 'women_only', labelAr: 'سيدات فقط', labelEn: 'Women Only', icon: Icons.woman),
    AudienceTag(id: 'men_only', labelAr: 'رجال فقط', labelEn: 'Men Only', icon: Icons.man),
    AudienceTag(id: 'couples', labelAr: 'مناسب للأزواج', labelEn: 'Couples', icon: Icons.favorite),
    AudienceTag(id: 'solo', labelAr: 'مناسب للفردي', labelEn: 'Solo Friendly', icon: Icons.person),
    AudienceTag(id: 'young_adults', labelAr: 'شباب', labelEn: 'Young Adults', icon: Icons.groups),
    AudienceTag(id: 'photography', labelAr: 'محبو التصوير', labelEn: 'Photography', icon: Icons.photo_camera),
    AudienceTag(id: 'business', labelAr: 'أعمال واجتماعات', labelEn: 'Business', icon: Icons.business_center),
    AudienceTag(id: 'students', labelAr: 'طلاب', labelEn: 'Students', icon: Icons.school),
  ];

  static AudienceTag? getById(String id) {
    try {
      return all.firstWhere((tag) => tag.id == id);
    } catch (_) {
      return null;
    }
  }
}
