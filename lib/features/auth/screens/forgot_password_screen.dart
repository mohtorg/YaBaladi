import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final result = await auth.resetPassword(_emailCtrl.text);

    if (!mounted) return;

    if (result.isSuccess) {
      setState(() => _emailSent = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'خطأ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();
    final theme = Theme.of(context);

    return AuthScaffold(
      title: l10n.forgotPasswordTitle,
      subtitle: _emailSent
          ? l10n.resetEmailSent
          : l10n.forgotPasswordSubtitle,
      child: _emailSent
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: YaBaladiDesignTokens.space4),
                Text(
                  l10n.resetEmailSent,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            )
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _emailCtrl,
                    label: l10n.email,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return l10n.errorEmailRequired;
                      }
                      if (!v.contains('@')) return l10n.errorEmailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: YaBaladiDesignTokens.space2),
                  AuthPrimaryButton(
                    label: l10n.sendResetLink,
                    isLoading: auth.isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}