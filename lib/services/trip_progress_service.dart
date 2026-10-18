// lib/services/trip_progress_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_progress.dart';

class TripProgressService {
  TripProgressService._();

  static const String _keyPrefix = 'trip_progress_';

  static Future<TripProgress?> load(String tripId) async {
    if (tripId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyPrefix$tripId');
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return TripProgress.fromJson(json);
    } on Exception catch (e) {
      debugPrint('TripProgressService.load($tripId) error: $e');
      return null;
    }
  }

  static Future<void> save(TripProgress progress) async {
    if (progress.tripId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_keyPrefix${progress.tripId}',
        jsonEncode(progress.toJson()),
      );
    } on Exception catch (e) {
      debugPrint('TripProgressService.save error: $e');
    }
  }

  static Future<void> clear(String tripId) async {
    if (tripId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_keyPrefix$tripId');
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
