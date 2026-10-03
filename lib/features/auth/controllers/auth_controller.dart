import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// نتيجة عملية Auth (نجاح/فشل مع رسالة خطأ)
class AuthResult {
  const AuthResult.success()
      : error = null,
        isSuccess = true;
  const AuthResult.failure(this.error) : isSuccess = false;

  final String? error;
  final bool isSuccess;
}

/// يغلّف Firebase Auth + Firestore user profile
class AuthController extends ChangeNotifier {
  AuthController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    _userSub = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  StreamSubscription<User?>? _userSub;

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  // ============================================================
  // GETTERS
  // ============================================================

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _user != null;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName;

  // ============================================================
  // INIT
  // ============================================================

  void _onAuthStateChanged(User? user) {
    _user = user;
    _isInitialized = true;
    notifyListeners();
  }

  // ============================================================
  // SIGN IN
  // ============================================================

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.failure('حدث خطأ غير متوقع');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SIGN UP
  // ============================================================

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await cred.user?.updateDisplayName(displayName.trim());

      final user = cred.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': displayName.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        }, SetOptions(merge: true));
      }

      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.failure('حدث خطأ غير متوقع');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _auth.signOut();
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<AuthResult> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (_) {
      return const AuthResult.failure('حدث خطأ غير متوقع');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهذا البريد';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'email-already-in-use':
        return 'هذا البريد مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جدًا';
      case 'user-disabled':
        return 'هذا الحساب معطّل';
      case 'too-many-requests':
        return 'محاولات كثيرة، حاول لاحقًا';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      case 'invalid-credential':
        return 'البريد أو كلمة المرور غير صحيحة';
      default:
        return e.message ?? 'حدث خطأ أثناء المصادقة';
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}