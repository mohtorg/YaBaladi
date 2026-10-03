import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/design_tokens.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favorites),
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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_border,
                size: 72,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: YaBaladiDesignTokens.space4),
              Text(
                l10n.favoritesEmptyTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: YaBaladiDesignTokens.space2),
              Text(
                l10n.favoritesEmptySubtitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: YaBaladiDesignTokens.space5),
              FilledButton.icon(
                icon: const Icon(Icons.explore_outlined),
                label: Text(l10n.discoverPlaces),
                onPressed: () => context.go(RoutePaths.home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}