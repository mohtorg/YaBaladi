import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/route_paths.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final result = await auth.signIn(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'حدث خطأ')),
      );
    }
    // النجاح: authGuard هيعمل redirect تلقائي إلى /home
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthController>();
    final result = await auth.signInWithGoogle();

    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'فشل تسجيل الدخول')),
      );
    }
  }

  void _continueAsGuest() {
    context.read<AuthController>().continueAsGuest();
    // authGuard هيعمل redirect تلقائي إلى /home
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return AuthScaffold(
      title: l10n.loginTitle,
      subtitle: l10n.loginSubtitle,
      showBackButton: false,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ═══════════ حقول Email/Password ═══════════
            AuthTextField(
              controller: _emailCtrl,
              label: l10n.email,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.errorEmailRequired;
                }
                if (!v.contains('@')) return l10n.errorEmailInvalid;
                return null;
              },
            ),
            AuthTextField(
              controller: _passwordCtrl,
              label: l10n.password,
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.errorPasswordRequired;
                }
                if (v.length < 6) return l10n.errorPasswordShort;
                return null;
              },
            ),

            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.go(RoutePaths.forgotPassword),
                child: Text(l10n.forgotPassword),
              ),
            ),
            const SizedBox(height: YaBaladiDesignTokens.space2),

            // ═══════════ زر الدخول الرئيسي ═══════════
            AuthPrimaryButton(
              label: l10n.login,
              isLoading: auth.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: YaBaladiDesignTokens.space5),

            // ═══════════ بطاقة تسجيل واضحة ═══════════
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(12),
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      l10n.noAccountYet,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(RoutePaths.register),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: Text(
                      l10n.registerCta,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: YaBaladiDesignTokens.space5),

            // ═══════════ فاصل "أو" ═══════════
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    l10n.or,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: YaBaladiDesignTokens.space4),

            // ═══════════ زر Google ═══════════
            OutlinedButton.icon(
              onPressed: auth.isLoading ? null : _signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: Text(l10n.continueWithGoogle),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
            ),

            const SizedBox(height: YaBaladiDesignTokens.space4),

            // ═══════════ زر Guest ═══════════
            OutlinedButton.icon(
              onPressed: _continueAsGuest,
              icon: const Icon(Icons.person_outline),
              label: Text(l10n.continueAsGuest),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: theme.colorScheme.outline),
              ),
            ),

            const SizedBox(height: YaBaladiDesignTokens.space2),

            Center(
              child: Text(
                l10n.guestNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}