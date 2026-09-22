// services/entry_intent.dart
// الغرض: الاحتفاظ باختيار شاشة البداية خلال عملية المصادقة الحالية فقط.
// السبب: بعد نجاح Firebase قد يعيد AuthGate البناء قبل أن نصل إلى شاشة إعداد الحساب.
// لا نخزن كلمة مرور أو رمز قفل هنا؛ هذا مجرد اختيار مؤقت لمسار الدخول.

import '../models/app_experience_mode.dart';

class EntryIntent {
  static AppExperienceMode? mode;
  static bool merchant = false;

  static void setPersonal(AppExperienceMode value) {
    mode = value;
    merchant = false;
  }

  static void setMerchant() {
    mode = null;
    merchant = true;
  }

  static void clear() {
    mode = null;
    merchant = false;
  }
}
