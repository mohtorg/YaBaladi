// screens/main_shell.dart
//
// الغرض: الشريط السفلي للمقيم بعد إعادة ترتيب تجربة "يا بلدي".
// الترتيب النهائي: الرئيسية، اكتشف، رحلتي، المفضلة، حسابي.
// السبب: "أضف مكان" ليست وظيفة أساسية الآن، والإعدادات مكانها داخل "حسابي" بدل حجز
// تبويب دائم لها. لا نعيد إضافة أي تبويب جديد إلا إذا كان له سلوك يومي واضح للمستخدم.
// العلاقة: الرئيسية = ملخص، اكتشف = البحث والأدوات، رحلتي = التخطيط، المفضلة = الحفظ، حسابي = النشاط والإعدادات.

import 'package:flutter/material.dart';
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
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'اكتشف'),
          BottomNavigationBarItem(icon: Icon(Icons.route_outlined), activeIcon: Icon(Icons.route), label: 'رحلتي'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), activeIcon: Icon(Icons.favorite), label: 'المفضلة'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
