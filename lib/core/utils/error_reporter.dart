// lib/core/utils/error_reporter.dart
//
// [v1.1] — FIX:
//   - إزالة RegExp (تحذير الإهمال) واستبداله بدالة _extractErrorCode تطابق
//     سلوك النمط السابق  \[.*?/(.*?)\]  تماماً.
//   - إضافة أقواس لجملة if (التزام بقاعدة curly_braces).
//   - اقتطاع stackTrace قبل الإرسال لتفادي تجاوز حد حجم مستند Firestore.
//   - KEPT: كل الوظائف والواجهة والتوقيعات العامة دون تغيير.

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
    if (_lastShownAt != null && now.difference(_lastShownAt!).inSeconds < 5) {
      return;
    }
    _lastShownAt = now;

    final errorString = error.toString();
    final errorCode = _extractErrorCode(errorString) ?? 'UNKNOWN';

    // ✅ إرسال لـ Firebase
    _sendToFirebase(errorCode, errorString, stackTrace);

    // ✅ عرض إشعار أنيق (تم إصلاح الخطأ هنا)
    _showUserToast(errorCode);
  }

  /// يستخرج الكود من نصوص مثل: "[firebase_auth/wrong-password] ..."
  /// فيعيد الجزء الواقع بين أول "/" وأول "]" التالية داخل قوسين مربعين
  /// على السطر نفسه (مطابق للنمط السابق \[.*?/(.*?)\]).
  static String? _extractErrorCode(String s) {
    bool isLineBreak(int c) => c == 10 || c == 13 || c == 0x2028 || c == 0x2029;

    var from = 0;
    while (true) {
      final open = s.indexOf('[', from);
      if (open < 0) return null;
      from = open + 1;

      // أول "/" بعد القوس على السطر نفسه
      var slash = open + 1;
      while (slash < s.length) {
        final c = s.codeUnitAt(slash);
        if (c == 47 || isLineBreak(c)) break;
        slash++;
      }
      if (slash >= s.length || s.codeUnitAt(slash) != 47) continue;

      // أول "]" بعد الشرطة المائلة على السطر نفسه
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

  static void _showUserToast(String code) {
    // ✅ التعديل الجوهري: ننتظر حتى ينتهي البناء (Build) ثم نعرض الإشعار
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = messengerKey.currentState;
      if (messenger == null) return;

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Colors.greenAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'تم إبلاغ فريق الدعم',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white),
                      ),
                      Text(
                        'سنعمل على حل المشكلة قريباً • كود: $code',
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
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    });
  }
}
