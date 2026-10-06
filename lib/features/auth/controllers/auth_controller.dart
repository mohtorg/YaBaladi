import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
///
/// آمن للاختبار: إذا لم يكن Firebase مُهيَّأً، يظل Controller صالحًا
/// (بـ isInitialized=false) بدون رمي استثناءات.
class AuthController extends ChangeNotifier {
  AuthController({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _injectedAuth = auth,
        _injectedFirestore = firestore,
        _injectedGoogleSignIn = googleSignIn {
    _initFirebase();
  }

  final FirebaseAuth? _injectedAuth;
  final FirebaseFirestore? _injectedFirestore;
  final GoogleSignIn? _injectedGoogleSignIn;

  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  GoogleSignIn? _googleSignIn;
  StreamSubscription<User?>? _userSub;

  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _firebaseAvailable = false;
  bool _isGuest = false;
  String? _verificationId;

  // ============================================================
  // GETTERS
  // ============================================================

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _user != null;
  bool get isGuest => _isGuest;
  bool get isActiveUser => _user != null;
  bool get firebaseAvailable => _firebaseAvailable;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String? get displayName => _user?.displayName;
  String? get verificationId => _verificationId;

  // ============================================================
  // INIT (آمن للاختبار)
  // ============================================================

  void _initFirebase() {
    try {
      _auth = _injectedAuth ?? FirebaseAuth.instance;
      _firestore = _injectedFirestore ?? FirebaseFirestore.instance;
      _googleSignIn = _injectedGoogleSignIn ?? GoogleSignIn();
      _firebaseAvailable = true;
      _userSub = _auth!.authStateChanges().listen(_onAuthStateChanged);
    } catch (e) {
      _firebaseAvailable = false;
      _isInitialized = true;
      debugPrint('AuthController: Firebase not available ($e)');
    }
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) _isGuest = false;
    _isInitialized = true;
    notifyListeners();
  }

  // ============================================================
  // EMAIL SIGN IN
  // ============================================================

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (_auth == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    _setLoading(true);
    try {
      await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      _isGuest = false;
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
  // EMAIL SIGN UP
  // ============================================================

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (_auth == null || _firestore == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    _setLoading(true);
    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await cred.user?.updateDisplayName(displayName.trim());

      final user = cred.user;
      if (user != null) {
        await _firestore!.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': displayName.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        }, SetOptions(merge: true));
      }

      _isGuest = false;
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
  // GOOGLE SIGN IN  ← المهمة #3
  // ============================================================

  Future<AuthResult> signInWithGoogle() async {
    if (_auth == null || _googleSignIn == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    _setLoading(true);
    try {
      // 1) افتح نافذة اختيار حساب Google
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        // المستخدم أغلق النافذة
        return const AuthResult.failure('تم إلغاء تسجيل الدخول');
      }

      // 2) احصل على tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3) أنشئ Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4) سجّل الدخول في Firebase
      final userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user;

      // 5) أنشئ/حدّث بروفايل المستخدم في Firestore
      if (user != null && _firestore != null) {
        await _firestore!.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        }, SetOptions(merge: true));
      }

      _isGuest = false;
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      return const AuthResult.failure('فشل تسجيل الدخول بـ Google');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // PHONE AUTH  ← المهمة #4
  // ============================================================

  /// يرسل رمز التحقق لرقم الموبايل.
  ///
  /// [phoneNumber] لازم يكون بصيغة E.164: مثلاً `+201012345678`
  Future<AuthResult> verifyPhone({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    if (_auth == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    _setLoading(true);
    try {
      await _auth!.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-retrieval (Android): يشتغل بدون إدخال OTP
          try {
            await _auth!.signInWithCredential(credential);
            _isGuest = false;
          } catch (e) {
            debugPrint('Auto-verification error: $e');
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_mapAuthError(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return AuthResult.failure('فشل إرسال الرمز: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// يتحقق من رمز OTP المُرسل للموبايل.
  Future<AuthResult> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    if (_auth == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    _setLoading(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );

      final userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && _firestore != null) {
        await _firestore!.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'phoneNumber': user.phoneNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'user',
        }, SetOptions(merge: true));
      }

      _isGuest = false;
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      return const AuthResult.failure('رمز التحقق غير صحيح');
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    if (_auth == null) {
      _isGuest = false;
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      // سجّل خروج من Google (لو كان داخل بيها)
      try {
        await _googleSignIn?.signOut();
      } catch (_) {}
      await _auth!.signOut();
    } finally {
      _isGuest = false;
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============================================================
  // GUEST MODE
  // ============================================================

  void continueAsGuest() {
    _isGuest = true;
    notifyListeners();
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<AuthResult> resetPassword(String email) async {
    if (_auth == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    _setLoading(true);
    try {
      await _auth!.sendPasswordResetEmail(email: email.trim());
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
      // ─── Phone-specific ───
      case 'invalid-phone-number':
        return 'رقم الموبايل غير صالح';
      case 'missing-phone-number':
        return 'أدخل رقم الموبايل';
      case 'quota-exceeded':
        return 'تم تجاوز الحد المسموح، حاول لاحقًا';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
        return 'انتهت صلاحية الرمز، أعد الإرسال';
      case 'session-expired':
        return 'انتهت الجلسة، أعد المحاولة';
      // ─── Google-specific ───
      case 'account-exists-with-different-credential':
        return 'الحساب موجود بطريقة تسجيل مختلفة';
      case 'operation-not-allowed':
        return 'طريقة التسجيل غير مفعّلة في Firebase';
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