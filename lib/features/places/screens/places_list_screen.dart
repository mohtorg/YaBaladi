import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../features/categories/controllers/categories_controller.dart';
import '../../../features/places/controllers/places_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/place.dart';
import '../../../theme/design_tokens.dart';

/// تعرض قائمة أماكن تصنيف معيّن.
class PlacesListScreen extends StatefulWidget {
  const PlacesListScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  State<PlacesListScreen> createState() => _PlacesListScreenState();
}

class _PlacesListScreenState extends State<PlacesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlacesController>().watchCategory(widget.categoryId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // اسم التصنيف من CategoriesController
    final categories = context.watch<CategoriesController>().categories;
    final cat = categories.where((c) => c.id == widget.categoryId).firstOrNull;
    final title = cat == null
        ? l10n.appName
        : (isArabic ? cat.nameAr : cat.nameEn);

    final places = context.watch<PlacesController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RoutePaths.home);
            }
          },
        ),
      ),
      body: _buildBody(context, places, isArabic),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PlacesController controller,
    bool isArabic,
  ) {
    switch (controller.status) {
      case PlacesStatus.idle:
      case PlacesStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case PlacesStatus.error:
        return _ErrorView(
          message: controller.error ?? 'حدث خطأ',
          onRetry: () => controller.watchCategory(widget.categoryId),
        );

      case PlacesStatus.loaded:
        if (controller.places.isEmpty) {
          return const _EmptyView();
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: controller.places.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: YaBaladiDesignTokens.space3),
          itemBuilder: (_, i) => _PlaceCard(
            place: controller.places[i],
            isArabic: isArabic,
          ),
        );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// PLACE CARD
// ═══════════════════════════════════════════════════════════════

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({required this.place, required this.isArabic});

  final Place place;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = isArabic ? place.nameAr : place.nameEn;

    return Card(
      clipBehavior: Clip.antiAlias,
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
                    ],
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
// EMPTY / ERROR
// ═══════════════════════════════════════════════════════════════

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.place_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('لا توجد أماكن في هذا التصنيف بعد'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

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