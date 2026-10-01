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

        final shouldDiscard = await _confirmDiscard();
        if (!context.mounted || !shouldDiscard) {
          return;
        }

        Navigator.of(context).pop(result);
      },
      child: child,
    );
  }
}
