import '../models/place_categories.dart';

enum CategorySourceStatus { sourceProven, documentedOnly }

class CategoryRegistryItem {
  final String registryId;
  final String labelEn;
  final CategorySourceStatus sourceStatus;

  const CategoryRegistryItem({
    required this.registryId,
    required this.labelEn,
    required this.sourceStatus,
  });
}

class CategoryRegistry {
  static const homeCategories = <CategoryRegistryItem>[
    CategoryRegistryItem(registryId: 'CAT-001', labelEn: 'Restaurants', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-002', labelEn: 'Cafes', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-003', labelEn: 'Events', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-004', labelEn: 'Historical Landmarks', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-005', labelEn: 'Cinema', sourceStatus: CategorySourceStatus.documentedOnly),
    CategoryRegistryItem(registryId: 'CAT-006', labelEn: 'Clubs & Gyms', sourceStatus: CategorySourceStatus.sourceProven),
  ];

  static const moreCategories = <CategoryRegistryItem>[
    CategoryRegistryItem(registryId: 'CAT-M01', labelEn: 'Beaches', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M02', labelEn: 'Tourist Villages', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M03', labelEn: 'Hotels & Resorts', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M04', labelEn: 'Beauty Centers', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M05', labelEn: 'Women Salons', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M06', labelEn: 'Men Salons', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M07', labelEn: 'Family & Entertainment', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M08', labelEn: 'Tourist Areas', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M09', labelEn: 'Museums', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M10', labelEn: 'Parks', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M11', labelEn: 'Culture & Arts', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M12', labelEn: 'Shopping', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M13', labelEn: 'Games & Entertainment', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M14', labelEn: 'Water Activities', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M15', labelEn: 'Trips & Outings', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M16', labelEn: 'Kids Activities & Places', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M17', labelEn: 'Health & Care', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M18', labelEn: 'Education & Training', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M19', labelEn: 'Tourism Services', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M20', labelEn: 'Services', sourceStatus: CategorySourceStatus.sourceProven),
    CategoryRegistryItem(registryId: 'CAT-M21', labelEn: 'Other', sourceStatus: CategorySourceStatus.sourceProven),
  ];

  static PlaceCategory? sourceFor(CategoryRegistryItem item) {
    for (final category in PlaceCategories.all) {
      if (category.labelEn == item.labelEn) return category;
    }
    return null;
  }

  static List<CategoryRegistryItem> get sourceProvenHomeCategories =>
      homeCategories.where((x) => x.sourceStatus == CategorySourceStatus.sourceProven).toList(growable: false);

  static List<CategoryRegistryItem> get sourceProvenMoreCategories =>
      moreCategories.where((x) => x.sourceStatus == CategorySourceStatus.sourceProven).toList(growable: false);
}
