// lib/features/auth/controllers/auth_controller.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/auth/role.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  AuthStatus _status = AuthStatus.loading;
  User? _user;
  UserRole _role = UserRole.values.first;
  String? _placeId;
  bool _isGuest = false;
  bool _isDisposed = false;
  bool _isLoading = false;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _placeSubscription;

  // ─── Getters ───
  AuthStatus get status => _status;
  User? get user => _user;
  UserRole get role => _role;
  UserRole get currentRole => _role;
  bool get isGuest => _isGuest;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get isMerchant => _role.name == 'merchant';
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
        final newRoleStr = data['role'] as String? ?? 'user';
        final newRole = UserRole.values.firstWhere(
          (e) => e.name == newRoleStr,
          orElse: () => UserRole.values.first,
        );
        if (_role != newRole) {
          _role = newRole;
          _safeNotify();
        }
        if (newRole.name == 'merchant') {
          _listenToMerchantPlace(uid);
        } else {
          _placeId = null;
          _placeSubscription?.cancel();
        }
      }
    });
  }

  void _listenToMerchantPlace(String uid) {
    _placeSubscription?.cancel();
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
        _placeId = null;
        _safeNotify();
      }
    });
  }

  void continueAsGuest() {
    _status = AuthStatus.unauthenticated;
    _isGuest = true;
    _user = null;
    _safeNotify();
  }

  // ✅ [FIX v5.0] جميع الدوال ترجع AuthResult لتتوافق مع الشاشات
  Future<AuthResult> signInWithEmail(
      {required String email, required String password}) async {
    _isLoading = true;
    _safeNotify();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _isGuest = false;
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'حدث خطأ');
    } catch (e) {
      return AuthResult.failure(e.toString());
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
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      await cred.user?.updateDisplayName(displayName);
      if (cred.user != null) {
        await _db.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'email': email,
          'name': displayName,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'حدث خطأ');
    } catch (e) {
      return AuthResult.failure(e.toString());
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<AuthResult> resetPassword(String email) async {
    _isLoading = true;
    _safeNotify();
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(e.message ?? 'حدث خطأ');
    } catch (e) {
      return AuthResult.failure(e.toString());
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    _isLoading = true;
    _safeNotify();
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.cancelled();

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      _isGuest = false;

      final user = userCredential.user;
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
    } catch (e) {
      return AuthResult.failure(e.toString());
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    _setUnauthenticated();
  }

  Future<AuthResult> deleteAccount({String? password}) async {
    try {
      if (password != null && _user?.email != null) {
        final cred = EmailAuthProvider.credential(
            email: _user!.email!, password: password);
        await _user?.reauthenticateWithCredential(cred);
      }
      await _user?.delete();
      _setUnauthenticated();
      return AuthResult.success();
    } catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  void _setUnauthenticated() {
    _userSubscription?.cancel();
    _placeSubscription?.cancel();
    _user = null;
    _placeId = null;
    _status = AuthStatus.unauthenticated;
    _isGuest = false;
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
  factory AuthResult.cancelled() =>
      AuthResult._(isSuccess: false, isCancelled: true);
}
