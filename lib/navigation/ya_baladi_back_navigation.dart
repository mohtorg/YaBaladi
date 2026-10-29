import 'package:flutter/material.dart';

/// Central back-navigation policy for Ya Baladi.
///
/// The current project sources define back behavior by route/screen:
/// previous screen, parent screen, exit behavior, and unsaved-change behavior.
/// Role-specific differences are intentionally not invented here because the
/// executable role/route matrix has not yet been established in the clean build.
class YaBaladiBackNavigation extends StatelessWidget {
  const YaBaladiBackNavigation({
    super.key,
    required this.child,
    this.isRoot = false,
    this.hasUnsavedChanges = false,
    this.onConfirmDiscard,
  });

  final Widget child;
  final bool isRoot;
  final bool hasUnsavedChanges;
  final Future<bool> Function()? onConfirmDiscard;

  Future<bool> _confirmDiscard() async {
    final callback = onConfirmDiscard;
    if (callback == null) {
      return false;
    }
    return callback();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: !isRoot && !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || isRoot || !hasUnsavedChanges) {
          return;
        }

        // ✅ نحفظ الـ NavigatorState قبل أي await
        final navigator = Navigator.of(context);

        final shouldDiscard = await _confirmDiscard();

        // ✅ فحص mounted بعد الـ await
        // ignore: use_build_context_synchronously
        if (!context.mounted) return;
        if (!shouldDiscard) return;
        if (!shouldDiscard) return;

        navigator.pop(result);
      },
      child: child,
    );
  }
}
