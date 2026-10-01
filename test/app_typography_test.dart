import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/theme/app_typography.dart';

void main() {
  test('Ya Baladi typography tokens match the approved hierarchy', () {
    expect(YaBaladiTypography.fontFamily, 'Cairo');

    expect(YaBaladiTypography.headingScreen.fontSize, 22);
    expect(YaBaladiTypography.headingScreen.fontWeight, FontWeight.w700);
    expect(YaBaladiTypography.headingScreen.height, 1.4);

    expect(YaBaladiTypography.headingSection.fontSize, 18);
    expect(YaBaladiTypography.headingSection.fontWeight, FontWeight.w600);
    expect(YaBaladiTypography.headingSection.height, 1.4);

    expect(YaBaladiTypography.headingSubsection.fontSize, 16);
    expect(YaBaladiTypography.headingSubsection.fontWeight, FontWeight.w500);
    expect(YaBaladiTypography.headingSubsection.height, 1.5);

    expect(YaBaladiTypography.headingLabel.fontSize, 13);
    expect(YaBaladiTypography.headingLabel.fontWeight, FontWeight.w600);
    expect(YaBaladiTypography.headingLabel.height, 1.4);
  });
}
