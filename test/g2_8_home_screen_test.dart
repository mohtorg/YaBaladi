import 'package:flutter_test/flutter_test.dart';

import 'package:yabaladi_rebuild/registries/category_registry.dart';
import 'package:yabaladi_rebuild/screens/home_screen.dart';

void main() {
  test('G2-008 Home uses the approved category registry', () {
    expect(CategoryRegistry.homeCategories, hasLength(6));
    expect(
      CategoryRegistry.homeCategories.map((item) => item.labelEn).toSet(),
      containsAll(<String>[
        'Restaurants',
        'Cafes',
        'Events',
        'Historical Landmarks',
        'Cinema',
        'Clubs & Gyms',
      ]),
    );
  });

  test('G2-008 HomeScreen can be constructed', () {
    const screen = HomeScreen();
    expect(screen, isA<HomeScreen>());
  });
}
