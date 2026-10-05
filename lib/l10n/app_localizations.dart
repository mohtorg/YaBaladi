import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'يا بلادي'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك'**
  String get welcome;

  /// No description provided for @home.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get home;

  /// No description provided for @search.
  ///
  /// In ar, this message translates to:
  /// **'البحث'**
  String get search;

  /// No description provided for @profile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settings;

  /// No description provided for @favorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get favorites;

  /// No description provided for @notifications.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notifications;

  /// No description provided for @login.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get login;

  /// No description provided for @register.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get register;

  /// No description provided for @logout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get email;

  /// No description provided for @password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'هل نسيت كلمة المرور؟'**
  String get forgotPassword;

  /// No description provided for @categories.
  ///
  /// In ar, this message translates to:
  /// **'التصنيفات'**
  String get categories;

  /// No description provided for @restaurants.
  ///
  /// In ar, this message translates to:
  /// **'مطاعم'**
  String get restaurants;

  /// No description provided for @cafes.
  ///
  /// In ar, this message translates to:
  /// **'مقاهي'**
  String get cafes;

  /// No description provided for @events.
  ///
  /// In ar, this message translates to:
  /// **'فعاليات'**
  String get events;

  /// No description provided for @historicalPlaces.
  ///
  /// In ar, this message translates to:
  /// **'أماكن تاريخية'**
  String get historicalPlaces;

  /// No description provided for @cinema.
  ///
  /// In ar, this message translates to:
  /// **'سينما'**
  String get cinema;

  /// No description provided for @gyms.
  ///
  /// In ar, this message translates to:
  /// **'صالات رياضية'**
  String get gyms;

  /// No description provided for @nearby.
  ///
  /// In ar, this message translates to:
  /// **'بالقرب مني'**
  String get nearby;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج'**
  String get noResults;

  /// No description provided for @noInternet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت'**
  String get noInternet;

  /// No description provided for @settingsGeneral.
  ///
  /// In ar, this message translates to:
  /// **'عام'**
  String get settingsGeneral;

  /// No description provided for @settingsAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsAccount;

  /// No description provided for @settingsLegal.
  ///
  /// In ar, this message translates to:
  /// **'القانوني والسياسات'**
  String get settingsLegal;

  /// No description provided for @settingsAdvanced.
  ///
  /// In ar, this message translates to:
  /// **'متقدم'**
  String get settingsAdvanced;

  /// No description provided for @languageLabel.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get languageLabel;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSelectTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get languageSelectTitle;

  /// No description provided for @languageSelectSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تطبيق التغيير فورًا'**
  String get languageSelectSubtitle;

  /// No description provided for @languageArabicSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'RTL — من اليمين لليسار'**
  String get languageArabicSubtitle;

  /// No description provided for @languageEnglishSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'LTR — من اليسار لليمين'**
  String get languageEnglishSubtitle;

  /// No description provided for @languageCurrent.
  ///
  /// In ar, this message translates to:
  /// **'اللغة الحالية'**
  String get languageCurrent;

  /// No description provided for @themeLabel.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get themeLabel;

  /// No description provided for @themeSelectTitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر المظهر'**
  String get themeSelectTitle;

  /// No description provided for @themeSelectSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'سيتم تطبيق التغيير فورًا'**
  String get themeSelectSubtitle;

  /// No description provided for @themeSystem.
  ///
  /// In ar, this message translates to:
  /// **'النظام'**
  String get themeSystem;

  /// No description provided for @themeSystemSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يتبع إعدادات الجهاز'**
  String get themeSystemSubtitle;

  /// No description provided for @themeLight.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get themeLight;

  /// No description provided for @themeLightSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'واجهة نهارية'**
  String get themeLightSubtitle;

  /// No description provided for @themeDark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get themeDark;

  /// No description provided for @themeDarkSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'واجهة ليلية'**
  String get themeDarkSubtitle;

  /// No description provided for @themeCurrent.
  ///
  /// In ar, this message translates to:
  /// **'المظهر الحالي'**
  String get themeCurrent;

  /// No description provided for @locationLabel.
  ///
  /// In ar, this message translates to:
  /// **'الموقع'**
  String get locationLabel;

  /// No description provided for @locationOnDemand.
  ///
  /// In ar, this message translates to:
  /// **'حسب الحاجة'**
  String get locationOnDemand;

  /// No description provided for @locationOnDemandSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'يُطلب عند الاستخدام فقط'**
  String get locationOnDemandSubtitle;

  /// No description provided for @locationAlways.
  ///
  /// In ar, this message translates to:
  /// **'دائمًا'**
  String get locationAlways;

  /// No description provided for @locationAlwaysSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'متاح دائمًا (غير موصى به)'**
  String get locationAlwaysSubtitle;

  /// No description provided for @locationDisabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّل'**
  String get locationDisabled;

  /// No description provided for @locationDisabledSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'لن يعمل البحث القريب'**
  String get locationDisabledSubtitle;

  /// No description provided for @notificationsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsLabel;

  /// No description provided for @notificationsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات التطبيق'**
  String get notificationsSubtitle;

  /// No description provided for @notificationsEnabled.
  ///
  /// In ar, this message translates to:
  /// **'مفعّلة'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In ar, this message translates to:
  /// **'معطّلة'**
  String get notificationsDisabled;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicyLabel;

  /// No description provided for @privacyPolicySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف نحمي بياناتك'**
  String get privacyPolicySubtitle;

  /// No description provided for @termsLabel.
  ///
  /// In ar, this message translates to:
  /// **'الشروط والأحكام'**
  String get termsLabel;

  /// No description provided for @termsSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'قواعد الاستخدام'**
  String get termsSubtitle;

  /// No description provided for @aboutLabel.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get aboutLabel;

  /// No description provided for @aboutSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'معلومات وتراخيص'**
  String get aboutSubtitle;

  /// No description provided for @versionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الإصدار'**
  String get versionLabel;

  /// No description provided for @versionValue.
  ///
  /// In ar, this message translates to:
  /// **'1.0.0+1'**
  String get versionValue;

  /// No description provided for @clearCacheLabel.
  ///
  /// In ar, this message translates to:
  /// **'مسح الذاكرة المؤقتة'**
  String get clearCacheLabel;

  /// No description provided for @clearCacheSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف البيانات المخزنة مؤقتًا'**
  String get clearCacheSubtitle;

  /// No description provided for @clearCacheConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد مسح البيانات المخزنة مؤقتًا؟'**
  String get clearCacheConfirm;

  /// No description provided for @clearCacheSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم مسح الذاكرة المؤقتة'**
  String get clearCacheSuccess;

  /// No description provided for @deleteAccountLabel.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccountLabel;

  /// No description provided for @deleteAccountSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف دائم لا يمكن التراجع عنه'**
  String get deleteAccountSubtitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In ar, this message translates to:
  /// **'هذا الإجراء لا يمكن التراجع عنه'**
  String get deleteAccountWarning;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد حذف حسابك نهائيًا؟'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountButton.
  ///
  /// In ar, this message translates to:
  /// **'حذف حسابي'**
  String get deleteAccountButton;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج؟'**
  String get logoutConfirmMessage;

  /// No description provided for @confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @yes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get no;

  /// No description provided for @apply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get apply;

  /// No description provided for @select.
  ///
  /// In ar, this message translates to:
  /// **'اختيار'**
  String get select;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بياناتك للوصول إلى حسابك'**
  String get loginSubtitle;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'انضم إلى مجتمع يا بلادي'**
  String get registerSubtitle;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك لإرسال رابط الاستعادة'**
  String get forgotPasswordSubtitle;

  /// No description provided for @displayName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get displayName;

  /// No description provided for @confirmPassword.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد كلمة المرور'**
  String get confirmPassword;

  /// No description provided for @noAccountYet.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟'**
  String get noAccountYet;

  /// No description provided for @haveAccountAlready.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب بالفعل؟'**
  String get haveAccountAlready;

  /// No description provided for @sendResetLink.
  ///
  /// In ar, this message translates to:
  /// **'إرسال رابط الاستعادة'**
  String get sendResetLink;

  /// No description provided for @resetEmailSent.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال رابط الاستعادة إلى بريدك الإلكتروني'**
  String get resetEmailSent;

  /// No description provided for @errorEmailRequired.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني مطلوب'**
  String get errorEmailRequired;

  /// No description provided for @errorEmailInvalid.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني غير صالح'**
  String get errorEmailInvalid;

  /// No description provided for @errorPasswordRequired.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور مطلوبة'**
  String get errorPasswordRequired;

  /// No description provided for @errorPasswordShort.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور قصيرة جدًا (6 أحرف على الأقل)'**
  String get errorPasswordShort;

  /// No description provided for @errorPasswordsMismatch.
  ///
  /// In ar, this message translates to:
  /// **'كلمتا المرور غير متطابقتين'**
  String get errorPasswordsMismatch;

  /// No description provided for @errorNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'الاسم مطلوب'**
  String get errorNameRequired;

  /// No description provided for @errorNameShort.
  ///
  /// In ar, this message translates to:
  /// **'الاسم قصير جدًا'**
  String get errorNameShort;

  /// No description provided for @profileActivity.
  ///
  /// In ar, this message translates to:
  /// **'نشاطي'**
  String get profileActivity;

  /// No description provided for @profileStatsFavorites.
  ///
  /// In ar, this message translates to:
  /// **'مفضلة'**
  String get profileStatsFavorites;

  /// No description provided for @profileStatsRatings.
  ///
  /// In ar, this message translates to:
  /// **'تقييمات'**
  String get profileStatsRatings;

  /// No description provided for @profileStatsPlaces.
  ///
  /// In ar, this message translates to:
  /// **'أماكني'**
  String get profileStatsPlaces;

  /// No description provided for @profileStatsPhotos.
  ///
  /// In ar, this message translates to:
  /// **'صوري'**
  String get profileStatsPhotos;

  /// No description provided for @profileGovernorateUnknown.
  ///
  /// In ar, this message translates to:
  /// **'غير محدد'**
  String get profileGovernorateUnknown;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أماكن في المفضلة'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ باستكشاف الأماكن واحفظ ما يعجبك'**
  String get favoritesEmptySubtitle;

  /// No description provided for @discoverPlaces.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف الأماكن'**
  String get discoverPlaces;

  /// No description provided for @searchComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'البحث قادم قريبًا'**
  String get searchComingSoon;

  /// No description provided for @settingsAppearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsAppearance;

  /// No description provided for @settingsPrivacySection.
  ///
  /// In ar, this message translates to:
  /// **'الخصوصية والأذونات'**
  String get settingsPrivacySection;

  /// No description provided for @settingsDangerSection.
  ///
  /// In ar, this message translates to:
  /// **'منطقة الخطر'**
  String get settingsDangerSection;

  /// No description provided for @continueAsGuest.
  ///
  /// In ar, this message translates to:
  /// **'متابعة كزائر'**
  String get continueAsGuest;

  /// No description provided for @guest.
  ///
  /// In ar, this message translates to:
  /// **'زائر'**
  String get guest;

  /// No description provided for @loginRequired.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول مطلوب'**
  String get loginRequired;

  /// No description provided for @loginRequiredMessage.
  ///
  /// In ar, this message translates to:
  /// **'هذه الميزة متاحة للمسجلين فقط. سجّل دخولك للاستفادة من كل إمكانيات التطبيق.'**
  String get loginRequiredMessage;

  /// No description provided for @maybeLater.
  ///
  /// In ar, this message translates to:
  /// **'لاحقًا'**
  String get maybeLater;

  /// No description provided for @or.
  ///
  /// In ar, this message translates to:
  /// **'أو'**
  String get or;

  /// No description provided for @guestNote.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك تصفح التطبيق كزائر. بعض الميزات تتطلب تسجيل الدخول.'**
  String get guestNote;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مكان...'**
  String get searchHint;

  /// No description provided for @searchIdleHint.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بالبحث عن مكان'**
  String get searchIdleHint;

  /// No description provided for @noSearchResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة'**
  String get noSearchResults;

  /// No description provided for @filters.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get filters;

  /// No description provided for @filterRating.
  ///
  /// In ar, this message translates to:
  /// **'التقييم'**
  String get filterRating;

  /// No description provided for @filterPrice.
  ///
  /// In ar, this message translates to:
  /// **'السعر'**
  String get filterPrice;

  /// No description provided for @filterSort.
  ///
  /// In ar, this message translates to:
  /// **'الترتيب'**
  String get filterSort;

  /// No description provided for @filterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get filterAll;

  /// No description provided for @sortRatingDesc.
  ///
  /// In ar, this message translates to:
  /// **'الأعلى تقييمًا'**
  String get sortRatingDesc;

  /// No description provided for @sortReviewsDesc.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر مراجعات'**
  String get sortReviewsDesc;

  /// No description provided for @sortNameAsc.
  ///
  /// In ar, this message translates to:
  /// **'الأبجدي'**
  String get sortNameAsc;

  /// No description provided for @sortNewest.
  ///
  /// In ar, this message translates to:
  /// **'الأحدث'**
  String get sortNewest;

  /// No description provided for @applyFilters.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clearFilters;

  /// No description provided for @noResultsWithFilters.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج بهذه الفلاتر'**
  String get noResultsWithFilters;

  /// No description provided for @viewOnMap.
  ///
  /// In ar, this message translates to:
  /// **'عرض على الخريطة'**
  String get viewOnMap;

  /// No description provided for @directions.
  ///
  /// In ar, this message translates to:
  /// **'الاتجاهات'**
  String get directions;

  /// No description provided for @details.
  ///
  /// In ar, this message translates to:
  /// **'التفاصيل'**
  String get details;

  /// No description provided for @recenter.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التمركز'**
  String get recenter;

  /// No description provided for @noCoordinates.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إحداثيات لعرض هذا المكان على الخريطة'**
  String get noCoordinates;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
