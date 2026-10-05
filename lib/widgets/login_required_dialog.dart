import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/route_paths.dart';

/// حوار أنيق يظهر للزائر عند محاولة الوصول لميزة تتطلب تسجيل دخول.
Future<void> showLoginRequiredDialog(
  BuildContext context, {
  String? featureName,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.lock_outline,
        size: 40,
        color: Theme.of(ctx).colorScheme.primary,
      ),
      title: Text(
        featureName ?? 'تسجيل الدخول مطلوب',
        textAlign: TextAlign.center,
      ),
      content: const Text(
        'هذه الميزة متاحة للمسجلين فقط.\n'
        'سجّل دخولك للاستفادة من كل إمكانيات التطبيق.',
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('لاحقًا'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            GoRouter.of(context).go(RoutePaths.login);
          },
          child: const Text('تسجيل الدخول'),
        ),
      ],
    ),
  );
}