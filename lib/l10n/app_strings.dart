import 'package:flutter/widgets.dart';

class AppStrings {
  static const supportedLocales = <Locale>[Locale('ar'), Locale('en')];

  static const Map<String, Map<String, String>> _values = {
    'ar': {
      'app_name': '\u064a\u0627 \u0628\u0644\u062f\u064a',
      'welcome': '\u0645\u0631\u062d\u0628\u064b\u0627 \u0628\u0643 \u0641\u064a \u064a\u0627 \u0628\u0644\u062f\u064a',
      'language': '\u0627\u0644\u0644\u063a\u0629',
      'arabic': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
      'english': '\u0627\u0644\u0625\u0646\u062c\u0644\u064a\u0632\u064a\u0629',
      'current_direction': '\u0627\u062a\u062c\u0627\u0647 \u0627\u0644\u0648\u0627\u062c\u0647\u0629: \u0645\u0646 \u0627\u0644\u064a\u0645\u064a\u0646 \u0625\u0644\u0649 \u0627\u0644\u064a\u0633\u0627\u0631',
      'change_language': '\u062a\u063a\u064a\u064a\u0631 \u0627\u0644\u0644\u063a\u0629',
    },
    'en': {
      'app_name': 'Ya Baladi',
      'welcome': 'Welcome to Ya Baladi',
      'language': 'Language',
      'arabic': 'Arabic',
      'english': 'English',
      'current_direction': 'Interface direction: left to right',
      'change_language': 'Change language',
    },
  };

  static String of(String key, Locale locale) {
    final lang = locale.languageCode == 'en' ? 'en' : 'ar';
    return _values[lang]?[key] ?? key;
  }
}
