// lib/features/notifications/services/fcm_service.dart
//
// [v1.1.1 — 2026-11-01] — ANALYZER FIX: Removed unnecessary firebase_core import.
//   - FIXED: 'Unnecessary import' warning.
//   - KEPT: All FCM logic and permission handling.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  FcmService._(); // Private constructor

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static bool _isInitialized = false;

  /// يتم استدعاؤها مرة واحدة عند تسجيل دخول المستخدم
  static Future<void> initialize(String userId) async {
    if (_isInitialized || userId.isEmpty) return;
    _isInitialized = true;

    try {
      // 1. طلب الإذن (خاص بـ iOS، ولأندرويد 13+)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // ✅ v1.1 FIX: التحقق من حالة الإذن قبل المتابعة
      // إذا رفض المستخدم، لا نحاول جلب التوكن لتجنب خطأ permission-blocked
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
            '⚠️ Notification permission denied by user. Skipping token fetch.');
        return;
      }

      // 2. جلب الـ Token الحالي وحفظه في Firestore
      await _saveTokenToFirestore(userId);

      // 3. الاستماع لتحديث الـ Token (قد يتغير في أي وقت)
      _fcm.onTokenRefresh.listen((newToken) async {
        await _saveTokenToFirestore(userId, token: newToken);
      });

      // 4. التعامل مع الإشعارات عند وصولها (والتطبيق مفتوح)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 Foreground message: ${message.notification?.title}');
        // هنا يمكن عرض SnackBar أو إشعار محلي
      });

      // 5. التعامل مع النقر على الإشعار (والتطبيق في الخلفية)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('👆 User tapped notification (Background)');
        debugPrint('Data: ${message.data}');
      });

      // 6. التعامل مع الإشعار الذي فتح التطبيق من حالة الإغلاق التام
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 App opened from terminated state via notification');
        debugPrint('Data: ${initialMessage.data}');
      }
    } catch (e) {
      debugPrint('❌ FCM Initialization Error: $e');
    }
  }

  /// حفظ الـ FCM Token في مستند المستخدم في Firestore
  static Future<void> _saveTokenToFirestore(String userId,
      {String? token}) async {
    try {
      final fcmToken = token ?? await _fcm.getToken();
      if (fcmToken == null) return;

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ FCM Token saved for user $userId');
    } on FirebaseException catch (e) {
      // ✅ v1.1 FIX: معالجة صامتة لخطأ permission-blocked
      // يحدث هذا إذا رفض المستخدم الإذن من إعدادات الهاتف سابقاً
      if (e.code == 'permission-blocked') {
        debugPrint(
            '⚠️ FCM token fetch blocked: Permission denied in device settings.');
      } else {
        debugPrint('❌ Failed to save FCM token: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }

  /// إعادة تعيين الحالة (عند تسجيل الخروج، حتى يمكن التهيئة مرة أخرى)
  static void reset() {
    _isInitialized = false;
  }
}
