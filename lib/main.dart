import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'l10n/theme_controller.dart';
import 'screens/main_shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const YaBaladiApp());
}

class YaBaladiApp extends StatefulWidget {
  const YaBaladiApp({super.key});

  @override
  State<YaBaladiApp> createState() => _YaBaladiAppState();
}

class _YaBaladiAppState extends State<YaBaladiApp> {
  late final LocaleController _localeController;
  late final ThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _localeController = LocaleController();
    _themeController = ThemeController();

    _localeController.load();
    _themeController.load();
  }

  @override
  void dispose() {
    _localeController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_localeController, _themeController]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,

          // === Localization ===
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocaleController.supportedLocales,
          locale: _localeController.locale,

          // === Theme ===
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeController.themeMode,

          // === Home ===
          home: MainShell(
            localeController: _localeController,
            themeController: _themeController,
          ),
        );
      },
    );
  }
}