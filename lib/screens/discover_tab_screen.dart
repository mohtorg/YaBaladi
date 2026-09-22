// screens/discover_tab_screen.dart
//
// الغرض: جعل "اكتشف" مساحة الاستكشاف العامة بدل تكرارها كزر ثانٍ في الشاشة الرئيسية.
// السبب: الشريط السفلي يحتاج وظيفة مستقلة للبحث والفلاتر، بينما الشاشة الرئيسية تعرض
// اختصارات سريعة فقط. لا نضيف "أضف مكان" إلى التنقل الرئيسي في هذه المرحلة.
// العلاقة: يفتح البحث الحالي، رحلة اليوم، الفعاليات، الأماكن القريبة، وخريطة التطبيق.
// لا نغيّر هذه الأدوار إلى تبويبات جديدة عشوائيًا؛ أي إضافة مستقبلية يجب أن تحافظ على
// قاعدة: الرئيسية = ملخص، اكتشف = استكشاف، رحلتي = تخطيط، المفضلة = حفظ، حسابي = شخصي.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'day_trip_screen.dart';
import 'events_today_screen.dart';
import 'nearby_places_screen.dart';
import 'search_screen.dart';
import 'app_map_screen.dart';
import 'library_screen.dart';

class DiscoverTabScreen extends StatelessWidget {
  final String cityId;

  const DiscoverTabScreen({super.key, this.cityId = 'port_said'});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _DiscoverAction(Icons.search, 'البحث', 'ابحث وفلتر الأماكن والخدمات', () => _push(context, SearchScreen(cityId: cityId))),
      _DiscoverAction(Icons.location_on_outlined, 'أماكن قريبة', 'ما حولك الآن', () => _push(context, NearbyPlacesScreen(cityId: cityId))),
      _DiscoverAction(Icons.event_available_outlined, 'فعاليات اليوم', 'ما يحدث اليوم', () => _push(context, EventsTodayScreen(cityId: cityId))),
      _DiscoverAction(Icons.route_outlined, 'رحلة اليوم', 'خطط ليومك', () => _push(context, DayTripScreen(cityId: cityId))),
      _DiscoverAction(Icons.photo_library_outlined, 'مكتبة يا بلدي', 'صور وحكايات ومعالم وتراث وفعاليات', () => _push(context, LibraryScreen(governorateId: cityId))),
      _DiscoverAction(Icons.explore_rounded, 'خريطة يا بلدي', 'تعرف على أقسام التطبيق واختصاراته', () => _push(context, AppMapScreen(cityId: cityId))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('اكتشف'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('ماذا تريد أن تفعل؟', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('كل أدوات الاستكشاف في مكان واحد، بدون ازدحام الشاشة الرئيسية.', style: TextStyle(color: Colors.grey, height: 1.5)),
          const SizedBox(height: 18),
          ...actions.map((action) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: .10),
                    child: Icon(action.icon, color: AppColors.primary),
                  ),
                  title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(action.subtitle),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: action.onTap,
                ),
              )),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

class _DiscoverAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DiscoverAction(this.icon, this.title, this.subtitle, this.onTap);
}
