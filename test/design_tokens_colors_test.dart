import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/theme/design_tokens.dart';

void main() {
  test('Ya Baladi approved brand colors are centralized', () {
    expect(YaBaladiDesignTokens.navy.toARGB32(), 0xFF0B2D5B);
    expect(YaBaladiDesignTokens.primaryBlue.toARGB32(), 0xFF0D6EFD);
    expect(YaBaladiDesignTokens.accentOrange.toARGB32(), 0xFFFF8A00);
    expect(YaBaladiDesignTokens.white.toARGB32(), 0xFFFFFFFF);
  });
}
