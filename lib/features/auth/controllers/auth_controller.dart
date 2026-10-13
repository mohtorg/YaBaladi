import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint, ChangeNotifier;
import 'package:google_sign_in/google_sign_in.dart';

/// Web Client ID من Firebase Console
/// (Authentication → Sign-in method → Google → Web SDK configuration)
const String _webGoogleClientId =
    '231838490815-ivkqvuc58t65p2riietbiqcecdhb27se.apps.googleusercontent.com';

/// نتيجة عملية Auth (نجاح/فشل مع رسالة خطأ)
class AuthResult {
  const AuthResult.success()
      : error = null,
        isSuccess = true;
  const AuthResult.failure(this.error) : isSuccess = false;

  final String? error;
  final bool isSuccess;
}

/// v1.4 — [2026-10-13] — requires-recent-login handling
///   - Added: deleteAccount() — Firestore data first, then Auth user
///   - Added: requires-recent-login mapping in _mapAuthError
///   - FIX: deleteAccount() forces _user=null + notifyListeners on success
///   - FIX: signOut() forces _user=null as safety net
///   - FIX: dispose() nullifies _userSub
///   - NEW: pre-check lastSignInTime before delete — fail fast with clear msg
///   - NEW: explicit try/catch around currentUser.delete() with logging
///
/// يغلّف Firebase Auth + Firestore user profile
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
  String? get photoUrl => _user?.photoURL;

  // ============================================================
  // INIT
  // ============================================================

  void _initFirebase() {
    try {
      _auth = _injectedAuth ?? FirebaseAuth.instance;
      _firestore = _injectedFirestore ?? FirebaseFirestore.instance;

      _googleSignIn = _injectedGoogleSignIn ??
          GoogleSignIn(
            clientId: kIsWeb ? _webGoogleClientId : null,
          );

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
  // GOOGLE SIGN IN
  // ============================================================

  Future<AuthResult> signInWithGoogle() async {
    if (_auth == null || _googleSignIn == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    _setLoading(true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

      if (googleUser == null) {
        return const AuthResult.failure('تم إلغاء تسجيل الدخول');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth!.signInWithCredential(credential);
      final user = userCredential.user;

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
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    if (_auth == null) {
      _user = null;
      _isGuest = false;
      notifyListeners();
      return;
    }

    _setLoading(true);
    try {
      try {
        await _googleSignIn?.signOut();
      } catch (_) {}
      await _auth!.signOut();
    } finally {
      _user = null;
      _isGuest = false;
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============================================================
  // DELETE ACCOUNT
  // ============================================================

  /// عمر تسجيل الدخول المسموح به قبل الحذف.
  /// Firebase Web يفرض نافذة recent-login. نستخدم 4 دقائق كهامش أمان.
  static const Duration _maxSignInAge = Duration(minutes: 4);

  /// يحذف حساب المستخدم نهائياً:
  ///   1) pre-check: عمر تسجيل الدخول
  ///   2) Firestore data (favorites + user doc)
  ///   3) Google sign-out
  ///   4) Firebase Auth delete + signOut
  ///   5) force local state
  ///
  /// **مهم:** Firestore قبل Auth مقصود — بعد حذف Auth
  /// لا يمكن الكتابة في Firestore (Security Rules سترفض).
  Future<AuthResult> deleteAccount() async {
    if (_auth == null || _firestore == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    final currentUser = _user;
    if (currentUser == null) {
      return const AuthResult.failure('لا يوجد مستخدم مسجّل');
    }

    // ── 0) pre-check: عمر تسجيل الدخول ──
    // يمنع محاولة delete() ستفشل حتماً بسبب requires-recent-login.
    final lastSignIn = currentUser.metadata.lastSignInTime;
    if (lastSignIn != null) {
      final age = DateTime.now().difference(lastSignIn);
      if (age > _maxSignInAge) {
        debugPrint(
          'deleteAccount: sign-in age ${age.inMinutes}m > '
          '${_maxSignInAge.inMinutes}m → requires-recent-login',
        );
        return const AuthResult.failure(
          'لأسباب أمنية، يجب تسجيل الدخول مرة أخرى قبل الحذف.\n'
          'اخرج من الحساب ثم ادخل مجدداً وأعد المحاولة.',
        );
      }
    }

    _setLoading(true);
    try {
      final uid = currentUser.uid;

      // ── 1) حذف مفضلة المستخدم (subcollection) ──
      try {
        final favsSnap = await _firestore!
            .collection('users')
            .doc(uid)
            .collection('favorites')
            .get();

        if (favsSnap.docs.isNotEmpty) {
          final batch = _firestore!.batch();
          for (final doc in favsSnap.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }
      } catch (e) {
        debugPrint('deleteAccount: favorites cleanup failed ($e)');
      }

      // ── 2) حذف وثيقة المستخدم ──
      try {
        await _firestore!.collection('users').doc(uid).delete();
      } catch (e) {
        debugPrint('deleteAccount: user doc cleanup failed ($e)');
      }

      // ── 3) Google sign-out ──
      try {
        await _googleSignIn?.signOut();
      } catch (_) {}

      // ── 4) حذف حساب Firebase Auth ──
      try {
        await currentUser.delete();
      } on FirebaseAuthException catch (e) {
        debugPrint(
          'deleteAccount: currentUser.delete() failed '
          '${e.code} — ${e.message}',
        );
        return AuthResult.failure(_mapAuthError(e));
      }

      // ── 5) signOut + force state ──
      try {
        await _auth!.signOut();
      } catch (e) {
        debugPrint('deleteAccount: signOut failed ($e)');
      }

      _user = null;
      _isGuest = false;
      notifyListeners();

      return const AuthResult.success();
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      return const AuthResult.failure('حدث خطأ أثناء حذف الحساب');
    } finally {
      _setLoading(false);
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
      case 'account-exists-with-different-credential':
        return 'الحساب موجود بطريقة تسجيل مختلفة';
      case 'operation-not-allowed':
        return 'طريقة التسجيل غير مفعّلة في Firebase';
      case 'requires-recent-login':
        return 'لأسباب أمنية، يجب تسجيل الدخول مرة أخرى قبل الحذف.';
      case 'popup-closed-by-user':
        return 'تم إغلاق نافذة Google قبل الإكمال';
      case 'popup-blocked':
        return 'المتصفح منع النافذة — اسمح بالنوافذ المنبثقة';
      case 'cancelled-popup-request':
        return 'تم إلغاء الطلب';
      case 'unauthorized-domain':
        return 'النطاق غير مصرح في Firebase';
      default:
        return e.message ?? 'حدث خطأ أثناء المصادقة';
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    _userSub = null;
    super.dispose();
  }
}
