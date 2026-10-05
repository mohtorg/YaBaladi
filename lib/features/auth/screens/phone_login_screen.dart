import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_primary_button.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/auth_text_field.dart';

/// شاشة تسجيل الدخول برقم الموبايل (خطوتين):
/// 1) إدخال الرقم → إرسال OTP
/// 2) إدخال OTP → التحقق
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _codeSent = false;
  String? _verificationId;
  String _displayPhone = '';

  Timer? _resendTimer;
  int _resendSeconds = 60;
  bool _canResend = true;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  /// يحوّل 01012345678 → +201012345678
  String _formatPhone(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('20')) return '+$digits';
    if (digits.startsWith('0')) return '+20${digits.substring(1)}';
    return '+20$digits';
  }

  void _startResendTimer() {
    _resendSeconds = 60;
    _canResend = false;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSeconds--;
        if (_resendSeconds <= 0) {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendCode() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthController>();
    final formatted = _formatPhone(_phoneCtrl.text);

    final result = await auth.verifyPhone(
      phoneNumber: formatted,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          _codeSent = true;
          _displayPhone = formatted;
        });
        _startResendTimer();
      },
      onError: (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );

    if (!mounted) return;
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? l10n.invalidPhone)),
      );
    }
  }

  Future<void> _verifyCode() async {
    if (!_otpFormKey.currentState!.validate()) return;
    if (_verificationId == null) return;

    final auth = context.read<AuthController>();
    final result = await auth.verifyOTP(
      verificationId: _verificationId!,
      smsCode: _otpCtrl.text,
    );

    if (!mounted) return;
    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'رمز غير صحيح')),
      );
    }
    // النجاح: authGuard يعمل redirect تلقائيًا إلى Home
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final auth = context.watch<AuthController>();

    return AuthScaffold(
      title: _codeSent ? l10n.otpTitle : l10n.phoneLoginTitle,
      subtitle: _codeSent
          ? '${l10n.otpSentTo} $_displayPhone'
          : l10n.phoneLoginSubtitle,
      showBackButton: true,
      exitOnBack: false,
      child: _codeSent
          ? _buildOtpForm(l10n, auth)
          : _buildPhoneForm(l10n, auth),
    );
  }

  Widget _buildPhoneForm(AppLocalizations l10n, AuthController auth) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _phoneCtrl,
            label: l10n.phoneNumber,
            icon: Icons.phone_iphone,
            hintText: l10n.phoneNumberHint,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendCode(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return l10n.invalidPhone;
              }
              final digits = v.replaceAll(RegExp(r'\D'), '');
              if (digits.length < 10) return l10n.invalidPhone;
              return null;
            },
          ),
          const SizedBox(height: YaBaladiDesignTokens.space4),
          AuthPrimaryButton(
            label: l10n.sendCode,
            isLoading: auth.isLoading,
            onPressed: _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpForm(AppLocalizations l10n, AuthController auth) {
    return Form(
      key: _otpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            controller: _otpCtrl,
            label: l10n.otpTitle,
            icon: Icons.lock_outline,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _verifyCode(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return l10n.otpRequired;
              if (v.trim().length != 6) return l10n.otpInvalidLength;
              return null;
            },
          ),
          const SizedBox(height: YaBaladiDesignTokens.space4),
          AuthPrimaryButton(
            label: l10n.verifyCode,
            isLoading: auth.isLoading,
            onPressed: _verifyCode,
          ),
          const SizedBox(height: YaBaladiDesignTokens.space3),
          Center(
            child: _canResend
                ? TextButton(
                    onPressed: () {
                      setState(() {
                        _codeSent = false;
                        _otpCtrl.clear();
                      });
                    },
                    child: Text(l10n.resendCode),
                  )
                : Text(
                    '${l10n.resendCode} ($_resendSeconds)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
          ),
        ],
      ),
    );
  }
}