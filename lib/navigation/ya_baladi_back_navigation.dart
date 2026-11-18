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

  /// الشاشة الفرعية التي سيتم تغليفها
  final Widget child;

  /// هل هذه الشاشة هي الشاشة الرئيسية (الجذر)؟
  final bool isRoot;

  /// هل هناك تغييرات غير محفوظة في الشاشة الحالية؟
  final bool hasUnsavedChanges;

  /// دالة تُستدعى لسؤال المستخدم عند محاولة الخروج مع وجود تغييرات
  final Future<bool> Function()? onConfirmDiscard;

  Future<bool> _confirmDiscard(BuildContext context) async {
    // إذا تم توفير دالة مخصصة، نستخدمها
    if (onConfirmDiscard != null) {
      return onConfirmDiscard!();
    }

    // إذا لم يتم توفير دالة، نعرض حواراً افتراضياً لحماية البيانات
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغييرات غير محفوظة'),
        content: const Text('هل تريد تجاهل التغييرات والعودة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('تجاهل'),
          ),
        ],
      ),
    );

    // إذا أغلق المستخدم الحوار دون اختيار، نعتبر ذلك رفضاً للخروج
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      // يمكن الرجوع إذا لم تكن الشاشة جذراً ولا توجد تغييرات غير محفوظة
      canPop: !isRoot && !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        // إذا تم الرجوع بالفعل، أو كنا في الشاشة الجذر، أو لا توجد تغييرات، لا تفعل شيئاً
        if (didPop || isRoot || !hasUnsavedChanges) {
          return;
        }

        // ✅ نحفظ الـ NavigatorState قبل أي await لتجنب مشاكل السياق
        final navigator = Navigator.of(context);

        // سؤال المستخدم لتأكيد الخروج (أو عرض الحوار الافتراضي)
        final shouldDiscard = await _confirmDiscard(context);

        // ✅ فحص mounted بعد الـ await لضمان أن الشاشة لا تزال موجودة
        // ignore: use_build_context_synchronously
        if (!context.mounted) return;

        // إذا رفض المستخدم الخروج، نوقف العملية
        if (!shouldDiscard) return;

        // إذا وافق المستخدم، ننفذ الرجوع
        navigator.pop(result);
      },
      child: child,
    );
  }
}
