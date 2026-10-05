import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/route_paths.dart';
import '../features/categories/controllers/categories_controller.dart';
import '../features/search/controllers/search_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/place.dart';
import '../theme/design_tokens.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PlacesSearchController(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final search = context.watch<PlacesSearchController>();
    final categories = context.watch<CategoriesController>().categories;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.search),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Search Bar ───
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _textCtrl,
              autofocus: false,
              textInputAction: TextInputAction.search,
              onChanged: search.setQuery,
              decoration: InputDecoration(
                hintText: 'ابحث عن مكان...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.hasQuery
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _textCtrl.clear();
                          search.setQuery('');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // ─── Category Chips ───
          if (categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  return _CategoryChip(
                    category: cat,
                    isArabic: isArabic,
                    selected: search.categoryId == cat.id,
                    onTap: () {
                      search.setCategory(
                        search.categoryId == cat.id ? null : cat.id,
                      );
                    },
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // ─── Results ───
          Expanded(
            child: _ResultsView(search: search, isArabic: isArabic),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY CHIP
// ═══════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isArabic,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool isArabic;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = isArabic ? category.nameAr : category.nameEn;
    return FilterChip(
      selected: selected,
      onSelected: (_) => onTap(),
      avatar: Icon(category.icon, size: 18),
      label: Text(label),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RESULTS
// ═══════════════════════════════════════════════════════════════

class _ResultsView extends StatelessWidget {
  const _ResultsView({required this.search, required this.isArabic});

  final PlacesSearchController search;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    switch (search.status) {
      case PlacesSearchStatus.idle:
        return const _IdleView();

      case PlacesSearchStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case PlacesSearchStatus.error:
        return _ErrorView(
          message: search.error ?? 'حدث خطأ',
          onRetry: search.refresh,
        );

      case PlacesSearchStatus.loaded:
        if (search.results.isEmpty) {
          return const _NoResultsView();
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: search.results.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: YaBaladiDesignTokens.space3),
          itemBuilder: (_, i) => _ResultCard(
            place: search.results[i],
            isArabic: isArabic,
          ),
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// RESULT CARD
// ═══════════════════════════════════════════════════════════════

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.place, required this.isArabic});

  final Place place;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = isArabic ? place.nameAr : place.nameEn;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(RoutePaths.placePath(place.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.place_outlined,
                  size: 30,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
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
                    if (place.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
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
              const Icon(Icons.chevron_left, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// IDLE / EMPTY / ERROR
// ═══════════════════════════════════════════════════════════════

class _IdleView extends StatelessWidget {
  const _IdleView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'ابدأ بالبحث عن مكان',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('لا توجد نتائج مطابقة'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}