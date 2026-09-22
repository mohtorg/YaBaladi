// screens/app_map_screen.dart
//
// الغرض: تقديم "خريطة يا بلدي" كخريطة وظيفية للتطبيق نفسه، وليس خريطة جغرافية.
// السبب: الخريطة الجغرافية ليست من أهم أربع وظائف في الشاشة الرئيسية الآن، بينما
// المستخدم الجديد يحتاج أن يفهم بسرعة ماذا يستطيع أن يفعل داخل التطبيق.
// العلاقة: الشاشة الرئيسية تفتحها كمدخل تعريفي سريع، وتبقى الخريطة الجغرافية
// (إن احتجناها لاحقًا) داخل سياق المكان/الرحلة بدل حجز مساحة رئيسية لها.
// لا نضيف هنا أي منطق أماكن أو خرائط خارجية؛ هذه الشاشة خاصة بفهم بنية المنتج.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'category_screen.dart';
import 'day_trip_screen.dart';
import 'search_screen.dart';
import 'events_today_screen.dart';
import 'nearby_places_screen.dart';

class AppMapScreen extends StatelessWidget {
  final String cityId;

  const AppMapScreen({super.key, this.cityId = 'port_said'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('خريطة يا بلدي'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: .82),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.explore_rounded, color: Colors.white, size: 34),
                SizedBox(height: 12),
                Text(
                  'اعرف طريقك داخل يا بلدي',
                  style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 7),
                Text(
                  'من اكتشاف المكان إلى تخطيط يومك وحفظ اختياراتك — كل أدواتك هنا.',
                  style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const _SectionLabel(title: 'ابدأ من هنا'),
          const SizedBox(height: 8),
          _MapNode(
            icon: Icons.home_rounded,
            title: 'الرئيسية',
            subtitle: 'ملخص شخصي لما يهمك الآن في مدينتك.',
            color: AppColors.primary,
            onTap: () => Navigator.pop(context),
          ),
          const _Connector(),
          _MapNode(
            icon: Icons.explore_rounded,
            title: 'اكتشف',
            subtitle: 'ابحث، فلتر، واستكشف الأماكن والخدمات والفعاليات.',
            color: AppColors.secondary,
            onTap: () => _push(context, SearchScreen(cityId: cityId)),
          ),
          const _Connector(),
          _MapNode(
            icon: Icons.route_rounded,
            title: 'رحلتي',
            subtitle: 'خطط لليوم واحفظ رحلاتك بدل البحث من جديد كل مرة.',
            color: AppColors.highlight,
            onTap: () => _push(context, DayTripScreen(cityId: cityId)),
          ),
          const SizedBox(height: 18),
          const _SectionLabel(title: 'اختصارات سريعة'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SmallNode(
                icon: Icons.location_on_outlined,
                title: 'أماكن قريبة',
                onTap: () => _push(context, NearbyPlacesScreen(cityId: cityId)),
              ),
              _SmallNode(
                icon: Icons.event_available_outlined,
                title: 'فعاليات اليوم',
                onTap: () => _push(context, EventsTodayScreen(cityId: cityId)),
              ),
              _SmallNode(
                icon: Icons.category_outlined,
                title: 'التصنيفات',
                onTap: () => _push(
                  context,
                  CategoryScreen(category: '', categoryLabel: 'كل التصنيفات', cityId: cityId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel(title: 'احتفظ بما يعجبك'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: .08)),
            ),
            child: const Row(
              children: [
                Icon(Icons.favorite_rounded, color: AppColors.accent),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'المفضلة وحسابي في الشريط السفلي دائمًا في متناولك.',
                    style: TextStyle(height: 1.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'الخريطة هنا تشرح التطبيق، وليست خريطة جغرافية. الخرائط الجغرافية تظل مرتبطة بسياق المكان أو الرحلة عند الحاجة.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerRight,
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsetsDirectional.only(start: 28),
        child: Container(width: 2, height: 18, color: AppColors.primary.withValues(alpha: .15)),
      );
}

class _MapNode extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MapNode({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: color.withValues(alpha: .10),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: Colors.grey, height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallNode extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SmallNode({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          width: 150,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.primary),
              const SizedBox(width: 7),
              Icon(icon, color: AppColors.primary, size: 21),
              const SizedBox(width: 7),
              Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            ],
          ),
        ),
      );
}
