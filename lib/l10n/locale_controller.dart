import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  Locale _locale = const Locale('ar');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (locale.languageCode == _locale.languageCode) return;
    _locale = locale;
    notifyListeners();
  }

  void toggle() {
    setLocale(
      _locale.languageCode == 'ar'
          ? const Locale('en')
          : const Locale('ar'),
    );
  }
}
