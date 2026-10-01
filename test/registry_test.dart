import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/registries/category_registry.dart';

void main() {
  test('approved Home category registry remains exactly six categories', () {
    expect(CategoryRegistry.homeCategories.length, 6);
    expect(CategoryRegistry.byId('CAT-001')?.nameEn, 'Restaurants');
    expect(CategoryRegistry.byId('CAT-002')?.nameEn, 'Cafes');
    expect(CategoryRegistry.byId('CAT-003')?.nameEn, 'Events');
    expect(CategoryRegistry.byId('CAT-004')?.nameEn, 'Historical Places');
    expect(CategoryRegistry.byId('CAT-005')?.nameEn, 'Cinema');
    expect(CategoryRegistry.byId('CAT-006')?.nameEn, 'Gyms');
  });

  test('only source-proven storage IDs are marked verified', () {
    expect(CategoryRegistry.verifiedHomeCategories.length, 4);
    expect(CategoryRegistry.documentedOnlyHomeCategories.length, 2);
    expect(CategoryRegistry.byId('CAT-004')?.storageId, isNull);
    expect(CategoryRegistry.byId('CAT-005')?.storageId, isNull);
  });

  test('documented-only categories are never treated as executable storage values', () {
    for (final c in CategoryRegistry.documentedOnlyHomeCategories) {
      expect(c.isVerifiedInCode, isFalse);
      expect(c.storageId, isNull);
    }
  });
}