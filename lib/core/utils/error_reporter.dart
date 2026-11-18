// lib/core/utils/error_reporter.dart
// [v1.2] — FIXED:
//   - Changed success icon to error icon (UX fix).
//   - Hid "UNKNOWN" error codes from the user (they still go to Firebase).
//   - Improved user-facing text for errors.
//   - Kept all Firebase logging and rate-limiting logic intact.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ErrorReporter {
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static DateTime? _lastShownAt;

  static void showError(Object error, [StackTrace? stackTrace]) {
    final now = DateTime.now();
    // منع تكرار الإشعار لنفس الخطأ في وقت قصير
    if (_lastShownAt != null && now.difference(_lastShownAt!).inSeconds < 5) {
      return;
    }
    _lastShownAt = now;

    final errorString = error.toString();

    // طباعة الخطأ في الـ Console للمبرمج
    debugPrint('🔥 ACTUAL ERROR: $errorString');
    if (stackTrace != null) debugPrint('🔥 STACK: $stackTrace');

    // محاولة استخراج كود الخطأ (إذا كان من Firebase)
    final errorCode = _extractErrorCode(errorString);

    // إرسال التذكرة لـ Firebase (يتم في الخلفية دون تعطيل المستخدم)
    _sendToFirebase(errorCode ?? 'UNKNOWN', errorString, stackTrace);

    // عرض الإشعار للمستخدم
    _showUserToast(errorCode);
  }

  static String? _extractErrorCode(String s) {
    bool isLineBreak(int c) => c == 10 || c == 13 || c == 0x2028 || c == 0x2029;

    var from = 0;
    while (true) {
      final open = s.indexOf('[', from);
      if (open < 0) return null;
      from = open + 1;

      var slash = open + 1;
      while (slash < s.length) {
        final c = s.codeUnitAt(slash);
        if (c == 47 || isLineBreak(c)) break;
        slash++;
      }
      if (slash >= s.length || s.codeUnitAt(slash) != 47) continue;

      var close = slash + 1;
      while (close < s.length) {
        final c = s.codeUnitAt(close);
        if (c == 93 || isLineBreak(c)) break;
        close++;
      }
      if (close >= s.length || s.codeUnitAt(close) != 93) continue;

      return s.substring(slash + 1, close);
    }
  }

  static Future<void> _sendToFirebase(
      String code, String message, StackTrace? stack) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? 'anonymous';
      final stackString = stack?.toString() ?? '';

      await FirebaseFirestore.instance.collection('support_tickets').add({
        'userId': uid,
        'userName': user?.displayName ?? 'زائر',
        'userEmail': user?.email ?? '',
        'errorCode': code,
        'errorMessage':
            message.length > 2000 ? message.substring(0, 2000) : message,
        'stackTrace': stackString.length > 4000
            ? stackString.substring(0, 4000)
            : stackString,
        'appVersion': '1.0.0+6',
        'platform': kIsWeb ? 'web' : 'mobile',
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ Support ticket sent: $code');
    } catch (e) {
      debugPrint('❌ Failed to send support ticket: $e');
    }
  }

  static void _showUserToast(String? code) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = messengerKey.currentState;
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();

      // تحديد ما إذا كنا سنعرض الكود للمستخدم أم لا
      // لا نعرض UNKNOWN لأنه لا يفيد المستخدم
      final bool showCode = code != null && code != 'UNKNOWN';

      messenger.showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                // ✅ تم تغيير الأيقونة إلى خطأ أحمر بدلاً من صح أخضر
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حدث خطأ غير متوقع', // ✅ رسالة واضحة بدلاً من "تم رفع التقرير"
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                      Text(
                        showCode
                            ? 'تم إبلاغ الدعم • كود: $code'
                            : 'تم إبلاغ فريق الدعم للمراجعة، يرجى المحاولة لاحقاً.',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: const Color(0xFF2E2E2E),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    });
  }
}
