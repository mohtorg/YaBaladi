// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';
import '../core/auth/role.dart'; // ✅ إضافة الاستيراد المفقود

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<AppUser?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      if (firebaseUser == null) return null;

      return await _syncUserWithFirestore(firebaseUser);
    } catch (e) {
      debugPrint('❌ Error in signInWithGoogle: $e');
      return null;
    }
  }

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
      debugPrint('❌ Error syncing user: $e');
      await _auth.signOut();
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ Error during Google SignOut: $e');
    }
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return null;
      }
      return AppUser.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('❌ Error getting current user data: $e');
      await _auth.signOut();
      return null;
    }
  }
}
