// lib/core/controllers/theme_controller.dart
// [v1.1.1 — 2026-11-05] — FIX: Removed unnecessary foundation.dart import.
// [v1.0 — 2026-11-03] — NEW: Global Theme Controller for Dark Mode.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _key = 'theme_mode';
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  ThemeController() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);

      // استخدام Switch Expression الحديثة (Dart 3)
      _mode = switch (saved) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system, // القيمة الافتراضية
      };

      notifyListeners();
    } catch (e) {
      // في حال فشل القراءة (مثلاً على بيئة غير مدعومة)، نستخدم النظام كافتراضي
      debugPrint('ThemeController: Failed to load theme mode -> $e');
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    // تحديث الواجهة فوراً لتعطي إحساساً بالاستجابة السريعة (Optimistic UI)
    _mode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (e) {
      debugPrint('ThemeController: Failed to save theme mode -> $e');
    }
  }

  /// الاسم العربي للمظهر الحالي (للعرض في واجهة الإعدادات).
  String get label => switch (_mode) {
        ThemeMode.light => 'فاتح',
        ThemeMode.dark => 'داكن',
        ThemeMode.system => 'النظام',
      };
}
