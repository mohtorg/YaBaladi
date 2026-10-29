// lib/widgets/ya_app_bar.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/router/route_paths.dart';

/// AppBar موحّد للتطبيق:
/// - زر رجوع ذكي (pop أو Home تلقائيًا)
/// - العنوان من l10n
/// - اختياريًا: actions
class YaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const YaAppBar({
    super.key,
    required this.title,
    this.actions,
    this.centerTitle = false,
  });

  final String title;
  final List<Widget>? actions;
  final bool centerTitle;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    // استخدام GoRouter.of(context) لضمان التوافقية
    final router = GoRouter.of(context);

    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      actions: actions,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (router.canPop()) {
            router.pop();
          } else {
            router.go(RoutePaths.home);
          }
        },
      ),
    );
  }
}
