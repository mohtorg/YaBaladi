// lib/features/auth/controllers/auth_controller.dart
//
// [v1.1 — 2026-10-22] — Auth error messages
//   - FIX: added 'invalid-credential' (Firebase now returns it instead of
//          user-not-found / wrong-password) — it was shown in English.
//   - FIX: signInWithGoogle handles FirebaseAuthException and treats
//          popup-closed / cancelled requests as a cancellation.
//   - NOTE: `uid` returns 'guest' for visitors — use `isLoggedIn` to test
//           signed-in state, never `uid == null`.
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
  bool get isGuest => _isGuest;

  /// معرّف المستخدم، أو 'guest' للزائر. غير قابل لـ null —
  /// للتحقق من تسجيل الدخول استعمل [isLoggedIn].
  String get uid => _user?.uid ?? 'guest';
  String get displayName => _user?.displayName ?? 'زائر';
  String get photoUrl => _user?.photoUrl ?? '';
  UserRole get currentRole => _user?.role ?? UserRole.visitor;

  bool get hasGoogleProvider => _user != null;
  bool get hasPasswordProvider => _authService.currentUserHasPasswordProvider;

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
            _isGuest = false;
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

  Future<AuthResult> signInWithEmail(
      {required String email, required String password}) async {
    _isGuest = false;
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user =
          await _authService.signInWithEmail(email: email, password: password);
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return AuthResult.success();
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'فشل تسجيل الدخول';
        notifyListeners();
        return AuthResult.failure(_errorMessage!);
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _arabizeAuthError(e);
      notifyListeners();
      return AuthResult.failure(_errorMessage!);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'خطأ غير متوقع: $e';
      notifyListeners();
      return AuthResult.failure(_errorMessage!);
    }
  }

  Future<AuthResult> signUpWithEmail(
      {required String email,
      required String password,
      required String displayName}) async {
    _isGuest = false;
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await _authService.signUpWithEmail(
          email: email, password: password, displayName: displayName);
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return AuthResult.success();
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'فشل إنشاء الحساب';
        notifyListeners();
        return AuthResult.failure(_errorMessage!);
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = _arabizeAuthError(e);
      notifyListeners();
      return AuthResult.failure(_errorMessage!);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'خطأ غير متوقع: $e';
      notifyListeners();
      return AuthResult.failure(_errorMessage!);
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    _isGuest = false;
    _errorMessage = null;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _user = user;
        _status = AuthStatus.authenticated;
        notifyListeners();
        return AuthResult.success();
      } else {
        _status = AuthStatus.unauthenticated;
        _errorMessage = 'تم إلغاء تسجيل الدخول';
        notifyListeners();
        return AuthResult.failure(_errorMessage!, isCancelled: true);
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      final cancelled = e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request' ||
          e.code == 'web-context-canceled';
      _errorMessage =
          cancelled ? 'تم إلغاء تسجيل الدخول' : _arabizeAuthError(e);
      notifyListeners();
      return AuthResult.failure(_errorMessage!, isCancelled: cancelled);
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'فشل تسجيل الدخول بجوجل: $e';
      notifyListeners();
      return AuthResult.failure(_errorMessage!);
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    try {
      await _authService.sendPasswordReset(email);
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('فشل إرسال البريد: $e');
    }
  }

  Future<AuthResult> deleteAccount({String? password}) async {
    try {
      await _authService.deleteAccount(password: password);
      _user = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure('فشل حذف الحساب: $e');
    }
  }

  void continueAsGuest() {
    _isGuest = true;
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isGuest = false;
    _status = AuthStatus.loading;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('❌ Error in signOut: $e');
    }
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _arabizeAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة، '
            'أو انتهت صلاحية بيانات الدخول';
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'هذا الحساب معطل';
      case 'email-already-in-use':
        return 'البريد مستخدم بالفعل';
      case 'account-exists-with-different-credential':
        return 'هذا البريد مسجّل بطريقة دخول أخرى، جرّب البريد أو Google';
      case 'weak-password':
        return 'كلمة المرور ضعيفة (6 أحرف على الأقل)';
      case 'operation-not-allowed':
        return 'طريقة الدخول غير مفعلة في Firebase';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقاً';
      case 'network-request-failed':
        return 'تعذر الاتصال بالشبكة';
      default:
        return e.message ?? 'حدث خطأ';
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
