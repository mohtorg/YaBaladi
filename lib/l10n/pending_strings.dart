// lib/l10n/pending_strings.dart
//
// [v1.1 — 2026-10-24] — PlacesFilterSheet strings
//   - NEW: مفاتيح ورقة تصفية الأماكن (places_filter_sheet.dart).
//   - REUSE (موجودة في ARB، لا تُكرَّر هنا): close, clearFilters, filterAll,
//          filterRating, filterPrice, sortRatingDesc, sortNewest.
//
// [v1.0 — 2026-10-23] — نصوص ثنائية اللغة في انتظار الانتقال إلى ARB
//
// الغرض: إزالة النصوص العربية الثابتة من الشاشات دون تعديل ملفات ARB
// والملفات المولّدة (app_localizations*.dart) في كل مرة.
//
// طريقة الاستعمال في أي شاشة:
//   final l10n = AppLocalizations.of(context);
//   Text(l10n.planTripAction)
//
// خطة الترحيل: عند الجاهزية يُنقل كل مفتاح إلى app_ar.arb / app_en.arb
// ثم يُشغَّل `flutter gen-l10n` ويُحذف الـ getter المقابل من هنا؛ ولا يحتاج
// أي استدعاء في الشاشات إلى تغيير لأن الأسماء متطابقة.
import 'app_localizations.dart';

extension PendingStrings on AppLocalizations {
  bool get _isArabic => localeName == 'ar';

  // ─── HomeScreen ───
  String get planTripAction => _isArabic ? 'خطط رحلة' : 'Plan a trip';

  String get myTripsAction => _isArabic ? 'رحلاتي' : 'My trips';

  String topRatedIn(String governorate) => _isArabic
      ? '⭐ الأعلى تقييماً في $governorate'
      : '⭐ Top rated in $governorate';

  String get guestBannerTitle => _isArabic
      ? 'سجّل دخولك للاستفادة من كل الميزات'
      : 'Sign in to enjoy all features';

  // ─── PlacesFilterSheet ───
  String get filterSheetTitle => _isArabic ? 'تصفية النتائج' : 'Filter results';

  String get sortByTitle => _isArabic ? 'الترتيب حسب' : 'Sort by';

  String get sortRecommended => _isArabic ? 'الأنسب' : 'Best match';

  String get sortNearest => _isArabic ? 'الأقرب إليك' : 'Nearest to you';

  /// شارة التقييم داخل الشريحة، مثل: ‎3+ ★★★‎
  String ratingChoice(int stars) => '$stars+ ${'★' * stars}';

  /// شريحة الفلتر الفعّال، مثل: ‎⭐ 3+ نجوم‎
  String starsPlus(int stars) =>
      _isArabic ? '⭐ $stars+ نجوم' : '⭐ $stars+ stars';

  String get priceBudget => _isArabic ? 'اقتصادي' : 'Budget';

  String get priceMedium => _isArabic ? 'متوسط' : 'Moderate';

  String get priceHigh => _isArabic ? 'مرتفع' : 'Expensive';

  String get amenitiesTitle => _isArabic ? 'المرافق' : 'Amenities';

  String get featuresTitle => _isArabic ? 'الطابع' : 'Style';

  String selectedCount(int count) =>
      _isArabic ? '$count محدد' : '$count selected';

  String get amenityWifi => _isArabic ? 'واي فاي' : 'Wi-Fi';

  String get amenityParking => _isArabic ? 'موقف سيارات' : 'Parking';

  String get amenityRestroom => _isArabic ? 'دورات مياه' : 'Restrooms';

  String get amenityAccessibility =>
      _isArabic ? 'ذوي احتياجات' : 'Accessibility';

  String get featureFamily => _isArabic ? 'عائلي' : 'Family-friendly';

  String get featureHalal => _isArabic ? 'حلال' : 'Halal';

  String get featureDelivery => _isArabic ? 'دليفري' : 'Delivery';

  String get featureReservation => _isArabic ? 'حجوزات' : 'Reservations';

  String showResultsCount(int count) =>
      _isArabic ? 'عرض $count نتيجة' : 'Show $count results';

  String get noMatchingResults =>
      _isArabic ? 'لا توجد نتائج مطابقة' : 'No matching results';
}
