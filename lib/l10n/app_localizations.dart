import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  // =====================================================================
  // النصوص الأصلية
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
  // 👈 [NEW] النصوص المفقودة التي تمت إضافتها لحل مشكلة home_screen
  // =====================================================================

  /// 'خطط رحلتك'
  String get planTripAction;

  /// 'رحلاتي'
  String get myTripsAction;

  /// 'الأعلى تقييماً في [governorateName]'
  String topRatedIn(String governorateName);

  /// 'سجل دخولك لتجربة أفضل!'
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
