import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's current locale (Arabic / English).
///
/// Features:
/// - Persists user's language choice via SharedPreferences
/// - Notifies listeners on change
/// - Provides `isArabic` helper
/// - Provides `toggle()` for quick switch
class LocaleController extends ChangeNotifier {
  LocaleController();

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String _storageKey = 'app_locale';
  static const Locale arabicLocale = Locale('ar');
  static const Locale englishLocale = Locale('en');
  static const Locale defaultLocale = arabicLocale;

  static const List<Locale> supportedLocales = [
    arabicLocale,
    englishLocale,
  ];

  // ============================================================
  // STATE
  // ============================================================

  Locale _locale = defaultLocale;
  bool _isLoaded = false;

  // ============================================================
  // GETTERS
  // ============================================================

  Locale get locale => _locale;

  bool get isLoaded => _isLoaded;

  bool get isArabic => _locale.languageCode == 'ar';

  bool get isEnglish => _locale.languageCode == 'en';

  // ============================================================
  // LOAD (from SharedPreferences)
  // ============================================================

  /// Load the saved locale from SharedPreferences.
  /// If none found, keep the default.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);

      if (saved != null) {
        final loaded = Locale(saved);
        if (supportedLocales.any(
          (l) => l.languageCode == loaded.languageCode,
        )) {
          _locale = loaded;
        }
      }
    } catch (_) {
      // On failure, keep default
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  // ============================================================
  // SET LOCALE
  // ============================================================

  /// Set the locale explicitly.
  /// Persists the change and notifies listeners.
  Future<void> setLocale(Locale locale) async {
    if (locale.languageCode == _locale.languageCode) return;

    if (!supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    )) {
      return;
    }

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, locale.languageCode);
    } catch (_) {
      // Silent fail — locale still updated in memory
    }
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  /// Toggle between Arabic and English.
  Future<void> toggle() async {
    await setLocale(isArabic ? englishLocale : arabicLocale);
  }

  // ============================================================
  // RESET
  // ============================================================

  /// Reset to default locale.
  Future<void> reset() async {
    await setLocale(defaultLocale);
  }
}