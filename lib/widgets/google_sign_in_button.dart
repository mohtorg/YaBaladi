// lib/widgets/google_sign_in_button.dart
//
// [v1.1 — 2026-11-05] — FIX: Used absolute package import to resolve path issues.

import 'package:flutter/material.dart';

// ✅ استخدام مسار الحزمة المطلق بدلاً من المسار النسبي
// تأكد من أن اسم المشروع في pubspec.yaml هو yabaladi_rebuild
import 'package:yabaladi_rebuild/features/auth/google_auth_service.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);

    final credential = await _authService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (credential != null) {
      // ✅ نجاح: يمكنك الانتقال للشاشة الرئيسية أو عرض رسالة
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('مرحباً ${credential.user?.displayName ?? ''}!'),
          backgroundColor: Colors.green,
        ),
      );
      // مثال للانتقال (يتطلب استيراد go_router):
      // context.go('/home');
    } else {
      // ❌ إلغاء أو فشل
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إلغاء تسجيل الدخول أو حدث خطأ.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSignIn,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        minimumSize: const Size(double.infinity, 50), // يملأ عرض الشاشة
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // يمكنك استبدال هذه الأيقونة بشعار جوجل (G) كصورة
                const Icon(Icons.g_mobiledata, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'الدخول باستخدام Google',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }
}
