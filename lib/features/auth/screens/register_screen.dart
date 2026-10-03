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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final result = await auth.signUp(
      email: _emailCtrl.text,
      password: _passwordCtrl.text,
      displayName: _nameCtrl.text,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'خطأ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();

    return AuthScaffold(
      title: l10n.registerTitle,
      subtitle: l10n.registerSubtitle,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              controller: _nameCtrl,
              label: l10n.displayName,
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.errorNameRequired;
                }
                if (v.trim().length < 2) return l10n.errorNameShort;
                return null;
              },
            ),
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
              textInputAction: TextInputAction.next,
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
            AuthTextField(
              controller: _confirmCtrl,
              label: l10n.confirmPassword,
              icon: Icons.lock_outline,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return l10n.errorPasswordRequired;
                }
                if (v != _passwordCtrl.text) {
                  return l10n.errorPasswordsMismatch;
                }
                return null;
              },
            ),

            const SizedBox(height: YaBaladiDesignTokens.space2),

            AuthPrimaryButton(
              label: l10n.register,
              isLoading: auth.isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: YaBaladiDesignTokens.space4),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.haveAccountAlready),
                TextButton(
                  onPressed: () => context.go(RoutePaths.login),
                  child: Text(l10n.login),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}