// screens/visitor_home_screen.dart
//
// مسار الزائر مستقل عن مسار المقيم.
// الهدف هنا ليس تغيير هوية "يا بلدي"، بل تغيير الأولوية: الزائر يريد أن يعرف
// ماذا يفعل الآن، وما الذي يمكن أن يضعه في "رحلة اليوم"، وأين يذهب بعد ذلك.
// تعتمد الشاشة على نفس Place/Category/Firestore foundation ولا تنشئ بيانات تجريبية.
// عند إضافة محرك تخطيط الرحلات لاحقًا، سيكون زر "رحلة اليوم" هو نقطة الدخول له.

import 'package:flutter/material.dart';
import '../models/egypt_governorates.dart';
import '../models/local_identity.dart';
import '../models/place_categories.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../models/governorate_visual_profile.dart';
import '../services/governorate_visual_service.dart';
import '../models/governorate_control.dart';
import '../services/governorate_control_service.dart';
import '../widgets/governorate_hero.dart';
import 'category_screen.dart';
import 'day_trip_screen.dart';
import 'search_screen.dart';

class VisitorHomeScreen extends StatefulWidget {
  const VisitorHomeScreen({super.key});

  @override
  State<VisitorHomeScreen> createState() => _VisitorHomeScreenState();
}

class _VisitorHomeScreenState extends State<VisitorHomeScreen> {
  String _selectedGovernorateId = EgyptGovernorates.activeGovernorateId;
  String _userName = '';
  GovernorateVisualProfile? _visual;
  final _governorateControlService = GovernorateControlService();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentAppUser();
    final visual = await GovernorateVisualService().getPublished(_selectedGovernorateId);
    if (!mounted) return;
    setState(() {
      _userName = user?.fullName.trim() ?? '';
      _visual = visual;
    });
  }

  void _showGovernoratePicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => StreamBuilder<List<GovernorateControl>>(
        stream: _governorateControlService.watchPublic(),
        builder: (context, snapshot) {
          final publicGovernorates = snapshot.data ?? const <GovernorateControl>[];
          final entries = publicGovernorates.isEmpty
              ? EgyptGovernorates.all.map((gov) => (gov.id, gov.nameAr)).toList()
              : publicGovernorates.map((gov) => (gov.id, gov.nameAr)).toList();
          return ListView(
            shrinkWrap: true,
            children: entries.map((entry) {
              final id = entry.$1;
              final name = entry.$2;
              final selected = id == _selectedGovernorateId;
              return ListTile(
                title: Text(name),
                trailing: selected ? const Icon(Icons.check) : null,
                onTap: () {
                  setState(() {
                    _selectedGovernorateId = id;
                    _visual = null;
                  });
                  Navigator.pop(context);
                  GovernorateVisualService().getPublished(id).then((visual) {
                    if (mounted && _selectedGovernorateId == id) {
                      setState(() => _visual = visual);
                    }
                  });
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  bool _featureAvailable(FeatureState? state) {
    return state != FeatureState.disabled &&
        state != FeatureState.hidden &&
        state != FeatureState.maintenance;
  }

  @override
  Widget build(BuildContext context) {
    final governorate = EgyptGovernorates.getById(_selectedGovernorateId);
    final localIdentity = LocalIdentity.forGovernorate(_selectedGovernorateId);

    return StreamBuilder<List<GovernorateControl>>(
      stream: _governorateControlService.watchPublic(),
      builder: (context, governorateSnapshot) {
        return StreamBuilder<Map<String, FeatureState>>(
          stream: _governorateControlService.watchEffectiveFeatureStates(_selectedGovernorateId),
          builder: (context, featureSnapshot) {
            final features = featureSnapshot.data ?? const <String, FeatureState>{};
            final placesAvailable = _featureAvailable(features['places']);
            final dayTripAvailable = _featureAvailable(features['day_trip']);

            return Scaffold(
              body: SafeArea(
                child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                          const Text(
                            'يا بلدي',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showGovernoratePicker,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName.isEmpty
                        ? 'أهلًا بك في ${governorate?.nameAr ?? ''} 👋'
                        : 'أهلًا بك يا $_userName 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'أنت الآن في وضع الزائر — اكتشف المكان واستمتع بيومك.',
                     style: TextStyle(color: Color(0xFFCFE0F5), fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: localIdentity.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'اكتشف ${localIdentity.labelFor('ar')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: GovernorateHero(
                governorateName: governorate?.nameAr ?? '',
                subtitle: 'ابدأ اكتشاف ${localIdentity.labelFor('ar')} من هنا',
                visual: _visual,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchScreen(cityId: _selectedGovernorateId),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.grey, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'ابحث عن مكان أو خدمة...',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (dayTripAvailable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DayTripScreen(cityId: _selectedGovernorateId),
                  ),
                ),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.primary.withValues(alpha: .82)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.route, color: Colors.white, size: 28),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رحلة اليوم',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'اختَر ما يناسب وقتك واهتماماتك وابدأ يومك.',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'ماذا تريد أن تكتشف؟',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: placesAvailable
                  ? GridView.count(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.45,
                children: PlaceCategories.all.take(12).map((category) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryScreen(
                          category: category.id,
                          categoryLabel: category.labelAr,
                          cityId: _selectedGovernorateId,
                        ),
                      ),
                    ),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(category.icon, color: AppColors.primary, size: 28),
                          const SizedBox(height: 6),
                          Text(category.labelAr, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              )
                  : const Center(child: Text('الأماكن غير متاحة حاليًا في هذه المحافظة.')),
            ),
          ],
        ),
      ),
    );
          },
        );
      },
    );
  }
}

