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
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'يا بلدي'**
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
  /// **'1.0.0+6'**
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

  /// No description provided for @delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @copy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get copy;

  /// No description provided for @copiedToClipboard.
  ///
  /// In ar, this message translates to:
  /// **'تم النسخ إلى الحافظة'**
  String get copiedToClipboard;

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
  /// **'انضم إلى مجتمع يا بلدي'**
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
  /// **'إجراءات خطرة'**
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

  /// No description provided for @searchRecent.
  ///
  /// In ar, this message translates to:
  /// **'عمليات بحث حديثة'**
  String get searchRecent;

  /// No description provided for @searchClearAll.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get searchClearAll;

  /// No description provided for @searchQuickCategories.
  ///
  /// In ar, this message translates to:
  /// **'تصنيفات سريعة'**
  String get searchQuickCategories;

  /// No description provided for @searchTrending.
  ///
  /// In ar, this message translates to:
  /// **'الأكثر بحثًا'**
  String get searchTrending;

  /// No description provided for @searchResultsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =0{لا توجد نتائج} =1{نتيجة واحدة} =2{نتيجتان} few{{count} نتائج} many{{count} نتيجة} other{{count} نتيجة}}'**
  String searchResultsCount(int count);

  /// No description provided for @searchNoResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج لـ'**
  String get searchNoResults;

  /// No description provided for @searchTips.
  ///
  /// In ar, this message translates to:
  /// **'جرّب:'**
  String get searchTips;

  /// No description provided for @searchTip1.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة الإملاء'**
  String get searchTip1;

  /// No description provided for @searchTip2.
  ///
  /// In ar, this message translates to:
  /// **'كلمة بحث أقصر'**
  String get searchTip2;

  /// No description provided for @searchTip3.
  ///
  /// In ar, this message translates to:
  /// **'تصنيف مختلف'**
  String get searchTip3;

  /// No description provided for @searchTryCategory.
  ///
  /// In ar, this message translates to:
  /// **'أو جرّب تصنيف:'**
  String get searchTryCategory;

  /// No description provided for @searchFilters.
  ///
  /// In ar, this message translates to:
  /// **'الفلاتر'**
  String get searchFilters;

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

  /// No description provided for @continueWithGoogle.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة باستخدام جوجل'**
  String get continueWithGoogle;

  /// No description provided for @googleSignInFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل تسجيل الدخول بجوجل'**
  String get googleSignInFailed;

  /// No description provided for @registerCta.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get registerCta;

  /// No description provided for @tripsTitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلتي'**
  String get tripsTitle;

  /// No description provided for @chooseGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'اختر المحافظة'**
  String get chooseGovernorate;

  /// No description provided for @useCurrentLocation.
  ///
  /// In ar, this message translates to:
  /// **'استخدام موقعي الحالي'**
  String get useCurrentLocation;

  /// No description provided for @fromGps.
  ///
  /// In ar, this message translates to:
  /// **'من GPS'**
  String get fromGps;

  /// No description provided for @orChooseAnotherGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'أو اختر محافظة أخرى'**
  String get orChooseAnotherGovernorate;

  /// No description provided for @chooseYourGovernorate.
  ///
  /// In ar, this message translates to:
  /// **'اختر محافظتك'**
  String get chooseYourGovernorate;

  /// No description provided for @defaultBadge.
  ///
  /// In ar, this message translates to:
  /// **'افتراضي'**
  String get defaultBadge;

  /// No description provided for @determineMyLocation.
  ///
  /// In ar, this message translates to:
  /// **'تحديد موقعي'**
  String get determineMyLocation;

  /// No description provided for @locationDefined.
  ///
  /// In ar, this message translates to:
  /// **'موقع محدد'**
  String get locationDefined;

  /// No description provided for @searchPlaceTitle.
  ///
  /// In ar, this message translates to:
  /// **'بحث عن مكان'**
  String get searchPlaceTitle;

  /// No description provided for @searchPlaceHint.
  ///
  /// In ar, this message translates to:
  /// **'مثال: بورسعيد، الشرق'**
  String get searchPlaceHint;

  /// No description provided for @noMatchingResults.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد نتائج مطابقة.'**
  String get noMatchingResults;

  /// No description provided for @locationSourceGps.
  ///
  /// In ar, this message translates to:
  /// **'GPS (الأدق)'**
  String get locationSourceGps;

  /// No description provided for @locationSourceGpsSub.
  ///
  /// In ar, this message translates to:
  /// **'قد يستغرق بضع ثوان'**
  String get locationSourceGpsSub;

  /// No description provided for @locationSourceNetwork.
  ///
  /// In ar, this message translates to:
  /// **'الشبكة (الأسرع)'**
  String get locationSourceNetwork;

  /// No description provided for @locationSourceNetworkSub.
  ///
  /// In ar, this message translates to:
  /// **'Wi-Fi / بيانات الجوال'**
  String get locationSourceNetworkSub;

  /// No description provided for @locationSourceLastKnown.
  ///
  /// In ar, this message translates to:
  /// **'آخر موقع معروف'**
  String get locationSourceLastKnown;

  /// No description provided for @locationSourceLastKnownSub.
  ///
  /// In ar, this message translates to:
  /// **'فوري — قد يكون قديماً'**
  String get locationSourceLastKnownSub;

  /// No description provided for @locationSourceManual.
  ///
  /// In ar, this message translates to:
  /// **'اختيار يدوي'**
  String get locationSourceManual;

  /// No description provided for @locationSourceManualSub.
  ///
  /// In ar, this message translates to:
  /// **'من قائمة المحافظات'**
  String get locationSourceManualSub;

  /// No description provided for @locationSourceOnline.
  ///
  /// In ar, this message translates to:
  /// **'بحث بالاسم'**
  String get locationSourceOnline;

  /// No description provided for @locationSourceOnlineSub.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم مدينتك أو حيّك'**
  String get locationSourceOnlineSub;

  /// No description provided for @planYourTrip.
  ///
  /// In ar, this message translates to:
  /// **'خطط لرحلتك'**
  String get planYourTrip;

  /// No description provided for @whereToGo.
  ///
  /// In ar, this message translates to:
  /// **'إلى أين تريد أن تذهب؟'**
  String get whereToGo;

  /// No description provided for @chooseGovernorateToStart.
  ///
  /// In ar, this message translates to:
  /// **'اختر المحافظة لتبدأ التخطيط.'**
  String get chooseGovernorateToStart;

  /// No description provided for @foundInBasket.
  ///
  /// In ar, this message translates to:
  /// **'وجدنا {count} في سلتك'**
  String foundInBasket(String count);

  /// No description provided for @tripIn.
  ///
  /// In ar, this message translates to:
  /// **'رحلة في {govName}. كيف تريد أن تكون؟'**
  String tripIn(String govName);

  /// No description provided for @governorate.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get governorate;

  /// No description provided for @duration.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get duration;

  /// No description provided for @halfDay.
  ///
  /// In ar, this message translates to:
  /// **'نصف يوم'**
  String get halfDay;

  /// No description provided for @halfDaySub.
  ///
  /// In ar, this message translates to:
  /// **'~4 ساعات'**
  String get halfDaySub;

  /// No description provided for @fullDay.
  ///
  /// In ar, this message translates to:
  /// **'يوم كامل'**
  String get fullDay;

  /// No description provided for @fullDaySub.
  ///
  /// In ar, this message translates to:
  /// **'~8 ساعات'**
  String get fullDaySub;

  /// No description provided for @weekend.
  ///
  /// In ar, this message translates to:
  /// **'عطلة نهاية أسبوع'**
  String get weekend;

  /// No description provided for @weekendSub.
  ///
  /// In ar, this message translates to:
  /// **'~16 ساعة (يومان)'**
  String get weekendSub;

  /// No description provided for @customDates.
  ///
  /// In ar, this message translates to:
  /// **'تواريخ مخصصة (3 أيام أو أكثر)'**
  String get customDates;

  /// No description provided for @tripDurationDays.
  ///
  /// In ar, this message translates to:
  /// **'{days, plural, =1{مدة الرحلة: يوم واحد} =2{مدة الرحلة: يومان} few{مدة الرحلة: {days} أيام} many{مدة الرحلة: {days} يوماً} other{مدة الرحلة: {days} يوم}}'**
  String tripDurationDays(int days);

  /// No description provided for @transportMode.
  ///
  /// In ar, this message translates to:
  /// **'وسيلة النقل'**
  String get transportMode;

  /// No description provided for @transportDriving.
  ///
  /// In ar, this message translates to:
  /// **'سيارة'**
  String get transportDriving;

  /// No description provided for @transportWalking.
  ///
  /// In ar, this message translates to:
  /// **'مشي'**
  String get transportWalking;

  /// No description provided for @transportBus.
  ///
  /// In ar, this message translates to:
  /// **'حافلة'**
  String get transportBus;

  /// No description provided for @preparingBestOrder.
  ///
  /// In ar, this message translates to:
  /// **'نقوم بتجهيز أفضل ترتيب لرحلتك...'**
  String get preparingBestOrder;

  /// No description provided for @notEnoughPlaces.
  ///
  /// In ar, this message translates to:
  /// **'لم نجد أماكن كافية'**
  String get notEnoughPlaces;

  /// No description provided for @modifyOptions.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الخيارات'**
  String get modifyOptions;

  /// No description provided for @modifyPlacesManually.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الأماكن يدوياً'**
  String get modifyPlacesManually;

  /// No description provided for @finalTouches.
  ///
  /// In ar, this message translates to:
  /// **'اللمسات الأخيرة'**
  String get finalTouches;

  /// No description provided for @addTripTitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف عنواناً لرحلتك'**
  String get addTripTitle;

  /// No description provided for @tripTitleField.
  ///
  /// In ar, this message translates to:
  /// **'عنوان الرحلة'**
  String get tripTitleField;

  /// No description provided for @previous.
  ///
  /// In ar, this message translates to:
  /// **'السابق'**
  String get previous;

  /// No description provided for @generateTrip.
  ///
  /// In ar, this message translates to:
  /// **'توليد الرحلة'**
  String get generateTrip;

  /// No description provided for @next.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get next;

  /// No description provided for @saveTrip.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الرحلة'**
  String get saveTrip;

  /// No description provided for @tripSavedSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الرحلة بنجاح'**
  String get tripSavedSuccess;

  /// No description provided for @loginRequiredForSave.
  ///
  /// In ar, this message translates to:
  /// **'يجب تسجيل الدخول لحفظ الرحلة'**
  String get loginRequiredForSave;

  /// No description provided for @saveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر الحفظ'**
  String get saveFailed;

  /// No description provided for @dayNumber.
  ///
  /// In ar, this message translates to:
  /// **'اليوم {day}'**
  String dayNumber(int day);

  /// No description provided for @minutes.
  ///
  /// In ar, this message translates to:
  /// **'دقيقة'**
  String get minutes;

  /// No description provided for @minutesDual.
  ///
  /// In ar, this message translates to:
  /// **'دقيقتان'**
  String get minutesDual;

  /// No description provided for @minutesPlural.
  ///
  /// In ar, this message translates to:
  /// **'دقائق'**
  String get minutesPlural;

  /// No description provided for @stations.
  ///
  /// In ar, this message translates to:
  /// **'محطة'**
  String get stations;

  /// No description provided for @stationsDual.
  ///
  /// In ar, this message translates to:
  /// **'محطتان'**
  String get stationsDual;

  /// No description provided for @stationsPlural.
  ///
  /// In ar, this message translates to:
  /// **'محطات'**
  String get stationsPlural;

  /// No description provided for @hours.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get hours;

  /// No description provided for @hoursPlural.
  ///
  /// In ar, this message translates to:
  /// **'ساعات'**
  String get hoursPlural;

  /// No description provided for @places.
  ///
  /// In ar, this message translates to:
  /// **'مكان'**
  String get places;

  /// No description provided for @placesDual.
  ///
  /// In ar, this message translates to:
  /// **'مكانان'**
  String get placesDual;

  /// No description provided for @placesPlural.
  ///
  /// In ar, this message translates to:
  /// **'أماكن'**
  String get placesPlural;

  /// No description provided for @newTrip.
  ///
  /// In ar, this message translates to:
  /// **'رحلة جديدة'**
  String get newTrip;

  /// No description provided for @tripTo.
  ///
  /// In ar, this message translates to:
  /// **'رحلة إلى {govName}'**
  String tripTo(String govName);

  /// No description provided for @bulkImportTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة المعالم (رفع مجمع)'**
  String get bulkImportTitle;

  /// No description provided for @bulkImportIntro.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك إدخال عشرات المعالم دفعة واحدة عبر ملف Excel.\nقم بتحميل القالب، تعبئته، ثم رفعه.'**
  String get bulkImportIntro;

  /// No description provided for @downloadExcelTemplate.
  ///
  /// In ar, this message translates to:
  /// **'1. تحميل قالب الإكسل'**
  String get downloadExcelTemplate;

  /// No description provided for @pickExcelFile.
  ///
  /// In ar, this message translates to:
  /// **'2. اختيار ملف الإكسل ومراجعته'**
  String get pickExcelFile;

  /// No description provided for @confirmUploadPlaces.
  ///
  /// In ar, this message translates to:
  /// **'3. تأكيد رفع {count, plural, =1{معلم واحد} =2{معلمين} few{{count} معالم} many{{count} معلماً} other{{count} معلم}} للقاعدة'**
  String confirmUploadPlaces(int count);

  /// No description provided for @preparingTemplate.
  ///
  /// In ar, this message translates to:
  /// **'جاري تحضير القالب...'**
  String get preparingTemplate;

  /// No description provided for @templateReady.
  ///
  /// In ar, this message translates to:
  /// **'تم تجهيز القالب! يمكنك الآن حفظه أو مشاركته.'**
  String get templateReady;

  /// No description provided for @templateError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء تحضير القالب: {error}'**
  String templateError(String error);

  /// No description provided for @readingFile.
  ///
  /// In ar, this message translates to:
  /// **'جاري قراءة الملف والتحقق من البيانات...'**
  String get readingFile;

  /// No description provided for @fileSelectionCancelled.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء اختيار الملف.'**
  String get fileSelectionCancelled;

  /// No description provided for @noValidDataFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على بيانات صالحة في الملف.'**
  String get noValidDataFound;

  /// No description provided for @fileReadSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم قراءة الملف بنجاح. يرجى مراجعة النتائج أدناه.'**
  String get fileReadSuccess;

  /// No description provided for @uploadingData.
  ///
  /// In ar, this message translates to:
  /// **'جاري رفع البيانات إلى قاعدة البيانات...'**
  String get uploadingData;

  /// No description provided for @uploadSuccess.
  ///
  /// In ar, this message translates to:
  /// **'🎉 تم رفع {count, plural, =1{معلم واحد} =2{معلمين} few{{count} معالم} many{{count} معلماً} other{{count} معلم}} بنجاح!'**
  String uploadSuccess(int count);

  /// No description provided for @duplicatesSkipped.
  ///
  /// In ar, this message translates to:
  /// **'(تم تجاهل {count, plural, =1{معلم مسجل مسبقاً} =2{معلمين مسجلين مسبقاً} few{{count} معالم مسجلة مسبقاً} many{{count} معلماً مسجلاً مسبقاً} other{{count} معلم مسجل مسبقاً}})'**
  String duplicatesSkipped(int count);

  /// No description provided for @sortReport.
  ///
  /// In ar, this message translates to:
  /// **'📊 تقرير الفرز:'**
  String get sortReport;

  /// No description provided for @validPlaces.
  ///
  /// In ar, this message translates to:
  /// **'✅ معالم صالحة للرفع: {count, plural, =0{لا يوجد} =1{معلم واحد} =2{معلمين} few{{count} معالم} many{{count} معلماً} other{{count} معلم}}'**
  String validPlaces(int count);

  /// No description provided for @errorLines.
  ///
  /// In ar, this message translates to:
  /// **'❌ أسطر بها أخطاء (سيتم تجاهلها): {count, plural, =0{لا يوجد} =1{سطر واحد} =2{سطرين} few{{count} أسطر} many{{count} سطراً} other{{count} سطر}}'**
  String errorLines(int count);

  /// No description provided for @bulkUploadSuccessMsg.
  ///
  /// In ar, this message translates to:
  /// **'تمت عملية الرفع المجمع بنجاح'**
  String get bulkUploadSuccessMsg;

  /// No description provided for @noDataToUpload.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات صالحة للرفع.'**
  String get noDataToUpload;

  /// No description provided for @allPlacesAlreadyRegistered.
  ///
  /// In ar, this message translates to:
  /// **'كل المعالم الموجودة في الملف مسجلة مسبقاً في قاعدة البيانات أو مكررة داخل الملف.'**
  String get allPlacesAlreadyRegistered;

  /// No description provided for @databaseConnectionError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء الاتصال بقاعدة البيانات: {error}'**
  String databaseConnectionError(String error);

  /// No description provided for @fileReadError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ أثناء قراءة الملف. تأكد من أن الملف بصيغة xlsx صحيحة وغير تالف. ({error})'**
  String fileReadError(String error);

  /// No description provided for @templateGenerationFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل في إنشاء ملف الإكسل'**
  String get templateGenerationFailed;

  /// No description provided for @templateShareText.
  ///
  /// In ar, this message translates to:
  /// **'قالب إدخال معالم يا بلدي (بورسعيد)'**
  String get templateShareText;

  /// No description provided for @templateShareSubject.
  ///
  /// In ar, this message translates to:
  /// **'قالب استيراد المعالم'**
  String get templateShareSubject;

  /// No description provided for @noValidFcmTokens.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رموز إشعارات صالحة لهذا المستخدم.'**
  String get noValidFcmTokens;

  /// No description provided for @pushSentSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال الإشعار بنجاح.'**
  String get pushSentSuccess;

  /// No description provided for @pushFailed.
  ///
  /// In ar, this message translates to:
  /// **'فشل إرسال الإشعار.'**
  String get pushFailed;

  /// No description provided for @notificationPlaceBlockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'🚫 تم إيقاف نشاطك مؤقتاً'**
  String get notificationPlaceBlockedTitle;

  /// No description provided for @notificationPlaceBlockedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف \"{placeName}\". السبب: {reason}'**
  String notificationPlaceBlockedBody(String placeName, String reason);

  /// No description provided for @notificationPlaceUnblockedTitle.
  ///
  /// In ar, this message translates to:
  /// **'✅ تم تفعيل نشاطك'**
  String get notificationPlaceUnblockedTitle;

  /// No description provided for @notificationPlaceUnblockedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم فك الحظر عن \"{placeName}\" بنجاح. يمكنك الآن استقبال الطلبات.'**
  String notificationPlaceUnblockedBody(String placeName);

  /// No description provided for @notificationSupportReplyTitle.
  ///
  /// In ar, this message translates to:
  /// **'💬 رد جديد من الدعم'**
  String get notificationSupportReplyTitle;

  /// No description provided for @notificationSupportReplyBody.
  ///
  /// In ar, this message translates to:
  /// **'تم الرد على بلاغك ({code}). يرجى فتح تفاصيل البلاغ للمراجعة.'**
  String notificationSupportReplyBody(String code);

  /// No description provided for @notificationMerchantApprovedTitle.
  ///
  /// In ar, this message translates to:
  /// **'🎉 تم قبول طلبك'**
  String get notificationMerchantApprovedTitle;

  /// No description provided for @notificationMerchantApprovedBody.
  ///
  /// In ar, this message translates to:
  /// **'تمت الموافقة على طلبك كتاجر. ابدأ الآن في إدارة نشاطك التجاري!'**
  String get notificationMerchantApprovedBody;

  /// No description provided for @notificationMerchantRejectedTitle.
  ///
  /// In ar, this message translates to:
  /// **'⚠️ طلبك يحتاج تعديل'**
  String get notificationMerchantRejectedTitle;

  /// No description provided for @notificationMerchantRejectedBody.
  ///
  /// In ar, this message translates to:
  /// **'السبب: {reason}'**
  String notificationMerchantRejectedBody(String reason);

  /// No description provided for @notificationNewReviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'⭐ تقييم جديد على {placeName}'**
  String notificationNewReviewTitle(String placeName);

  /// No description provided for @notificationNewReviewBody.
  ///
  /// In ar, this message translates to:
  /// **'حصلت على تقييم {rating} نجوم. \"{comment}\"'**
  String notificationNewReviewBody(String rating, String comment);

  /// No description provided for @planTripAction.
  ///
  /// In ar, this message translates to:
  /// **'خطط لرحلتك'**
  String get planTripAction;

  /// No description provided for @myTripsAction.
  ///
  /// In ar, this message translates to:
  /// **'رحلاتي'**
  String get myTripsAction;

  /// No description provided for @topRatedIn.
  ///
  /// In ar, this message translates to:
  /// **'الأعلى تقييماً في {governorateName}'**
  String topRatedIn(String governorateName);

  /// No description provided for @guestBannerTitle.
  ///
  /// In ar, this message translates to:
  /// **'سجل دخولك لتجربة أفضل!'**
  String get guestBannerTitle;
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
      'that was used.');
}
