import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/registries/category_registry.dart';

void main() {
  group('CategoryRegistry - Home', () {
    test('contains exactly 6 home categories', () {
      expect(CategoryRegistry.homeCategories.length, 6);
    });

    test('uses stable registry IDs CAT-001..CAT-006', () {
      final ids = CategoryRegistry.homeCategories
          .map((c) => c.registryId)
          .toList(growable: false);
      expect(ids, [
        'CAT-001',
        'CAT-002',
        'CAT-003',
        'CAT-004',
        'CAT-005',
        'CAT-006',
      ]);
    });

    test('exactly one category is marked documentedOnly', () {
      final documentedOnly = CategoryRegistry.homeCategories
          .where((c) => c.sourceStatus == CategorySourceStatus.documentedOnly)
          .toList(growable: false);
      expect(documentedOnly.length, 1);
      expect(documentedOnly.first.registryId, 'CAT-005');
    });

    test('all other home categories are sourceProven', () {
      final proven = CategoryRegistry.homeCategories
          .where((c) => c.sourceStatus == CategorySourceStatus.sourceProven)
          .toList(growable: false);
      expect(proven.length, 5);
    });
  });

  group('CategoryRegistry - More', () {
    test('moreCategories contains 21 entries', () {
      expect(CategoryRegistry.moreCategories.length, 21);
    });

    test('all moreCategories are sourceProven', () {
      for (final c in CategoryRegistry.moreCategories) {
        expect(c.sourceStatus, CategorySourceStatus.sourceProven);
      }
    });
  });

  group('CategoryRegistry - sourceProven getters', () {
    test('sourceProvenHomeCategories returns only proven home', () {
      final proven = CategoryRegistry.sourceProvenHomeCategories;
      expect(proven.length, 5);
      for (final c in proven) {
        expect(c.sourceStatus, CategorySourceStatus.sourceProven);
      }
    });

    test('sourceProvenMoreCategories returns all more', () {
      final proven = CategoryRegistry.sourceProvenMoreCategories;
      expect(proven.length, 21);
    });
  });
}