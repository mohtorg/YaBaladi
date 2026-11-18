// lib/core/helpers/notification_helper.dart
// [v1.1 — 2026-11-05] — FIX: Optimized Firestore broadcast query, added HTTP status check, and formatted.

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../../features/notifications/models/notification_model.dart';

class NotificationHelper {
  NotificationHelper._();

  // ✅ رابط Cloudflare Worker (يُفضل نقله لاحقاً إلى متغيرات البيئة)
  static const String _workerUrl =
      'https://solitary-thunder-fe28.mohtorg1971.workers.dev';

  /// إرسال إشعار لمستخدم معين (أو للجميع) وحفظه في قاعدة البيانات.
  static Future<void> send({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? route,
    Map<String, dynamic> data = const {},
  }) async {
    if (userId.isEmpty) return;

    try {
      // 1. حفظ الإشعار في Firestore (In-App Notification)
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'data': {
          ...data,
          if (route != null) 'route': route,
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. إرسال Push Notification
      await _sendPushNotification(
        userId: userId,
        title: title,
        body: body,
        data: {
          ...data,
          if (route != null) 'route': route,
        },
      );
    } catch (e) {
      debugPrint('❌ NotificationHelper.send error: $e');
    }
  }

  static Future<void> _sendPushNotification({
    required String userId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      List<String> tokens = [];

      if (userId == 'all') {
        // إرسال للجميع (Broadcast)
        // نستخدم isGreaterThan: '' بدلاً من isNotEqualTo: null لتجنب مشاكل الـ Index
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('fcmToken', isGreaterThan: '')
            .get();

        tokens = snap.docs
            .map((d) => d.data()['fcmToken']?.toString() ?? '')
            .where((t) => t.isNotEmpty)
            .toList();
      } else {
        // إرسال لمستخدم واحد
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final token = doc.data()?['fcmToken']?.toString();
        if (token != null && token.isNotEmpty) {
          tokens.add(token);
        }
      }

      if (tokens.isEmpty) {
        debugPrint('⚠️ No valid FCM tokens found for user: $userId');
        return;
      }

      // تحذير إذا كانت البيانات كبيرة جداً (FCM limit is 4KB)
      final payloadString = jsonEncode(data);
      if (payloadString.length > 4000) {
        debugPrint(
            '⚠️ Warning: FCM data payload is large (${payloadString.length} bytes). May fail.');
      }

      final response = await http
          .post(
            Uri.parse(_workerUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tokens': tokens,
              'title': title,
              'body': body,
              'data': data,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('📢 Push Notification sent successfully to $userId');
      } else {
        debugPrint(
            '❌ Push Notification failed. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Push Notification error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Convenience Methods (دوال جاهزة للاستخدام السريع)
  // ═══════════════════════════════════════════════════════════════

  static Future<void> notifyPlaceBlocked(
    String userId,
    String placeName,
    String reason,
  ) {
    return send(
      userId: userId,
      title: '🚫 تم إيقاف نشاطك مؤقتاً',
      body: 'تم إيقاف "$placeName". السبب: $reason',
      type: NotificationType.placeBlocked,
      route: '/merchant/dashboard',
    );
  }

  static Future<void> notifyPlaceUnblocked(String userId, String placeName) {
    return send(
      userId: userId,
      title: '✅ تم تفعيل نشاطك',
      body: 'تم فك الحظر عن "$placeName" بنجاح. يمكنك الآن استقبال الطلبات.',
      type: NotificationType.placeUnblocked,
      route: '/merchant/dashboard',
    );
  }

  static Future<void> notifySupportReply(String userId, String code) {
    return send(
      userId: userId,
      title: '💬 رد جديد من الدعم',
      body: 'تم الرد على بلاغك ($code). يرجى فتح تفاصيل البلاغ للمراجعة.',
      type: NotificationType.supportReply,
      route: '/profile',
    );
  }

  static Future<void> notifyMerchantApproved(String userId) {
    return send(
      userId: userId,
      title: '🎉 تم قبول طلبك',
      body: 'تمت الموافقة على طلبك كتاجر. ابدأ الآن في إدارة نشاطك التجاري!',
      type: NotificationType.merchantApproved,
      route: '/merchant/dashboard',
    );
  }

  static Future<void> notifyMerchantRejected(String userId, String reason) {
    return send(
      userId: userId,
      title: '⚠️ طلبك يحتاج تعديل',
      body: 'السبب: $reason',
      type: NotificationType.merchantRejected,
      route: '/profile',
    );
  }

  static Future<void> notifyNewReviewForPlace({
    required String ownerUid,
    required String placeId,
    required String placeName,
    required double rating,
    required String comment,
  }) {
    return send(
      userId: ownerUid,
      title: '⭐ تقييم جديد على $placeName',
      body: 'حصلت على تقييم ${rating.toStringAsFixed(1)} نجوم. "$comment"',
      type: NotificationType.newReview,
      route: '/merchant/dashboard',
      data: {'placeId': placeId},
    );
  }
}
