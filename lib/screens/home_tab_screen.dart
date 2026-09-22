// screens/home_tab_screen.dart
//
// ============================================================
// الفكرة العامة من الشاشة دي:
// دي "التبويب الرئيسي" الجديد - هيدر ترحيبي + بحث + شبكة أيقونات
// لأنواع الأماكن بس (مطاعم، كافيهات، فعاليات...).
// عن قصد ملهاش فلاتر جمهور هنا - دي بقت متنقلة لشاشة الفئة نفسها
// (category_screen.dart) عشان الشاشة الرئيسية تفضل بسيطة ونضيفة
// ============================================================

import 'package:flutter/material.dart';
import '../models/egypt_governorates.dart';
import 'category_screen.dart';
import 'search_screen.dart';
import '../services/auth_service.dart';
import '../models/place_categories.dart';
import '../models/local_identity.dart';
import '../theme/app_colors.dart';
import '../models/governorate_visual_profile.dart';
import '../services/governorate_visual_service.dart';
import '../widgets/governorate_hero.dart';
import '../services/weather_service.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import 'nearby_places_screen.dart';
import 'events_today_screen.dart';
import 'day_trip_screen.dart';
import 'app_map_screen.dart';
import 'place_details_screen.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  String _selectedCityId = EgyptGovernorates.activeGovernorateId;
  final String _locationLabel = 'الموقع';
  String _userName = '';
  GovernorateVisualProfile? _visual;
  WeatherSnapshot? _weather;
  bool _weatherLoading = false;
  List<Place> _newPlaces = [];
  @override void initState() { super.initState(); _loadHeader(); }
  Future<void> _loadHeader() async {
    final u = await AuthService().getCurrentAppUser();
    final visual = await GovernorateVisualService().getPublished(_selectedCityId);
    final weather = await WeatherService().getCurrent(_selectedCityId);
    final places = await PlaceService().getPlacesByCity(_selectedCityId);
    final cutoff = DateTime.now().subtract(const Duration(days: 14));
    final newPlaces = places.where((p) => p.publishedAt != null && p.publishedAt!.isAfter(cutoff)).toList();
    if (!mounted) return;
    setState(() {
      _userName = u?.fullName.trim() ?? '';
      _visual = visual;
      _weather = weather;
      _newPlaces = newPlaces;
    });
  }

  // ------------------------------------------------------------
  // الفكرة: كل فئة عندها اسم عربي، أيقونة، ولون خلفية مميز -
  // بنعرضهم كقائمة ثابتة هنا عشان الشبكة تتبني منها بحلقة for
  // بدل ما نكرر نفس كود البطاقة 6 مرات يدويًا
  // ------------------------------------------------------------
  // ------------------------------------------------------------
  // التصنيفات الرئيسية موحدة في PlaceCategories حتى تستخدم نفس القيم
  // لوحة الأدمن + البحث + الشاشة الرئيسية. لا نكتب category يدويًا.
  // ------------------------------------------------------------
  final List<_CategoryItem> _categories = PlaceCategories.all
      .map((c) => _CategoryItem(c.id, c.labelAr, c.icon, const Color(0xFFFFF4E8), const Color(0xFFD8720C)))
      .toList();

  // ------------------------------------------------------------
  // الفكرة: نافذة بسيطة لاختيار المحافظة - بديل عن الـ Dropdown
  // القديم، بنفتحها بالضغط على أيقونة الموقع في الهيدر
  // ------------------------------------------------------------
  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: EgyptGovernorates.all.map((gov) {
          final isActive = gov.id == EgyptGovernorates.activeGovernorateId;
          return ListTile(
            title: Text(gov.nameAr),
            trailing: !isActive ? const Text('قريبًا', style: TextStyle(color: Colors.grey, fontSize: 12)) : null,
            enabled: isActive,
            selected: gov.id == _selectedCityId,
            onTap: isActive
                ? () {
                    setState(() {
                      _selectedCityId = gov.id;
                      _visual = null;
                      _weather = null;
                      _weatherLoading = true;
                    });
                    Navigator.pop(context);
                    Future.wait([
                      GovernorateVisualService().getPublished(gov.id),
                      WeatherService().getCurrent(gov.id),
                      PlaceService().getPlacesByCity(gov.id),
                    ]).then((results) {
                      if (!mounted || _selectedCityId != gov.id) return;
                      setState(() {
                        _visual = results[0] as GovernorateVisualProfile?;
                        _weather = results[1] as WeatherSnapshot?;
                        final places = results[2] as List<Place>;
                        final cutoff = DateTime.now().subtract(const Duration(days: 14));
                        _newPlaces = places.where((p) => p.publishedAt != null && p.publishedAt!.isAfter(cutoff)).toList();
                        _weatherLoading = false;
                      });
                    });
                  }
                : null,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cityName = EgyptGovernorates.getById(_selectedCityId)?.nameAr ?? '';
    final localIdentity = LocalIdentity.forGovernorate(_selectedCityId);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
            // ------------------------------------------------------------
            // الفكرة: هيدر أزرق فيه (يمين ليسار): جرس إشعارات، اسم التطبيق
            // ومحافظة المستخدم الحالية، ورسالة ترحيب بالاسم
            // ------------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.notifications_none, color: Colors.white),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.asset('assets/branding/ya_baladi_icon.png', width: 28, height: 28),
                          ),
                          const SizedBox(width: 8),
                          const Text('يا بلدي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showCityPicker,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.location_on, size: 16, color: Color(0xFF1454A3)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('${_locationLabel == 'موقعي الحالي' ? '📍 $_locationLabel' : cityName} • ${_userName.isEmpty ? 'أهلًا بيك' : 'أهلًا بيك يا $_userName'} 👋', style: const TextStyle(color: Color(0xFFCFE0F5), fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: localIdentity.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('اكتشف ${localIdentity.labelFor('ar')}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            // شريط البحث (بيوديك لشاشة فئة "الكل" بنص بحث مبدئي لاحقًا)
            Padding(padding: const EdgeInsets.all(16), child: InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SearchScreen(cityId:_selectedCityId))), child: Container(height:42,padding:const EdgeInsets.symmetric(horizontal:12),decoration:BoxDecoration(color:Colors.grey[100],borderRadius:BorderRadius.circular(10)),child:const Row(children:[Icon(Icons.search,color:Colors.grey,size:20),SizedBox(width:8),Text('ابحث عن أي مكان أو خدمة بسهولة!',style:TextStyle(color:Colors.grey,fontSize:13))])))),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GovernorateHero(
                governorateName: cityName,
                subtitle: _userName.isEmpty
                    ? 'اكتشف ما حولك في ${localIdentity.labelFor('ar')}'
                    : 'أهلًا بك يا $_userName 👋 • اكتشف ${localIdentity.labelFor('ar')}',
                visual: _visual,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _weatherLoading
                            ? 'الطقس الآن • جارٍ التحديث...'
                            : _weather == null
                                ? 'الطقس الآن • غير متاح حاليًا'
                                : 'الطقس الآن في $cityName • ${_weather!.temperatureC.round()}° • ${_weather!.conditionAr}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ------------------------------------------------------------
            // اختصارات الشاشة الأولى: أربع وظائف يومية واضحة.
            // الخريطة الجغرافية أزيلت من هذه المنطقة؛ الزر الرابع يفتح خريطة التطبيق
            // نفسها لمساعدة المستخدم على فهم الأقسام، بينما الخريطة الجغرافية تظل سياقية.
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(child: _QuickAction(icon: Icons.location_on_outlined, label: 'أماكن قريبة', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NearbyPlacesScreen(cityId: _selectedCityId))))),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickAction(icon: Icons.event_available_outlined, label: 'فعاليات اليوم', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventsTodayScreen(cityId: _selectedCityId))))),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickAction(icon: Icons.route_outlined, label: 'رحلة اليوم', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DayTripScreen(cityId: _selectedCityId))))),
                  const SizedBox(width: 8),
                  Expanded(child: _QuickAction(icon: Icons.explore_rounded, label: 'خريطة يا بلدي', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppMapScreen(cityId: _selectedCityId))))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('التصنيفات الرئيسية', textAlign: TextAlign.right, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._categories.take(6).map((cat) => _CategoryPill(item: cat, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: cat.categoryValue, categoryLabel: cat.label, cityId: _selectedCityId))))),
                      _CategoryPill(item: _CategoryItem('all', 'المزيد', Icons.apps, const Color(0xFFF1F4F8), AppColors.primary), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: '', categoryLabel: 'كل التصنيفات', cityId: _selectedCityId)))),
                    ],
                  ),
                ],
              ),
            ),
            if (_newPlaces.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('الجديد في $cityName', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(
                height: 155,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _newPlaces.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final place = _newPlaces[index];
                    return SizedBox(
                      width: 230,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlaceDetailsScreen(place: place))),
                          child: Stack(children: [
                            Positioned.fill(child: place.imageUrl.isEmpty ? const ColoredBox(color: Color(0xFFEAF0F7), child: Icon(Icons.place, size: 40)) : Image.network(place.imageUrl, fit: BoxFit.cover)),
                            Positioned(left: 8, top: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Text('جديد', style: TextStyle(fontWeight: FontWeight.bold)))),
                            Positioned(left: 0, right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(10), color: Colors.black54, child: Text(place.nameAr, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// الفكرة: كلاس بسيط لتجميع بيانات كل فئة مع بعض (اسم القيمة المخزّنة
// في قاعدة البيانات، الاسم المعروض، الأيقونة، الألوان)
// ------------------------------------------------------------
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: .06), borderRadius: BorderRadius.circular(14)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: AppColors.primary, size: 25),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final _CategoryItem item;
  final VoidCallback onTap;

  const _CategoryPill({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: item.bgColor, borderRadius: BorderRadius.circular(24)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(item.icon, size: 18, color: item.iconColor),
          const SizedBox(width: 6),
          Text(item.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: item.iconColor)),
        ]),
      ),
    );
  }
}


class _CategoryItem {
  final String categoryValue; // القيمة المخزّنة في حقل "category" بالمكان
  final String label; // الاسم المعروض للمستخدم
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _CategoryItem(this.categoryValue, this.label, this.icon, this.bgColor, this.iconColor);
}



