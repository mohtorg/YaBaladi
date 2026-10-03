import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:yabaladi_rebuild/core/router/app_router.dart';
import 'package:yabaladi_rebuild/l10n/app_localizations.dart';
import 'package:yabaladi_rebuild/l10n/locale_controller.dart';
import 'package:yabaladi_rebuild/l10n/theme_controller.dart';

void main() {
  testWidgets('Bottom navigation renders 4 destinations', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: MaterialApp.router(
          routerConfig: appRouter,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('ar'), Locale('en')],
          locale: const Locale('ar'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('حسابي'), findsOneWidget);
    expect(find.text('المفضلة'), findsOneWidget);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}