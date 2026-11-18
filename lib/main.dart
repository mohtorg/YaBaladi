// lib/main.dart
//
// [v4.2 — 2026-11-15] — ONE-TIME RESET: Added `_runOneTimeReset` flag and
//   `ResetRatingsUtil` execution to clean legacy ratings before Phase 8.
//   ⚠️ Set `_runOneTimeReset = false` after the first successful run.
// [v4.1 — 2026-11-11] — SAFE ERROR WIDGET FIX:
//   - Changed ErrorWidget root to Center to prevent layout crashes inside Lists.
// [v4.0 — 2026-11-10] — SAFE ERROR WIDGET.
// [v3.9 — 2026-11-10] — FIX: Initialized intl Arabic date formatting.
// [v3.8 — 2026-11-10] — RATING: Added RatingController to MultiProvider.
// [v3.7 — PRODUCTION] — FINAL FIX: RTL + localeResolutionCallback.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:yabaladi_rebuild/features/auth/google_auth_service.dart';

import 'core/location/browsing_location_controller.dart';
import 'core/router/app_router.dart';
import 'core/utils/error_reporter.dart';
import 'core/utils/reset_ratings_util.dart'; // ✅ Phase 8: One-time reset utility
import 'features/auth/controllers/auth_controller.dart';
import 'features/categories/controllers/categories_controller.dart';
import 'features/favorites/controllers/favorites_controller.dart';
import 'features/filters/controllers/filters_controller.dart';
import 'features/notifications/controllers/notifications_controller.dart';
import 'features/notifications/services/fcm_service.dart';
import 'features/places/controllers/places_controller.dart';
import 'features/rating/controllers/rating_controller.dart';
import 'features/support/controllers/support_tickets_controller.dart';
import 'features/trip/controllers/trip_plans_controller.dart';
import 'features/trip/controllers/trip_bag_controller.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'l10n/theme_controller.dart';
import 'theme/app_theme.dart';

/// ⚠️ TEMPORARY FLAG: Set to `true` ONCE to wipe all ratings and aggregates,
/// then change back to `false` and hot-restart to prevent accidental data loss.
const bool _runOneTimeReset = false;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ ضروري جداً: تفعيل بيانات اللغة العربية لتنسيق التاريخ
  await initializeDateFormatting('ar', null);

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorReporter.showError(details.exception, details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorReporter.showError(error, stack);
    return true;
  };

  // ✅ إصلاح جذري: استخدام Center كجذر لمنع الانهيارات داخل القوائم
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bug_report, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                const Text(
                  'حدث خطأ في عرض هذه الشاشة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  details.exception.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      webExperimentalForceLongPolling: true,
      webExperimentalAutoDetectLongPolling: true,
    );

    // ✅ Phase 8: One-time reset before app starts
    if (_runOneTimeReset) {
      try {
        debugPrint('⚠️ RUNNING ONE-TIME RATINGS RESET...');
        await ResetRatingsUtil.resetAllRatings();
        debugPrint(
            '✅ RATINGS RESET COMPLETED. CHANGE _runOneTimeReset TO false NOW.');
      } catch (e) {
        debugPrint('❌ RATINGS RESET FAILED: $e');
      }
    }

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await GoogleAuthService().init();
  } catch (e) {
    debugPrint('Critical Initialization Error: $e');
  }

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
        ChangeNotifierProvider<FiltersController>(
          create: (_) => FiltersController()..load(),
        ),
        ChangeNotifierProxyProvider<FiltersController, PlacesController>(
          create: (_) => PlacesController(),
          update: (_, filters, places) {
            final controller = places ?? PlacesController();
            controller.setFiltersMetadata(filters.all);
            return controller;
          },
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
        ChangeNotifierProvider<TripBagController>(
          create: (_) => TripBagController(),
        ),
        ChangeNotifierProvider<RatingController>(
          create: (_) => RatingController(),
        ),
        ChangeNotifierProvider<SupportTicketsController>(
          create: (_) => SupportTicketsController()..loadTickets(),
        ),
        ChangeNotifierProxyProvider<AuthController, NotificationsController>(
          create: (_) => NotificationsController(),
          update: (_, auth, ctrl) {
            final controller = ctrl ?? NotificationsController();
            if (auth.isLoggedIn && auth.uid.isNotEmpty) {
              controller.listen(auth.uid);
              FcmService.initialize(auth.uid);
            } else {
              controller.stop();
              FcmService.reset();
            }
            return controller;
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
    if (_router == null || !identical(_authController, auth)) {
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
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Directionality(
      textDirection: locale.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: MaterialApp.router(
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
        localeResolutionCallback: (deviceLocale, supported) {
          if (locale.isArabic) return const Locale('ar');
          if (locale.isEnglish) return const Locale('en');
          return const Locale('ar');
        },
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: theme.themeMode,
        routerConfig: _router!,
      ),
    );
  }
}
