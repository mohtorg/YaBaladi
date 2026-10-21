// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/location/browsing_location_controller.dart';
import '../core/router/route_paths.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/categories/controllers/categories_controller.dart';
import '../features/places/controllers/places_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../widgets/welcome_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlacesController>().load();
      _loadLocation();
    });
  }

  Future<void> _loadLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    if (loc != null) {
      context
          .read<BrowsingLocationController>()
          .setPhysicalLocation(loc.latitude, loc.longitude);
    }
  }

  Future<void> _refresh() async {
    await context.read<CategoriesController>().reload();
    await context.read<PlacesController>().refresh();
    await LocationService.clearCache();
    await _loadLocation();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesController>();
    final places = context.watch<PlacesController>();
    final auth = context.watch<AuthController>();
    final browsing = context.watch<BrowsingLocationController>().browsing;

    final placesInGovernorate =
        places.places.where((p) => p.governorate == browsing.nameAr).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: WelcomeHeader(
                  onSearchTap: () => context.go(RoutePaths.search),
                  onNotificationsTap: () {},
                  onAvatarTap: () => context.go(RoutePaths.profile),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: _QuickActionCard(
                              icon: Icons.add_road,
                              label: 'خطط رحلة',
                              color: Theme.of(context).colorScheme.primary,
                              onTap: () =>
                                  context.push(RoutePaths.tripPlanner))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _QuickActionCard(
                              icon: Icons.luggage,
                              label: 'رحلاتي',
                              color: Colors.orange.shade700,
                              onTap: () => context.push(RoutePaths.trips))),
                    ],
                  ),
                ),
              ),
              if (categories.status == CategoriesStatus.loaded &&
                  categories.categories.isNotEmpty)
                _CategoryGrid(categories: categories.categories),
              if (places.status == PlacesStatus.loaded &&
                  placesInGovernorate.isNotEmpty) ...[
                // ✅ قسم الأعلى تقييماً فقط
                SliverToBoxAdapter(
                  child: _HorizontalSection(
                    title: '⭐ الأعلى تقييماً في ${browsing.nameAr}',
                    places: _topRatedPlaces(placesInGovernorate, limit: 5),
                  ),
                ),
              ],
              // ✅ التصحيح: استخدام حالة المصادقة الجديدة للتحقق من الزائر
              if (auth.status == AuthStatus.unauthenticated)
                const SliverToBoxAdapter(child: _GuestBanner()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  List<Place> _topRatedPlaces(List<Place> all, {int limit = 5}) {
    final sorted = [...all]
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sorted.take(limit).toList();
  }
}

// ... (باقي الويدجت المساعدة _QuickActionCard, _CategoryGrid, _HorizontalSection, _PlaceMiniCard, _GuestBanner كما هي من الملف السابق، سأدرجها هنا للاكتمال) ...

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle),
                  child: Icon(icon, size: 26, color: color)),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  const _CategoryGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.1),
        delegate: SliverChildBuilderDelegate(
            (_, i) => _CategoryTile(category: categories[i]),
            childCount: categories.length),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final label = l10n.localeName == 'ar' ? category.nameAr : category.nameEn;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(RoutePaths.categoryPath(category.id)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle),
                  child: Icon(category.icon,
                      size: 24, color: theme.colorScheme.onPrimaryContainer)),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  final String title;
  final List<Place> places;
  const _HorizontalSection({required this.title, required this.places});

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: places.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _PlaceMiniCard(place: places[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceMiniCard extends StatelessWidget {
  final Place place;
  const _PlaceMiniCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? place.nameAr : place.nameEn;

    return SizedBox(
      width: 160,
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.go(RoutePaths.placePath(place.id)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 100,
                child: place.imageUrls.isNotEmpty
                    ? Image.network(place.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(theme))
                    : _placeholder(theme),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 12, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(place.averageRating.toStringAsFixed(1),
                            style: theme.textTheme.bodySmall),
                        const SizedBox(width: 4),
                        Text('(${place.reviewCount})',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
        color: theme.colorScheme.surfaceContainerHigh,
        child: Center(
            child: Icon(Icons.place_outlined,
                size: 32, color: theme.colorScheme.onSurfaceVariant)),
      );
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('سجّل دخولك للاستفادة من كل الميزات',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: FilledButton(
                      onPressed: () => context.go(RoutePaths.login),
                      child: const Text('تسجيل الدخول'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => context.go(RoutePaths.register),
                      child: const Text('إنشاء حساب'))),
            ],
          ),
        ],
      ),
    );
  }
}
