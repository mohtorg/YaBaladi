import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/route_paths.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/favorites/controllers/favorites_controller.dart';
import '../l10n/app_localizations.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBackPress;
  String? _lastSyncedUid;

  int _indexFromLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final paths = [
      RoutePaths.home,
      RoutePaths.profile,
      RoutePaths.favorites,
      RoutePaths.settings,
    ];
    final idx = paths.indexWhere((p) => p == location);
    return idx < 0 ? 0 : idx;
  }

  /// زامن الـ FavoritesController مع حالة المصادقة.
  void _syncFavoritesWatcher(String? uid) {
    if (_lastSyncedUid == uid) return;
    _lastSyncedUid = uid;

    final fav = context.read<FavoritesController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (uid != null) {
        fav.startWatching(uid);
      } else {
        fav.stopWatching();
      }
    });
  }

  /// عند الضغط على Bottom Nav
  ///
  /// ملاحظة: دلوقتي بنسمح للزائر يدخل "حسابي" عادي،
  /// والـ ProfileScreen بتعرض "_GuestUpgradeCard" مع زر
  /// "الخروج من الوضع الزائر".
  ///
  /// الـ guard مفعّل فقط على "المفضلة" (تحتاج تسجيل دخول حقيقي).
  Future<void> _onTap(BuildContext context, _NavDest dest) async {
    final auth = context.read<AuthController>();

    // ═══════════════════════════════════════════════════════════
    // الـ guard القديم (dialog) — شال من "حسابي"
    // ═══════════════════════════════════════════════════════════
    //
    // if (dest.requiresLogin && auth.isGuest) {
    //   await showLoginRequiredDialog(context, featureName: dest.label);
    //   return;
    // }
    //
    // ═══════════════════════════════════════════════════════════

    // ─── محفوظ فقط للمفضلة ───
    if (dest.lockForGuest && auth.isGuest) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('سجّل دخولك لعرض مفضلاتك'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    if (context.mounted) context.go(dest.path);
  }

  /// منطق زر الرجوع:
  /// - لو مش في Home → ارجع للـ Home
  /// - لو في Home → "اضغط مرة أخرى للخروج"
  void _handleBack(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location != RoutePaths.home) {
      context.go(RoutePaths.home);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('اضغط مرة أخرى للخروج من التطبيق'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final favorites = context.watch<FavoritesController>();
    final index = _indexFromLocation(context);
    final isGuest = auth.isGuest;

    // ─── زامن المراقبة ───
    _syncFavoritesWatcher(auth.uid);

    final destinations = [
      _NavDest(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.home,
        path: RoutePaths.home,
        lockForGuest: false,
      ),
      _NavDest(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.profile,
        path: RoutePaths.profile,
        lockForGuest: false, // ← الزائر مسموح له
      ),
      _NavDest(
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        label: l10n.favorites,
        path: RoutePaths.favorites,
        lockForGuest: true, // ← المفضلة فقط
        badgeCount: favorites.count,
      ),
      _NavDest(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
        path: RoutePaths.settings,
        lockForGuest: false,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        body: widget.child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => _onTap(context, destinations[i]),
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: _buildIcon(
                  context,
                  Icon(d.icon),
                  locked: d.lockForGuest && isGuest,
                  badgeCount: d.badgeCount,
                ),
                selectedIcon: _buildIcon(
                  context,
                  Icon(d.selectedIcon),
                  locked: d.lockForGuest && isGuest,
                  badgeCount: d.badgeCount,
                ),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(
    BuildContext context,
    Widget icon, {
    required bool locked,
    int badgeCount = 0,
  }) {
    // Guest → نقطة صغيرة على المفضلة
    if (locked) {
      return Badge(
        backgroundColor: Theme.of(context).colorScheme.primary,
        smallSize: 10,
        child: icon,
      );
    }

    // مسجّل + فيه مفضلات → badge بالرقم
    if (badgeCount > 0) {
      return Badge(
        label: Text('$badgeCount'),
        child: icon,
      );
    }

    return icon;
  }
}

class _NavDest {
  const _NavDest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
    required this.lockForGuest,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
  final bool lockForGuest;
  final int badgeCount;
}