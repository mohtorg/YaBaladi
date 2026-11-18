// lib/l10n/locale_controller.dart
//
// [v1.5 — 2026-11-05] — FINAL FIX: Removed device locale detection to prevent
//                        unexpected RTL→LTR flip. Arabic is now the guaranteed
//                        default. English is only used when explicitly saved.

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's current locale (Arabic / English).
///
/// Design decisions:
/// - Arabic is always the default (never reads device locale).
/// - English is only used if the user explicitly selected it.
/// - This prevents the app from flipping to LTR unexpectedly on web/mobile.
class LocaleController extends ChangeNotifier {
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
  bool _isSetting = false;

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
  ///
  /// ⚠️ If no preference is saved, Arabic is ALWAYS used as the default.
  /// We intentionally DO NOT read the device locale because:
  /// - Browsers/emulators often report `en` regardless of user preference.
  /// - This causes the app to flip from RTL to LTR unexpectedly.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);

      if (saved != null) {
        // ✅ User has an explicit preference — honor it.
        final loaded = Locale(saved);
        if (supportedLocales.any(
          (l) => l.languageCode == loaded.languageCode,
        )) {
          _locale = loaded;
          debugPrint(
            'LocaleController: Loaded saved locale "${loaded.languageCode}"',
          );
        }
      } else {
        // ✅ No saved preference — Arabic is the guaranteed default.
        _locale = arabicLocale;
        debugPrint(
          'LocaleController: No saved locale. Defaulting to Arabic (RTL).',
        );
      }
    } catch (e) {
      // On failure, keep default (Arabic).
      debugPrint('LocaleController: Failed to load locale -> $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  // ============================================================
  // SET LOCALE
  // ============================================================

  /// Set the locale explicitly. Persists the change and notifies listeners.
  Future<void> setLocale(Locale locale) async {
    // Guard: Prevent concurrent calls.
    if (_isSetting) return;

    // Skip if unchanged.
    if (locale.languageCode == _locale.languageCode) return;

    // Verify supported.
    if (!supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    )) {
      debugPrint(
        'LocaleController: Unsupported locale "${locale.languageCode}"',
      );
      return;
    }

    _isSetting = true;
    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, locale.languageCode);
      debugPrint('LocaleController: Saved locale "${locale.languageCode}"');
    } catch (e) {
      debugPrint('LocaleController: Failed to save locale -> $e');
    } finally {
      _isSetting = false;
    }
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  /// Toggle between Arabic and English.
  /// Safe to call before load completes (will no-op until ready).
  Future<void> toggle() async {
    if (!_isLoaded) {
      debugPrint('LocaleController: toggle() called before load() completed.');
      return;
    }
    await setLocale(isArabic ? englishLocale : arabicLocale);
  }

  // ============================================================
  // RESET
  // ============================================================

  /// Reset to default locale (Arabic).
  Future<void> reset() async {
    await setLocale(defaultLocale);
  }
}
