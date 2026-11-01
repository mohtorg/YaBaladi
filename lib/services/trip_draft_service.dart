// lib/services/trip_draft_service.dart
//
// [v1.1 — 2026-10-17] — Fix analyzer: catch clauses

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trip_draft.dart';

class TripDraftService {
  TripDraftService._();

  static const String _keyPrefix = 'trip_draft_';

  static String _key(String userId) => '$_keyPrefix$userId';

  static Future<void> save(TripDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = draft.copyWith(savedAt: DateTime.now()).toJson();
      await prefs.setString(_key(draft.userId), jsonEncode(data));
      debugPrint('✅ TripDraftService: saved (user=${draft.userId})');
    } on Exception catch (e) {
      debugPrint('❌ TripDraftService.save error: $e');
    }
  }

  static Future<TripDraft?> load(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId));
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return TripDraft.fromJson(map);
    } on FormatException catch (e) {
      debugPrint('❌ TripDraftService.load format error: $e');
      return null;
    } on Exception catch (e) {
      debugPrint('❌ TripDraftService.load error: $e');
      return null;
    }
  }

  static Future<void> clear(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId));
      debugPrint('🗑️ TripDraftService: cleared (user=$userId)');
    } on Exception catch (e) {
      debugPrint('❌ TripDraftService.clear error: $e');
    }
  }

  static Future<bool> exists(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_key(userId));
    } on Exception catch (_) {
      return false;
    }
  }
}
