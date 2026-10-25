// lib/features/reviews/screens/my_reviews_screen.dart
//
// [v1.2 — 2026-10-22] — Wave 2: Null-safety lint fixes
//   - FIX: isLoggedIn بدلاً من فحص uid == null (لأن uid='guest')
//   - KEPT: context.push، _placesCache limit، etc.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/auth/controllers/auth_controller.dart';
import '../../../models/place.dart';
import '../../../models/review.dart';
import '../../../repositories/places_repository.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/my_reviews_controller.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late final MyReviewsController _ctrl;
  final _placesRepo = PlacesRepository();
  final Map<String, Place?> _placesCache = {};

  static const int _maxCacheSize = 100;

  @override
  void initState() {
    super.initState();
    _ctrl = MyReviewsController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthController>();
      // ✅ FIX: isLoggedIn بدلاً من uid != null
      if (auth.isLoggedIn) _ctrl.load(auth.uid);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<Place?> _resolvePlace(String placeId) async {
    if (_placesCache.containsKey(placeId)) return _placesCache[placeId];

    // ✅ حد أقصى للـ cache (يمنع نمو غير محدود)
    if (_placesCache.length >= _maxCacheSize) {
      _placesCache.clear();
    }

    try {
      final p = await _placesRepo.getById(placeId);
      _placesCache[placeId] = p;
      return p;
    } on Exception catch (e) {
      debugPrint('_resolvePlace($placeId) error: $e');
      _placesCache[placeId] = null;
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyReviewsController>.value(
      value: _ctrl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقييماتي'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RoutePaths.profile);
              }
            },
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<MyReviewsController>(
      builder: (context, ctrl, _) {
        if (ctrl.isLoading && ctrl.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ctrl.hasError && ctrl.isEmpty) {
          return _ErrorState(message: ctrl.error ?? 'حدث خطأ');
        }

        if (ctrl.isEmpty) {
          return const _EmptyState();
        }

        final reviews = ctrl.reviews;

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _StatsCard(
              total: ctrl.totalCount,
              average: ctrl.averageRating,
            ),
            const SizedBox(height: 8),
            _FilterChips(ctrl: ctrl),
            const SizedBox(height: 4),
            _SortBar(ctrl: ctrl),
            const SizedBox(height: 8),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'لا توجد تقييمات في هذه الفئة',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...reviews.map(
                (r) => _ReviewCard(
                  review: r,
                  placeFuture: _resolvePlace(r.placeId),
                  onDelete: () => _confirmDelete(r),
                ),
              ),
            const SizedBox(height: YaBaladiDesignTokens.space4),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(Review review) async {
    final auth = context.read<AuthController>();
    // ✅ FIX: isLoggedIn بدلاً من uid == null
    if (!auth.isLoggedIn) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('حذف التقييم'),
        content: const Text('هل أنت متأكد من حذف هذا التقييم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // ✅ استخدمنا auth.uid مباشرة (بدون !)
    final ok = await _ctrl.remove(review.id, auth.uid);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'تم حذف التقييم' : (_ctrl.error ?? 'تعذّر الحذف'),
          ),
        ),
      );
  }
}

// ═══════════════════════════════════════════════════════════════
// STATS CARD
// ═══════════════════════════════════════════════════════════════

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.total, required this.average});

  final int total;
  final double average;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: YaBaladiDesignTokens.space4,
        vertical: YaBaladiDesignTokens.space2,
      ),
      child: Container(
        padding: const EdgeInsets.all(YaBaladiDesignTokens.space4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              Icons.star_outline,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'متوسط تقييماتك من $total مراجعة',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer
                          .withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FILTER CHIPS
// ═══════════════════════════════════════════════════════════════

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.ctrl});

  final MyReviewsController ctrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: YaBaladiDesignTokens.space4,
      ),
      child: Row(
        children: [
          _Chip(
            label: 'الكل',
            selected: ctrl.filter == MyReviewsFilter.all,
            onSelect: () => ctrl.setFilter(MyReviewsFilter.all),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: '5 نجوم',
            selected: ctrl.filter == MyReviewsFilter.fiveStars,
            onSelect: () => ctrl.setFilter(MyReviewsFilter.fiveStars),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: '4 نجوم',
            selected: ctrl.filter == MyReviewsFilter.fourStars,
            onSelect: () => ctrl.setFilter(MyReviewsFilter.fourStars),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'أقل من 4',
            selected: ctrl.filter == MyReviewsFilter.lowRating,
            onSelect: () => ctrl.setFilter(MyReviewsFilter.lowRating),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onSelect,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelect(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SORT BAR
// ═══════════════════════════════════════════════════════════════

class _SortBar extends StatelessWidget {
  const _SortBar({required this.ctrl});

  final MyReviewsController ctrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: YaBaladiDesignTokens.space4,
        vertical: 4,
      ),
      child: Row(
        children: [
          Icon(
            Icons.sort,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'الترتيب:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<MyReviewsSort>(
            value: ctrl.sort,
            underline: const SizedBox.shrink(),
            style: theme.textTheme.bodySmall,
            items: const [
              DropdownMenuItem(
                value: MyReviewsSort.newest,
                child: Text('الأحدث'),
              ),
              DropdownMenuItem(
                value: MyReviewsSort.highestRating,
                child: Text('الأعلى تقييماً'),
              ),
            ],
            onChanged: (v) {
              if (v != null) ctrl.setSort(v);
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REVIEW CARD
// ═══════════════════════════════════════════════════════════════

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.placeFuture,
    required this.onDelete,
  });

  final Review review;
  final Future<Place?> placeFuture;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: YaBaladiDesignTokens.space4,
        vertical: 6,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // ✅ context.push بدل go — يبقي "تقييماتي" في الـ stack
          onTap: () => context.push(RoutePaths.placePath(review.placeId)),
          child: Padding(
            padding: const EdgeInsets.all(YaBaladiDesignTokens.space3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FutureBuilder<Place?>(
                        future: placeFuture,
                        builder: (context, snap) {
                          final name = _placeName(
                            snap.data,
                            isArabic: isArabic,
                          );
                          return Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'حذف',
                      onPressed: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      final filled = (i + 1) <= review.rating.round();
                      return Icon(
                        filled ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber.shade700,
                      );
                    }),
                    const SizedBox(width: 8),
                    if (review.createdAt != null)
                      Text(
                        _formatDate(review.createdAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                if (review.comment.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    review.comment,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _placeName(Place? place, {required bool isArabic}) {
    if (place == null) return '…';
    return isArabic ? place.nameAr : place.nameEn;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY / ERROR
// ═══════════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 72,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'لم تكتب أي تقييم بعد',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ بتقييم الأماكن التي زرتها',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
