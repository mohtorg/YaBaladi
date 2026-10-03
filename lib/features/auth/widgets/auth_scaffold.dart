import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_paths.dart';
import '../../../theme/design_tokens.dart';

/// Scaffold موحّد لشاشات Auth (Login/Register/ForgotPassword)
///
/// يحتوي على PopScope للتحكم في زر الرجوع:
/// - إذا كانت الشاشة الرئيسية (Login) → يغلق التطبيق
/// - إذا كانت ثانوية (Register/ForgotPassword) → يعود لـ Login
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = true,
    this.exitOnBack = false,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  /// true = زر الرجوع يغلق التطبيق (لشاشة Login)
  /// false = زر الرجوع يعود لـ Login (لـ Register/ForgotPassword)
  final bool exitOnBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      // إذا كانت شاشة الدخول → نسمح للنظام بإغلاق التطبيق
      // إذا كانت شاشة ثانوية → نمنع الإغلاق ونعود لـ Login
      canPop: exitOnBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // الشاشة ثانوية → نعود لـ Login
        context.go(RoutePaths.login);
      },
      child: Scaffold(
        appBar: showBackButton
            ? AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (exitOnBack) {
                      // اترك النظام يتعامل معه
                      Navigator.of(context).maybePop();
                    } else {
                      context.go(RoutePaths.login);
                    }
                  },
                ),
              )
            : null,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(YaBaladiDesignTokens.space5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: YaBaladiDesignTokens.space4),

                Icon(
                  Icons.location_city_rounded,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: YaBaladiDesignTokens.space4),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: YaBaladiDesignTokens.space2),

                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: YaBaladiDesignTokens.space6),

                child,

                const SizedBox(height: YaBaladiDesignTokens.space4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}