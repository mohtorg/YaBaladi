// ╪║┘╪د┘ ╪د┘┘à╪│╪ز╪«╪»┘à ╪د┘┘à┘é┘è┘à.
// ┘é╪د╪╣╪»╪ر ╪د┘╪ز┘┘é┘: ╪د┘╪▒╪خ┘è╪│┘è╪ر = ┘à┘╪«╪╡╪î ╪د┘â╪ز╪┤┘ = ╪د╪│╪ز┘â╪┤╪د┘╪î ╪▒╪ص┘╪ز┘è = ╪ز╪«╪╖┘è╪╖╪î ╪د┘┘à┘╪╢┘╪ر = ╪ص┘╪╕╪î ╪ص╪│╪د╪ذ┘è = ╪د┘┘╪┤╪د╪╖ ┘ê╪د┘╪ح╪╣╪»╪د╪»╪د╪ز.

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import 'home_tab_screen.dart';
import 'discover_tab_screen.dart';
import 'day_trip_screen.dart';
import 'favorites_tab_screen.dart';
import 'account_tab_screen.dart';
import '../theme/app_colors.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    HomeTabScreen(),
    DiscoverTabScreen(),
    DayTripScreen(),
    FavoritesTabScreen(),
    AccountTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = LocaleController.of(context).locale.languageCode;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.home_outlined), activeIcon: const Icon(Icons.home), label: AppStrings.of('home', lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.explore_outlined), activeIcon: const Icon(Icons.explore), label: AppStrings.of('discover', lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.route_outlined), activeIcon: const Icon(Icons.route), label: AppStrings.of('day_trip', lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.favorite_border), activeIcon: const Icon(Icons.favorite), label: AppStrings.of('favorites', lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.person_outline), activeIcon: const Icon(Icons.person), label: AppStrings.of('account', lang)),
        ],
      ),
    );
  }
}
