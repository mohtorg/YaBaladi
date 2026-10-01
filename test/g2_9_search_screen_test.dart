import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/screens/search_screen.dart';

void main() {
  test('G2-009 SearchScreen can be constructed', () {
    const screen = SearchScreen();
    expect(screen, isA<SearchScreen>());
  });
}
