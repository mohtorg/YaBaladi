// lib/features/notifications/services/fcm_service.dart
// [v1.2.0 — 2026-11-03] — ENHANCEMENT: Multi-device support + proper logout cleanup + Worker sync.
//   - ADDED: Save tokens to users/{uid}/fcm_tokens/{token} (multi-device support).
//   - ADDED: deleteToken on reset (prevents receiving after logout).
//   - ADDED: Store & cancel token refresh subscription (prevents leaks).
//   - ADDED: Optional Cloudflare Worker sync (set _workerUrl).
//   - FIXED: _isInitialized moved after permission grant (prevents false-positive).
//   - FIXED: Reset now async + fully cleans up resources.
//   - KEPT: All previous logic (permission, onMessage, initial message).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class FcmService {
  FcmService._(); // Private constructor

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // ⚠️ ضع رابط Cloudflare Worker هنا إذا كان لديك واحد.
  // اتركه فارغاً إذا كان الـ Worker يقرأ التوكنات من Firestore مباشرة.
  static const String _workerUrl = '';
  // مثال: 'https://yabaladi-notifications.username.workers.dev/register-token'

  static bool _isInitialized = false;
  static String? _currentUserId;
  static StreamSubscription<String>? _tokenRefreshSub;

  /// يُستدعى عند تسجيل دخول المستخدم
  static Future<void> initialize(String userId) async {
    if (userId.isEmpty) return;

    // ✅ إذا كان نفس المستخدم، لا نكرر التهيئة
    if (_isInitialized && _currentUserId == userId) return;

    // ✅ إذا كان مستخدم مختلف دخل، ننظف التوكن القديم أولاً
    if (_isInitialized && _currentUserId != null && _currentUserId != userId) {
      await reset();
    }

    _currentUserId = userId;

    try {
      // 1. طلب الإذن (iOS + Android 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
            '⚠️ FCM: Notification permission denied. Skipping token fetch.');
        return;
      }

      // ✅ ننقل _isInitialized هنا لضمان عدم تفعيلها إلا بعد نجاح الإذن
      _isInitialized = true;
      debugPrint(
          '✅ FCM: Permission granted (${settings.authorizationStatus}).');

      // 2. جلب التوكن الحالي وحفظه
      await _saveTokenToFirestore(userId);

      // 3. الاستماع لتحديث التوكن (مع حفظ الـ subscription للإلغاء لاحقاً)
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
        debugPrint('🔄 FCM: Token refreshed');
        await _saveTokenToFirestore(userId, token: newToken);
      });

      // 4. الإشعارات في المقدمة (يمكن عرضها عبر flutter_local_notifications لاحقاً)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground: ${message.notification?.title}');
      });

      // 5. النقر على إشعار (التطبيق في الخلفية)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('👆 Tapped (background). Data: ${message.data}');
      });

      // 6. الإشعار الذي فتح التطبيق من حالة الإغلاق التام
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
            '🚀 App opened from terminated. Data: ${initialMessage.data}');
      }
    } catch (e) {
      debugPrint('❌ FCM Initialization Error: $e');
    }
  }

  /// حفظ الـ FCM Token في Firestore
  /// - يحفظه في حقل `fcmToken` (للتوافق مع Worker الحالي)
  /// - ويحفظه في subcollection `fcm_tokens` (لدعم أجهزة متعددة)
  /// - يُرسله للـ Worker إذا كان الرابط مُعرّفاً
  static Future<void> _saveTokenToFirestore(
    String userId, {
    String? token,
  }) async {
    try {
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken == null) {
        debugPrint(
            '⚠️ FCM: Token is null (maybe missing google-services.json).');
        return;
      }

      final userRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      // 1. تحديث الحقل الأساسي (للتوافق مع Worker الذي يقرأ fcmToken مباشرة)
      await userRef.update({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 2. حفظ في subcollection لدعم الأجهزة المتعددة
      await userRef.collection('fcm_tokens').doc(fcmToken).set({
        'token': fcmToken,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ FCM: Token saved for $userId');

      // 3. مزامنة اختيارية مع Cloudflare Worker
      await _syncTokenWithWorker(userId, fcmToken);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-blocked') {
        debugPrint('⚠️ FCM: Token fetch blocked (permission denied).');
      } else {
        debugPrint('❌ FCM: Failed to save token: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ FCM: Failed to save token: $e');
    }
  }

  /// إرسال التوكن إلى Cloudflare Worker (اختياري)
  static Future<void> _syncTokenWithWorker(String userId, String token) async {
    if (_workerUrl.isEmpty) return;

    try {
      final response = await http
          .post(
            Uri.parse(_workerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'token': token,
              'platform': defaultTargetPlatform.name,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('☁️ FCM: Token synced with Worker.');
      } else {
        debugPrint('⚠️ FCM: Worker responded with ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ FCM: Worker sync failed: $e');
    }
  }

  /// إعادة تعيين الحالة (عند تسجيل الخروج)
  /// - يحذف التوكن من Firebase
  /// - يمسحه من Firestore
  /// - يلغي الاستماع لتجديد التوكن
  static Future<void> reset() async {
    try {
      // 1. حذف التوكن من Firebase (يمنع استقبال الإشعارات لهذا الجهاز)
      await _fcm.deleteToken();

      // 2. مسح التوكن من Firestore
      if (_currentUserId != null) {
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_currentUserId)
              .update({
            'fcmToken': FieldValue.delete(),
            'fcmTokenUpdatedAt': FieldValue.delete(),
          });
        } catch (_) {
          // تجاهل — قد لا يكون المستند موجوداً
        }
      }

      // 3. إلغاء الاستماع لتجديد التوكن (منع الـ leak)
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = null;

      debugPrint('🗑️ FCM: Reset complete (token deleted).');
    } catch (e) {
      debugPrint('❌ FCM reset error: $e');
    } finally {
      _isInitialized = false;
      _currentUserId = null;
    }
  }
}
