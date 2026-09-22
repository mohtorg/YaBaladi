// main.dart
// نقطة البداية الرئيسية للتطبيق.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/locale_controller.dart';
import 'screens/auth_gate.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

// ملاحظة التعديل:
// أزلنا زرع البيانات التجريبية من بداية التطبيق؛ لأن التطبيق الحقيقي يجب ألا
// يكتب بيانات تلقائيًا عند كل تشغيل. يتم إدخال البيانات من Firebase Console
// أو من لوحة الإدارة. كما أضفنا إدارة اللغة على مستوى التطبيق وربطناها فعليًا
// بـ MaterialApp حتى يعمل RTL/LTR وتبديل اللغة بصورة صحيحة.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar');

  void _toggleLocale() {
    setState(() {
      _locale = _locale.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'يا بلدي',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
      builder: (context, child) {
        return LocaleController(
          locale: _locale,
          toggleLocale: _toggleLocale,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}
