// lib/services/location_cache_service.dart
//
// [v1.0 — 2026-10-19] — Wave 5.5c: Cache مستقل (ADR-1)
//   - يحفظ/يقرأ LocationData من SharedPreferences
//   - يتحقق من صلاحية البيانات (validate)
//   - Cache صالح لمدة 7 أيام (يمكن تغييره)

import 'package:shared_preferences/shared_preferences.dart';
import 'location_service.dart';

class LocationCacheService {
  static const _kLat = 'loc_cache_lat';
  static const _kLng = 'loc_cache_lng';
  static const _kNameAr = 'loc_cache_nameAr';
  static const _kAccuracy = 'loc_cache_accuracy';
  static const _kTimestamp = 'loc_cache_timestamp';

  /// صلاحية الـ cache — 7 أيام
  static const Duration maxAge = Duration(days: 7);

  /// حفظ LocationData
  static Future<void> save(LocationData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kLat, data.latitude);
    await prefs.setDouble(_kLng, data.longitude);
    await prefs.setInt(_kTimestamp, DateTime.now().millisecondsSinceEpoch);

    if (data.nameAr != null) {
      await prefs.setString(_kNameAr, data.nameAr!);
    } else {
      await prefs.remove(_kNameAr);
    }

    if (data.accuracyMeters != null) {
      await prefs.setDouble(_kAccuracy, data.accuracyMeters!);
    } else {
      await prefs.remove(_kAccuracy);
    }
  }

  /// قراءة LocationData — يعيد null إذا لا يوجد أو تالف
  static Future<LocationData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_kLat);
    final lng = prefs.getDouble(_kLng);
    final ts = prefs.getInt(_kTimestamp);

    if (lat == null || lng == null || ts == null) return null;

    // [validate] رفض (0,0) والقيم اللانهائية
    if (lat == 0 && lng == 0) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat.abs() > 90 || lng.abs() > 180) return null;

    final age = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(ts),
    );
    if (age > maxAge) return null;

    return LocationData(
      latitude: lat,
      longitude: lng,
      nameAr: prefs.getString(_kNameAr),
      accuracyMeters: prefs.getDouble(_kAccuracy),
    );
  }

  /// مسح الـ cache
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLat);
    await prefs.remove(_kLng);
    await prefs.remove(_kNameAr);
    await prefs.remove(_kAccuracy);
    await prefs.remove(_kTimestamp);
  }

  /// عمر الـ cache بالدقائق (null إذا لم يوجد)
  static Future<int?> ageInMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_kTimestamp);
    if (ts == null) return null;
    return DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(ts))
        .inMinutes;
  }
}
