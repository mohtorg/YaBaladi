// lib/features/trip/controllers/trip_bag_controller.dart
//
// [v1.1 — 2026-10-27] — LOCAL PERSISTENCE: Save & Load with SharedPreferences

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripBagController extends ChangeNotifier {
  static const String _bagKey = 'trip_bag_items';

  final List<Map<String, dynamic>> _bagItems = [];
  bool _isInitialized = false;

  List<Map<String, dynamic>> get bagItems => List.unmodifiable(_bagItems);
  int get itemCount => _bagItems.length;
  bool get isEmpty => _bagItems.isEmpty;
  bool get isInitialized => _isInitialized;

  TripBagController() {
    _loadFromPrefs(); // تحميل السلة عند بدء التشغيل
  }

  // ✅ تحميل السلة المحفوظة
  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? bagString = prefs.getString(_bagKey);
      if (bagString != null) {
        final List<dynamic> decoded = jsonDecode(bagString);
        _bagItems.clear();
        _bagItems.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      }
    } catch (e) {
      debugPrint('Error loading bag: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ✅ حفظ السلة
  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_bagItems);
      await prefs.setString(_bagKey, encoded);
    } catch (e) {
      debugPrint('Error saving bag: $e');
    }
  }

  // إضافة مكان
  void addPlace(Map<String, dynamic> place) {
    final exists = _bagItems.any((item) => item['id'] == place['id']);
    if (!exists) {
      _bagItems.add(place);
      _saveToPrefs();
      notifyListeners();
    }
  }

  // إزالة مكان
  void removePlace(String placeId) {
    _bagItems.removeWhere((item) => item['id'] == placeId);
    _saveToPrefs();
    notifyListeners();
  }

  // تفريغ السلة
  void clearBag() {
    _bagItems.clear();
    _saveToPrefs();
    notifyListeners();
  }
}
