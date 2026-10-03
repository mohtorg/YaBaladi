import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the app's current theme mode.
///
/// Three modes are supported:
/// - ThemeMode.light  → Always light
/// - ThemeMode.dark   → Always dark
/// - ThemeMode.system → Follow device settings (default)
///
/// The choice is persisted via SharedPreferences.
class ThemeController extends ChangeNotifier {
  ThemeController();

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const String _storageKey = 'app_theme_mode';
  static const ThemeMode defaultMode = ThemeMode.system;

  // ============================================================
  // STATE
  // ============================================================

  ThemeMode _themeMode = defaultMode;
  bool _isLoaded = false;

  // ============================================================
  // GETTERS
  // ============================================================

  ThemeMode get themeMode => _themeMode;

  bool get isLoaded => _isLoaded;

  bool get isLight => _themeMode == ThemeMode.light;

  bool get isDark => _themeMode == ThemeMode.dark;

  bool get isSystem => _themeMode == ThemeMode.system;

  // ============================================================
  // LOAD (from SharedPreferences)
  // ============================================================

  /// Load the saved theme mode from SharedPreferences.
  /// If none found, keep the default (system).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);

      if (saved != null) {
        _themeMode = _modeFromString(saved);
      }
    } catch (_) {
      // On failure, keep default
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  // ============================================================
  // SET MODE
  // ============================================================

  /// Set the theme mode explicitly.
  /// Persists the change and notifies listeners.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == _themeMode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _modeToString(mode));
    } catch (_) {
      // Silent fail — mode still updated in memory
    }
  }

  // ============================================================
  // TOGGLE (light ↔ dark, ignores system)
  // ============================================================

  /// Toggle between light and dark.
  /// If currently system, switch to light.
  Future<void> toggle() async {
    if (isDark) {
      await setMode(ThemeMode.light);
    } else {
      await setMode(ThemeMode.dark);
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  /// Reset to system mode.
  Future<void> reset() async {
    await setMode(defaultMode);
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _modeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}