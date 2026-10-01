import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/screens/main_shell.dart';

void main() {
  testWidgets('G2-006 exposes four bottom navigation destinations', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MainShell()));

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    expect(find.text('الرئيسية'), findsAtLeastNWidgets(1));
    expect(find.text('حسابي'), findsAtLeastNWidgets(1));
    expect(find.text('المفضلة'), findsAtLeastNWidgets(1));
    expect(find.text('الإعدادات'), findsAtLeastNWidgets(1));

    await tester.tap(find.text('المفضلة').last);
    await tester.pump();

    expect(find.text('المفضلة'), findsAtLeastNWidgets(1));
  });
}
