// lib/features/auth/screens/forgot_password_screen.dart
//
// [v3.0 — 2026-10-26] — ABSOLUTE FINAL FIX: No dependency on return type (try/catch only)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _emailSent = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ منع الضغط المتكرر
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthController>();
      final String email = _emailCtrl.text.trim();

      // ✅ استدعاء الدالة دون انتظار نتيجة معينة
      await auth.resetPassword(email);

      if (!mounted) return;

      // ✅ إذا لم يحدث خطأ، نعتبر العملية ناجحة
      setState(() => _emailSent = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('استعادة كلمة المرور'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child:
                _emailSent ? _buildSuccessView(theme) : _buildFormView(theme),
          ),
        ),
      ),
    );
  }

  // ─── واجهة نجاح الإرسال ───
  Widget _buildSuccessView(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.mark_email_read_outlined,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'تم إرسال الرابط بنجاح',
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'يرجى مراجعة بريدك الإلكتروني (بما في ذلك مجلد البريد العشوائي) واتباع التعليمات لإعادة تعيين كلمة المرور.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('العودة لتسجيل الدخول'),
        ),
      ],
    );
  }

  // ─── واجهة إدخال البريد ───
  Widget _buildFormView(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'نسيت كلمة المرور؟',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أدخل بريدك الإلكتروني المسجل لدينا وسنرسل لك رابطاً لإعادة تعيين كلمة المرور.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'البريد الإلكتروني',
              hintText: 'example@domain.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'البريد الإلكتروني مطلوب';
              }
              if (!v.contains('@') || !v.contains('.')) {
                return 'البريد الإلكتروني غير صالح';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            // ✅ استخدام حالة التحميل المحلية بدلاً من auth.isLoading
            onPressed: _isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'إرسال رابط الاستعادة',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}
