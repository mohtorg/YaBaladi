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
/// Select and expand the newly-created Localizations item, then choose the
/// locale or locales your application supports and add them to the list.
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

  // =====================================================================
  // 1. النصوص العامة (General)
  // =====================================================================
  String get appName;
  String get welcome;
  String get home;
  String get search;
  String get profile;
  String get settings;
  String get favorites;
  String get notifications;
  String get login;
  String get register;
  String get logout;
  String get email;
  String get password;
  String get forgotPassword;
  String get categories;
  String get restaurants;
  String get cafes;
  String get events;
  String get historicalPlaces;
  String get cinema;
  String get gyms;
  String get nearby;
  String get loading;
  String get error;
  String get retry;
  String get noResults;
  String get noInternet;
  String get settingsGeneral;
  String get settingsAccount;
  String get settingsLegal;
  String get settingsAdvanced;
  String get languageLabel;
  String get languageArabic;
  String get languageEnglish;
  String get languageSelectTitle;
  String get languageSelectSubtitle;
  String get languageArabicSubtitle;
  String get languageEnglishSubtitle;
  String get languageCurrent;
  String get themeLabel;
  String get themeSelectTitle;
  String get themeSelectSubtitle;
  String get themeSystem;
  String get themeSystemSubtitle;
  String get themeLight;
  String get themeLightSubtitle;
  String get themeDark;
  String get themeDarkSubtitle;
  String get themeCurrent;
  String get locationLabel;
  String get locationOnDemand;
  String get locationOnDemandSubtitle;
  String get locationAlways;
  String get locationAlwaysSubtitle;
  String get locationDisabled;
  String get locationDisabledSubtitle;
  String get notificationsLabel;
  String get notificationsSubtitle;
  String get notificationsEnabled;
  String get notificationsDisabled;
  String get privacyPolicyLabel;
  String get privacyPolicySubtitle;
  String get termsLabel;
  String get termsSubtitle;
  String get aboutLabel;
  String get aboutSubtitle;
  String get versionLabel;
  String get versionValue;
  String get clearCacheLabel;
  String get clearCacheSubtitle;
  String get clearCacheConfirm;
  String get clearCacheSuccess;
  String get deleteAccountLabel;
  String get deleteAccountSubtitle;
  String get deleteAccountWarning;
  String get deleteAccountConfirm;
  String get deleteAccountButton;
  String get logoutConfirmTitle;
  String get logoutConfirmMessage;
  String get confirm;
  String get cancel;
  String get save;
  String get close;
  String get yes;
  String get no;
  String get apply;
  String get select;
  String get delete;
  String get edit;
  String get done;
  String get copy;
  String get copiedToClipboard;
  String get loginTitle;
  String get loginSubtitle;
  String get registerTitle;
  String get registerSubtitle;
  String get forgotPasswordTitle;
  String get forgotPasswordSubtitle;
  String get displayName;
  String get confirmPassword;
  String get noAccountYet;
  String get haveAccountAlready;
  String get sendResetLink;
  String get resetEmailSent;
  String get errorEmailRequired;
  String get errorEmailInvalid;
  String get errorPasswordRequired;
  String get errorPasswordShort;
  String get errorPasswordsMismatch;
  String get errorNameRequired;
  String get errorNameShort;
  String get profileActivity;
  String get profileStatsFavorites;
  String get profileStatsRatings;
  String get favoritesEmptyTitle;
  String get favoritesEmptySubtitle;
  String get discoverPlaces;
  String get settingsAppearance;
  String get settingsPrivacySection;
  String get settingsDangerSection;
  String get continueAsGuest;
  String get guest;
  String get loginRequired;
  String get loginRequiredMessage;
  String get maybeLater;
  String get or;
  String get guestNote;
  String get searchHint;
  String get searchIdleHint;
  String get noSearchResults;
  String get searchRecent;
  String get searchClearAll;
  String get searchQuickCategories;
  String get searchTrending;
  String searchResultsCount(int count);
  String get searchNoResults;
  String get searchTips;
  String get searchTip1;
  String get searchTip2;
  String get searchTip3;
  String get searchTryCategory;
  String get searchFilters;
  String get filters;
  String get filterRating;
  String get filterPrice;
  String get filterSort;
  String get filterAll;
  String get sortRatingDesc;
  String get sortReviewsDesc;
  String get sortNameAsc;
  String get sortNewest;
  String get applyFilters;
  String get clearFilters;
  String get noResultsWithFilters;
  String get viewOnMap;
  String get directions;
  String get details;
  String get recenter;
  String get noCoordinates;
  String get continueWithGoogle;
  String get registerCta;
  String get googleSignInFailed;
  String get tripsTitle;

  // =====================================================================
  // 2. Location & Governorate Picker
  // =====================================================================
  String get chooseGovernorate;
  String get useCurrentLocation;
  String get fromGps;
  String get orChooseAnotherGovernorate;
  String get chooseYourGovernorate;
  String get defaultBadge;
  String get determineMyLocation;
  String get locationDefined;
  String get searchPlaceTitle;
  String get searchPlaceHint;
  String get noMatchingResults;
  String get locationSourceGps;
  String get locationSourceGpsSub;
  String get locationSourceNetwork;
  String get locationSourceNetworkSub;
  String get locationSourceLastKnown;
  String get locationSourceLastKnownSub;
  String get locationSourceManual;
  String get locationSourceManualSub;
  String get locationSourceOnline;
  String get locationSourceOnlineSub;

  // =====================================================================
  // 3. Trip Planner
  // =====================================================================
  String get planYourTrip;
  String get whereToGo;
  String get chooseGovernorateToStart;
  String foundInBasket(String count);
  String tripIn(String govName);
  String get governorate;
  String get duration;
  String get halfDay;
  String get halfDaySub;
  String get fullDay;
  String get fullDaySub;
  String get weekend;
  String get weekendSub;
  String get customDates;
  String tripDurationDays(int days);
  String get transportMode;
  String get transportDriving;
  String get transportWalking;
  String get transportBus;
  String get preparingBestOrder;
  String get notEnoughPlaces;
  String get modifyOptions;
  String get modifyPlacesManually;
  String get finalTouches;
  String get addTripTitle;
  String get tripTitleField;
  String get previous;
  String get generateTrip;
  String get next;
  String get saveTrip;
  String get tripSavedSuccess;
  String get loginRequiredForSave;
  String get saveFailed;
  String dayNumber(int day);
  String get minutes;
  String get minutesDual;
  String get minutesPlural;
  String get stations;
  String get stationsDual;
  String get stationsPlural;
  String get hours;
  String get hoursPlural;
  String get places;
  String get placesDual;
  String get placesPlural;
  String get newTrip;
  String tripTo(String govName);

  // =====================================================================
  // 4. Bulk Import (Excel)
  // =====================================================================
  String get bulkImportTitle;
  String get bulkImportIntro;
  String get downloadExcelTemplate;
  String get pickExcelFile;
  String confirmUploadPlaces(int count);
  String get preparingTemplate;
  String get templateReady;
  String templateError(String error);
  String get readingFile;
  String get fileSelectionCancelled;
  String get noValidDataFound;
  String get fileReadSuccess;
  String get uploadingData;
  String uploadSuccess(int count);
  String duplicatesSkipped(int count);
  String get sortReport;
  String validPlaces(int count);
  String errorLines(int count);
  String get bulkUploadSuccessMsg;
  String get noDataToUpload;
  String get allPlacesAlreadyRegistered;
  String databaseConnectionError(String error);
  String fileReadError(String error);
  String get templateGenerationFailed;
  String get templateShareText;
  String get templateShareSubject;

  // =====================================================================
  // 5. Notifications & FCM
  // =====================================================================
  String get noValidFcmTokens;
  String get pushSentSuccess;
  String get pushFailed;
  String get notificationPlaceBlockedTitle;
  String notificationPlaceBlockedBody(String placeName, String reason);
  String get notificationPlaceUnblockedTitle;
  String notificationPlaceUnblockedBody(String placeName);
  String get notificationSupportReplyTitle;
  String notificationSupportReplyBody(String code);
  String get notificationMerchantApprovedTitle;
  String get notificationMerchantApprovedBody;
  String get notificationMerchantRejectedTitle;
  String notificationMerchantRejectedBody(String reason);
  String notificationNewReviewTitle(String placeName);
  String notificationNewReviewBody(String rating, String comment);

  // =====================================================================
  // 6. Home Screen Actions (المضافة حديثاً)
  // =====================================================================
  String get planTripAction;
  String get myTripsAction;
  String topRatedIn(String governorateName);
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
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
