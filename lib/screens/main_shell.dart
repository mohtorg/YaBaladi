import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/route_paths.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../l10n/app_localizations.dart';
import '../widgets/login_required_dialog.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBackPress;

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

  Future<void> _onTap(BuildContext context, _NavDest dest) async {
    final auth = context.read<AuthController>();

    if (dest.requiresLogin && auth.isGuest) {
      await showLoginRequiredDialog(context, featureName: dest.label);
      return;
    }

    if (context.mounted) context.go(dest.path);
  }

  /// منطق زر الرجوع:
  /// - لو مش في Home → ارجع للـ Home
  /// - لو في Home → "اضغط مرة أخرى للخروج"
  void _handleBack(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    // مش في Home → ارجع للـ Home بدل الخروج
    if (location != RoutePaths.home) {
      context.go(RoutePaths.home);
      return;
    }

    // إحنا في Home → منطق "اضغط مرتين"
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

    // ضغط مرتين خلال ثانيتين → اخرج
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final index = _indexFromLocation(context);
    final isGuest = auth.isGuest;

    final destinations = [
      _NavDest(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: l10n.home,
        path: RoutePaths.home,
        requiresLogin: false,
      ),
      _NavDest(
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
        label: l10n.profile,
        path: RoutePaths.profile,
        requiresLogin: true,
      ),
      _NavDest(
        icon: Icons.favorite_border,
        selectedIcon: Icons.favorite,
        label: l10n.favorites,
        path: RoutePaths.favorites,
        requiresLogin: true,
      ),
      _NavDest(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n.settings,
        path: RoutePaths.settings,
        requiresLogin: false,
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
                icon: _maybeLocked(
                  context,
                  Icon(d.icon),
                  locked: d.requiresLogin && isGuest,
                ),
                selectedIcon: _maybeLocked(
                  context,
                  Icon(d.selectedIcon),
                  locked: d.requiresLogin && isGuest,
                ),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }

  Widget _maybeLocked(
    BuildContext context,
    Widget icon, {
    required bool locked,
  }) {
    if (!locked) return icon;
    return Badge(
      backgroundColor: Theme.of(context).colorScheme.primary,
      smallSize: 10,
      child: icon,
    );
  }
}

class _NavDest {
  const _NavDest({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.path,
    required this.requiresLogin,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String path;
  final bool requiresLogin;
}