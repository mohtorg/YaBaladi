// ⭐ الهدف: بناء ثقة قابلة للتحقق، لا جمع نجوم.
// بصمة الجهاز — لمنع تعدد الحسابات من نفس الجهاز.
// يعتمد على حزمة device_info_plus (مضافة في pubspec.yaml).

import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static String? _cachedDeviceId;

  /// يعيد بصمة جهاز فريدة وثابتة (يُخزَّن في الذاكرة لتفادي إعادة الحساب).
  /// الصيغة: "android:XXXX" أو "ios:XXXX" أو "other:XXXX"
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        // AndroidDeviceInfo.id نوعه String (غير قابل لـ null) في هذا الإصدار.
        _cachedDeviceId = 'android:${info.id}';
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        // identifierForVendor نوعه String? — نستخدم بديلًا عند null.
        final vendorId = info.identifierForVendor ??
            'no_vendor_${DateTime.now().millisecondsSinceEpoch}';
        _cachedDeviceId = 'ios:$vendorId';
      } else {
        // منصات أخرى (Windows, macOS, Linux, Web) — معرّف مؤقت.
        _cachedDeviceId = 'other:${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (_) {
      // في حال فشل DeviceInfoPlugin لأي سبب (صلاحيات، منصة غير مدعومة).
      _cachedDeviceId = 'unknown:${DateTime.now().millisecondsSinceEpoch}';
    }
    return _cachedDeviceId!;
  }

  /// يعيد معلومات جهاز إضافية (اختياري، للتحليلات أو للتحقق الإضافي).
  static Future<Map<String, dynamic>> getDeviceMetadata() async {
    final plugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        return {
          'platform': 'android',
          'model': info.model,
          'brand': info.brand,
          'version': info.version.release,
          'sdkInt': info.version.sdkInt,
        };
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        return {
          'platform': 'ios',
          'model': info.model,
          'name': info.name,
          'version': info.systemVersion,
        };
      } else if (Platform.isWindows) {
        final info = await plugin.windowsInfo;
        return {
          'platform': 'windows',
          'computerName': info.computerName,
          'productName': info.productName,
        };
      } else if (Platform.isMacOS) {
        final info = await plugin.macOsInfo;
        return {
          'platform': 'macos',
          'model': info.model,
          'osRelease': info.osRelease,
        };
      } else if (Platform.isLinux) {
        final info = await plugin.linuxInfo;
        return {
          'platform': 'linux',
          'prettyName': info.prettyName,
          'version': info.version,
        };
      }
    } catch (_) {
      // تجاهل الأخطاء — المعلومات الإضافية ليست حرجة.
    }
    return {'platform': 'unknown'};
  }

  /// للاختبار فقط — يمسح الكاش من الذاكرة.
  static void clearCache() {
    _cachedDeviceId = null;
  }
}
