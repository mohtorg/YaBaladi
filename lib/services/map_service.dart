// lib/services/map_service.dart
//
// [v1.1 — 2026-10-22] — Thin wrapper over LocationUrlHelper
//   - REFACTOR: Build URLs via LocationUrlHelper (single source of truth)
//   - REFACTOR: Delegate launching to LocationUrlHelper.open (uses canLaunchUrl)
//   - FIX: Removed redundant platformDefault fallback
//   - ADD: Private constructor to prevent instantiation
//   - KEEP: getDistanceInMeters (pure math — no permissions needed)

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/helpers/location_url_helper.dart';

/// خدمة الخرائط — توفر واجهة مختصرة لفتح المواقع والاتجاهات.
///
/// ⚠️ ملاحظة معمارية:
///   هذا الملف غلاف رقيق حول [LocationUrlHelper].
///   عند الحاجة لتعديل طريقة بناء روابط Google Maps أو آلية الفتح،
///   عدّل [LocationUrlHelper] — لا هذا الملف.
class MapService {
  MapService._();

  /// 1. فتح موقع محدد على خرائط جوجل
  static Future<void> openLocation(double lat, double lng) async {
    final url = LocationUrlHelper.mapUrl(lat: lat, lng: lng);
    final ok = await LocationUrlHelper.open(url);
    if (!ok) {
      debugPrint('MapService.openLocation failed: ($lat, $lng)');
    }
  }

  /// 2. فتح الاتجاهات (Navigation) إلى مكان محدد
  static Future<void> openDirections(double destLat, double destLng) async {
    final url = LocationUrlHelper.directionsUrl(lat: destLat, lng: destLng);
    final ok = await LocationUrlHelper.open(url);
    if (!ok) {
      debugPrint('MapService.openDirections failed: ($destLat, $destLng)');
    }
  }

  /// 3. حساب المسافة بالأمتار بين نقطتين
  ///
  /// يستخدم Haversine خلف الكواليس — لا يحتاج إذن الموقع.
  /// يعمل حتى لو لم يكن GPS مفعّلاً على الجهاز.
  static double getDistanceInMeters(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}
