// lib/widgets/login_required_dialog.dart
//
// [v1.1 — 2026-10-25] — i18n of hard-coded strings
//   - FIX: العنوان الافتراضي والمحتوى وزرّا «لاحقًا» و«تسجيل الدخول» صارت
//          من AppLocalizations (loginRequired, loginRequiredMessage,
//          maybeLater, login) بدل النصوص العربية الثابتة.
//   - KEPT: توقيع الدالة (featureName) ومسار التوجيه دون تغيير.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/route_paths.dart';
import '../l10n/app_localizations.dart';

/// حوار أنيق يظهر للزائر عند محاولة الوصول لميزة تتطلب تسجيل دخول.
Future<void> showLoginRequiredDialog(
  BuildContext context, {
  String? featureName,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx);

      return AlertDialog(
        icon: Icon(
          Icons.lock_outline,
          size: 40,
          color: Theme.of(ctx).colorScheme.primary,
        ),
        title: Text(
          featureName ?? l10n.loginRequired,
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.loginRequiredMessage,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.maybeLater),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              GoRouter.of(context).go(RoutePaths.login);
            },
            child: Text(l10n.login),
          ),
        ],
      );
    },
  );
}
