// lib/models/companion_type.dart
//
// [v1.0 — 2026-10-18] — Wave 5.1: Companion Type
//   - 5 أنواع من الرفاق
//   - كل نوع له تصنيفات مفضلة/متجنبة (تؤثر على توليد الرحلة)
//   - كل نوع له emoji + ألوان + رسالة تشويقية

import 'package:flutter/material.dart';

enum CompanionType {
  solo,      // 🧑 وحدي
  couple,    // 💑 مع شريك
  friends,   // 👫 أصدقاء
  family,    // 👨‍👩‍👧 عائلة
  withKids,  // 👶 مع أطفال
}

extension CompanionTypeX on CompanionType {
  String get code => switch (this) {
        CompanionType.solo => 'solo',
        CompanionType.couple => 'couple',
        CompanionType.friends => 'friends',
        CompanionType.family => 'family',
        CompanionType.withKids => 'with_kids',
      };

  String get labelAr => switch (this) {
        CompanionType.solo => 'وحدي',
        CompanionType.couple => 'مع شريك',
        CompanionType.friends => 'أصدقاء',
        CompanionType.family => 'عائلة',
        CompanionType.withKids => 'مع أطفال',
      };

  String get tagline => switch (this) {
        CompanionType.solo => 'مغامرة شخصية، حرية كاملة',
        CompanionType.couple => 'لحظات رومانسية، جلسات هادئة',
        CompanionType.friends => 'ضحك، مغامرة، حياة ليلية',
        CompanionType.family => 'دفء، أماكن آمنة، مسافات قصيرة',
        CompanionType.withKids => 'مرح، أمان، مرافق مناسبة',
      };

  String get emoji => switch (this) {
        CompanionType.solo => '🧑',
        CompanionType.couple => '💑',
        CompanionType.friends => '👫',
        CompanionType.family => '👨‍👩‍👧',
        CompanionType.withKids => '👶',
      };

  /// اللون المميز للبطاقة.
  Color get color => switch (this) {
        CompanionType.solo => const Color(0xFF2196F3),    // أزرق
        CompanionType.couple => const Color(0xFFE91E63),  // وردي
        CompanionType.friends => const Color(0xFFFF9800), // برتقالي
        CompanionType.family => const Color(0xFF4CAF50),  // أخضر
        CompanionType.withKids => const Color(0xFF9C27B0),// بنفسجي
      };

  /// التصنيفات المفضلة — تُعطي دفعة +30% في الترتيب.
  List<String> get preferredCategories => switch (this) {
        CompanionType.solo => ['landmarks', 'cafes', 'shopping', 'parks'],
        CompanionType.couple => ['beaches', 'cafes', 'restaurants', 'landmarks'],
        CompanionType.friends => ['restaurants', 'shopping', 'events', 'beaches'],
        CompanionType.family => ['landmarks', 'parks', 'beaches', 'family', 'restaurants'],
        CompanionType.withKids => ['parks', 'beaches', 'family', 'landmarks'],
      };

  /// التصنيفات المتجنبة — تُعطي خصم -30% في الترتيب.
  List<String> get avoidedCategories => switch (this) {
        CompanionType.solo => ['family'],
        CompanionType.couple => ['family'],
        CompanionType.friends => ['family'],
        CompanionType.family => ['nightlife'],
        CompanionType.withKids => ['nightlife', 'events'],
      };
}

CompanionType companionFromCode(String? code) {
  return switch (code) {
    'solo' => CompanionType.solo,
    'couple' => CompanionType.couple,
    'friends' => CompanionType.friends,
    'family' => CompanionType.family,
    'with_kids' => CompanionType.withKids,
    _ => CompanionType.family,
  };
}