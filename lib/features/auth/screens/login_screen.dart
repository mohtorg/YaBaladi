// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final auth = context.read<AuthController>();
    final result = await auth.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess && !result.isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'فشل تسجيل الدخول'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _continueAsGuest() {
    final auth = context.read<AuthController>();
    auth.continueAsGuest();
    if (mounted) context.go(RoutePaths.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AuthScaffold(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      showBackButton: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: YaBaladiDesignTokens.space6),

          OutlinedButton.icon(
            onPressed: _isLoading ? null : _signInWithGoogle,
            icon: const Icon(Icons.g_mobiledata, size: 32, color: Colors.blue),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      l10n.continueWithGoogle,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space4),

          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(l10n.or, style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: YaBaladiDesignTokens.space4),

          OutlinedButton.icon(
            onPressed: _isLoading ? null : _continueAsGuest,
            icon: const Icon(Icons.person_outline),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                l10n.continueAsGuest,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.outline),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: YaBaladiDesignTokens.space5),

          Center(
            child: Text(
              l10n.guestNote,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // ✅ التصحيح: استبدال Spacer بـ SizedBox آمن
          const SizedBox(height: YaBaladiDesignTokens.space6),
        ],
      ),
    );
  }
}
