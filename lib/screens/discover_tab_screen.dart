// مساحة الاستكشاف العامة.
// الوظيفة الواحدة لها مكان أساسي واحد: رحلة اليوم تخص تبويب رحلتي، لذلك لا نكررها هنا.

import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../theme/app_colors.dart';
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
    final lang = LocaleController.of(context).locale.languageCode;
    final actions = [
      _DiscoverAction(Icons.search, AppStrings.of('search_action', lang), AppStrings.of('search_action_desc', lang), () => _push(context, SearchScreen(cityId: cityId))),
      _DiscoverAction(Icons.location_on_outlined, AppStrings.of('nearby_places', lang), AppStrings.of('nearby_places_desc', lang), () => _push(context, NearbyPlacesScreen(cityId: cityId))),
      _DiscoverAction(Icons.event_available_outlined, AppStrings.of('events_today', lang), AppStrings.of('events_today_desc', lang), () => _push(context, EventsTodayScreen(cityId: cityId))),
      _DiscoverAction(Icons.photo_library_outlined, AppStrings.of('library', lang), AppStrings.of('library_desc', lang), () => _push(context, LibraryScreen(governorateId: cityId))),
      _DiscoverAction(Icons.explore_rounded, AppStrings.of('map', lang), AppStrings.of('map_desc', lang), () => _push(context, AppMapScreen(cityId: cityId))),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of('discover', lang)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(AppStrings.of('discover_prompt', lang), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(AppStrings.of('discover_subtitle', lang), style: const TextStyle(color: Colors.grey, height: 1.5)),
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
