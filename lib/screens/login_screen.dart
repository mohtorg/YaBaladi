// screens/login_screen.dart
// الغرض: المصادقة الفعلية بعد اختيار مسار الاستخدام من شاشة الترحيب.
// ندعم Google وEmail/Password كما هو قائم؛ لا نكسر طرق الدخول الحالية.
// اختيار مقيم/زائر هنا هو تجربة الاستخدام فقط، بينما صلاحيات مقدم الخدمة منفصلة.

import 'package:flutter/material.dart';
import '../models/app_experience_mode.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../services/entry_intent.dart';

class LoginScreen extends StatefulWidget {
  final AppExperienceMode? initialMode;
  final bool initialMerchant;

  const LoginScreen({
    super.key,
    this.initialMode,
    this.initialMerchant = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _applyInitialPath() async {
    // بعد نجاح المصادقة نطبق اختيار المسار على الحساب الشخصي.
    // مقدم الخدمة يمر إلى شاشة بيانات النشاط بعد المصادقة.
    if (widget.initialMode == null) return;
    final user = await _authService.getCurrentAppUser();
    if (user == null || user.role.isEmpty) {
      await _authService.setAccountType(role: 'user');
      await _authService.setExperienceMode(widget.initialMode!);
      EntryIntent.clear();
      return;
    }
    if (user.role == 'user') {
      await _authService.setExperienceMode(widget.initialMode!);
      EntryIntent.clear();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.signInWithGoogle();
      await _applyInitialPath();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'حدث خطأ أثناء الدخول بحساب Google، حاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailAuth() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'من فضلك املأ كل الحقول المطلوبة.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_isSignUpMode) {
        await _authService.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          _fullNameController.text.trim(),
        );
      } else {
        await _authService.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
      await _applyInitialPath();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) return 'البريد الإلكتروني مسجل بالفعل.';
    if (raw.contains('weak-password')) return 'كلمة السر ضعيفة، يجب أن تكون 6 أحرف على الأقل.';
    if (raw.contains('user-not-found') || raw.contains('wrong-password')) return 'البريد الإلكتروني أو كلمة السر غير صحيحة.';
    if (raw.contains('invalid-email')) return 'صيغة البريد الإلكتروني غير صحيحة.';
    return 'حدث خطأ، حاول مرة أخرى.';
  }

  String get _screenTitle {
    if (widget.initialMerchant) return 'دخول مقدم الخدمة';
    if (widget.initialMode == AppExperienceMode.visitor) return 'دخول الزائر';
    if (widget.initialMode == AppExperienceMode.resident) return 'دخول المقيم';
    return _isSignUpMode ? 'إنشاء حساب جديد' : 'تسجيل الدخول';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/branding/ya_baladi_icon.png', width: 96, height: 96),
                ),
                const SizedBox(height: 14),
                const Text('يا بلدي', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: AppColors.primary)),
                const SizedBox(height: 6),
                Text(_screenTitle, style: TextStyle(fontSize: 17, color: Colors.grey[600])),
                const SizedBox(height: 30),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 28, color: AppColors.primary),
                    label: const Text('الدخول بحساب Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(children: [Expanded(child: Divider(color: Colors.grey[300])), const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('أو')), Expanded(child: Divider(color: Colors.grey[300]))]),
                const SizedBox(height: 20),
                if (_isSignUpMode) ...[
                  TextField(controller: _fullNameController, decoration: InputDecoration(labelText: 'الاسم بالكامل', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 12),
                ],
                TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 12),
                TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: 'كلمة السر', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleEmailAuth,
                    style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(_isSignUpMode ? 'إنشاء الحساب' : 'دخول'),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isLoading ? null : () => setState(() { _isSignUpMode = !_isSignUpMode; _errorMessage = null; }),
                  child: Text(_isSignUpMode ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب'),
                ),
                const SizedBox(height: 12),
                const Text('بعد تسجيل الدخول يمكنك تفعيل الدخول السريع ببصمة أو نمط/PIN الهاتف.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
