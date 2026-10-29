import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/registries/category_registry.dart';

void main() {
  test('Home registry contains exactly six approved categories', () {
    expect(CategoryRegistry.homeCategories, hasLength(6));
    expect(CategoryRegistry.sourceProvenHomeCategories, hasLength(5));
    expect(
      CategoryRegistry.homeCategories
          .where((x) => x.sourceStatus == CategorySourceStatus.documentedOnly)
          .single
          .labelEn,
      'Cinema',
    );
  });

  test('More registry contains only categories proven by current source', () {
    expect(CategoryRegistry.moreCategories, isNotEmpty);

    for (final item in CategoryRegistry.moreCategories) {
      expect(item.sourceStatus, CategorySourceStatus.sourceProven);
      expect(CategoryRegistry.sourceFor(item), isNotNull,
          reason: 'More category missing from source: ${item.labelEn}');
    }
  });

  test('Registry has unique IDs', () {
    final all = [...CategoryRegistry.homeCategories, ...CategoryRegistry.moreCategories];
    final ids = all.map((x) => x.registryId).toSet();
    expect(ids.length, all.length);
  });

  test('Cinema is not exposed as a source-proven category', () {
    final cinema = CategoryRegistry.homeCategories
        .firstWhere((x) => x.labelEn == 'Cinema');
    expect(cinema.sourceStatus, CategorySourceStatus.documentedOnly);
    expect(CategoryRegistry.sourceFor(cinema), isNull);
  });
}
