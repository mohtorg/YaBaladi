import 'package:flutter/material.dart';

import '../../../theme/design_tokens.dart';

/// Scaffold موحّد لشاشات Auth (Login/Register/ForgotPassword)
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBackButton = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: showBackButton
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
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
    );
  }
}