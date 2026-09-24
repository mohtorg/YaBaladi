// l10n/locale_controller.dart
// يوفر اللغة الحالية (Locale) ودالة تبديلها لأي شاشة في التطبيق
// من غير ما نحتاج نمرر المتغير يدويًا من شاشة لشاشة

import 'package:flutter/material.dart';

class LocaleController extends InheritedWidget {
  final Locale locale;
  final VoidCallback toggleLocale;

  const LocaleController({
    super.key,
    required this.locale,
    required this.toggleLocale,
    required super.child,
  });

  static LocaleController of(BuildContext context) {
    final result =
        context.dependOnInheritedWidgetOfExactType<LocaleController>();
    assert(result != null, 'لازم يكون في LocaleController فوق في الشجرة');
    return result!;
  }

  @override
  bool updateShouldNotify(LocaleController oldWidget) {
    return oldWidget.locale != locale;
  }
}
