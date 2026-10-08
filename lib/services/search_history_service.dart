// lib/services/search_history_service.dart


import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة حفظ "آخر عمليات البحث" باستخدام SharedPreferences.
///
/// - تحفظ حتى [maxItems] عملية بحث.
/// - تمنع التكرار (لو كرر المستخدم بحث، يتحرك للأعلى).
/// - الأحدث في الأول.
class SearchHistoryService {
  SearchHistoryService._();

  static const String _key = 'recent_searches';
  static const int _maxItems = 5;

  /// يجلب آخر عمليات البحث (الأحدث في الأول).
  static Future<List<String>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key);
      if (raw == null || raw.isEmpty) return const [];
      return raw;
    } catch (e) {
      debugPrint('SearchHistoryService.getHistory: $e');
      return const [];
    }
  }

  /// يضيف عملية بحث جديدة:
  /// - لو موجودة، يحذفها من مكانها ويضعها في الأول.
  /// - لو جديدة، يضيفها في الأول.
  /// - يقتطع القائمة إلى [_maxItems].
  static Future<List<String>> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getHistory();

    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_key) ?? <String>[];

      // إزالة التكرار (case-insensitive)
      final lower = trimmed.toLowerCase();
      current.removeWhere((q) => q.toLowerCase() == lower);

      // إضافة في الأول
      current.insert(0, trimmed);

      // اقتطاع
      final updated = current.take(_maxItems).toList();

      await prefs.setStringList(_key, updated);
      return updated;
    } catch (e) {
      debugPrint('SearchHistoryService.addQuery: $e');
      return getHistory();
    }
  }

  /// يحذف عملية بحث واحدة.
  static Future<List<String>> removeQuery(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_key) ?? <String>[];

      final lower = query.toLowerCase();
      current.removeWhere((q) => q.toLowerCase() == lower);

      await prefs.setStringList(_key, current);
      return current;
    } catch (e) {
      debugPrint('SearchHistoryService.removeQuery: $e');
      return getHistory();
    }
  }

  /// يمسح كل عمليات البحث.
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('SearchHistoryService.clearAll: $e');
    }
  }
}