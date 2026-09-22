// models/place_categories.dart
// قائمة التصنيفات الرئيسية الموحدة في التطبيق.
// السبب: منع اختلاف قيمة category بين لوحة الأدمن والصفحة الرئيسية والبحث.
// لا نستخدم هذه القائمة لفئات الجمهور؛ الجمهور موجود في AudienceTags بشكل مستقل.
import 'package:flutter/material.dart';

class PlaceCategory {
  final String id;
  final String labelAr;
  final String labelEn;
  final IconData icon;
  const PlaceCategory({required this.id, required this.labelAr, required this.labelEn, required this.icon});
}

class PlaceCategories {
  static const all = <PlaceCategory>[
    PlaceCategory(id: 'فعالية', labelAr: 'فعاليات', labelEn: 'Events', icon: Icons.celebration),
    PlaceCategory(id: 'مطعم', labelAr: 'مطاعم', labelEn: 'Restaurants', icon: Icons.restaurant),
    PlaceCategory(id: 'كافيه', labelAr: 'كافيهات', labelEn: 'Cafes', icon: Icons.coffee),
    PlaceCategory(id: 'بلاج', labelAr: 'شواطئ وبلاجات', labelEn: 'Beaches', icon: Icons.beach_access),
    PlaceCategory(id: 'قرية سياحية', labelAr: 'قرى سياحية', labelEn: 'Tourist Villages', icon: Icons.hotel),
    PlaceCategory(id: 'فندق ومنتجع', labelAr: 'فنادق ومنتجعات', labelEn: 'Hotels & Resorts', icon: Icons.king_bed),
    PlaceCategory(id: 'بيوتي سنتر', labelAr: 'بيوتي سنتر', labelEn: 'Beauty Centers', icon: Icons.spa),
    PlaceCategory(id: 'كوافير حريمي', labelAr: 'كوافير حريمي', labelEn: 'Women Salons', icon: Icons.content_cut),
    PlaceCategory(id: 'كوافير رجالي', labelAr: 'كوافير رجالي', labelEn: 'Men Salons', icon: Icons.content_cut),
    PlaceCategory(id: 'نادي', labelAr: 'نوادي وصالات جيم', labelEn: 'Clubs & Gyms', icon: Icons.fitness_center),
    PlaceCategory(id: 'ترفيه أسري', labelAr: 'أماكن أسرية وترفيهية', labelEn: 'Family & Entertainment', icon: Icons.family_restroom),
    PlaceCategory(id: 'منطقة سياحية', labelAr: 'مناطق سياحية', labelEn: 'Tourist Areas', icon: Icons.account_balance),
    PlaceCategory(id: 'معلم تاريخي', labelAr: 'معالم تاريخية', labelEn: 'Historical Landmarks', icon: Icons.museum),
    PlaceCategory(id: 'متحف', labelAr: 'متاحف', labelEn: 'Museums', icon: Icons.museum),
    PlaceCategory(id: 'حديقة', labelAr: 'حدائق ومتنزهات', labelEn: 'Parks', icon: Icons.park),
    PlaceCategory(id: 'ثقافة وفنون', labelAr: 'ثقافة وفنون', labelEn: 'Culture & Arts', icon: Icons.theater_comedy),
    PlaceCategory(id: 'تسوق', labelAr: 'تسوق', labelEn: 'Shopping', icon: Icons.shopping_bag),
    PlaceCategory(id: 'ألعاب وترفيه', labelAr: 'ألعاب وترفيه', labelEn: 'Games & Entertainment', icon: Icons.sports_esports),
    PlaceCategory(id: 'أنشطة بحرية', labelAr: 'أنشطة بحرية', labelEn: 'Water Activities', icon: Icons.sailing),
    PlaceCategory(id: 'رحلات وخروجات', labelAr: 'رحلات وخروجات', labelEn: 'Trips & Outings', icon: Icons.hiking),
    PlaceCategory(id: 'أطفال', labelAr: 'أنشطة وأماكن للأطفال', labelEn: 'Kids Activities & Places', icon: Icons.child_care),
    PlaceCategory(id: 'صحة وعناية', labelAr: 'صحة وعناية', labelEn: 'Health & Care', icon: Icons.health_and_safety),
    PlaceCategory(id: 'تعليم وتدريب', labelAr: 'تعليم وتدريب', labelEn: 'Education & Training', icon: Icons.school),
    PlaceCategory(id: 'خدمات سياحية', labelAr: 'خدمات سياحية', labelEn: 'Tourism Services', icon: Icons.travel_explore),
    PlaceCategory(id: 'خدمات', labelAr: 'خدمات', labelEn: 'Services', icon: Icons.build),
    PlaceCategory(id: 'أخرى', labelAr: 'أخرى', labelEn: 'Other', icon: Icons.more_horiz),
  ];

  static PlaceCategory? byId(String id) {
    for (final item in all) { if (item.id == id) return item; }
    return null;
  }
}
