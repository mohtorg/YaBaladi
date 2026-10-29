// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../core/auth/role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Mapping from enum to Firestore string (rules use 'user', not 'member')
  static String _roleToFirestore(UserRole role) {
    switch (role) {
      case UserRole.visitor:
        // Visitors never persist a users/ doc; this is a safe fallback.
        return 'user';
      case UserRole.member:
        return 'user';
      case UserRole.merchant:
        return 'merchant';
      case UserRole.team:
        return 'team';
      case UserRole.manager:
        return 'manager';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.admin:
        return 'admin';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Google Sign-In — via Firebase's built-in provider
  // (no google_sign_in package)
  // ═══════════════════════════════════════════════════════════════
  Future<AppUser?> signInWithGoogle() async {
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});

      final UserCredential cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);

      final fbUser = cred.user;
      if (fbUser == null) return null;

      await fbUser.reload();
      // After reload() the cached user object may be replaced; read it again.
      return await _syncUserWithFirestore(_auth.currentUser ?? fbUser);
    } on FirebaseAuthException catch (e, st) {
      debugPrint('❌ Google Sign-In: ${e.code} — ${e.message}');
      if (e.code == 'account-exists-with-different-credential') {
        Error.throwWithStackTrace(
          FirebaseAuthException(
            code: e.code,
            message:
                'هذا البريد مسجَّل بطريقة أخرى. سجّل الدخول بالطريقة الأصلية، '
                'ثم اربط Google من الإعدادات.',
          ),
          st,
        );
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Email / Password
  // ═══════════════════════════════════════════════════════════════
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fbUser = cred.user;
    if (fbUser == null) return null;
    return await _syncUserWithFirestore(fbUser);
  }

  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fbUser = cred.user;
    if (fbUser == null) return null;

    try {
      await fbUser.updateDisplayName(displayName.trim());
      await fbUser.reload();

      final appUser = AppUser(
        uid: fbUser.uid,
        email: fbUser.email ?? email.trim(),
        displayName: displayName.trim(),
        photoUrl: fbUser.photoURL,
        role: UserRole.member,
        createdAt: DateTime.now(),
      );
      final payload = appUser.toMap();
      payload['role'] = _roleToFirestore(UserRole.member);
      await _firestore.collection('users').doc(fbUser.uid).set(payload);
      return appUser;
    } catch (e) {
      // Rollback: don't leave an orphaned Auth account without a doc.
      try {
        await fbUser.delete();
      } catch (_) {/* best-effort */}
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Utilities
  // ═══════════════════════════════════════════════════════════════
  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  bool get currentUserHasPasswordProvider =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  bool get currentUserHasGoogleProvider =>
      _auth.currentUser?.providerData
          .any((p) => p.providerId == 'google.com') ??
      false;

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ═══════════════════════════════════════════════════════════════
  // Delete account — reauthenticate → Firestore → Auth
  // ═══════════════════════════════════════════════════════════════
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('لا يوجد مستخدم مسجل الدخول.');

    final hasPassword =
        user.providerData.any((p) => p.providerId == 'password');
    final hasGoogle =
        user.providerData.any((p) => p.providerId == 'google.com');

    // Reauthenticate BEFORE touching Firestore, so a failure here never
    // leaves an Auth account without its users/ document.
    if (hasPassword) {
      if (password == null || password.isEmpty) {
        throw Exception('كلمة المرور مطلوبة لحذف الحساب.');
      }
      final email = user.email;
      if (email == null) {
        throw Exception('تعذّر قراءة بريد المستخدم.');
      }
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: password),
      );
    } else if (hasGoogle) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      if (kIsWeb) {
        await user.reauthenticateWithPopup(provider);
      } else {
        await user.reauthenticateWithProvider(provider);
      }
    }

    await _firestore.collection('users').doc(user.uid).delete();
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception(
          'انتهت الجلسة. سجّل الدخول مجدداً ثم أعد المحاولة.',
        );
      }
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Internal
  // ═══════════════════════════════════════════════════════════════
  Future<AppUser?> _syncUserWithFirestore(User fbUser) async {
    final docRef = _firestore.collection('users').doc(fbUser.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      final name = fbUser.displayName?.trim();
      final appUser = AppUser(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: (name == null || name.isEmpty) ? 'مستخدم جديد' : name,
        photoUrl: fbUser.photoURL,
        role: UserRole.member,
        createdAt: DateTime.now(),
      );
      final payload = appUser.toMap();
      payload['role'] = _roleToFirestore(UserRole.member);
      await docRef.set(payload);
      return appUser;
    }

    return AppUser.fromMap(docSnap.id, docSnap.data()!);
  }

  Future<AppUser?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('❌ getCurrentUserData: $e');
      return null;
    }
  }
}
