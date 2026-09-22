// screens/auth_gate.dart
// بوابة المصادقة والمسارات النهائية.
// الترتيب الأمني: Firebase Auth أولًا، ثم المصادقة المحلية الاختيارية، ثم الصلاحيات والمسار.
// لا نستخدم نمط/PIN الجهاز كبديل عن Firebase؛ هو فقط يحمي إعادة فتح الجلسة على الجهاز.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/quick_auth_service.dart';
import '../models/user_model.dart';
import '../models/app_experience_mode.dart';
import 'welcome_role_screen.dart';
import 'main_shell.dart';
import 'account_type_screen.dart';
import 'merchant_home_screen.dart';
import 'visitor_shell.dart';
import 'admin/admin_dashboard_screen.dart';
import '../theme/app_colors.dart';
import '../services/entry_intent.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (!authSnapshot.hasData) {
          return const WelcomeRoleScreen();
        }
        return const QuickAuthGate(child: _AuthenticatedRouter());
      },
    );
  }
}

class QuickAuthGate extends StatefulWidget {
  final Widget child;
  const QuickAuthGate({super.key, required this.child});

  @override
  State<QuickAuthGate> createState() => _QuickAuthGateState();
}

class _QuickAuthGateState extends State<QuickAuthGate> {
  final QuickAuthService _quickAuth = QuickAuthService();
  bool _loading = true;
  bool _locked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final enabled = await _quickAuth.isEnabled();
      if (!enabled) {
        if (mounted) setState(() { _loading = false; _locked = false; });
        return;
      }
      final ok = await _quickAuth.authenticate();
      if (!mounted) return;
      setState(() { _loading = false; _locked = !ok; _error = ok ? null : 'لم يتم التحقق من هوية الجهاز.'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _locked = true; _error = 'تعذر تشغيل الدخول السريع على هذا الجهاز.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _LoadingScreen(message: 'جارٍ التحقق من الجهاز...');
    if (!_locked) return widget.child;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(radius: 38, backgroundColor: Color(0xFFEAF2FB), child: Icon(Icons.lock_outline, color: AppColors.primary, size: 40)),
                const SizedBox(height: 18),
                const Text('الدخول السريع', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(_error ?? 'استخدم بصمة الإصبع أو نمط/PIN الهاتف للمتابعة.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, height: 1.5)),
                const SizedBox(height: 22),
                SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _check, icon: const Icon(Icons.fingerprint), label: const Text('المحاولة مرة أخرى'))),
                const SizedBox(height: 10),
                TextButton(onPressed: () async { await _quickAuth.setEnabled(false); if (mounted) setState(() { _locked = false; }); }, child: const Text('إيقاف الدخول السريع على هذا الجهاز')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthenticatedRouter extends StatelessWidget {
  const _AuthenticatedRouter();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().hasAdminClaim(),
      builder: (context, adminSnapshot) {
        if (adminSnapshot.connectionState == ConnectionState.waiting) return const _LoadingScreen();
        if (adminSnapshot.data == true) return const AdminDashboardScreen();

        return StreamBuilder<AppUser?>(
          stream: AuthService().currentAppUserStream,
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) return const _LoadingScreen();
            final appUser = userSnapshot.data;

            return FutureBuilder<bool>(
              future: AuthService().isModerator(),
              builder: (context, moderatorSnapshot) {
                if (moderatorSnapshot.connectionState == ConnectionState.waiting) return const _LoadingScreen();
                if (moderatorSnapshot.data == true) return const AdminDashboardScreen();

                if (appUser == null || appUser.role.isEmpty) return AccountTypeScreen(initialMerchant: EntryIntent.merchant);
                if (appUser.isMerchant) return const MerchantHomeScreen();

                final mode = appUser.experienceMode;
                if (mode == null) return const AccountTypeScreen();
                if (mode == AppExperienceMode.visitor) return const VisitorShell();
                return const MainShell();
              },
            );
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  final String message;
  const _LoadingScreen({this.message = 'جارٍ التحميل...'});

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text(message)])));
}
