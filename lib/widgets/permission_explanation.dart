// توحيد شاشة الشرح التي تظهر قبل نافذة Android الرسمية للصلاحية.
// لا نطلب أي صلاحية هنا؛ هذه الشاشة تشرح السبب فقط وتعيد قرار المستخدم.
import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

Future<bool> showPermissionExplanation({required BuildContext context, required String lang, required String titleKey, required String bodyKey}) async {
  final result = await showDialog<bool>(context: context, barrierDismissible: true, builder: (dialogContext) => AlertDialog(
    title: Text(AppStrings.of(titleKey, lang)),
    content: Text(AppStrings.of(bodyKey, lang)),
    actions: [
      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(AppStrings.of('permission_not_now', lang))),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: AppColors.primary), onPressed: () => Navigator.pop(dialogContext, true), child: Text(AppStrings.of('permission_continue', lang))),
    ],
  ));
  return result == true;
}
