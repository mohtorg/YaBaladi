import 'package:flutter_test/flutter_test.dart';
import 'package:yabaladi_rebuild/l10n/app_strings.dart';
import 'package:yabaladi_rebuild/l10n/locale_controller.dart';

void main() {
  test('Arabic and English strings and locale switching', () {
    final controller = LocaleController();

    expect(controller.locale.languageCode, 'ar');
    expect(
      AppStrings.of('welcome', controller.locale),
      'مرحبًا بك في يا بلدي',
    );

    controller.toggle();

    expect(controller.locale.languageCode, 'en');
    expect(
      AppStrings.of('welcome', controller.locale),
      'Welcome to Ya Baladi',
    );
  });
}
