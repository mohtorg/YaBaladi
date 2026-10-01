import 'package:flutter/material.dart';

import '../registries/category_registry.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _arabicLabels = <String, String>{
    'Restaurants': 'المطاعم',
    'Cafes': 'المقاهي',
    'Events': 'الفعاليات',
    'Historical Landmarks': 'الأماكن التاريخية',
    'Cinema': 'السينما',
    'Clubs & Gyms': 'الأندية والصالات الرياضية',
  };

  @override
  Widget build(BuildContext context) {
    final categories = CategoryRegistry.homeCategories;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'يا بلدي',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('اكتشف الأماكن والخدمات من حولك بسهولة.'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = categories[index];
                  final label =
                      _arabicLabels[category.labelEn] ?? category.labelEn;

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
