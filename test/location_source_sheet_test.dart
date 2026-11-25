// test/location_source_sheet_test.dart
//
// [v1.0 — 2026-10-19] — Wave 5.5c: Widget test for LocationSourceSheet
//   - يتحقق من عرض 5 خيارات + العنوان
//   - FIX: إزالة ChangeNotifierProvider (Sheet يستقبل controller مباشرة)
//   - FIX: إضافة LocationSource import للتوثيق

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/core/location/browsing_location_controller.dart';
import 'package:yabaladi_rebuild/core/location/location_source.dart';
import 'package:yabaladi_rebuild/core/location/location_source_sheet.dart';

void main() {
  testWidgets('LocationSourceSheet يعرض 6 نصوص متوقعة', (tester) async {
    final ctrl = BrowsingLocationController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationSourceSheet(controller: ctrl),
        ),
      ),
    );

    // العنوان
    expect(find.text('تحديد موقعي'), findsOneWidget);

    // 5 خيارات المصادر (من LocationSource.values)
    expect(
        find.text(LocationSource.gps.labelAr), findsOneWidget); // 'GPS (الأدق)'
    expect(find.text(LocationSource.network.labelAr),
        findsOneWidget); // 'الشبكة (الأسرع)'
    expect(find.text(LocationSource.lastKnown.labelAr),
        findsOneWidget); // 'آخر موقع معروف'
    expect(find.text(LocationSource.manual.labelAr),
        findsOneWidget); // 'اختيار يدوي'
    expect(find.text(LocationSource.onlineSearch.labelAr),
        findsOneWidget); // 'بحث بالاسم'
  });
}
