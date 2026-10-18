// lib/features/search/screens/explore_screen.dart
//
// [v1.5.1 — 2026-10-18] — Final Polish
//   - REMOVED: unused import 'dart:async'
//   - FIX: catId now non-null (String) — no more `catId != null` or `catId!`
//   - FIX: redundant null check inside isCategoryMode
//
// [v1.5.0 — 2026-10-18] — Final Cleanup
//   - REMOVED: _EmptyGovernorateView (unused dead code, -120 lines)
//   - FIX: catId null check instead of ! (no-op warning)
//   - FIX: trailing commas + const where needed
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/location/browsing_location_controller.dart';
import '../../../core/router/route_paths.dart';
import '../../../features/categories/controllers/categories_controller.dart';
import '../../../features/places/controllers/places_controller.dart';
import '../../../features/places/widgets/places_filter_sheet.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import '../../../repositories/places_repository.dart';
import '../../../services/search_history_service.dart';
import '../../../theme/design_tokens.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  final _repo = PlacesRepository();

  List<String> _recent = const [];
  List<Place> _trending = const [];
  bool _initLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryId == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setupController();
      _loadInitialData();
    });
  }

  void _setupController() {
    final controller = context.read<PlacesController>();
    controller.clearAll(notify: false);
    controller.load();
  }

  Future<void> _loadInitialData() async {
    final recent = await SearchHistoryService.getHistory();
    final trending = await _repo.getTrending(limit: 5);
    if (!mounted) return;
    setState(() {
      _recent = recent;
      _trending = trending;
      _initLoaded = true;
    });
  }

  Future<void> _handleRefresh() async {
    await context.read<PlacesController>().refresh();
    final trending = await _repo.getTrending(limit: 5);
    if (!mounted) return;
    setState(() => _trending = trending);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    context.read<PlacesController>().setQuery(value);
  }

  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      _saveToHistory(value.trim());
    }
  }

  void _clearQuery() {
    _searchController.clear();
    context.read<PlacesController>().clearQuery();
    _focusNode.requestFocus();
  }

  Future<void> _saveToHistory(String query) async {
    final updated = await SearchHistoryService.addQuery(query);
    if (!mounted) return;
    setState(() => _recent = List<String>.from(updated));
  }

  void _applyRecent(String q) {
    _searchController.text = q;
    _searchController.selection = TextSelection.collapsed(offset: q.length);
    context.read<PlacesController>().setQuery(q);
    _saveToHistory(q);
    setState(() {});
    _focusNode.requestFocus();
  }

  Future<void> _removeRecent(String q) async {
    final updated = await SearchHistoryService.removeQuery(q);
    if (!mounted) return;
    setState(() => _recent = List<String>.from(updated));
  }

  Future<void> _clearAllRecent() async {
    await SearchHistoryService.clearAll();
    if (!mounted) return;
    setState(() => _recent = const []);
  }

  void _openFilterSheet(PlacesController controller) {
    showPlacesFilterSheet(context: context, controller: controller);
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  bool _matchesCategory(
    Place p,
    String catId,
    String catNameAr,
    String catNameEn,
  ) {
    // الحصول على تصنيفات المكان (تدعم categories و categoryId)
    final placeCats = p.categories.map((e) => e.toLowerCase().trim()).toList();
    if (placeCats.isEmpty && p.categoryId.isNotEmpty) {
      placeCats.add(p.categoryId.toLowerCase().trim());
    }

    // إذا لم يكن للمكان أي تصنيف، لا نعرضه في تصنيف محدد
    if (placeCats.isEmpty) return false;

    // دالة مساعدة للمطابقة المرنة
    bool matches(String target) {
      if (target.isEmpty) return false;
      return placeCats.any(
        (c) => c == target || c.contains(target) || target.contains(c),
      );
    }

    // المطابقة باستخدام ID التصنيف أو اسمه العربي أو الإنجليزي
    if (matches(catId) || matches(catNameAr) || matches(catNameEn)) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = context.watch<PlacesController>();
    final browsingCtrl = context.watch<BrowsingLocationController>();
    final browsing = browsingCtrl.browsing;

    // ✅ catId الآن String (غير-null) — يمنع warnings
    final catId = widget.categoryId ?? '';
    final isCategoryMode = catId.isNotEmpty;
    final hasQuery = controller.hasQuery;

    final placesInGovernorate = _filterByGovernorate(
      controller.places,
      browsing.nameAr,
    );

    String title = l10n.search;
    String catNameAr = '';
    String catNameEn = '';

    // جلب اسم التصنيف بالعربي والإنجليزي للمطابقة
    if (isCategoryMode) {
      final cats = context.watch<CategoriesController>().categories;
      final cat = cats.where((c) => c.id == catId).firstOrNull;
      if (cat != null) {
        final isArabic = l10n.localeName == 'ar';
        title = isArabic ? cat.nameAr : cat.nameEn;
        catNameAr = cat.nameAr.toLowerCase().trim();
        catNameEn = cat.nameEn.toLowerCase().trim();
      }
    }

    // ✅ الفلترة تتم هنا قبل تمريرها للـ Body
    List<Place> finalPlaces = placesInGovernorate;
    if (isCategoryMode) {
      final idLower = catId.toLowerCase().trim();
      finalPlaces = placesInGovernorate
          .where((p) => _matchesCategory(p, idLower, catNameAr, catNameEn))
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l10n.home,
          onPressed: _onBack,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            Text(
              browsing.nameAr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          if (isCategoryMode || hasQuery)
            _FilterButton(
              count: controller.activeFilterCount,
              onPressed: () => _openFilterSheet(controller),
            ),
        ],
      ),
      body: Column(
        children: [
          _SearchBar(
            controller: _searchController,
            focusNode: _focusNode,
            hintText: l10n.searchHint,
            onChanged: _onQueryChanged,
            onSubmitted: _onSubmitted,
            onClear: _clearQuery,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _buildBody(
                context,
                controller,
                l10n,
                isCategoryMode,
                hasQuery,
                finalPlaces,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Place> _filterByGovernorate(
    List<Place> places,
    String governorateName,
  ) {
    if (governorateName.isEmpty) return places;
    final targetGov = governorateName.trim().toLowerCase();

    return places.where((p) {
      final placeGov = p.governorate.trim().toLowerCase();
      if (targetGov == 'بورسعيد') {
        return placeGov == 'بورسعيد' ||
            placeGov == 'portsaid' ||
            placeGov == 'port said' ||
            placeGov == 'port_said';
      }
      if (targetGov == 'القاهرة') {
        return placeGov == 'القاهرة' || placeGov == 'cairo';
      }
      return placeGov == targetGov;
    }).toList();
  }

  Widget _buildBody(
    BuildContext context,
    PlacesController controller,
    AppLocalizations l10n,
    bool isCategoryMode,
    bool hasQuery,
    List<Place> finalPlaces,
  ) {
    // ═══ وضع البحث الحر (بدون categoryId) ═══
    if (!isCategoryMode) {
      if (!hasQuery) {
        if (finalPlaces.isNotEmpty) {
          return _ResultsList(places: finalPlaces, query: '');
        }
        return _EmptyStateView(
          recent: _recent,
          trending: _trending,
          loading: !_initLoaded,
          onRecentTap: _applyRecent,
          onRecentRemove: _removeRecent,
          onClearAll: _clearAllRecent,
        );
      }

      if (controller.status == PlacesStatus.loading && finalPlaces.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      if (finalPlaces.isNotEmpty) {
        return _ResultsList(places: finalPlaces, query: controller.query);
      }

      return _NoResultsView(
        query: controller.query,
        hasFilters: controller.hasActiveFilters,
        onClearFilters: controller.clearFilters,
      );
    }

    // ═══ وضع التصنيف (categoryId موجود) ═══
    if (controller.status == PlacesStatus.loading && finalPlaces.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.status == PlacesStatus.error) {
      return _ErrorView(
        message: controller.error ?? 'حدث خطأ',
        onRetry: () => controller.load(),
      );
    }

    if (finalPlaces.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا توجد أماكن في هذا التصنيف حالياً.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    return _ResultsList(
      places: finalPlaces,
      query: controller.query,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Search Bar
// ═══════════════════════════════════════════════════════════════

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, _) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                      tooltip: 'مسح',
                    )
                  : null,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Filter Button
// ═══════════════════════════════════════════════════════════════

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final icon = const Icon(Icons.tune);
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: IconButton(
        icon: count > 0 ? Badge(label: Text('$count'), child: icon) : icon,
        tooltip: 'الفلاتر',
        onPressed: onPressed,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Empty State (Recent + Trending)
// ═══════════════════════════════════════════════════════════════

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
    required this.recent,
    required this.trending,
    required this.loading,
    required this.onRecentTap,
    required this.onRecentRemove,
    required this.onClearAll,
  });

  final List<String> recent;
  final List<Place> trending;
  final bool loading;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRecentRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final l10n = AppLocalizations.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (recent.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.history,
            title: l10n.searchRecent,
            action: TextButton(
              onPressed: onClearAll,
              child: Text(
                l10n.searchClearAll,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          ...recent.map(
            (q) => ListTile(
              dense: true,
              leading: const Icon(Icons.history, size: 20),
              title: Text(q, style: const TextStyle(fontSize: 14)),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onRecentRemove(q),
              ),
              onTap: () => onRecentTap(q),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (trending.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.local_fire_department_outlined,
            title: l10n.searchTrending,
          ),
          for (final place in trending) _TrendingTile(place: place),
          const SizedBox(height: 16),
        ],
        if (recent.isEmpty && trending.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.search,
                  size: 72,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.searchIdleHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Section Header
// ═══════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.action,
  });

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Trending Tile
// ═══════════════════════════════════════════════════════════════

class _TrendingTile extends StatelessWidget {
  const _TrendingTile({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? place.nameAr : place.nameEn;

    return ListTile(
      dense: true,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.place_outlined,
          size: 20,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(name, style: const TextStyle(fontSize: 14)),
      subtitle: Row(
        children: [
          Icon(Icons.star, size: 12, color: Colors.amber.shade700),
          const SizedBox(width: 2),
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
      onTap: () => context.go(RoutePaths.placePath(place.id)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Results List
// ═══════════════════════════════════════════════════════════════

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.places, required this.query});

  final List<Place> places;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              query.isNotEmpty
                  ? l10n.searchResultsCount(places.length)
                  : '${places.length} مكان',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          sliver: SliverList.separated(
            itemCount: places.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: YaBaladiDesignTokens.space3),
            itemBuilder: (_, i) => _ResultCard(place: places[i]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Result Card
// ═══════════════════════════════════════════════════════════════

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.place});

  final Place place;

  String? get _priceLabel {
    switch (place.priceLevel) {
      case 1:
        return '< 100 ج.م';
      case 2:
        return '< 500 ج.م';
      case 3:
        return '< 1000 ج.م';
      case 4:
        return '> 1000 ج.م';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final name = isArabic ? place.nameAr : place.nameEn;
    final priceLabel = _priceLabel;

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
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.place_outlined,
                  size: 36,
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
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
                        if (priceLabel != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            priceLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
// No Results
// ═══════════════════════════════════════════════════════════════

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({
    required this.query,
    required this.hasFilters,
    required this.onClearFilters,
  });

  final String query;
  final bool hasFilters;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    if (hasFilters) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.filter_alt_off,
            size: 72,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج بهذه الفلاتر',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: onClearFilters,
              child: const Text('مسح الفلاتر'),
            ),
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Icon(
          Icons.search_off,
          size: 72,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          query.isNotEmpty
              ? '${l10n.searchNoResults} "$query"'
              : 'لا توجد نتائج',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.searchTips,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        _TipLine(text: l10n.searchTip1),
        _TipLine(text: l10n.searchTip2),
        _TipLine(text: l10n.searchTip3),
      ],
    );
  }
}

class _TipLine extends StatelessWidget {
  const _TipLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.circle, size: 4),
          const SizedBox(width: 6),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Error View
// ═══════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
        ),
      ],
    );
  }
}
