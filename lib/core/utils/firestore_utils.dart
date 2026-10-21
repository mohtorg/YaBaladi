// lib/core/utils/firestore_utils.dart
//
// [v1.0 — 2026-10-21] — Central Firestore data extraction utilities
//   - Eliminates .data() as Map<String, dynamic>? ?? {} repetition
//   - Type-safe getters with fallbacks

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreUtils {
  FirestoreUtils._();

  /// استخراج بيانات المستند بأمان
  static Map<String, dynamic> dataOf(DocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  static Map<String, dynamic> dataOfSnapshot(QueryDocumentSnapshot doc) {
    return doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
  }

  // ─── Type-safe getters ───

  static String stringOf(Map<String, dynamic> data, String key,
      [String fallback = '']) {
    return data[key]?.toString() ?? fallback;
  }

  static bool boolOf(Map<String, dynamic> data, String key,
      [bool fallback = false]) {
    return data[key] == true;
  }

  static int intOf(Map<String, dynamic> data, String key, [int fallback = 0]) {
    return (data[key] as num?)?.toInt() ?? fallback;
  }

  static double doubleOf(Map<String, dynamic> data, String key,
      [double fallback = 0.0]) {
    return (data[key] as num?)?.toDouble() ?? fallback;
  }

  static GeoPoint? geoPointOf(Map<String, dynamic> data, String key) {
    final v = data[key];
    return v is GeoPoint ? v : null;
  }

  static List<String> stringListOf(Map<String, dynamic> data, String key) {
    final v = data[key];
    if (v is List) {
      return v.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  /// استخراج إحداثيات من أي مكان (location أو lat/lng)
  static ({double lat, double lng})? coordinatesOf(Map<String, dynamic> data) {
    final lat = (data['latitude'] ?? data['location']?.latitude) as num?;
    final lng = (data['longitude'] ?? data['location']?.longitude) as num?;
    if (lat == null || lng == null) return null;
    return (lat: lat.toDouble(), lng: lng.toDouble());
  }
}
