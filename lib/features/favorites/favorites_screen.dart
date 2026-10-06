import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../features/favorites/controllers/favorites_controller.dart';
import '../../../l10n/app_localizations.dart';
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
  final Map<String, Future<Place?>> _placesCache = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final favorites = context.watch<FavoritesController>();

    // ─── Guest → Empty state مع دعوة لتسجيل الدخول ───
    if (auth.uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.favorites)),
        body: _EmptyView(
          icon: Icons.lock_outline,
          title: 'تسجيل الدخول مطلوب',
          subtitle: 'سجّل دخولك لعرض مفضلاتك',
          showDiscover: false,
        ),
      );
    }

    // ─── مسجّل و مفيش مفضلة → Empty state ───
    if (favorites.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.favorites)),
        body: const _EmptyView(),
      );
    }

    // ─── عرض القائمة ───
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.favorites} (${favorites.count})'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: favorites.favorites.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: YaBaladiDesignTokens.space3),
        itemBuilder: (_, i) {
          final fav = favorites.favorites[i];
          return _FavoriteCard(
            favorite: fav,
            placeFuture: _placesCache.putIfAbsent(
              fav.placeId,
              () => _placesRepo.getById(fav.placeId),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FAVORITE CARD
// ═══════════════════════════════════════════════════════════════

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.favorite,
    required this.placeFuture,
  });

  final Favorite favorite;
  final Future<Place?> placeFuture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return FutureBuilder<Place?>(
      future: placeFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            child: SizedBox(
              height: 90,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        final place = snap.data;
        if (place == null) {
          return const SizedBox.shrink();
        }

        final name = isArabic ? place.nameAr : place.nameEn;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.go(RoutePaths.placePath(place.id)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // ─── Thumbnail ───
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.place_outlined,
                      size: 32,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ─── Info ───
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star,
                                size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              place.averageRating.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 8),
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
      },
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