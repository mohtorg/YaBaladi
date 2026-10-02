import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../registries/category_registry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Get localized label for a category
  String _categoryLabel(AppLocalizations l10n, String labelEn) {
    switch (labelEn) {
      case 'Restaurants':
        return l10n.restaurants;
      case 'Cafes':
        return l10n.cafes;
      case 'Events':
        return l10n.events;
      case 'Historical Landmarks':
        return l10n.historicalPlaces;
      case 'Cinema':
        return l10n.cinema;
      case 'Clubs & Gyms':
        return l10n.gyms;
      default:
        return labelEn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final categories = CategoryRegistry.homeCategories;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                l10n.appName,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(l10n.welcome),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = categories[index];
                  final label = _categoryLabel(l10n, category.labelEn);

                  return Card(
                    child: InkWell(
                      onTap: () {},
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: categories.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.35,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}