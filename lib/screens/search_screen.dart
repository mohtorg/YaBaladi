import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/route_paths.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.search),
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
                Icons.search,
                size: 72,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: YaBaladiDesignTokens.space4),
              Text(
                l10n.searchComingSoon,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
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