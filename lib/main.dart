// lib/main.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/location/browsing_location_controller.dart';
import 'core/router/app_router.dart';
import 'core/utils/error_reporter.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/categories/controllers/categories_controller.dart';
import 'features/favorites/controllers/favorites_controller.dart';
import 'features/filters/controllers/filters_controller.dart';
import 'features/notifications/controllers/notifications_controller.dart';
import 'features/notifications/services/fcm_service.dart'; // ✅ استيراد خدمة FCM
import 'features/places/controllers/places_controller.dart';
import 'features/support/controllers/support_tickets_controller.dart';
import 'features/trip/controllers/trip_plans_controller.dart';
import 'features/trip/controllers/trip_bag_controller.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'l10n/theme_controller.dart';
import 'theme/app_theme.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('📩 Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorReporter.showError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.showError(error, stack);
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            const Text('حدث خطأ في عرض هذه الشاشة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(details.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
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
            create: (_) => LocaleController()..load()),
        ChangeNotifierProvider<ThemeController>(
            create: (_) => ThemeController()..load()),
        ChangeNotifierProvider<AuthController>(create: (_) => AuthController()),
        ChangeNotifierProvider<CategoriesController>(
            create: (_) => CategoriesController()..start()),
        ChangeNotifierProvider<FiltersController>(
            create: (_) => FiltersController()..load()),
        ChangeNotifierProxyProvider<FiltersController, PlacesController>(
          create: (_) => PlacesController(),
          update: (_, filters, places) =>
              places!..setFiltersMetadata(filters.all),
        ),
        ChangeNotifierProvider<FavoritesController>(
            create: (_) => FavoritesController()),
        ChangeNotifierProvider<BrowsingLocationController>(
            create: (_) => BrowsingLocationController()),
        ChangeNotifierProvider<TripPlansController>(
            create: (_) => TripPlansController()),
        ChangeNotifierProvider<TripBagController>(
            create: (_) => TripBagController()),
        ChangeNotifierProvider<SupportTicketsController>(
            create: (_) => SupportTicketsController()..loadTickets()),

        // ✅ متحكم الإشعارات + تفعيل FCM عند تسجيل الدخول
        ChangeNotifierProxyProvider<AuthController, NotificationsController>(
          create: (_) => NotificationsController(),
          update: (_, auth, ctrl) {
            if (ctrl == null) return NotificationsController();
            if (auth.isLoggedIn && auth.uid.isNotEmpty) {
              // 1. تفعيل الإشعارات الداخلية (In-App)
              ctrl.listen(auth.uid);

              // 2. تفعيل إشعارات FCM (Push Notifications)
              FcmService.initialize(auth.uid);
            } else {
              ctrl.stop();
              FcmService.reset(); // ✅ إعادة تعيين FCM عند الخروج
            }
            return ctrl;
          },
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

    if (_router == null) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: ErrorReporter.messengerKey,
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
