import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

/// Utility class to create notifications in Firestore.
/// Can be called from anywhere (admin app, merchant app, etc.)
class NotificationHelper {
  NotificationHelper._();

  static Future<void> send({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? route, // ✅ جديد: مسار الشاشة التي تفتح عند الضغط
    Map<String, dynamic> data = const {},
  }) async {
    if (userId.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'data': {
          ...data,
          if (route != null) 'route': route, // ✅ حفظ المسار داخل data
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // silent fail - notifications should never break the app
    }
  }

  // ─── Convenience methods ───

  static Future<void> notifyPlaceBlocked(
      String userId, String placeName, String reason) {
    return send(
      userId: userId,
      title: '🚫 تم إيقاف نشاطك مؤقتاً',
      body: 'تم إيقاف "$placeName". السبب: $reason',
      type: NotificationType.placeBlocked,
      route: '/merchant/dashboard', // ✅ يفتح لوحة التاجر
    );
  }

  static Future<void> notifyPlaceUnblocked(String userId, String placeName) {
    return send(
      userId: userId,
      title: '✅ تم تفعيل نشاطك',
      body: 'تم فك الحظر عن "$placeName" بنجاح. يمكنك الآن استقبال الطلبات.',
      type: NotificationType.placeUnblocked,
      route: '/merchant/dashboard', // ✅
    );
  }

  static Future<void> notifySupportReply(String userId, String code) {
    return send(
      userId: userId,
      title: '💬 رد جديد من الدعم',
      body: 'تم الرد على بلاغك ($code). يرجى فتح تفاصيل البلاغ للمراجعة.',
      type: NotificationType.supportReply,
      route: '/profile', // ✅ يفتح شاشة الحساب
    );
  }

  static Future<void> notifyMerchantApproved(String userId) {
    return send(
      userId: userId,
      title: '🎉 تم قبول طلبك',
      body: 'تمت الموافقة على طلبك كتاجر. ابدأ الآن في إدارة نشاطك التجاري!',
      type: NotificationType.merchantApproved,
      route: '/merchant/dashboard', // ✅
    );
  }

  static Future<void> notifyMerchantRejected(String userId, String reason) {
    return send(
      userId: userId,
      title: '⚠️ طلبك يحتاج تعديل',
      body: 'السبب: $reason',
      type: NotificationType.merchantRejected,
      route: '/profile', // ✅
    );
  }
}
