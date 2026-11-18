// lib/features/trip/controllers/trip_bag_controller.dart
//
// [v1.3 - TRUE FIX] - Resolved compile error:
//   - FIXED: 'removeWhere' returns void, not int. Now uses length comparison.
//   - KEPT: All v1.2 safety guards (dispose, safe notify, JSON-safe save).

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TripBagController extends ChangeNotifier {
  static const String _bagKey = 'trip_bag_items';

  final List<Map<String, dynamic>> _bagItems = [];
  bool _isInitialized = false;
  bool _disposed = false;

  List<Map<String, dynamic>> get bagItems => List.unmodifiable(_bagItems);
  int get itemCount => _bagItems.length;
  bool get isEmpty => _bagItems.isEmpty;
  bool get isInitialized => _isInitialized;

  TripBagController() {
    _loadFromPrefs();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

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
      _safeNotify();
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Defensive: create a JSON-safe copy in case the item contains
      // Firestore types like GeoPoint or Timestamp.
      final safeItems = _bagItems.map((item) {
        return item.map((key, value) {
          if (value is String || value is num || value is bool) {
            return MapEntry(key, value);
          }
          if (value is List) {
            return MapEntry(key, value.map((e) => e.toString()).toList());
          }
          return MapEntry(key, value.toString());
        });
      }).toList();

      final String encoded = jsonEncode(safeItems);
      await prefs.setString(_bagKey, encoded);
    } catch (e) {
      debugPrint('Error saving bag: $e');
    }
  }

  void addPlace(Map<String, dynamic> place) {
    final placeId = place['id']?.toString();
    if (placeId == null || placeId.isEmpty) return;

    final exists = _bagItems.any((item) => item['id']?.toString() == placeId);
    if (!exists) {
      _bagItems.add(place);
      _saveToPrefs();
      _safeNotify();
    }
  }

  void removePlace(String placeId) {
    // ✅ FIX: removeWhere returns void. Track length manually.
    final beforeLength = _bagItems.length;
    _bagItems.removeWhere((item) => item['id']?.toString() == placeId);
    final removedCount = beforeLength - _bagItems.length;

    if (removedCount > 0) {
      _saveToPrefs();
      _safeNotify();
    }
  }

  void clearBag() {
    if (_bagItems.isEmpty) return;
    _bagItems.clear();
    _saveToPrefs();
    _safeNotify();
  }
}
