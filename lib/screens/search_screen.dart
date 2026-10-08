import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/route_paths.dart';
import '../l10n/app_localizations.dart';
import '../models/place.dart';
import '../repositories/places_repository.dart';
import '../theme/design_tokens.dart';

/// شاشة البحث في الأماكن.
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

  @override
  void initState() {
    super.initState();
    // فتح الكيبورد تلقائيًا
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // SEARCH (Debounced)
  // ═══════════════════════════════════════════════════════════════

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _runSearch(value);
    });
    // تحديث الـ UI فورًا للـ query
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
      ScaffoldMessenger.of(context).showSnackBar(
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

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        // ═══════════════════════════════════════════════
        // زر الرجوع
        // ═══════════════════════════════════════════════
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
        title: const Text('البحث'),
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
    // Idle: مفيش بحث
    if (_query.isEmpty) {
      return _IdleView(
        title: l10n.searchIdleHint,
      );
    }

    // Loading
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Empty: مفيش نتائج
    if (_results.isEmpty) {
      return _IdleView(
        icon: Icons.search_off,
        title: l10n.noSearchResults,
        subtitle: 'جرّب كلمة بحث أخرى',
      );
    }

    // Results
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: YaBaladiDesignTokens.space3),
      itemBuilder: (_, i) => _ResultCard(place: _results[i]),
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

// ═══════════════════════════════════════════════════════════════
// IDLE / EMPTY VIEW
// ═══════════════════════════════════════════════════════════════

class _IdleView extends StatelessWidget {
  const _IdleView({
    this.icon = Icons.search,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
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
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: YaBaladiDesignTokens.space2),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}