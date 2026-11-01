// lib/l10n/pending_strings.dart
//
// [v1.5 — 2026-10-25] — MyReviewsScreen strings
//   - NEW: myReviewsTitle, noReviewsInCategory, deleteReviewTitle,
//          deleteReviewConfirm, deleteAction, reviewDeleted, deleteFailed,
//          reviewsAverageFrom, fiveStars, fourStars, belowFourStars,
//          sortLabel, noReviewsYet, startReviewingHint.
//   - REUSE (ARB): error, cancel, filterAll, sortNewest, sortRatingDesc.
//
// [v1.4 — 2026-10-25] — ExploreScreen strings
//   - NEW: showAllAction, locationUnavailable, errorWithMessage,
//          noProvidersNearby, noPlacesMatch, clearFiltersAction,
//          showGovernoratePlaces, distanceMeters, distanceKilometers.
//   - REUSE: searchHint, filters (ARB) و sortNearest (v1.1).
//
// [v1.3 — 2026-10-25] — PlaceDetailsScreen strings
//   - NEW: addressLabel, phoneLabel, reviewsFeature, alreadyReviewed,
//          thanksForReview, addedToFavorites, removedFromFavorites,
//          favoriteUpdateFailed, callAction, whatsappAction,
//          cannotOpenPhone, cannotOpenWhatsApp, placeNotFound.
//   - REUSE (ARB): favorites.
//
// [v1.2 — 2026-10-25] — NoInternetView strings
//   - NEW: noInternetTitle, noInternetBody, retryNow.
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

  // ─── NoInternetView ───
  String get noInternetTitle =>
      _isArabic ? 'أهلاً بك في يا بلدي! 🏙️' : 'Welcome to Ya Baladi! 🏙️';

  String get noInternetBody => _isArabic
      ? 'يبدو أنك انقطعت عن الإنترنت!\nلا تقلق، يمكنك تصفح الأماكن التي زرتها سابقاً (إذا كانت محفوظة)، أو إعادة المحاولة عند استعادة الاتصال.'
      : 'Looks like you are offline!\nDon\'t worry, you can browse places you visited before (if saved), or try again once the connection is back.';

  String get retryNow => _isArabic ? 'إعادة المحاولة الآن' : 'Retry now';

  // ─── PlaceDetailsScreen ───
  String get addressLabel => _isArabic ? 'العنوان' : 'Address';

  String get phoneLabel => _isArabic ? 'الهاتف' : 'Phone';

  /// اسم الميزة في حوار «تسجيل الدخول مطلوب».
  String get reviewsFeature => _isArabic ? 'المراجعات' : 'Reviews';

  String get alreadyReviewed => _isArabic
      ? 'لديك مراجعة على هذا المكان بالفعل'
      : 'You have already reviewed this place';

  String get thanksForReview => _isArabic
      ? 'شكراً على مشاركة تجربتك!'
      : 'Thanks for sharing your experience!';

  String get addedToFavorites =>
      _isArabic ? 'أُضيف إلى المفضلة' : 'Added to favorites';

  String get removedFromFavorites =>
      _isArabic ? 'أُزيل من المفضلة' : 'Removed from favorites';

  String favoriteUpdateFailed(Object error) => _isArabic
      ? 'تعذّر تحديث المفضلة: $error'
      : 'Could not update favorites: $error';

  String get callAction => _isArabic ? 'اتصال' : 'Call';

  String get whatsappAction => _isArabic ? 'واتساب' : 'WhatsApp';

  String get cannotOpenPhone =>
      _isArabic ? 'تعذر فتح تطبيق الهاتف' : 'Could not open the phone app';

  String get cannotOpenWhatsApp =>
      _isArabic ? 'تعذر فتح واتساب' : 'Could not open WhatsApp';

  String get placeNotFound =>
      _isArabic ? 'هذا المكان غير موجود' : 'This place was not found';

  // ─── ExploreScreen ───
  String get showAllAction => _isArabic ? 'عرض الكل' : 'Show all';

  String get locationUnavailable => _isArabic
      ? 'تعذر تحديد موقعك. تأكد من تفعيل GPS.'
      : 'Could not determine your location. Make sure GPS is enabled.';

  String errorWithMessage(Object error) =>
      _isArabic ? 'حدث خطأ: $error' : 'An error occurred: $error';

  String get noProvidersNearby => _isArabic
      ? 'لا يوجد مقدمي خدمة قرب منك حالياً.'
      : 'No service providers near you right now.';

  String get noPlacesMatch =>
      _isArabic ? 'لا توجد أماكن تطابق بحثك.' : 'No places match your search.';

  String get clearFiltersAction => _isArabic ? 'مسح الفلاتر' : 'Clear filters';

  String get showGovernoratePlaces =>
      _isArabic ? 'عرض الأماكن في المحافظة' : 'Show places in the governorate';

  String distanceMeters(int meters) => _isArabic ? '$meters م' : '$meters m';

  String distanceKilometers(String km) => _isArabic ? '$km كم' : '$km km';

  // ─── MyReviewsScreen ───
  String get myReviewsTitle => _isArabic ? 'تقييماتي' : 'My reviews';

  String get noReviewsInCategory => _isArabic
      ? 'لا توجد تقييمات في هذه الفئة'
      : 'No reviews in this category';

  String get deleteReviewTitle => _isArabic ? 'حذف التقييم' : 'Delete review';

  String get deleteReviewConfirm => _isArabic
      ? 'هل أنت متأكد من حذف هذا التقييم؟'
      : 'Are you sure you want to delete this review?';

  String get deleteAction => _isArabic ? 'حذف' : 'Delete';

  String get reviewDeleted => _isArabic ? 'تم حذف التقييم' : 'Review deleted';

  String get deleteFailed => _isArabic ? 'تعذّر الحذف' : 'Could not delete';

  String reviewsAverageFrom(int total) => _isArabic
      ? 'متوسط تقييماتك من $total مراجعة'
      : 'Your average rating from $total reviews';

  String get fiveStars => _isArabic ? '5 نجوم' : '5 stars';

  String get fourStars => _isArabic ? '4 نجوم' : '4 stars';

  String get belowFourStars => _isArabic ? 'أقل من 4' : 'Below 4';

  String get sortLabel => _isArabic ? 'الترتيب:' : 'Sort:';

  String get noReviewsYet => _isArabic
      ? 'لم تكتب أي تقييم بعد'
      : 'You haven\'t written any reviews yet';

  String get startReviewingHint => _isArabic
      ? 'ابدأ بتقييم الأماكن التي زرتها'
      : 'Start by rating the places you visited';
}
