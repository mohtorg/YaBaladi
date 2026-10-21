// lib/features/auth/controllers/auth_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/app_user.dart';
import '../../../services/auth_service.dart';
import '../../../core/auth/role.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthResult {
  final bool isSuccess;
  final String? error;
  final bool isCancelled;

  AuthResult._(this.isSuccess, this.error, {this.isCancelled = false});
  factory AuthResult.success() => AuthResult._(true, null);
  factory AuthResult.failure(String error, {bool isCancelled = false}) =>
      AuthResult._(false, error, isCancelled: isCancelled);
}

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  StreamSubscription<User?>? _authSub;

  AuthStatus _status = AuthStatus.loading;
  AppUser? _user;
  String? _errorMessage;
  bool _isGuest = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  UserRole get role => _user?.role ?? UserRole.visitor;
  String? get errorMessage => _errorMessage;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isInitialized => _status != AuthStatus.loading;
  bool get isLoggedIn => _status == AuthStatus.authenticated && !_isGuest;

  // ✅ التصحيح الجذري: الزائر هو فقط من ضغط "الدخول كزائر"
  bool get isGuest => _isGuest;

  String get uid => _user?.uid ?? 'guest';
  String get displayName => _user?.displayName ?? 'زائر';
  String get photoUrl => _user?.photoUrl ?? '';
  UserRole get currentRole => _user?.role ?? UserRole.visitor;
  bool get hasGoogleProvider => _user != null;
  bool get hasPasswordProvider => false;

  AuthController() {
    _init();
  }

  void _init() {
    _authSub = _authService.authStateChanges.listen(
      (firebaseUser) async {
        try {
          if (firebaseUser == null) {
            if (!_isGuest) {
              _status = AuthStatus.unauthenticated;
              _user = null;
            }
            notifyListeners();
          } else {
            _isGuest = false; // إذا سجل الدخول، لم يعد زائراً
            _user = await _authService.getCurrentUserData();
            _status = _user != null
                ? AuthStatus.authenticated
                : AuthStatus.unauthenticated;
            notifyListeners();
          }
        } catch (e) {
          debugPrint('❌ Error in AuthState listener: $e');
          _status = AuthStatus.unauthenticated;
          notifyListeners();
        }
      },
      onError: (Object e) {
        debugPrint('❌ Stream Error: $e');
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      },
    );
  }

  void continueAsGuest() {
    _isGuest = true;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<AuthResult> signIn({String? email, String? password}) async {
    return _handleSignIn();
  }

  Future<AuthResult> signInWithGoogle() async {
    return _handleSignIn();
  }

  Future<AuthResult> _handleSignIn() async {
    _isGuest = false;
    _errorMessage = null;
    // نترك الحالة كما هي (loading لا يتغير هنا) لمنع انهيار FlutLab
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return AuthResult.success();
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'تم إلغاء تسجيل الدخول أو حدث خطأ.';
        notifyListeners();
        return AuthResult.failure(_errorMessage!, isCancelled: true);
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'فشل تسجيل الدخول: $e';
      notifyListeners();
      return AuthResult.failure(_errorMessage!);
    }
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
    String? name,
  }) async {
    return AuthResult.failure(
        'التسجيل بالبريد غير مدعوم حالياً. يرجى استخدام Google.');
  }

  Future<AuthResult> resetPassword(String email) async {
    return AuthResult.failure('استعادة كلمة المرور غير مدعومة حالياً.');
  }

  Future<AuthResult> deleteAccount({String? password}) async {
    return AuthResult.failure('حذف الحساب غير مدعوم حالياً.');
  }

  Future<void> signOut() async {
    _isGuest = false; // ✅ التصحيح: إنهاء وضع الزائر
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('❌ Error in signOut: $e');
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
