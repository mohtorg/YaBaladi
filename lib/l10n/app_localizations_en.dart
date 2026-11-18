// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Ya Baladi';
  @override
  String get welcome => 'Welcome';
  @override
  String get home => 'Home';
  @override
  String get search => 'Search';
  @override
  String get profile => 'Profile';
  @override
  String get settings => 'Settings';
  @override
  String get favorites => 'Favorites';
  @override
  String get notifications => 'Notifications';
  @override
  String get login => 'Sign In';
  @override
  String get register => 'Create Account';
  @override
  String get logout => 'Sign Out';
  @override
  String get email => 'Email';
  @override
  String get password => 'Password';
  @override
  String get forgotPassword => 'Forgot password?';
  @override
  String get categories => 'Categories';
  @override
  String get restaurants => 'Restaurants';
  @override
  String get cafes => 'Cafes';
  @override
  String get events => 'Events';
  @override
  String get historicalPlaces => 'Historical Places';
  @override
  String get cinema => 'Cinema';
  @override
  String get gyms => 'Gyms';
  @override
  String get nearby => 'Nearby';
  @override
  String get loading => 'Loading...';
  @override
  String get error => 'An error occurred';
  @override
  String get retry => 'Retry';
  @override
  String get noResults => 'No results';
  @override
  String get noInternet => 'No internet connection';
  @override
  String get settingsGeneral => 'General';
  @override
  String get settingsAccount => 'Account';
  @override
  String get settingsLegal => 'Legal & Policies';
  @override
  String get settingsAdvanced => 'Advanced';
  @override
  String get languageLabel => 'Language';
  @override
  String get languageArabic => 'العربية';
  @override
  String get languageEnglish => 'English';
  @override
  String get languageSelectTitle => 'Choose Language';
  @override
  String get languageSelectSubtitle => 'Changes apply immediately';
  @override
  String get languageArabicSubtitle => 'RTL — Right to left';
  @override
  String get languageEnglishSubtitle => 'LTR — Left to right';
  @override
  String get languageCurrent => 'Current language';
  @override
  String get themeLabel => 'Theme';
  @override
  String get themeSelectTitle => 'Choose Theme';
  @override
  String get themeSelectSubtitle => 'Changes apply immediately';
  @override
  String get themeSystem => 'System';
  @override
  String get themeSystemSubtitle => 'Follows device settings';
  @override
  String get themeLight => 'Light';
  @override
  String get themeLightSubtitle => 'Daytime interface';
  @override
  String get themeDark => 'Dark';
  @override
  String get themeDarkSubtitle => 'Night interface';
  @override
  String get themeCurrent => 'Current theme';
  @override
  String get locationLabel => 'Location';
  @override
  String get locationOnDemand => 'On demand';
  @override
  String get locationOnDemandSubtitle => 'Only requested when used';
  @override
  String get locationAlways => 'Always';
  @override
  String get locationAlwaysSubtitle => 'Always available (not recommended)';
  @override
  String get locationDisabled => 'Disabled';
  @override
  String get locationDisabledSubtitle => 'Nearby search won\'t work';
  @override
  String get notificationsLabel => 'Notifications';
  @override
  String get notificationsSubtitle => 'App alerts';
  @override
  String get notificationsEnabled => 'Enabled';
  @override
  String get notificationsDisabled => 'Disabled';
  @override
  String get privacyPolicyLabel => 'Privacy Policy';
  @override
  String get privacyPolicySubtitle => 'How we protect your data';
  @override
  String get termsLabel => 'Terms & Conditions';
  @override
  String get termsSubtitle => 'Usage rules';
  @override
  String get aboutLabel => 'About';
  @override
  String get aboutSubtitle => 'Info & licenses';
  @override
  String get versionLabel => 'Version';
  @override
  String get versionValue => '1.0.0+6';
  @override
  String get clearCacheLabel => 'Clear Cache';
  @override
  String get clearCacheSubtitle => 'Delete cached data';
  @override
  String get clearCacheConfirm => 'Do you want to clear cached data?';
  @override
  String get clearCacheSuccess => 'Cache cleared';
  @override
  String get deleteAccountLabel => 'Delete Account';
  @override
  String get deleteAccountSubtitle => 'Permanent, irreversible';
  @override
  String get deleteAccountWarning => 'This action cannot be undone';
  @override
  String get deleteAccountConfirm =>
      'Do you want to delete your account permanently?';
  @override
  String get deleteAccountButton => 'Delete my account';
  @override
  String get logoutConfirmTitle => 'Sign Out';
  @override
  String get logoutConfirmMessage => 'Do you want to sign out?';
  @override
  String get confirm => 'Confirm';
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get close => 'Close';
  @override
  String get yes => 'Yes';
  @override
  String get no => 'No';
  @override
  String get apply => 'Apply';
  @override
  String get select => 'Select';
  @override
  String get delete => 'Delete';
  @override
  String get edit => 'Edit';
  @override
  String get done => 'Done';
  @override
  String get copy => 'Copy';
  @override
  String get copiedToClipboard => 'Copied to clipboard';
  @override
  String get loginTitle => 'Sign In';
  @override
  String get loginSubtitle => 'Enter your credentials to access your account';
  @override
  String get registerTitle => 'Create Account';
  @override
  String get registerSubtitle => 'Join the Ya Baladi community';
  @override
  String get forgotPasswordTitle => 'Reset Password';
  @override
  String get forgotPasswordSubtitle =>
      'Enter your email to receive a reset link';
  @override
  String get displayName => 'Full Name';
  @override
  String get confirmPassword => 'Confirm Password';
  @override
  String get noAccountYet => 'Don\'t have an account?';
  @override
  String get haveAccountAlready => 'Already have an account?';
  @override
  String get sendResetLink => 'Send Reset Link';
  @override
  String get resetEmailSent => 'A reset link has been sent to your email';
  @override
  String get errorEmailRequired => 'Email is required';
  @override
  String get errorEmailInvalid => 'Invalid email';
  @override
  String get errorPasswordRequired => 'Password is required';
  @override
  String get errorPasswordShort => 'Password is too short (min 6 chars)';
  @override
  String get errorPasswordsMismatch => 'Passwords don\'t match';
  @override
  String get errorNameRequired => 'Name is required';
  @override
  String get errorNameShort => 'Name is too short';
  @override
  String get profileActivity => 'My Activity';
  @override
  String get profileStatsFavorites => 'Favorites';
  @override
  String get profileStatsRatings => 'Ratings';
  @override
  String get favoritesEmptyTitle => 'No favorites yet';
  @override
  String get favoritesEmptySubtitle =>
      'Start exploring places and save what you like';
  @override
  String get discoverPlaces => 'Discover Places';
  @override
  String get settingsAppearance => 'Appearance';
  @override
  String get settingsPrivacySection => 'Privacy & Permissions';
  @override
  String get settingsDangerSection => 'Danger Actions';
  @override
  String get continueAsGuest => 'Continue as guest';
  @override
  String get guest => 'Guest';
  @override
  String get loginRequired => 'Login required';
  @override
  String get loginRequiredMessage =>
      'This feature is available for registered users only. Sign in to unlock all features.';
  @override
  String get maybeLater => 'Maybe later';
  @override
  String get or => 'or';
  @override
  String get guestNote =>
      'You can browse as a guest. Some features require sign-in.';
  @override
  String get searchHint => 'Search for a place...';
  @override
  String get searchIdleHint => 'Start by searching for a place';
  @override
  String get noSearchResults => 'No matching results';
  @override
  String get searchRecent => 'Recent searches';
  @override
  String get searchClearAll => 'Clear all';
  @override
  String get searchQuickCategories => 'Quick categories';
  @override
  String get searchTrending => 'Trending now';
  @override
  String searchResultsCount(int count) {
    final String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count results',
      one: '1 result',
      zero: 'No results',
    );
    return '$_temp0';
  }

  @override
  String get searchNoResults => 'No results for';
  @override
  String get searchTips => 'Try:';
  @override
  String get searchTip1 => 'Check the spelling';
  @override
  String get searchTip2 => 'Use a shorter word';
  @override
  String get searchTip3 => 'Try another category';
  @override
  String get searchTryCategory => 'Or try a category:';
  @override
  String get searchFilters => 'Filters';
  @override
  String get filters => 'Filters';
  @override
  String get filterRating => 'Rating';
  @override
  String get filterPrice => 'Price';
  @override
  String get filterSort => 'Sort';
  @override
  String get filterAll => 'All';
  @override
  String get sortRatingDesc => 'Top rated';
  @override
  String get sortReviewsDesc => 'Most reviewed';
  @override
  String get sortNameAsc => 'Alphabetical';
  @override
  String get sortNewest => 'Newest';
  @override
  String get applyFilters => 'Apply';
  @override
  String get clearFilters => 'Clear';
  @override
  String get noResultsWithFilters => 'No results with these filters';
  @override
  String get viewOnMap => 'View on map';
  @override
  String get directions => 'Directions';
  @override
  String get details => 'Details';
  @override
  String get recenter => 'Recenter';
  @override
  String get noCoordinates =>
      'No coordinates available to show this place on the map';
  @override
  String get continueWithGoogle => 'Continue with Google';
  @override
  String get registerCta => 'Create New Account';
  @override
  String get googleSignInFailed => 'Google sign-in failed';
  @override
  String get tripsTitle => 'My Trips';

  // =====================================================================
  // Location & Governorate Picker
  // =====================================================================
  @override
  String get chooseGovernorate => 'Choose Governorate';
  @override
  String get useCurrentLocation => 'Use my current location';
  @override
  String get fromGps => 'From GPS';
  @override
  String get orChooseAnotherGovernorate => 'Or choose another governorate';
  @override
  String get chooseYourGovernorate => 'Choose your governorate';
  @override
  String get defaultBadge => 'Default';
  @override
  String get determineMyLocation => 'Determine my location';
  @override
  String get locationDefined => 'Selected Location';
  @override
  String get searchPlaceTitle => 'Search for a place';
  @override
  String get searchPlaceHint => 'e.g. Port Said, El-Sharq';
  @override
  String get noMatchingResults => 'No matching results.';
  @override
  String get locationSourceGps => 'GPS (Most accurate)';
  @override
  String get locationSourceGpsSub => 'May take a few seconds';
  @override
  String get locationSourceNetwork => 'Network (Fastest)';
  @override
  String get locationSourceNetworkSub => 'Wi-Fi / Mobile data';
  @override
  String get locationSourceLastKnown => 'Last known location';
  @override
  String get locationSourceLastKnownSub => 'Instant — may be outdated';
  @override
  String get locationSourceManual => 'Manual selection';
  @override
  String get locationSourceManualSub => 'From governorate list';
  @override
  String get locationSourceOnline => 'Search by name';
  @override
  String get locationSourceOnlineSub => 'Type your city or district';

  // =====================================================================
  // Trip Planner
  // =====================================================================
  @override
  String get planYourTrip => 'Plan Your Trip';
  @override
  String get whereToGo => 'Where do you want to go?';
  @override
  String get chooseGovernorateToStart =>
      'Choose the governorate to start planning.';
  @override
  String foundInBasket(String count) {
    return 'Found $count in your basket';
  }

  @override
  String tripIn(String govName) {
    return 'A trip in $govName. How do you want it to be?';
  }

  @override
  String get governorate => 'Governorate';
  @override
  String get duration => 'Duration';
  @override
  String get halfDay => 'Half Day';
  @override
  String get halfDaySub => '~4 hours';
  @override
  String get fullDay => 'Full Day';
  @override
  String get fullDaySub => '~8 hours';
  @override
  String get weekend => 'Weekend';
  @override
  String get weekendSub => '~16 hours (2 days)';
  @override
  String get customDates => 'Custom dates (3+ days)';
  @override
  String tripDurationDays(int days) {
    final String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Trip duration: $days days',
      one: 'Trip duration: 1 day',
    );
    return '$_temp0';
  }

  @override
  String get transportMode => 'Transport Mode';
  @override
  String get transportDriving => 'Driving';
  @override
  String get transportWalking => 'Walking';
  @override
  String get transportBus => 'Bus';
  @override
  String get preparingBestOrder => 'Preparing the best order for your trip...';
  @override
  String get notEnoughPlaces => 'We couldn\'t find enough places';
  @override
  String get modifyOptions => 'Modify Options';
  @override
  String get modifyPlacesManually => 'Modify places manually';
  @override
  String get finalTouches => 'Final Touches';
  @override
  String get addTripTitle => 'Add a title to your trip';
  @override
  String get tripTitleField => 'Trip Title';
  @override
  String get previous => 'Previous';
  @override
  String get generateTrip => 'Generate Trip';
  @override
  String get next => 'Next';
  @override
  String get saveTrip => 'Save Trip';
  @override
  String get tripSavedSuccess => 'Trip saved successfully';
  @override
  String get loginRequiredForSave => 'You must be logged in to save a trip';
  @override
  String get saveFailed => 'Save failed';
  @override
  String dayNumber(int day) {
    return 'Day $day';
  }

  @override
  String get minutes => 'Minute';
  @override
  String get minutesDual => 'Two minutes';
  @override
  String get minutesPlural => 'Minutes';
  @override
  String get stations => 'Stop';
  @override
  String get stationsDual => 'Two stops';
  @override
  String get stationsPlural => 'Stops';
  @override
  String get hours => 'Hour';
  @override
  String get hoursPlural => 'Hours';
  @override
  String get places => 'Place';
  @override
  String get placesDual => 'Two places';
  @override
  String get placesPlural => 'Places';
  @override
  String get newTrip => 'New Trip';
  @override
  String tripTo(String govName) {
    return 'Trip to $govName';
  }

  // =====================================================================
  // Bulk Import (Excel)
  // =====================================================================
  @override
  String get bulkImportTitle => 'Manage Places (Bulk Import)';
  @override
  String get bulkImportIntro =>
      'You can insert dozens of places at once via an Excel file.\nDownload the template, fill it in, then upload it.';
  @override
  String get downloadExcelTemplate => '1. Download Excel Template';
  @override
  String get pickExcelFile => '2. Pick and review Excel file';
  @override
  String confirmUploadPlaces(int count) {
    final String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '3. Confirm upload of $_temp0';
  }

  @override
  String get preparingTemplate => 'Preparing template...';
  @override
  String get templateReady =>
      'Template is ready! You can now save or share it.';
  @override
  String templateError(String error) {
    return 'An error occurred while preparing the template: $error';
  }

  @override
  String get readingFile => 'Reading file and validating data...';
  @override
  String get fileSelectionCancelled => 'File selection was cancelled.';
  @override
  String get noValidDataFound => 'No valid data found in the file.';
  @override
  String get fileReadSuccess =>
      'File read successfully. Please review the results below.';
  @override
  String get uploadingData => 'Uploading data to the database...';
  @override
  String uploadSuccess(int count) {
    final String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '🎉 Successfully uploaded $_temp0!';
  }

  @override
  String duplicatesSkipped(int count) {
    final String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count duplicate places skipped',
      one: '1 duplicate place skipped',
    );
    return '($_temp0)';
  }

  @override
  String get sortReport => '📊 Sort Report:';
  @override
  String validPlaces(int count) {
    final String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places',
      one: '1 place',
    );
    return '✅ Valid places to upload: $_temp0';
  }

  @override
  String errorLines(int count) {
    final String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lines',
      one: '1 line',
    );
    return '❌ Lines with errors (will be skipped): $_temp0';
  }

  @override
  String get bulkUploadSuccessMsg => 'Bulk upload completed successfully';
  @override
  String get noDataToUpload => 'No valid data to upload.';
  @override
  String get allPlacesAlreadyRegistered =>
      'All places in the file are already registered in the database or duplicated within the file.';
  @override
  String databaseConnectionError(String error) {
    return 'Database connection error: $error';
  }

  @override
  String fileReadError(String error) {
    return 'An error occurred while reading the file. Ensure it is a valid, uncorrupted xlsx file. ($error)';
  }

  @override
  String get templateGenerationFailed => 'Failed to generate Excel file';
  @override
  String get templateShareText => 'Ya Baladi Places Template (Port Said)';
  @override
  String get templateShareSubject => 'Places Import Template';

  // =====================================================================
  // Notifications & FCM
  // =====================================================================
  @override
  String get noValidFcmTokens => 'No valid FCM tokens found for this user.';
  @override
  String get pushSentSuccess => 'Notification sent successfully.';
  @override
  String get pushFailed => 'Failed to send notification.';
  @override
  String get notificationPlaceBlockedTitle =>
      '🚫 Your activity has been temporarily suspended';
  @override
  String notificationPlaceBlockedBody(String placeName, String reason) {
    return '"$placeName" has been suspended. Reason: $reason';
  }

  @override
  String get notificationPlaceUnblockedTitle =>
      '✅ Your activity has been reactivated';
  @override
  String notificationPlaceUnblockedBody(String placeName) {
    return '"$placeName" has been unblocked successfully. You can now receive requests.';
  }

  @override
  String get notificationSupportReplyTitle => '💬 New reply from support';
  @override
  String notificationSupportReplyBody(String code) {
    return 'Your ticket ($code) has been replied to. Please open the ticket details for review.';
  }

  @override
  String get notificationMerchantApprovedTitle =>
      '🎉 Your request has been approved';
  @override
  String get notificationMerchantApprovedBody =>
      'You have been approved as a merchant. Start managing your business now!';
  @override
  String get notificationMerchantRejectedTitle =>
      '⚠️ Your request needs adjustment';
  @override
  String notificationMerchantRejectedBody(String reason) {
    return 'Reason: $reason';
  }

  @override
  String notificationNewReviewTitle(String placeName) {
    return '⭐ New review for $placeName';
  }

  @override
  String notificationNewReviewBody(String rating, String comment) {
    return 'You received a $rating-star rating. "$comment"';
  }

  // =====================================================================
  // Home Screen Actions
  // =====================================================================
  @override
  String get planTripAction => 'Plan Your Trip';
  @override
  String get myTripsAction => 'My Trips';
  @override
  String topRatedIn(String governorateName) {
    return 'Top rated in $governorateName';
  }

  @override
  String get guestBannerTitle => 'Sign in for a better experience!';
}
