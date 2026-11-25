// lib/features/auth/controllers/auth_controller.dart
// [v5.2.3 — 2026-11-15] — LINTER FIX: Added curly braces to all `if` statements.
// [v5.2.2 — 2026-11-15] — FIX: Guarantee Firestore doc deletion before Auth deletion.
// [v5.2.1 — 2026-11-15] — FIX: Handle Google re-authentication for account deletion.
// [v5.2.0 — 2026-11-15] — AUTO-CREATE USER DOC

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/auth/role.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

const String _networkMessage = 'لا يوجد اتصال بالإنترنت أو حدث خطأ غير متوقع.';
const String _bannedMessage = 'عذراً، هذا الحساب محظور. يرجى التواصل مع الدعم.';

const Set<String> _cancelCodes = {
  'popup-closed-by-user',
  'cancelled-popup-request',
  'canceled',
  'web-context-canceled',
  'web-context-cancelled',
};

String _authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    case 'user-disabled':
      return 'هذا الحساب موقوف. تواصل مع الدعم.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
    case 'email-already-in-use':
      return 'هذا البريد مسجَّل مسبقاً.';
    case 'weak-password':
      return 'كلمة المرور ضعيفة. استعمل 6 أحرف على الأقل.';
    case 'too-many-requests':
      return 'محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة.';
    case 'network-request-failed':
      return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وأعد المحاولة.';
    case 'operation-not-allowed':
      return 'طريقة تسجيل الدخول هذه غير مفعّلة في Firebase.';
    case 'requires-recent-login':
      return 'انتهت الجلسة. سجّل الدخول مجدداً ثم أعد المحاولة.';
    default:
      return e.message ?? 'حدث خطأ';
  }
}

String _googleErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'network-request-failed':
      return 'لا يوجد اتصال بالإنترنت.';
    case 'popup-blocked':
      return 'المتصفح منع نافذة تسجيل الدخول.';
    case 'unauthorized-domain':
      return 'هذا النطاق غير مصرَّح به في Firebase.';
    case 'operation-not-allowed':
      return 'تسجيل الدخول بـ Google غير مفعّل في Firebase.';
    case 'account-exists-with-different-credential':
      return 'هذا البريد مسجَّل بطريقة أخرى.';
    case 'user-disabled':
      return 'هذا الحساب موقوف.';
    case 'too-many-requests':
      return 'محاولات كثيرة. انتظر قليلاً.';
    case 'invalid-app-info':
    case 'developer-error':
    case 'app-not-authorized':
    case 'invalid-api-key':
    case 'internal-error':
      return 'تعذر تسجيل الدخول بـ Google (كود: ${e.code}).';
    default:
      return 'تعذر تسجيل الدخول بـ Google (كود: ${e.code}).';
  }
}

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthStatus _status = AuthStatus.loading;
  User? _user;
  UserRole _role = UserRole.values.first;
  String? _placeId;
  bool _isGuest = false;
  bool _isDisposed = false;
  bool _isLoading = false;
  bool _isRoleReady = false;

  bool get isRoleReady => _isRoleReady;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _placeSubscription;
  String? _placeListenUid;

  AuthStatus get status => _status;
  User? get user => _user;
  UserRole get role => _role;
  UserRole get currentRole => _role;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get isMerchant => _role == UserRole.merchant;
  bool get isAdmin => _role == UserRole.admin;
  bool get isModerator => _role == UserRole.moderator;
  bool get hasPlace => _placeId != null;
  String? get placeId => _placeId;
  String get uid => _user?.uid ?? '';

  String get displayName {
    final dn = _user?.displayName;
    return (dn == null || dn.isEmpty) ? 'مستخدم' : dn;
  }

  String? get photoUrl => _user?.photoURL;

  bool get hasPasswordProvider =>
      _user?.providerData.any((p) => p.providerId == 'password') ?? false;
  bool get hasGoogleProvider =>
      _user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  AuthController() {
    _init();
  }

  Future<void> _init() async {
    _authSubscription = _auth.authStateChanges().listen(
      (User? user) async {
        if (user == null) {
          if (_isDisposed) {
            return;
          }
          if (_auth.currentUser == null) {
            _setUnauthenticated();
          }
        } else {
          _user = user;
          await _ensureUserDocExists(user);
          _status = AuthStatus.authenticated;
          _isGuest = false;
          _isRoleReady = false;
          _listenToUserRole(user.uid);
          _safeNotify();
        }
      },
      onError: (Object e) => debugPrint('AuthController auth stream error: $e'),
    );
  }

  Future<void> _ensureUserDocExists(User user) async {
    try {
      final docRef = _db.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'مستخدم',
          'role': 'user',
          'isBanned': false,
          'publishedRatingsCount': 0,
          'trustScore': 0.0,
          'hasConfirmedReports': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('AuthController _ensureUserDocExists error: $e');
    }
  }

  void _listenToUserRole(String uid) {
    _userSubscription?.cancel();
    _userSubscription =
        _db.collection('users').doc(uid).snapshots().listen((doc) async {
      if (doc.exists) {
        final data = doc.data() ?? {};
        if (data['isBanned'] == true) {
          await _auth.signOut();
          _setUnauthenticated();
          return;
        }
        final newRole = roleFromCode(data['role'] as String?);
        if (_role != newRole) {
          _role = newRole;
        }
        if (newRole == UserRole.merchant) {
          _listenToMerchantPlace(uid);
        } else {
          _stopMerchantPlaceListener();
        }
      } else {
        _role = UserRole.values.first;
        _stopMerchantPlaceListener();
      }
      if (_user?.uid == uid) {
        _isRoleReady = true;
        _safeNotify();
      }
    }, onError: (Object e) async {
      debugPrint('AuthController role stream error: $e');
      _role = UserRole.values.first;
      if (_user?.uid == uid) {
        _isRoleReady = true;
        _safeNotify();
      }
    });
  }

  void _stopMerchantPlaceListener() {
    _placeSubscription?.cancel();
    _placeSubscription = null;
    _placeListenUid = null;
    _placeId = null;
  }

  void _listenToMerchantPlace(String uid) {
    if (_placeSubscription != null && _placeListenUid == uid) {
      return;
    }
    _placeSubscription?.cancel();
    _placeListenUid = uid;
    _placeSubscription = _db
        .collection('places')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isNotEmpty) {
        final newPlaceId = snap.docs.first.id;
        if (_placeId != newPlaceId) {
          _placeId = newPlaceId;
          _safeNotify();
        }
      } else {
        if (_placeId != null) {
          _placeId = null;
          _safeNotify();
        }
      }
    },
            onError: (Object e) =>
                debugPrint('AuthController place stream error: $e'));
  }

  void continueAsGuest() {
    _userSubscription?.cancel();
    _userSubscription = null;
    _stopMerchantPlaceListener();
    _status = AuthStatus.unauthenticated;
    _isGuest = true;
    _user = null;
    _role = UserRole.values.first;
    _isRoleReady = true;
    _safeNotify();
  }

  Future<AuthResult> signInWithEmail(
      {required String email, required String password}) async {
    _isLoading = true;
    _safeNotify();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      if (cred.user != null) {
        await _ensureUserDocExists(cred.user!);
        final doc = await _db.collection('users').doc(cred.user!.uid).get();
        if (doc.exists && doc.data()?['isBanned'] == true) {
          await _auth.signOut();
          return AuthResult.failure(_bannedMessage);
        }
      }
      _isGuest = false;
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_authErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(_networkMessage);
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _safeNotify();
    UserCredential? cred;
    try {
      final cleanEmail = email.trim();
      cred = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail, password: password);
      try {
        await cred.user?.updateDisplayName(displayName);
        if (cred.user != null) {
          await _db.collection('users').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'email': cleanEmail,
            'name': displayName,
            'role': 'user',
            'isBanned': false,
            'publishedRatingsCount': 0,
            'trustScore': 0.0,
            'hasConfirmedReports': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } catch (e) {
        debugPrint('❌ Firestore write failed, rolling back: $e');
        try {
          await cred.user?.delete();
        } catch (rollbackErr) {
          debugPrint('⚠️ Rollback failed: $rollbackErr');
        }
        return AuthResult.failure(
            'تعذر إنشاء مستند المستخدم. تحقق من الاتصال وأعد المحاولة.');
      }
      _isGuest = false;
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_authErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(_networkMessage);
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    _isLoading = true;
    _safeNotify();
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_authErrorMessage(e));
    } catch (e) {
      return AuthResult.failure(_networkMessage);
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    _safeNotify();
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      googleProvider.setCustomParameters({'prompt': 'select_account'});
      final UserCredential userCredential;
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        userCredential = await _auth.signInWithProvider(googleProvider);
      }
      final user = userCredential.user;
      _isGuest = false;
      if (user != null) {
        try {
          final docRef = _db.collection('users').doc(user.uid);
          final doc = await docRef.get();
          if (doc.exists && doc.data()?['isBanned'] == true) {
            await _auth.signOut();
            return AuthResult.failure(_bannedMessage);
          }
          if (!doc.exists) {
            await docRef.set({
              'uid': user.uid,
              'email': user.email,
              'name': user.displayName ?? 'مستخدم',
              'role': 'user',
              'isBanned': false,
              'publishedRatingsCount': 0,
              'trustScore': 0.0,
              'hasConfirmedReports': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (e) {
          debugPrint('⚠️ Firestore user doc sync failed (continuing): $e');
        }
      }
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'FirebaseAuthException in Google Sign In: ${e.code} - ${e.message}');
      if (_cancelCodes.contains(e.code)) {
        return AuthResult.cancelled(
            'لم يكتمل تسجيل الدخول. تأكد من الاتصال بالإنترنت.');
      }
      return AuthResult.failure(_googleErrorMessage(e));
    } catch (e) {
      debugPrint('Unexpected error in Google Sign In: $e');
      return AuthResult.failure(_networkMessage);
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _setUnauthenticated();
  }

  Future<AuthResult> deleteAccount({String? password}) async {
    final user = _auth.currentUser ?? _user;
    if (user == null) {
      return AuthResult.failure('لا يوجد مستخدم مسجل الدخول.');
    }

    _isLoading = true;
    _safeNotify();

    try {
      final email = user.email;
      final hasGoogle =
          user.providerData.any((p) => p.providerId == 'google.com');
      final hasPassword =
          user.providerData.any((p) => p.providerId == 'password');

      if (hasPassword &&
          password != null &&
          password.isNotEmpty &&
          email != null) {
        final cred =
            EmailAuthProvider.credential(email: email, password: password);
        await user.reauthenticateWithCredential(cred);
      } else if (hasGoogle) {
        final last = user.metadata.lastSignInTime;
        final recent =
            last != null && DateTime.now().difference(last).inMinutes < 4;
        if (!recent) {
          final provider = GoogleAuthProvider()
            ..setCustomParameters({'prompt': 'select_account'});
          if (kIsWeb) {
            await user.reauthenticateWithPopup(provider);
          } else {
            await user.reauthenticateWithProvider(provider);
          }
        }
      }

      try {
        await _db.collection('users').doc(user.uid).delete();
        debugPrint('✅ User Firestore document deleted successfully.');
      } catch (e) {
        debugPrint('❌ Failed to delete Firestore document: $e');
        return AuthResult.failure(
          'تعذر حذف بيانات المستخدم من قاعدة البيانات. يرجى المحاولة مرة أخرى أو التواصل مع الدعم.',
        );
      }

      await user.delete();
      _setUnauthenticated();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) {
        return AuthResult.cancelled('أُلغيت عملية التحقق. لم يُحذف الحساب.');
      }
      if (e.code == 'requires-recent-login') {
        return AuthResult.failure(
            'انتهت الجلسة. يرجى إعادة تسجيل الدخول والمحاولة مجدداً.');
      }
      return AuthResult.failure(_authErrorMessage(e));
    } catch (e) {
      debugPrint('AuthController deleteAccount error: $e');
      return AuthResult.failure('تعذر حذف الحساب. أعد المحاولة.');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void _setUnauthenticated() {
    _userSubscription?.cancel();
    _stopMerchantPlaceListener();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _role = UserRole.values.first;
    _isRoleReady = true;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    _userSubscription?.cancel();
    _placeSubscription?.cancel();
    super.dispose();
  }
}

class AuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? error;

  AuthResult._({required this.isSuccess, this.isCancelled = false, this.error});

  factory AuthResult.success() => AuthResult._(isSuccess: true);

  factory AuthResult.failure(String error) =>
      AuthResult._(isSuccess: false, error: error);

  factory AuthResult.cancelled([String? message]) => AuthResult._(
        isSuccess: false,
        isCancelled: true,
        error: message ?? 'أُلغي تسجيل الدخول.',
      );
}
