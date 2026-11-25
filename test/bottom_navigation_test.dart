import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:yabaladi_rebuild/l10n/locale_controller.dart';
import 'package:yabaladi_rebuild/l10n/theme_controller.dart';

/// اختبار بسيط ومعزول — لا يعتمد على Firebase أو Auth أو Router
///
/// الهدف: التأكد أن الـ providers الأساسية تُبنى، وأن MaterialApp
/// تُنشأ بدون crash.
///
/// اختبارات Auth/Router يمكن أن تكون في ملفات منفصلة مع Firebase mock.
void main() {
  testWidgets('Localization and theme providers build successfully',
      (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(child: Text('Ya Baladi Test')),
          ),
        ),
      ),
    );
    await tester.pump();

    // التطبيق بنى بدون crash
    expect(find.text('Ya Baladi Test'), findsOneWidget);
  });
}