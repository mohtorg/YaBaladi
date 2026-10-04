import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'l10n/theme_controller.dart';
import 'theme/app_theme.dart';

// 🔔 Background message handler
// لازم تكون top-level function (برة أي كلاس)
// و@pragma('vm:entry-point') ضرورية عشان Flutter ميخليهاش tree-shaken
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // تهيئة Firebase جوه الـ handler — ده جوهر الحل
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('📩 Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 سجّل الـ background handler بعد التهيئة
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const YaBaladiApp());
}

class YaBaladiApp extends StatelessWidget {
  const YaBaladiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController()..load(),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController()..load(),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(),
        ),
      ],
      child: const _AppRoot(),
    );
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  GoRouter? _router;
  AuthController? _authController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final auth = context.read<AuthController>();

    // نبني router مرة واحدة فقط (أو عند تغيّر auth)
    if (_router == null || _authController != auth) {
      _router = createAppRouter(auth);
      _authController = auth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    final theme = context.watch<ThemeController>();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar'), Locale('en')],
      locale: locale.locale,

      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: theme.themeMode,

      routerConfig: _router!,
    );
  }
}