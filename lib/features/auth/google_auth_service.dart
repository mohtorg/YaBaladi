// lib/features/auth/google_auth_service.dart
//
// [v1.3 — 2026-11-05] — FIX: Prevented multiple GSI initializations on Web.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  // ✅ قفل لمنع التهيئة المتكررة (خاصة على الويب)
  static bool _isInitialized = false;

  Future<void> init() async {
    // إذا كنا على الويب، لا نحتاج لتهيئة GoogleSignIn الأصلي
    // لأننا نستخدم signInWithPopup الخاص بـ Firebase.
    if (kIsWeb) return;

    // إذا تمت التهيئة مسبقاً، لا تكررها
    if (_isInitialized) return;

    try {
      await _googleSignIn.isSignedIn();
      _isInitialized = true;
      debugPrint('✅ GoogleSignIn service is ready.');
    } catch (e) {
      debugPrint('❌ GoogleSignIn initialization failed: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // 🌐 بيئة الويب: استخدام Popup لتجنب تجميد التطبيق
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(authProvider);
      } else {
        // 📱 بيئة الهواتف
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          debugPrint('Google Sign-In cancelled by user.');
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }
}
