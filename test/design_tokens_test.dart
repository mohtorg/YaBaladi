import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/theme/design_tokens.dart';

void main() {
  test('Ya Baladi design tokens are centrally defined', () {
    expect(YaBaladiDesignTokens.space4, 16);
    expect(YaBaladiDesignTokens.radiusMedium, 12);
    expect(YaBaladiDesignTokens.elevation1, 1);
    expect(YaBaladiDesignTokens.maxContentWidth, 1200);
  });
}