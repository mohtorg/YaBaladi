// lib/features/search/screens/explore_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/location/browsing_location_controller.dart';
import '../../../core/location/governorate_picker_sheet.dart';
import '../../../core/router/route_paths.dart';
import '../../../features/categories/controllers/categories_controller.dart';
import '../../../features/places/controllers/places_controller.dart';
import '../../../features/places/widgets/places_filter_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import '../../../services/location_service.dart';
import '../../../services/map_service.dart';
import '../../../widgets/location_actions.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.categoryId});
  final String? categoryId;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent * 0.8) {
        context.read<PlacesController>().loadMore();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadCurrentGovernorateData();
    });
  }

  void _loadCurrentGovernorateData() {
    final browsing = context.read<BrowsingLocationController>().browsing;
    context.read<PlacesController>().loadPaginated(
          governorateNameAr: browsing.nameAr,
          categoryId: widget.categoryId,
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNearest() async {
    if (_isFetchingLocation) return;
    setState(() => _isFetchingLocation = true);

    try {
      final loc = await LocationService.getCurrentLocation();
      if (!mounted) return;

      if (loc == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تعذر تحديد موقعك. تأكد من تفعيل GPS.'),
              backgroundColor: Colors.orange),
        );
        return;
      }

      await context.read<PlacesController>().loadNearest(
            userLat: loc.latitude,
            userLng: loc.longitude,
          );
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  void _openFilterSheet(PlacesController controller) {
    showPlacesFilterSheet(context: context, controller: controller);
  }

  void _openGovernoratePicker(BrowsingLocationController ctrl) {
    GovernoratePickerSheet.show(
      context,
      controller: ctrl,
    ).then((_) {
      if (mounted) {
        _loadCurrentGovernorateData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<PlacesController>();
    final browsingCtrl = context.watch<BrowsingLocationController>();
    final browsing = browsingCtrl.browsing;
    final isNearestMode = controller.mode == PlacesMode.nearest;
    final theme = Theme.of(context);

    String title = l10n.search;
    if (widget.categoryId != null) {
      final cats = context.watch<CategoriesController>().categories;
      final cat = cats.where((c) => c.id == widget.categoryId).firstOrNull;
      if (cat != null) title = cat.nameAr;
    }

    final displayPlaces = controller.filteredPlaces;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RoutePaths.home),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            // ✅ الزر الجديد الواضح (Pill Button)
            if (!isNearestMode)
              InkWell(
                onTap: () => _openGovernoratePicker(browsingCtrl),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 4),
                      Text(
                        browsing.nameAr,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.arrow_drop_down,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.near_me,
                        size: 14, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      'الأقرب إليك',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'الفلاتر',
            icon: Badge(
              label: Text('${controller.activeFilterCount}'),
              isLabelVisible: controller.activeFilterCount > 0,
              child: const Icon(Icons.tune),
            ),
            onPressed: () => _openFilterSheet(controller),
          ),
          IconButton(
            tooltip: isNearestMode ? 'عرض الكل' : 'الأقرب إليك',
            icon: _isFetchingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(
                    isNearestMode ? Icons.list : Icons.near_me,
                    color: isNearestMode ? theme.colorScheme.primary : null,
                  ),
            onPressed: () {
              if (isNearestMode) {
                _loadCurrentGovernorateData();
              } else {
                _loadNearest();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => controller.setQuery(val),
              decoration: InputDecoration(
                hintText: 'ابحث عن مكان...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _buildBody(context, controller, displayPlaces),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, PlacesController controller, List<Place> places) {
    if (controller.status == PlacesStatus.loading && places.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.status == PlacesStatus.error) {
      return Center(child: Text('حدث خطأ: ${controller.error}'));
    }

    if (places.isEmpty) {
      final isNearest = controller.mode == PlacesMode.nearest;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isNearest ? Icons.location_off : Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                isNearest
                    ? 'لا يوجد مقدمي خدمة قرب منك حالياً.'
                    : 'لا توجد أماكن تطابق بحثك.',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              if (controller.hasActiveFilters) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: controller.clearFilters,
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('مسح الفلاتر'),
                ),
              ] else if (isNearest) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _loadCurrentGovernorateData,
                  icon: const Icon(Icons.list),
                  label: const Text('عرض الأماكن في المحافظة'),
                ),
              ]
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      itemCount: places.length + (controller.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == places.length) {
          return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()));
        }

        final place = places[index];
        double? distanceKm;
        if (controller.userLat != null &&
            controller.userLng != null &&
            place.location != null) {
          final meters = MapService.getDistanceInMeters(
            controller.userLat!,
            controller.userLng!,
            place.location!.latitude,
            place.location!.longitude,
          );
          distanceKm = meters / 1000;
        }

        return _PlaceCard(place: place, distanceKm: distanceKm);
      },
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  final double? distanceKm;

  const _PlaceCard({required this.place, this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RoutePaths.placePath(place.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.place,
                    size: 32, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.nameAr,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text(place.averageRating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall),
                        const SizedBox(width: 8),
                        if (distanceKm != null) ...[
                          Icon(Icons.near_me,
                              size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 2),
                          Text(
                            distanceKm! < 1
                                ? '${(distanceKm! * 1000).toStringAsFixed(0)} م'
                                : '${distanceKm!.toStringAsFixed(1)} كم',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (place.location != null)
                LocationActions(
                    lat: place.location!.latitude,
                    lng: place.location!.longitude),
            ],
          ),
        ),
      ),
    );
  }
}
