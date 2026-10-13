import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/route_paths.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/favorites/controllers/favorites_controller.dart';
import '../l10n/app_localizations.dart';

/// [v1.2 — StatefulShellRoute + Favorites Race Fix]
///   - REFACTOR: يستقبل StatefulNavigationShell بدل Widget child.
///     التنقل بين التبويبات يحفظ الحالة (لا rebuild للشاشات السابقة).
///   - FIX: _syncFavoritesWatcher محمي بمولّد طلبات (_favoritesSyncGeneration)
///          لمنع race condition عند login/logout متتاليين.
///   - NavigationBar يستخدم navigationShell.currentIndex و goBranch().
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  /// [v1.2] StatefulNavigationShell — يحفظ حالة كل تبويب.
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBackPress;
  String? _lastSyncedUid;
  int _favoritesSyncGeneration = 0;

  /// زامن الـ FavoritesController مع حالة المصادقة.
  ///
  /// [v1.1] محمي بمولّد طلبات — آخر طلب فقط يُنفَّذ.
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

  /// عند الضغط على Bottom Nav
  ///
  /// [v1.2] يستخدم navigationShell.goBranch() بدل context.go()
  ///   - إذا نفس التبويب → reset إلى الـ root (initialLocation: true)
  ///   - إذا تبويب آخر → التبديل مع حفظ الحالة
  void _onTap(BuildContext context, _NavDest dest, int index) {
    final auth = context.read<AuthController>();

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

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  /// منطق زر الرجوع:
  /// - إذا لم نكن في Home branch على الـ root → ارجع للـ Home root
  /// - إذا كنا في Home root → "اضغط مرة أخرى للخروج"
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
    final favorites = context.watch<FavoritesController>();
    final isGuest = auth.isGuest;
    final currentIndex = widget.navigationShell.currentIndex;

    _syncFavoritesWatcher(auth.uid);

    final destinations = [
      _NavDest(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.home,
        lockForGuest: false,
      ),
      _NavDest(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.profile,
        lockForGuest: false,
      ),
      _NavDest(
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        label: l10n.favorites,
        lockForGuest: true,
        badgeCount: favorites.count,
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
    if (locked) {
      return Badge(
        backgroundColor: Theme.of(context).colorScheme.primary,
        smallSize: 10,
        child: icon,
      );
    }

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
    required this.lockForGuest,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool lockForGuest;
  final int badgeCount;
}
