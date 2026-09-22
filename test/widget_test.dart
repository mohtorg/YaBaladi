// test/widget_test.dart
// ملاحظة التعديل:
// اختبار Counter الافتراضي أزيل لأنه لا يخص التطبيق الحالي. استبدلناه باختبارات
// بسيطة لا تتطلب تهيئة Firebase حتى يمكن تشغيلها في بيئة CI أو جهاز المطور بسهولة.

import 'package:flutter_test/flutter_test.dart';
import 'package:ya_baladi/l10n/app_strings.dart';

void main() {
  test('يسترجع اسم التطبيق بالعربية والإنجليزية', () {
    expect(AppStrings.of('app_name', 'ar'), 'يا بلدي');
    expect(AppStrings.of('app_name', 'en'), 'Ya Baladi');
  });
}
