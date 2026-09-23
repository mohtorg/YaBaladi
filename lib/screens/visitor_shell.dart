// غلاف وضع الزائر.
// الإعدادات ليست تبويبًا مستقلًا؛ تُدار من حسابي حتى لا تتكرر الوظائف.

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import 'visitor_home_screen.dart';
import 'day_trip_screen.dart';
import 'account_tab_screen.dart';

class VisitorShell extends StatefulWidget {
  const VisitorShell({super.key});

  @override
  State<VisitorShell> createState() => _VisitorShellState();
}

class _VisitorShellState extends State<VisitorShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    VisitorHomeScreen(),
    DayTripScreen(),
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
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.explore), label: AppStrings.of('discover', lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.route), label: AppStrings.of('day_trip', lang)),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: AppStrings.of('account', lang)),
        ],
      ),
    );
  }
}
