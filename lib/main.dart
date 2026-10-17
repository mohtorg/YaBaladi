// lib/main.dart
//
// [v1.5 — 2026-10-17] — Documentation: accurate cold-start comment
//   - CHANGE: v1.4's comment now reflects that the real fix is in
//     PlacesRepository (Source.server + retry), not long-polling.
//   - NO code changes.
//
// [v1.4 — 2026-10-15] — Firestore long-polling (FlutLab Web)
//   - FirebaseFirestore.settings.webExperimentalForceLongPolling = true
//   - ⚠️ NOTE: Long-polling alone did NOT fix the 38s cold start.
//            Real fix is in PlacesRepository (Source.server + retry).
//
// [v1.3 — 2026-10-15] — FIX: PlacesController..load()
// [v1.2 — 2026-10-15] — G6.7: TripPlansController provider
// [v1.1 — 2026-10-14] — G4.2-c: BrowsingLocationController provider
// [v1.0 — 2026-10-13] — Initial app setup

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/location/browsing_location_controller.dart';
import 'core/router/app_router.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/categories/controllers/categories_controller.dart';
import 'features/favorites/controllers/favorites_controller.dart';
import 'features/places/controllers/places_controller.dart';
import 'features/trip/controllers/trip_plans_controller.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'l10n/theme_controller.dart';
import 'theme/app_theme.dart';

// 🔔 Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

  // ═══════════════════════════════════════════════════════════════
  // Firestore settings — FlutLab Web specific
  // ═══════════════════════════════════════════════════════════════
  // FlutLab Free يحجب WebChannel → SDK يفشل.
  // الحل المؤقت: long-polling.
  // الحل الجذري: PlacesRepository يستخدم Source.server + retry.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
    webExperimentalForceLongPolling: true,
    webExperimentalAutoDetectLongPolling: true,
  );

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
        ChangeNotifierProvider<CategoriesController>(
          create: (_) => CategoriesController()..start(),
        ),
        // ✅ [v1.3] ..load() — ضروري لجلب Places عند الإقلاع
        ChangeNotifierProvider<PlacesController>(
          create: (_) => PlacesController()..load(),
        ),
        ChangeNotifierProvider<FavoritesController>(
          create: (_) => FavoritesController(),
        ),
        ChangeNotifierProvider<BrowsingLocationController>(
          create: (_) => BrowsingLocationController(),
        ),
        ChangeNotifierProvider<TripPlansController>(
          create: (_) => TripPlansController(),
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
