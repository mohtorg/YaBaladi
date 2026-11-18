// ⭐ الهدف: بناء ثقة قابلة للتحقق، لا جمع نجوم.
// التحقق من رمز المكان — دليل الوجود المادي.

import 'dart:convert';

class PinService {
  /// يتحقق من أن رمز المستخدم يطابق الرمز المخزَّن للمكان.
  ///
  /// pinObfuscated = base64(utf8("placeId:pin"))
  /// — لا يعطي أمانًا تشفيريًا كاملًا، لكنه يكفي للتحقق من الوجود المادي
  ///   طالما أن App Check يمنع التطبيقات المعدلة من قراءة وثيقة المكان.
  static bool verify({
    required String placeId,
    required String pinObfuscated,
    required String userInput,
  }) {
    if (userInput.trim().isEmpty) return false;
    try {
      final decoded = utf8.decode(base64.decode(pinObfuscated));
      final parts = decoded.split(':');
      if (parts.length != 2) return false;
      if (parts[0] != placeId) return false;
      return parts[1] == userInput.trim();
    } catch (_) {
      return false;
    }
  }

  /// يولّد الحقل pinObfuscated عند إضافة مكان جديد (يُستخدم من لوحة الإدارة).
  static String obfuscate({
    required String placeId,
    required String pin,
  }) {
    return base64.encode(utf8.encode('$placeId:$pin'));
  }

  /// يولّد رمزًا عشوائيًا من 4 أرقام (للاستخدام عند إضافة مكان جديد).
  static String generatePin() {
    final rand = DateTime.now().microsecondsSinceEpoch % 9000 + 1000;
    return rand.toString().padLeft(4, '0');
  }
}
