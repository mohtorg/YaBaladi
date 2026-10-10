import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/route_paths.dart';
import '../features/auth/controllers/auth_controller.dart';
import '../features/categories/controllers/categories_controller.dart';
import '../features/places/controllers/places_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../widgets/welcome_header.dart';

/// الصفحة الرئيسية:
/// - Welcome Header
/// - Categories Grid (3 أعمدة)
/// - الأقرب إليك
/// - الأعلى تقييمًا
/// - Guest Banner
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationData? _userLocation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PlacesController>().load();
      _loadLocation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // لو الـ Controller في وضع مختلف (category / search)
    // → نعيد التحميل بـ load() عشان Home يعرض كل الأماكن
    final controller = context.read<PlacesController>();
    if (controller.mode != PlacesMode.all) {
      controller.load();
    }
  }

  Future<void> _loadLocation() async {
    final loc = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _userLocation = loc);
  }

  Future<void> _refresh() async {
    // Capture controllers BEFORE any await (avoid BuildContext across gaps)
    final categories = context.read<CategoriesController>();
    final places = context.read<PlacesController>();

    await categories.reload();
    await places.refresh();
    await LocationService.clearCache();
    await _loadLocation();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoriesController>();
    final places = context.watch<PlacesController>();
    final auth = context.watch<AuthController>();

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
                  onNotificationsTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('الإشعارات — قريبًا')),
                    );
                  },
                  onAvatarTap: () => context.go(RoutePaths.profile),
                ),
              ),
              if (categories.status == CategoriesStatus.loaded &&
                  categories.categories.isNotEmpty)
                _CategoryGrid(categories: categories.categories),
              if (categories.status == CategoriesStatus.loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              if (places.status == PlacesStatus.loaded &&
                  places.places.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _HorizontalSection(
                    title: '📍 الأقرب إليك',
                    places: _nearestPlaces(places.places, limit: 5),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HorizontalSection(
                    title: '⭐ الأعلى تقييمًا',
                    places: _topRatedPlaces(places.places, limit: 5),
                  ),
                ),
              ],
              if (auth.isGuest) const SliverToBoxAdapter(child: _GuestBanner()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

  List<Place> _nearestPlaces(List<Place> all, {int limit = 5}) {
    final loc = _userLocation;
    if (loc == null) {
      final sorted = [...all]..sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });
      return sorted.take(limit).toList();
    }

    final withDistance = all
        .where((p) => p.location != null)
        .map((p) => MapEntry(
              p,
              _haversine(
                loc.latitude,
                loc.longitude,
                p.location!.latitude,
                p.location!.longitude,
              ),
            ))
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return withDistance.take(limit).map((e) => e.key).toList();
  }

  List<Place> _topRatedPlaces(List<Place> all, {int limit = 5}) {
    final sorted = [...all]
      ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return sorted.take(limit).toList();
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    double rad(double d) => d * math.pi / 180.0;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rad(lat1)) *
            math.cos(rad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY GRID (3 أعمدة)
// ═══════════════════════════════════════════════════════════════

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, i) => _CategoryTile(category: categories[i]),
          childCount: categories.length,
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';
    final label = isArabic ? category.nameAr : category.nameEn;

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
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  size: 24,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HORIZONTAL SECTION
// ═══════════════════════════════════════════════════════════════

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({
    required this.title,
    required this.places,
  });

  final String title;
  final List<Place> places;

  @override
  Widget build(BuildContext context) {
    if (places.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 170,
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

// ═══════════════════════════════════════════════════════════════
// PLACE MINI CARD
// ═══════════════════════════════════════════════════════════════

class _PlaceMiniCard extends StatelessWidget {
  const _PlaceMiniCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';
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
                    ? Image.network(
                        place.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(theme),
                      )
                    : _placeholder(theme),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star,
                            size: 12, color: Colors.amber.shade700),
                        const SizedBox(width: 2),
                        Text(
                          place.averageRating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${place.reviewCount})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
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
          child: Icon(
            Icons.place_outlined,
            size: 32,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// GUEST BANNER
// ═══════════════════════════════════════════════════════════════

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
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard,
                  color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'سجّل دخولك للاستفادة من كل الميزات',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go(RoutePaths.login),
                  child: const Text('تسجيل الدخول'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.go(RoutePaths.register),
                  child: const Text('إنشاء حساب'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
