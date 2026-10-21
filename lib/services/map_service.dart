// lib/services/map_service.dart
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class MapService {
  /// 1. فتح موقع محدد على خرائط جوجل
  static Future<void> openLocation(double lat, double lng) async {
    final uri =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await _launch(uri);
  }

  /// 2. فتح الاتجاهات (Navigation) إلى مكان محدد
  static Future<void> openDirections(double destLat, double destLng) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving');
    await _launch(uri);
  }

  /// 3. حساب المسافة بالأمتار بين نقطتين
  static double getDistanceInMeters(
      double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  /// 4. دالة مساعدة لفتح الروابط مع خطة بديلة (Fallback)
  static Future<void> _launch(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        // في حال عدم وجود تطبيق خرائط، يفتح المتصفح
        if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
          debugPrint('Could not launch map URL');
        }
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
    }
  }
}
