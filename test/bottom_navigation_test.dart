import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/l10n/app_localizations.dart';
import 'package:yabaladi_rebuild/l10n/locale_controller.dart';
import 'package:yabaladi_rebuild/l10n/theme_controller.dart';
import 'package:yabaladi_rebuild/screens/main_shell.dart';

void main() {
  testWidgets(
    'MainShell renders with all 4 navigation destinations',
    (tester) async {
      final localeController = LocaleController();
      final themeController = ThemeController();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ar'),
          home: MainShell(
            localeController: localeController,
            themeController: themeController,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 4 destinations expected: Home, Search, Favorites, Settings
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    },
  );
}