import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, debugPrint, ChangeNotifier;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/permissions.dart';
import '../../../core/auth/role.dart';

/// Web Client ID من Firebase Console
const String _webGoogleClientId =
    '231838490815-ivkqvuc58t65p2riietbiqcecdhb27se.apps.googleusercontent.com';

/// نتيجة عملية Auth (نجاح/فشل/إلغاء مع رسالة خطأ)
class AuthResult {
  const AuthResult.success()
      : error = null,
        isSuccess = true,
        isCancelled = false;
  const AuthResult.failure(this.error)
      : isSuccess = false,
        isCancelled = false;
  const AuthResult.cancelled()
      : error = null,
        isSuccess = false,
        isCancelled = true;

  final String? error;
  final bool isSuccess;
  final bool isCancelled;
}

/// v1.7 — [2026-10-14] — G4.1-c: Role-aware auth
///   - NEW: currentRole getter (UserRole)
///   - NEW: hasPermission(Permission) method
///   - NEW: isAdmin / isMerchant convenience getters
///   - NEW: _loadUserRole() — يقرأ users/{uid}.role من Firestore
///   - NEW: resetRole() — يستدعيه signOut / deleteAccount
///   - CHANGE: _onAuthStateChanged يستدعي _loadUserRole تلقائياً
///
/// v1.6 — [2026-10-14] — D4 full: re-auth حسب مزود الحساب
/// v1.5.1 — [2026-10-14] — D4 fix: nullable GoogleSignIn
/// v1.5 — [2026-10-14] — D4: Real re-authentication before delete
/// v1.4 — [2026-10-13] — requires-recent-login handling
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

  /// [v1.7] الدور الحالي للمستخدم.
  /// الافتراضي: visitor (زائر) عند عدم تسجيل الدخول.
  /// يُحدَّث تلقائياً من Firestore بعد المصادقة.
  UserRole _userRole = UserRole.visitor;

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

  // ─── [v1.7] Role & Permissions ───

  /// الدور الحالي. visitor عند عدم تسجيل الدخول.
  UserRole get currentRole {
    if (_user == null) return UserRole.visitor;
    return _userRole;
  }

  /// هل هو مسؤول كامل؟
  bool get isAdmin => currentRole == UserRole.admin;

  /// هل هو تاجر؟
  bool get isMerchant => currentRole == UserRole.merchant;

  /// هل يملك صلاحية محددة؟
  bool hasPermission(Permission permission) =>
      roleHasPermission(currentRole, permission);

  /// كل الصلاحيات الفعلية للمستخدم الحالي.
  Set<Permission> get permissions => defaultPermissionsFor(currentRole);

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

    // [v1.7] أعِد تعيين الدور عند تغيّر الحالة
    if (user == null) {
      _userRole = UserRole.visitor;
    } else {
      // مؤقتاً member حتى نقرأ من Firestore
      _userRole = UserRole.member;
      _loadUserRole(user.uid);
    }

    _isInitialized = true;
    notifyListeners();
  }

  /// [v1.7] يقرأ الدور من users/{uid}.role ويُحدِّث _userRole.
  Future<void> _loadUserRole(String userId) async {
    if (_firestore == null) return;
    try {
      final doc = await _firestore!.collection('users').doc(userId).get();
      final roleCode = doc.data()?['role'] as String?;
      final newRole = roleFromCode(roleCode);
      if (newRole != _userRole && _user?.uid == userId) {
        _userRole = newRole;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthController._loadUserRole failed: $e');
      // نُبقي _userRole = member (الافتراضي الآمن)
    }
  }

  /// [v1.7] يُصفِّر الدور — يُستخدَم قبل signOut / deleteAccount.
  void _resetRole() {
    _userRole = UserRole.visitor;
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
        return const AuthResult.cancelled();
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
      _resetRole();
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
      _resetRole();
      _setLoading(false);
      notifyListeners();
    }
  }

  // ============================================================
  // DELETE ACCOUNT (D4)
  // ============================================================

  /// [v1.5] إعادة التحقق من الهوية عبر Google popup.
  Future<AuthResult> _reauthenticateWithGoogle() async {
    if (_auth == null || _googleSignIn == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    final currentUser = _user;
    if (currentUser == null) {
      return const AuthResult.failure('لا يوجد مستخدم مسجّل');
    }

    final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();

    if (googleUser == null) {
      return const AuthResult.cancelled();
    }

    if (googleUser.email != currentUser.email) {
      debugPrint(
        'reauthenticate: account mismatch '
        '(${googleUser.email} vs ${currentUser.email})',
      );
      try {
        await _googleSignIn?.signOut();
      } catch (_) {}
      return const AuthResult.failure(
        'يجب استخدام نفس حساب Google المسجّل حالياً',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    await currentUser.reauthenticateWithCredential(credential);
    return const AuthResult.success();
  }

  /// [v1.5.1] Re-auth عبر Email/Password.
  Future<AuthResult> _reauthenticateWithPassword(String password) async {
    final currentUser = _user;
    if (currentUser == null) {
      return const AuthResult.failure('لا يوجد مستخدم مسجّل');
    }

    final email = currentUser.email;
    if (email == null || email.isEmpty) {
      return const AuthResult.failure('البريد الإلكتروني غير متوفر');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapAuthError(e));
    } catch (e) {
      debugPrint('reauthenticate (password) error: $e');
      return const AuthResult.failure('فشل التحقق من كلمة المرور');
    }
  }

  /// [v1.5.1] حذف الحساب مع re-auth إلزامي.
  Future<AuthResult> deleteAccount({String? password}) async {
    if (_auth == null || _firestore == null) {
      return const AuthResult.failure('Firebase غير متاح');
    }

    final currentUser = _user;
    if (currentUser == null) {
      return const AuthResult.failure('لا يوجد مستخدم مسجّل');
    }

    _setLoading(true);
    try {
      // ── 1) اختيار نوع re-auth حسب المزود ──
      AuthResult reauthResult;

      if (hasGoogleProvider) {
        reauthResult = await _reauthenticateWithGoogle();
      } else if (hasPasswordProvider) {
        if (password == null || password.isEmpty) {
          return const AuthResult.failure(
            'كلمة المرور مطلوبة لتأكيد الحذف',
          );
        }
        reauthResult = await _reauthenticateWithPassword(password);
      } else {
        return const AuthResult.failure(
          'طريقة تسجيل الدخول الحالية غير مدعومة للحذف.\n'
          'يرجى التواصل مع الدعم.',
        );
      }

      if (reauthResult.isCancelled) {
        return const AuthResult.cancelled();
      }
      if (!reauthResult.isSuccess) {
        return AuthResult.failure(
          reauthResult.error ?? 'فشل التحقق من الهوية',
        );
      }

      // ── 2) حذف مفضلة المستخدم ──
      final uid = currentUser.uid;
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

      // ── 3) حذف وثيقة المستخدم ──
      try {
        await _firestore!.collection('users').doc(uid).delete();
      } catch (e) {
        debugPrint('deleteAccount: user doc cleanup failed ($e)');
      }

      // ── 4) Google sign-out ──
      try {
        await _googleSignIn?.signOut();
      } catch (_) {}

      // ── 5) حذف حساب Firebase Auth ──
      try {
        await currentUser.delete();
      } on FirebaseAuthException catch (e) {
        debugPrint(
          'deleteAccount: currentUser.delete() failed '
          '${e.code} — ${e.message}',
        );
        return AuthResult.failure(_mapAuthError(e));
      }

      // ── 6) signOut + force state ──
      try {
        await _auth!.signOut();
      } catch (e) {
        debugPrint('deleteAccount: signOut failed ($e)');
      }

      _user = null;
      _isGuest = false;
      _resetRole();
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
  // PROVIDER DETECTION (D4)
  // ============================================================

  /// هل الحساب مسجَّل عبر Google؟
  bool get hasGoogleProvider =>
      _user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  /// هل الحساب مسجَّل عبر Email/Password؟
  bool get hasPasswordProvider =>
      _user?.providerData.any((p) => p.providerId == 'password') ?? false;

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
