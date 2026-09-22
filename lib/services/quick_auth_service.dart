// services/quick_auth_service.dart
// الغرض: ربط إعادة فتح جلسة يا بلدي بمصادقة الجهاز الرسمية.
// السبب: المستخدم طلب الدخول لاحقًا ببصمة/نمط/PIN الهاتف بدل إعادة تسجيل بيانات الحساب.
// الأمان: التطبيق لا يرى نمط الهاتف ولا كلمة المرور؛ Android يعرض نافذة المصادقة النظامية.
// لا نغيّر هذا المسار إلى تخزين كلمة مرور أو PIN داخل التطبيق.

import 'package:flutter/services.dart';

class QuickAuthService {
  static const MethodChannel _channel = MethodChannel('ya_baladi/quick_auth');

  Future<bool> isDeviceSupported() async {
    return await _channel.invokeMethod<bool>('isDeviceSupported') ?? false;
  }

  Future<bool> isEnabled() async {
    return await _channel.invokeMethod<bool>('isEnabled') ?? false;
  }

  Future<void> setEnabled(bool enabled) async {
    await _channel.invokeMethod<void>('setEnabled', {'enabled': enabled});
  }

  Future<bool> authenticate() async {
    return await _channel.invokeMethod<bool>('authenticate') ?? false;
  }
}
