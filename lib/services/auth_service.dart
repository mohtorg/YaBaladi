// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../core/auth/role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Web Client ID (إجباري لجوالات Android/iOS للحصول على idToken)
  static const String _webClientId =
      '231838490815-ivkqvuc58t65p2riietbiqcecdhb27se.apps.googleusercontent.com';

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    // على الويب لا نستخدم هذه الحزمة، نمرر null. على الجوال نمرر الـ Web ID
    serverClientId: kIsWeb ? null : _webClientId,
    scopes: const ['email', 'profile', 'openid'],
  );

  // ═══════════════════════════════════════════════════════════════
  // Google Sign-In (Designed for All Devices)
  // ═══════════════════════════════════════════════════════════════
  Future<AppUser?> signInWithGoogle() async {
    try {
      // ─────────────────────────────────────────────────────────────
      // 🌐 1. منطق الويب (Flutter Web)
      // ─────────────────────────────────────────────────────────────
      if (kIsWeb) {
        debugPrint('🌐 تسجيل الدخول عبر Google (Web) - Popup');
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.setCustomParameters({'prompt': 'select_account'});

        final userCredential = await _auth.signInWithPopup(googleProvider);
        final firebaseUser = userCredential.user;

        if (firebaseUser == null) return null;
        return await _syncUserWithFirestore(firebaseUser);
      }

      // ─────────────────────────────────────────────────────────────
      // 📱 2. منطق الجوال (Android / iOS)
      // ─────────────────────────────────────────────────────────────
      debugPrint('📱 تسجيل الدخول عبر Google (Mobile) - google_sign_in');

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('ℹ️ المستخدم ألغى عملية تسجيل الدخول');
        return null;
      }

      final googleAuth = await googleUser.authentication;
      debugPrint(
        '🔍 Google Auth: idToken=${googleAuth.idToken != null}, '
        'accessToken=${googleAuth.accessToken != null}',
      );

      // التحقق الإجباري من الـ idToken
      if (googleAuth.idToken == null) {
        debugPrint('❌ خطأ حرج: idToken = null');
        debugPrint(
            '🔴 تأكد من إضافة بصمة SHA-1 الخاصة بـ FlutLab أو جهازك إلى Firebase.');
        throw Exception(
            'فشل الحصول على idToken. تحقق من إعدادات SHA-1 في Firebase.');
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) return null;
      return await _syncUserWithFirestore(firebaseUser);
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ FirebaseAuthException: ${e.code} — ${e.message}');
      rethrow; // نرمي الخطأ للواجهة لعرضه للمستخدم
    } catch (e) {
      debugPrint('❌ خطأ غير متوقع في Google Sign-In: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Email / Password Sign-In
  // ═══════════════════════════════════════════════════════════════
  Future<AppUser?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;
      return await _syncUserWithFirestore(firebaseUser);
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ خطأ غير متوقع في signInWithEmail: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Register
  // ═══════════════════════════════════════════════════════════════
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      await firebaseUser.updateDisplayName(displayName.trim());
      await firebaseUser.reload();

      final appUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email,
        displayName: displayName.trim(),
        photoUrl: firebaseUser.photoURL,
        role: UserRole.member,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(appUser.toMap());
      return appUser;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint('❌ خطأ غير متوقع في signUpWithEmail: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Helpers & Utilities
  // ═══════════════════════════════════════════════════════════════
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('لا يوجد مستخدم مسجل');

    final hasPassword =
        user.providerData.any((p) => p.providerId == 'password');
    if (hasPassword && (password == null || password.isEmpty)) {
      throw Exception('كلمة المرور مطلوبة لحذف الحساب');
    }

    try {
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      debugPrint('✅ تم حذف الحساب بنجاح');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('يرجى تسجيل الدخول مرة أخرى ثم إعادة المحاولة');
      }
      rethrow;
    }
  }

  bool get currentUserHasPasswordProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  bool get currentUserHasGoogleProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData
        .any((p) => p.providerId == 'google.com' || p.providerId == 'google');
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('⚠️ Google SignOut: $e');
    }
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> _syncUserWithFirestore(User firebaseUser) async {
    try {
      final docRef = _firestore.collection('users').doc(firebaseUser.uid);
      final docSnap = await docRef.get();

      AppUser appUser;
      if (!docSnap.exists) {
        appUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? 'مستخدم جديد',
          photoUrl: firebaseUser.photoURL,
          role: UserRole.member,
          createdAt: DateTime.now(),
        );
        await docRef.set(appUser.toMap());
      } else {
        appUser = AppUser.fromMap(docSnap.id, docSnap.data()!);
      }
      return appUser;
    } catch (e) {
      debugPrint('❌ خطأ في مزامنة المستخدم: $e');
      await _auth.signOut();
      return null;
    }
  }

  Future<AppUser?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('❌ خطأ: $e');
      return null;
    }
  }
}
