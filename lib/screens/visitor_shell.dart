// screens/visitor_shell.dart
// غلاف مستقل للزائر: تبويب الاكتشاف، رحلة اليوم، الحساب، الإعدادات.
// لا نعيد استخدام MainShell حتى لا يصبح مسار الزائر مجرد نسخة من مسار المقيم.

import 'package:flutter/material.dart';
import 'visitor_home_screen.dart';
import 'day_trip_screen.dart';
import 'account_tab_screen.dart';
import 'settings_tab_screen.dart';

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
    SettingsTabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'اكتشف'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'رحلة اليوم'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
        ],
      ),
    );
  }
}
