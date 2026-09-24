// screens/home_tab_screen.dart
//
// ============================================================
// ╪د┘┘┘â╪▒╪ر ╪د┘╪╣╪د┘à╪ر ┘à┘ ╪د┘╪┤╪د╪┤╪ر ╪»┘è:
// ╪»┘è "╪د┘╪ز╪ذ┘ê┘è╪ذ ╪د┘╪▒╪خ┘è╪│┘è" ╪د┘╪ش╪»┘è╪» - ┘ç┘è╪»╪▒ ╪ز╪▒╪ص┘è╪ذ┘è + ╪ذ╪ص╪س + ╪┤╪ذ┘â╪ر ╪ث┘è┘é┘ê┘╪د╪ز
// ┘╪ث┘┘ê╪د╪╣ ╪د┘╪ث┘à╪د┘â┘ ╪ذ╪│ (┘à╪╖╪د╪╣┘à╪î ┘â╪د┘┘è┘ç╪د╪ز╪î ┘╪╣╪د┘┘è╪د╪ز...).
// ╪╣┘ ┘é╪╡╪» ┘à┘┘ç╪د╪┤ ┘┘╪د╪ز╪▒ ╪ش┘à┘ç┘ê╪▒ ┘ç┘╪د - ╪»┘è ╪ذ┘é╪ز ┘à╪ز┘┘é┘╪ر ┘╪┤╪د╪┤╪ر ╪د┘┘╪خ╪ر ┘┘╪│┘ç╪د
// (category_screen.dart) ╪╣╪┤╪د┘ ╪د┘╪┤╪د╪┤╪ر ╪د┘╪▒╪خ┘è╪│┘è╪ر ╪ز┘╪╢┘ ╪ذ╪│┘è╪╖╪ر ┘ê┘╪╢┘è┘╪ر
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
import 'member_qr_scanner_screen.dart';
import 'place_details_screen.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  String _selectedCityId = EgyptGovernorates.activeGovernorateId;
  final String _locationLabel = '╪د┘┘à┘ê┘é╪╣';
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
  // ╪د┘┘┘â╪▒╪ر: ┘â┘ ┘╪خ╪ر ╪╣┘╪»┘ç╪د ╪د╪│┘à ╪╣╪▒╪ذ┘è╪î ╪ث┘è┘é┘ê┘╪ر╪î ┘ê┘┘ê┘ ╪«┘┘┘è╪ر ┘à┘à┘è╪▓ -
  // ╪ذ┘╪╣╪▒╪╢┘ç┘à ┘â┘é╪د╪خ┘à╪ر ╪س╪د╪ذ╪ز╪ر ┘ç┘╪د ╪╣╪┤╪د┘ ╪د┘╪┤╪ذ┘â╪ر ╪ز╪ز╪ذ┘┘è ┘à┘┘ç╪د ╪ذ╪ص┘┘é╪ر for
  // ╪ذ╪»┘ ┘à╪د ┘┘â╪▒╪▒ ┘┘╪│ ┘â┘ê╪» ╪د┘╪ذ╪╖╪د┘é╪ر 6 ┘à╪▒╪د╪ز ┘è╪»┘ê┘è┘ï╪د
  // ------------------------------------------------------------
  // ------------------------------------------------------------
  // ╪د┘╪ز╪╡┘┘è┘╪د╪ز ╪د┘╪▒╪خ┘è╪│┘è╪ر ┘à┘ê╪ص╪»╪ر ┘┘è PlaceCategories ╪ص╪ز┘ë ╪ز╪│╪ز╪«╪»┘à ┘┘╪│ ╪د┘┘é┘è┘à
  // ┘┘ê╪ص╪ر ╪د┘╪ث╪»┘à┘ + ╪د┘╪ذ╪ص╪س + ╪د┘╪┤╪د╪┤╪ر ╪د┘╪▒╪خ┘è╪│┘è╪ر. ┘╪د ┘┘â╪ز╪ذ category ┘è╪»┘ê┘è┘ï╪د.
  // ------------------------------------------------------------
  final List<_CategoryItem> _categories = PlaceCategories.all
      .map((c) => _CategoryItem(c.id, c.labelAr, c.icon, const Color(0xFFFFF4E8), const Color(0xFFD8720C)))
      .toList();

  // ------------------------------------------------------------
  // ╪د┘┘┘â╪▒╪ر: ┘╪د┘╪░╪ر ╪ذ╪│┘è╪╖╪ر ┘╪د╪«╪ز┘è╪د╪▒ ╪د┘┘à╪ص╪د┘╪╕╪ر - ╪ذ╪»┘è┘ ╪╣┘ ╪د┘┘ Dropdown
  // ╪د┘┘é╪»┘è┘à╪î ╪ذ┘┘╪ز╪ص┘ç╪د ╪ذ╪د┘╪╢╪║╪╖ ╪╣┘┘ë ╪ث┘è┘é┘ê┘╪ر ╪د┘┘à┘ê┘é╪╣ ┘┘è ╪د┘┘ç┘è╪»╪▒
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
            trailing: !isActive ? const Text('┘é╪▒┘è╪ذ┘ï╪د', style: TextStyle(color: Colors.grey, fontSize: 12)) : null,
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
            // ╪د┘┘┘â╪▒╪ر: ┘ç┘è╪»╪▒ ╪ث╪▓╪▒┘é ┘┘è┘ç (┘è┘à┘è┘ ┘┘è╪│╪د╪▒): ╪ش╪▒╪│ ╪ح╪┤╪╣╪د╪▒╪د╪ز╪î ╪د╪│┘à ╪د┘╪ز╪╖╪ذ┘è┘é
            // ┘ê┘à╪ص╪د┘╪╕╪ر ╪د┘┘à╪│╪ز╪«╪»┘à ╪د┘╪ص╪د┘┘è╪ر╪î ┘ê╪▒╪│╪د┘╪ر ╪ز╪▒╪ص┘è╪ذ ╪ذ╪د┘╪د╪│┘à
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
                          const Text('┘è╪د ╪ذ┘╪»┘è', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  Text('${_locationLabel == '┘à┘ê┘é╪╣┘è ╪د┘╪ص╪د┘┘è' ? '≡اô $_locationLabel' : cityName} ظت ${_userName.isEmpty ? '╪ث┘ç┘┘ï╪د ╪ذ┘è┘â' : '╪ث┘ç┘┘ï╪د ╪ذ┘è┘â ┘è╪د $_userName'} ≡اّï', style: const TextStyle(color: Color(0xFFCFE0F5), fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: localIdentity.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text('╪د┘â╪ز╪┤┘ ${localIdentity.labelFor('ar')}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            // ╪┤╪▒┘è╪╖ ╪د┘╪ذ╪ص╪س (╪ذ┘è┘ê╪»┘è┘â ┘╪┤╪د╪┤╪ر ┘╪خ╪ر "╪د┘┘â┘" ╪ذ┘╪╡ ╪ذ╪ص╪س ┘à╪ذ╪»╪خ┘è ┘╪د╪ص┘é┘ï╪د)
            Padding(padding: const EdgeInsets.all(16), child: InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>SearchScreen(cityId:_selectedCityId))), child: Container(height:42,padding:const EdgeInsets.symmetric(horizontal:12),decoration:BoxDecoration(color:Colors.grey[100],borderRadius:BorderRadius.circular(10)),child:const Row(children:[Icon(Icons.search,color:Colors.grey,size:20),SizedBox(width:8),Text('╪د╪ذ╪ص╪س ╪╣┘ ╪ث┘è ┘à┘â╪د┘ ╪ث┘ê ╪«╪»┘à╪ر ╪ذ╪│┘ç┘ê┘╪ر!',style:TextStyle(color:Colors.grey,fontSize:13))])))),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: GovernorateHero(
                governorateName: cityName,
                subtitle: _userName.isEmpty
                    ? '╪د┘â╪ز╪┤┘ ┘à╪د ╪ص┘ê┘┘â ┘┘è ${localIdentity.labelFor('ar')}'
                    : '╪ث┘ç┘┘ï╪د ╪ذ┘â ┘è╪د $_userName ≡اّï ظت ╪د┘â╪ز╪┤┘ ${localIdentity.labelFor('ar')}',
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
                            ? '╪د┘╪╖┘é╪│ ╪د┘╪ت┘ ظت ╪ش╪د╪▒┘ ╪د┘╪ز╪ص╪»┘è╪س...'
                            : _weather == null
                                ? '╪د┘╪╖┘é╪│ ╪د┘╪ت┘ ظت ╪║┘è╪▒ ┘à╪ز╪د╪ص ╪ص╪د┘┘è┘ï╪د'
                                : '╪د┘╪╖┘é╪│ ╪د┘╪ت┘ ┘┘è $cityName ظت ${_weather!.temperatureC.round()}┬░ ظت ${_weather!.conditionAr}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ------------------------------------------------------------
            // ╪د╪«╪ز╪╡╪د╪▒╪د╪ز ╪د┘╪┤╪د╪┤╪ر ╪د┘╪ث┘ê┘┘ë: ╪ث╪▒╪ذ╪╣ ┘ê╪╕╪د╪خ┘ ┘è┘ê┘à┘è╪ر ┘ê╪د╪╢╪ص╪ر.
            // ╪د┘╪«╪▒┘è╪╖╪ر ╪د┘╪ش╪║╪▒╪د┘┘è╪ر ╪ث╪▓┘è┘╪ز ┘à┘ ┘ç╪░┘ç ╪د┘┘à┘╪╖┘é╪ر╪ؤ ╪د┘╪▓╪▒ ╪د┘╪▒╪د╪ذ╪╣ ┘è┘╪ز╪ص ╪«╪▒┘è╪╖╪ر ╪د┘╪ز╪╖╪ذ┘è┘é
            // ┘┘╪│┘ç╪د ┘┘à╪│╪د╪╣╪»╪ر ╪د┘┘à╪│╪ز╪«╪»┘à ╪╣┘┘ë ┘┘ç┘à ╪د┘╪ث┘é╪│╪د┘à╪î ╪ذ┘è┘┘à╪د ╪د┘╪«╪▒┘è╪╖╪ر ╪د┘╪ش╪║╪▒╪د┘┘è╪ر ╪ز╪╕┘ ╪│┘è╪د┘é┘è╪ر.
            // ------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _QuickAction(icon: Icons.location_on_outlined, label: '╪ث┘à╪د┘â┘ ┘é╪▒┘è╪ذ╪ر', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NearbyPlacesScreen(cityId: _selectedCityId))))),
                      const SizedBox(width: 8),
                      Expanded(child: _QuickAction(icon: Icons.event_available_outlined, label: '┘╪╣╪د┘┘è╪د╪ز ╪د┘┘è┘ê┘à', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventsTodayScreen(cityId: _selectedCityId))))),
                      const SizedBox(width: 8),
                      Expanded(child: _QuickAction(icon: Icons.route_outlined, label: '╪▒╪ص┘╪ر ╪د┘┘è┘ê┘à', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DayTripScreen(cityId: _selectedCityId))))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _QuickAction(icon: Icons.qr_code_scanner, label: '┘à╪│╪ص QR', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemberQrScannerScreen())))),
                      const SizedBox(width: 8),
                      Expanded(child: _QuickAction(icon: Icons.explore_rounded, label: '╪«╪▒┘è╪╖╪ر ┘è╪د ╪ذ┘╪»┘è', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AppMapScreen(cityId: _selectedCityId))))),
                      const SizedBox(width: 8),
                      const Expanded(child: SizedBox(height: 76)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('╪د┘╪ز╪╡┘┘è┘╪د╪ز ╪د┘╪▒╪خ┘è╪│┘è╪ر', textAlign: TextAlign.right, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._categories.take(6).map((cat) => _CategoryPill(item: cat, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: cat.categoryValue, categoryLabel: cat.label, cityId: _selectedCityId))))),
                      _CategoryPill(item: _CategoryItem('all', '╪د┘┘à╪▓┘è╪»', Icons.apps, const Color(0xFFF1F4F8), AppColors.primary), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryScreen(category: '', categoryLabel: '┘â┘ ╪د┘╪ز╪╡┘┘è┘╪د╪ز', cityId: _selectedCityId)))),
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
                  child: Text('╪د┘╪ش╪»┘è╪» ┘┘è $cityName', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
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
                            Positioned(left: 8, top: 8, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: const Text('╪ش╪»┘è╪»', style: TextStyle(fontWeight: FontWeight.bold)))),
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
// ╪د┘┘┘â╪▒╪ر: ┘â┘╪د╪│ ╪ذ╪│┘è╪╖ ┘╪ز╪ش┘à┘è╪╣ ╪ذ┘è╪د┘╪د╪ز ┘â┘ ┘╪خ╪ر ┘à╪╣ ╪ذ╪╣╪╢ (╪د╪│┘à ╪د┘┘é┘è┘à╪ر ╪د┘┘à╪«╪▓┘ّ┘╪ر
// ┘┘è ┘é╪د╪╣╪»╪ر ╪د┘╪ذ┘è╪د┘╪د╪ز╪î ╪د┘╪د╪│┘à ╪د┘┘à╪╣╪▒┘ê╪╢╪î ╪د┘╪ث┘è┘é┘ê┘╪ر╪î ╪د┘╪ث┘┘ê╪د┘)
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
  final String categoryValue; // ╪د┘┘é┘è┘à╪ر ╪د┘┘à╪«╪▓┘ّ┘╪ر ┘┘è ╪ص┘é┘ "category" ╪ذ╪د┘┘à┘â╪د┘
  final String label; // ╪د┘╪د╪│┘à ╪د┘┘à╪╣╪▒┘ê╪╢ ┘┘┘à╪│╪ز╪«╪»┘à
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const _CategoryItem(this.categoryValue, this.label, this.icon, this.bgColor, this.iconColor);
}



