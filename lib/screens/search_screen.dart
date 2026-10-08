import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/router/route_paths.dart';
import '../features/categories/controllers/categories_controller.dart';
import '../l10n/app_localizations.dart';
import '../models/category.dart';
import '../models/place.dart';
import '../repositories/places_repository.dart';
import '../services/search_history_service.dart';
import '../theme/design_tokens.dart';

/// شاشة البحث في الأماكن.
///
/// الميزات:
/// - Search bar مع Debounce (350ms)
/// - Recent Searches (من SharedPreferences)
/// - Quick Categories (من Firestore)
/// - Trending (Top 5 من PlacesRepository)
/// - Filter icon (يفتح places_filter_sheet لاحقًا)
/// - 4 حالات: Empty / Loading / Results / No Results
/// - Auto-save لكل بحث ناجح
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _repo = PlacesRepository();

  Timer? _debounce;
  String _query = '';
  bool _loading = false;
  List<Place> _results = const [];

  List<String> _recent = const [];
  List<Place> _trending = const [];
  bool _initLoaded = false;

  @override
  void initState() {
    super.initState();
    // فتح الكيبورد تلقائيًا
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _loadInitData();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // INITIAL LOAD
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadInitData() async {
    final recent = await SearchHistoryService.getHistory();
    final trending = await _repo.getTrending(limit: 5);
    if (!mounted) return;
    setState(() {
      _recent = recent;
      _trending = trending;
      _initLoaded = true;
    });
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH
  // ═══════════════════════════════════════════════════════════════

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(value);
    });
    setState(() => _query = value.trim());
  }

  Future<void> _runSearch(String value) async {
    final q = value.trim();

    if (q.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = const [];
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final results = await _repo.search(query: q);

      // حفظ في التاريخ (فقط لو فيه نتائج)
      if (results.isNotEmpty) {
        final updated = await SearchHistoryService.addQuery(q);
        if (mounted) {
          setState(() => _recent = updated);
        }
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = results;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _results = const [];
      });
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تعذّر البحث، حاول لاحقًا')),
        );
    }
  }

  void _clearSearch() {
    _controller.clear();
    _debounce?.cancel();
    setState(() {
      _query = '';
      _results = const [];
      _loading = false;
    });
    _focusNode.requestFocus();
  }

  void _applyRecent(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _runSearch(q);
    setState(() => _query = q);
  }

  void _openCategory(String categoryId) {
    context.go(RoutePaths.categoryPath(categoryId));
  }

  Future<void> _removeRecent(String q) async {
    final updated = await SearchHistoryService.removeQuery(q);
    if (!mounted) return;
    setState(() => _recent = updated);
  }

  Future<void> _clearAllRecent() async {
    await SearchHistoryService.clearAll();
    if (!mounted) return;
    setState(() => _recent = const []);
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
        title: Text(l10n.search),
      ),
      body: Column(
        children: [
          // ─── Search Field ───
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
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
            ),
          ),

          // ─── Content ───
          Expanded(child: _buildContent(l10n)),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    // ─── Idle: مفيش بحث ───
    if (_query.isEmpty) {
      return _EmptyStateView(
        recent: _recent,
        trending: _trending,
        loading: !_initLoaded,
        onRecentTap: _applyRecent,
        onRecentRemove: _removeRecent,
        onClearAll: _clearAllRecent,
        onCategoryTap: _openCategory,
      );
    }

    // ─── Loading ───
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // ─── No Results ───
    if (_results.isEmpty) {
      return _NoResultsView(
        query: _query,
        onCategoryTap: _openCategory,
      );
    }

    // ─── Results ───
    return _ResultsList(
      results: _results,
      count: _results.length,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE — Recent + Categories + Trending
// ═══════════════════════════════════════════════════════════════

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
    required this.recent,
    required this.trending,
    required this.loading,
    required this.onRecentTap,
    required this.onRecentRemove,
    required this.onClearAll,
    required this.onCategoryTap,
  });

  final List<String> recent;
  final List<Place> trending;
  final bool loading;
  final ValueChanged<String> onRecentTap;
  final ValueChanged<String> onRecentRemove;
  final VoidCallback onClearAll;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = context.watch<CategoriesController>().categories;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        // ═══════════ RECENT SEARCHES ═══════════
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

        // ═══════════ QUICK CATEGORIES ═══════════
        if (categories.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.category_outlined,
            title: l10n.searchQuickCategories,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in categories.take(8))
                  _CategoryChip(
                    category: cat,
                    onTap: () => onCategoryTap(cat.id),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ═══════════ TRENDING ═══════════
        if (trending.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.local_fire_department_outlined,
            title: l10n.searchTrending,
          ),
          for (final place in trending)
            _TrendingTile(place: place),
          const SizedBox(height: 16),
        ],

        // ═══════════ IDLE FALLBACK ═══════════
        if (recent.isEmpty && categories.isEmpty && trending.isEmpty)
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION HEADER
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
          ?action,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CATEGORY CHIP
// ═══════════════════════════════════════════════════════════════

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = l10n.localeName == 'ar';
    final label = isArabic ? category.nameAr : category.nameEn;

    return ActionChip(
      avatar: Icon(category.icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TRENDING TILE
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
// NO RESULTS
// ═══════════════════════════════════════════════════════════════

class _NoResultsView extends StatelessWidget {
  const _NoResultsView({
    required this.query,
    required this.onCategoryTap,
  });

  final String query;
  final ValueChanged<String> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final categories = context.watch<CategoriesController>().categories;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(
          Icons.search_off,
          size: 72,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          '${l10n.searchNoResults} "$query"',
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
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.searchTryCategory,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final cat in categories.take(6))
                _CategoryChip(
                  category: cat,
                  onTap: () => onCategoryTap(cat.id),
                ),
            ],
          ),
        ],
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
// RESULTS LIST
// ═══════════════════════════════════════════════════════════════

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results, required this.count});

  final List<Place> results;
  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            l10n.searchResultsCount(count),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: results.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: YaBaladiDesignTokens.space3),
            itemBuilder: (_, i) => _ResultCard(place: results[i]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// RESULT CARD
// ═══════════════════════════════════════════════════════════════

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
                    if (place.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        place.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 6),
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

              const Icon(Icons.chevron_left, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}