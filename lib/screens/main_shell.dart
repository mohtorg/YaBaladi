import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/route_paths.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/favorites/controllers/favorites_controller.dart';
import '../l10n/app_localizations.dart';

/// [v1.3 — 2026-10-15] — G6.7: Bottom Nav (4 tabs)
///   - CHANGE: 5 tabs → 4 tabs: الرئيسية | رحلتي | حسابي | الإعدادات
///   - CHANGE: المفضلة انتقلت لـ ProfileScreen (drill-down)
///   - NEW: تبويب "رحلتي" (trips)
///
/// [v1.2 — 2026-10-14] — StatefulShellRoute + Favorites race fix
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBackPress;
  String? _lastSyncedUid;
  int _favoritesSyncGeneration = 0;

  void _syncFavoritesWatcher(String? uid) {
    if (_lastSyncedUid == uid) return;
    _lastSyncedUid = uid;

    final myGen = ++_favoritesSyncGeneration;
    final fav = context.read<FavoritesController>();
    final capturedUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (myGen != _favoritesSyncGeneration) return;

      if (capturedUid != null) {
        fav.startWatching(capturedUid);
      } else {
        fav.stopWatching();
      }
    });
  }

  void _onTap(BuildContext context, _NavDest dest, int index) {
    final auth = context.read<AuthController>();

    if (dest.lockForGuest && auth.isGuest) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('سجّل دخولك للوصول لهذه الميزة'),
            duration: Duration(seconds: 2),
          ),
        );
      return;
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _handleBack(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location != RoutePaths.home) {
      widget.navigationShell.goBranch(0, initialLocation: true);
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
    final currentIndex = widget.navigationShell.currentIndex;

    _syncFavoritesWatcher(auth.uid);

    // [v1.3] 4 tabs — المفضلة انتقلت لـ Profile
    final destinations = [
      _NavDest(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.home,
        lockForGuest: false,
      ),
      _NavDest(
        icon: Icons.explore_outlined,
        selectedIcon: Icons.explore,
        label: l10n.tripsTitle,
        lockForGuest: false, // الزائر يرى Empty State
      ),
      _NavDest(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.profile,
        lockForGuest: false,
      ),
      _NavDest(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
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
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentIndex,
          onDestinationSelected: (i) => _onTap(context, destinations[i], i),
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _NavDest {
  const _NavDest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.lockForGuest,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool lockForGuest;
}
