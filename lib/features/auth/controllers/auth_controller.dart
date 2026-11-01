// lib/features/auth/controllers/auth_controller.dart
//
// [v4.7 — 2026-10-29] — FIX (مراجعة وتصويب، بدون تغيير الواجهة العامة):
//   - الدور: استعمال roleFromCode بدل UserRole.values.firstWhere؛ كان 'user' المخزَّن في
//     Firestore لا يطابق أي اسم في التعداد (member) فيتحول كل مستخدم إلى visitor.
//   - رسائل الأخطاء: تحويل رموز FirebaseAuthException إلى رسائل عربية مناسبة
//     (لم تعد كل أخطاء Google تعرض «تأكد من بصمة التطبيق»).
//   - إلغاء المستخدم لنافذة Google (popup-closed-by-user وغيرها) يُعاد كـ AuthResult.cancelled
//     برسالة محايدة، وبقي الحقل error غير null حتى لا ينهار أي مستدعٍ يقرؤه.
//   - _listenToMerchantPlace: لم يعد يُعاد الاشتراك عند كل تحديث لمستند المستخدم + معالجة الأخطاء.
//   - deleteAccount: إعادة مصادقة مستخدم Google عند الحاجة، وحذف مستند users/{uid}، ورسائل واضحة.
//   - قص (trim) البريد الإلكتروني في تسجيل الدخول والتسجيل واستعادة كلمة المرور.
//   - isMerchant/isAdmin/isModerator: مقارنة بالتعداد بدل مقارنة النصوص.
// [v4.6 — 2026-10-29] — LINT FIX: remove redundant material.dart import.
//   foundation.dart already exports ChangeNotifier, debugPrint, kIsWeb.
// [v4.5 — 2026-10-28] — FIX: Remove google_sign_in package, use Firebase signInWithProvider

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // ChangeNotifier + debugPrint + kIsWeb

import '../../../core/auth/role.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

// ═══════════════════════════════════════════════════════════════
// Error messages (Arabic)
// ═══════════════════════════════════════════════════════════════

const String _networkMessage = 'لا يوجد اتصال بالإنترنت أو حدث خطأ غير متوقع.';

/// رموز تعني أن المستخدم أغلق نافذة تسجيل الدخول أو ألغاها.
const Set<String> _cancelCodes = {
  'popup-closed-by-user',
  'cancelled-popup-request',
  'canceled',
  'web-context-canceled',
  'web-context-cancelled',
};

/// رسائل عامة لأخطاء المصادقة (بريد/كلمة مرور وغيرها).
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

/// رسائل خاصة بتسجيل الدخول عبر Google.
String _googleErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'network-request-failed':
      return 'لا يوجد اتصال بالإنترنت. تحقق من الشبكة وأعد المحاولة.';
    case 'popup-blocked':
      return 'المتصفح منع نافذة تسجيل الدخول. اسمح بالنوافذ المنبثقة ثم أعد المحاولة.';
    case 'unauthorized-domain':
      return 'هذا النطاق غير مصرَّح به في Firebase (Authentication ← Authorized domains).';
    case 'operation-not-allowed':
      return 'تسجيل الدخول بـ Google غير مفعّل في Firebase (Authentication ← Sign-in method).';
    case 'account-exists-with-different-credential':
      return 'هذا البريد مسجَّل بطريقة أخرى. سجّل الدخول بالطريقة الأصلية، '
          'ثم اربط Google من الإعدادات.';
    case 'user-disabled':
      return 'هذا الحساب موقوف. تواصل مع الدعم.';
    case 'too-many-requests':
      return 'محاولات كثيرة. انتظر قليلاً ثم أعد المحاولة.';
    case 'invalid-app-info':
    case 'developer-error':
    case 'app-not-authorized':
    case 'invalid-api-key':
    case 'internal-error':
      return 'تعذر تسجيل الدخول بـ Google (كود: ${e.code}).\n'
          'تأكد من بصمة التطبيق (SHA-1 / SHA-256) وملف google-services.json في Firebase.';
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

  /// الـ uid الذي يُستمع حالياً لمكانه (لتفادي إعادة الاشتراك بلا داعٍ).
  String? _placeListenUid;

  // ─── Getters ───
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
  String get displayName => _user?.displayName ?? 'مستخدم';
  String? get photoUrl => _user?.photoURL;

  bool get hasPasswordProvider =>
      _user?.providerData.any((p) => p.providerId == 'password') ?? false;
  bool get hasGoogleProvider =>
      _user?.providerData.any((p) => p.providerId == 'google.com') ?? false;

  AuthController() {
    _init();
  }

  Future<void> _init() async {
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _setUnauthenticated();
      } else {
        _user = user;
        _status = AuthStatus.authenticated;
        _isGuest = false;
        _isRoleReady = false;
        _listenToUserRole(user.uid);
        _safeNotify();
      }
    });
  }

  void _listenToUserRole(String uid) {
    _userSubscription?.cancel();
    _userSubscription =
        _db.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data() ?? {};
        // roleFromCode يقبل 'user' كمرادف لـ member، ويعيد member لأي قيمة غير معروفة.
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
      _isRoleReady = true;
      _safeNotify();
    }, onError: (Object e) {
      debugPrint('AuthController role stream error: $e');
      _role = UserRole.values.first;
      _isRoleReady = true;
      _safeNotify();
    });
  }

  void _stopMerchantPlaceListener() {
    _placeSubscription?.cancel();
    _placeSubscription = null;
    _placeListenUid = null;
    _placeId = null;
  }

  void _listenToMerchantPlace(String uid) {
    // اشتراك قائم لنفس المستخدم: لا حاجة لإعادته عند كل تحديث لمستند المستخدم.
    if (_placeSubscription != null && _placeListenUid == uid) return;

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
    }, onError: (Object e) {
      debugPrint('AuthController place stream error: $e');
    });
  }

  void continueAsGuest() {
    _status = AuthStatus.unauthenticated;
    _isGuest = true;
    _user = null;
    _isRoleReady = true;
    _safeNotify();
  }

  Future<AuthResult> signInWithEmail(
      {required String email, required String password}) async {
    _isLoading = true;
    _safeNotify();
    try {
      await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
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
    try {
      final cleanEmail = email.trim();
      final cred = await _auth.createUserWithEmailAndPassword(
          email: cleanEmail, password: password);
      await cred.user?.updateDisplayName(displayName);
      if (cred.user != null) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': cleanEmail,
          'name': displayName,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
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

  // ✅ الطريقة الأصلية لـ Firebase (بدون google_sign_in package)
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
        final docRef = _db.collection('users').doc(user.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'uid': user.uid,
            'email': user.email,
            'name': user.displayName ?? 'مستخدم',
            'role': 'user',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      debugPrint(
          'FirebaseAuthException in Google Sign In: ${e.code} - ${e.message}');
      if (_cancelCodes.contains(e.code)) {
        // نافذة Google أُغلقت قبل الاكتمال (من المستخدم، أو لعدم وجود اتصال،
        // أو لأن المتصفح منعها): ليست خطأ في إعدادات التطبيق.
        return AuthResult.cancelled(
          'لم يكتمل تسجيل الدخول. تأكد من الاتصال بالإنترنت ومن السماح '
          'بالنوافذ المنبثقة، ثم أعد المحاولة.',
        );
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

    try {
      final email = user.email;
      final hasGoogle =
          user.providerData.any((p) => p.providerId == 'google.com');

      if (password != null && email != null) {
        final cred =
            EmailAuthProvider.credential(email: email, password: password);
        await user.reauthenticateWithCredential(cred);
      } else if (hasGoogle) {
        // مستخدم Google: نعيد المصادقة إلا إذا كان دخوله حديثاً جداً.
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

      // حذف مستند المستخدم قبل حذف حساب Auth (القواعد تتطلب أن يكون المستخدم مسجلاً).
      try {
        await _db.collection('users').doc(user.uid).delete();
      } catch (e) {
        debugPrint('AuthController: users doc delete failed (continuing): $e');
      }

      await user.delete();
      _setUnauthenticated();
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) {
        return AuthResult.cancelled('أُلغيت عملية التحقق. لم يُحذف الحساب.');
      }
      return AuthResult.failure(_authErrorMessage(e));
    } catch (e) {
      debugPrint('AuthController deleteAccount error: $e');
      return AuthResult.failure('تعذر حذف الحساب. أعد المحاولة.');
    }
  }

  void _setUnauthenticated() {
    _userSubscription?.cancel();
    _stopMerchantPlaceListener();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _isGuest = false;
    _isRoleReady = true;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
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

  /// إلغاء من المستخدم؛ [message] رسالة محايدة تُعرض إن لم يعالج المستدعي الإلغاء.
  factory AuthResult.cancelled([String? message]) => AuthResult._(
        isSuccess: false,
        isCancelled: true,
        error: message ?? 'أُلغي تسجيل الدخول.',
      );
}
