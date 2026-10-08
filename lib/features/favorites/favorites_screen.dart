import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/categories/controllers/categories_controller.dart';
import '../../../features/favorites/controllers/favorites_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/category.dart';
import '../../../models/favorite.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';
import '../../../theme/design_tokens.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _placesRepo = PlacesRepository();

  /// cache: placeId → Future Place?
  final Map<String, Future<Place?>> _placesCache = {};

  /// cache للـ places بعد ما تتحمّل → نستخدمها للتجميع
  final Map<String, Place?> _loadedPlaces = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final favorites = context.watch<FavoritesController>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.home,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.home);
            }
          },
        ),
        title: Text(
          favorites.isEmpty
              ? l10n.favorites
              : '${l10n.favorites} (${favorites.count})',
        ),
      ),
      body: _buildBody(context, auth, favorites),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AuthController auth,
    FavoritesController favorites,
  ) {
    // ─── Guest → Empty state ───
    if (auth.uid == null) {
      return const _EmptyView(
        icon: Icons.lock_outline,
        title: 'تسجيل الدخول مطلوب',
        subtitle: 'سجّل دخولك لعرض مفضلاتك',
        showDiscover: false,
      );
    }

    // ─── مسجّل و مفيش مفضلة ───
    if (favorites.isEmpty) {
      return const _EmptyView();
    }

    // ─── نبني الـ futures ───
    for (final fav in favorites.favorites) {
      _placesCache.putIfAbsent(
        fav.placeId,
        () => _placesRepo.getById(fav.placeId),
      );
    }

    // ─── نستخدم FutureBuilder واحد لكل الأماكن ───
    return FutureBuilder<List<Place?>>(
      future: Future.wait(_placesCache.values),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final places = snap.data ?? const <Place?>[];

        // نحدّث الـ loadedPlaces
        for (final p in places) {
          if (p != null) _loadedPlaces[p.id] = p;
        }

        // نبني قائمة (Place + Favorite) مع بعض
        final items = <_FavItem>[];
        for (final fav in favorites.favorites) {
          final place = _loadedPlaces[fav.placeId];
          if (place != null) {
            items.add(_FavItem(favorite: fav, place: place));
          }
        }

        if (items.isEmpty) {
          return const _EmptyView();
        }

        return _GroupedFavoritesList(items: items);
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MODEL: عنصر مفضلة
// ═══════════════════════════════════════════════════════════════

class _FavItem {
  const _FavItem({required this.favorite, required this.place});

  final Favorite favorite;
  final Place place;
}

// ═══════════════════════════════════════════════════════════════
// GROUPED LIST
// ═══════════════════════════════════════════════════════════════

class _GroupedFavoritesList extends StatelessWidget {
  const _GroupedFavoritesList({required this.items});

  final List<_FavItem> items;

  @override
  Widget build(BuildContext context) {
    // ─── التجميع حسب categoryId ───
    final grouped = <String, List<_FavItem>>{};
    for (final item in items) {
      final catId = item.place.categoryId.isEmpty
          ? '_unknown'
          : item.place.categoryId;
      grouped.putIfAbsent(catId, () => []).add(item);
    }

    // ─── الترتيب حسب order التصنيف ───
    final categories = context.watch<CategoriesController>().categories;
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ca = _findCategory(categories, a);
        final cb = _findCategory(categories, b);
        final oa = ca?.order ?? 999;
        final ob = cb?.order ?? 999;
        return oa.compareTo(ob);
      });

    // ─── بناء الـ list ───
    final children = <Widget>[];
    for (final catId in sortedKeys) {
      final catItems = grouped[catId]!;
      final cat = _findCategory(categories, catId);

      children.add(
        _CategoryHeader(
          category: cat,
          count: catItems.length,
        ),
      );

      for (final item in catItems) {
        children.add(
          _FavoriteCard(item: item),
        );
      }

      children.add(
        const SizedBox(height: YaBaladiDesignTokens.space2),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: children,
    );
  }

  Category? _findCategory(List<Category> categories, String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY HEADER
// ═══════════════════════════════════════════════════════════════

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({required this.category, required this.count});

  final Category? category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';

    final label = category == null
        ? 'أخرى'
        : (isArabic ? category!.nameAr : category!.nameEn);

    final icon = category?.icon ?? Icons.place_outlined;

    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 8,
        right: 4,
        left: 4,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FAVORITE CARD
// ═══════════════════════════════════════════════════════════════

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.item});

  final _FavItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';
    final place = item.place;
    final name = isArabic ? place.nameAr : place.nameEn;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(RoutePaths.placePath(place.id)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // ─── Thumbnail ───
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.place_outlined,
                  size: 26,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),

              // ─── Info ───
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 13,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          place.averageRating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '(${place.reviewCount})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ─── Remove ───
              IconButton(
                tooltip: 'إزالة من المفضلة',
                icon: const Icon(Icons.favorite, color: Colors.red),
                iconSize: 20,
                onPressed: () async {
                  final auth = context.read<AuthController>();
                  if (auth.uid == null) return;
                  await context
                      .read<FavoritesController>()
                      .toggle(auth.uid!, place.id);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY VIEW
// ═══════════════════════════════════════════════════════════════

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    this.icon = Icons.favorite_border,
    this.title,
    this.subtitle,
    this.showDiscover = true,
  });

  final IconData icon;
  final String? title;
  final String? subtitle;
  final bool showDiscover;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: YaBaladiDesignTokens.space4),
            Text(
              title ?? l10n.favoritesEmptyTitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space2),
            Text(
              subtitle ?? l10n.favoritesEmptySubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (showDiscover) ...[
              const SizedBox(height: YaBaladiDesignTokens.space5),
              FilledButton.icon(
                icon: const Icon(Icons.explore_outlined),
                label: Text(l10n.discoverPlaces),
                onPressed: () => context.go(RoutePaths.home),
              ),
            ],
          ],
        ),
      ),
    );
  }
}